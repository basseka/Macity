// supabase functions deploy send-notifications --no-verify-jwt
//
// Envoie les rappels J-2/J-1(/H-1) en attente dans notification_queue.
// Couvre 2 flux : events publies par un pro (establishment_events, via
// event_id) ET events du feed likes par un user (scraped_events, via
// event_identifiant, cf migration 20260916190000_liked_events_reminders).
//
// Secrets requis (Supabase Dashboard > Edge Functions > Secrets):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVICE_ACCOUNT_JSON

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SA_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;
const BATCH_SIZE = 500;

const sbHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

interface QueueRow {
  id: number;
  user_id: string;
  event_id: number;
  event_identifiant: string | null;
  type: string;
  batch_key: string;
  event_title: string;
  event_starts_at: string | null;
  establishment_id: string;
}

// ─── FCM v1 OAuth2 (meme pattern que send-mairie-notification) ───────

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

function base64url(data: Uint8Array): string {
  let b64 = "";
  for (let i = 0; i < data.length; i++) {
    b64 += String.fromCharCode(data[i]);
  }
  return btoa(b64).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64urlStr(str: string): string {
  return base64url(new TextEncoder().encode(str));
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryStr = atob(pemBody);
  const bytes = new Uint8Array(binaryStr.length);
  for (let i = 0; i < binaryStr.length; i++) {
    bytes[i] = binaryStr.charCodeAt(i);
  }
  return crypto.subtle.importKey(
    "pkcs8",
    bytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && now < tokenExpiresAt - 60) {
    return cachedAccessToken;
  }

  const header = base64urlStr(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64urlStr(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const signingInput = `${header}.${payload}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64url(new Uint8Array(sig))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth2 token error: ${await tokenRes.text()}`);
  }

  const tokenData = await tokenRes.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);
  return cachedAccessToken!;
}

Deno.serve(async (_req) => {
  try {
    const sa: ServiceAccount = JSON.parse(FCM_SA_JSON);

    // 1. Claim les notifications dues (via fonction SQL avec lock)
    const claimRes = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/claim_pending_notifications`,
      {
        method: "POST",
        headers: sbHeaders,
        body: JSON.stringify({ batch_size: BATCH_SIZE }),
      },
    );

    if (!claimRes.ok) {
      const err = await claimRes.text();
      throw new Error(`claim failed: ${err}`);
    }

    const pending: QueueRow[] = await claimRes.json();
    if (!pending.length) {
      return json({ sent: 0, failed: 0 });
    }

    // 2. Grouper par user_id
    const byUser = new Map<string, QueueRow[]>();
    for (const row of pending) {
      const list = byUser.get(row.user_id) ?? [];
      list.push(row);
      byUser.set(row.user_id, list);
    }

    const accessToken = await getAccessToken(sa);
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    const sentIds: number[] = [];
    const failedIds: number[] = [];

    // 3. Pour chaque user, recuperer ses tokens et envoyer
    for (const [userId, notifications] of byUser) {
      const tokensRes = await fetch(
        `${SUPABASE_URL}/rest/v1/user_fcm_tokens?user_id=eq.${userId}&select=token`,
        { headers: sbHeaders },
      );
      const tokens: { token: string }[] = tokensRes.ok
        ? await tokensRes.json()
        : [];

      if (!tokens.length) {
        for (const n of notifications) failedIds.push(n.id);
        continue;
      }

      // Grouper par batch_key pour eviter le spam (un seul push par
      // event/date meme si J-2 et J-1 tombent claimes dans le meme run)
      const byBatch = new Map<string, QueueRow[]>();
      for (const n of notifications) {
        const key = n.batch_key ?? `${n.event_id}`;
        const list = byBatch.get(key) ?? [];
        list.push(n);
        byBatch.set(key, list);
      }

      for (const [, group] of byBatch) {
        // Le plus proche dans le temps (1_day > 2_days > 1_hour cote urgence
        // d'affichage) : on prend la ligne la plus recemment due du groupe.
        const primary = group[0];
        const title = group.length === 1
          ? `Rappel : ${primary.event_title}`
          : `${group.length} evenements a venir`;
        const body = group.length === 1
          ? formatBody(primary)
          : group.map((g) => g.event_title).join(", ");

        // Deep link vers la fiche : uniquement resolvable pour un event du
        // feed like (scraped_events, event_identifiant) : le flux pro
        // (establishment_events, event_id bigint) n'a pas d'ecran de detail
        // dedie a ce jour, on n'envoie pas de deep link casse dans ce cas.
        const eventIdentifiant = group.length === 1
          ? primary.event_identifiant
          : null;

        for (const { token } of tokens) {
          try {
            const fcmRes = await fetch(fcmUrl, {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                message: {
                  token,
                  notification: { title, body },
                  data: {
                    type: "event_reminder",
                    ...(eventIdentifiant ? { event_id: eventIdentifiant } : {}),
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                  },
                  android: {
                    priority: "high",
                    notification: { channel_id: "pulz_reminders" },
                  },
                },
              }),
            });

            if (!fcmRes.ok) {
              const errText = await fcmRes.text();
              if (
                errText.includes("UNREGISTERED") ||
                errText.includes("INVALID_ARGUMENT") ||
                errText.includes("NOT_FOUND")
              ) {
                await fetch(
                  `${SUPABASE_URL}/rest/v1/user_fcm_tokens?token=eq.${
                    encodeURIComponent(token)
                  }`,
                  { method: "DELETE", headers: sbHeaders },
                );
              }
            }
          } catch {
            // Erreur reseau FCM, on continue avec le token suivant
          }
        }

        for (const n of group) sentIds.push(n.id);
      }
    }

    // 4. Mettre a jour les statuts dans la queue (un PATCH par id : la
    // syntaxe PostgREST pour un filtre "in" via fetch ajoute peu de valeur
    // ici vu les volumes, et evite tout risque de PATCH sans filtre).
    for (const id of sentIds) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${id}`,
        {
          method: "PATCH",
          headers: { ...sbHeaders, Prefer: "return=minimal" },
          body: JSON.stringify({
            status: "sent",
            sent_at: new Date().toISOString(),
          }),
        },
      );
    }

    for (const id of failedIds) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${id}`,
        {
          method: "PATCH",
          headers: { ...sbHeaders, Prefer: "return=minimal" },
          body: JSON.stringify({ status: "failed" }),
        },
      );
    }

    return json({ sent: sentIds.length, failed: failedIds.length });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

function formatBody(n: QueueRow): string {
  if (n.event_starts_at) {
    const date = new Date(n.event_starts_at);
    const formatted = date.toLocaleDateString("fr-FR", {
      weekday: "long",
      day: "numeric",
      month: "long",
      hour: "2-digit",
      minute: "2-digit",
    });
    switch (n.type) {
      case "2_days":
        return `Dans 2 jours : ${formatted}`;
      case "1_day":
        return `Demain : ${formatted}`;
      case "1_hour":
        return `Dans 1 heure !`;
      default:
        return formatted;
    }
  }
  // Pas d'heure fiable (event scrape, cf migration) : message generique.
  switch (n.type) {
    case "2_days":
      return "Dans 2 jours, ne l'oublie pas !";
    case "1_day":
      return "C'est demain !";
    default:
      return "Bientot !";
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

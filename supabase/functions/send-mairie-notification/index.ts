// supabase functions deploy send-mairie-notification --no-verify-jwt
//
// Envoie un push FCM aux habitants d'une ville quand la mairie publie un message.
// Appele par le dashboard macity-admin apres insertion dans mairie_notifications.
//
// Secrets requis : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVICE_ACCOUNT_JSON
//
// POST body : { notification_id: string }

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SA_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;

const sbHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

// ─── FCM v1 OAuth2 ───────────────────────────────────────────

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
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth2 token error: ${await tokenRes.text()}`);
  }

  const tokenData = await tokenRes.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);
  return cachedAccessToken!;
}

// ─── Helpers ─────────────────────────────────────────────────

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * Normalise la ville pour le matching.
 * "Toulouse (31000)" → "toulouse"
 * "Saint-Gaudens" → "saint-gaudens"
 */
function normalizeVille(ville: string): string {
  return ville
    .replace(/\s*\(.*\)$/, "") // retire "(31000)"
    .trim()
    .toLowerCase();
}

// ─── Main handler ────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const sa: ServiceAccount = JSON.parse(FCM_SA_JSON);

    const { notification_id } = await req.json();
    if (!notification_id) {
      return json({ error: "notification_id requis" }, 400);
    }

    // 1. Recuperer la notification mairie
    const notifRes = await fetch(
      `${SUPABASE_URL}/rest/v1/mairie_notifications?id=eq.${notification_id}&select=id,ville,title,body`,
      { headers: sbHeaders },
    );
    if (!notifRes.ok) throw new Error(`fetch notif: ${await notifRes.text()}`);

    const notifs = await notifRes.json();
    if (!notifs.length) {
      return json({ error: "Notification introuvable" }, 404);
    }

    const notif = notifs[0];
    const villeNormalized = normalizeVille(notif.ville);

    // 2. Trouver les user_ids dont la ville correspond
    //    user_profiles.ville stocke "Toulouse (31000)" ou "Toulouse"
    //    On cherche avec ilike pour matcher les deux formats
    const usersRes = await fetch(
      `${SUPABASE_URL}/rest/v1/user_profiles?ville=ilike.${encodeURIComponent(villeNormalized + "*")}&select=user_id`,
      { headers: sbHeaders },
    );
    if (!usersRes.ok) throw new Error(`fetch users: ${await usersRes.text()}`);

    const users: { user_id: string }[] = await usersRes.json();
    if (!users.length) {
      return json({ sent: 0, reason: "Aucun habitant inscrit pour cette ville" });
    }

    // 3. Recuperer les tokens FCM de ces users
    const userIds = users.map((u) => u.user_id);
    // PostgREST : user_id=in.(id1,id2,id3)
    const inList = userIds.join(",");
    const tokensRes = await fetch(
      `${SUPABASE_URL}/rest/v1/user_fcm_tokens?user_id=in.(${encodeURIComponent(inList)})&select=token`,
      { headers: sbHeaders },
    );
    if (!tokensRes.ok) throw new Error(`fetch tokens: ${await tokensRes.text()}`);

    const tokens: { token: string }[] = await tokensRes.json();
    if (!tokens.length) {
      return json({ sent: 0, reason: "Aucun token FCM pour les habitants de cette ville" });
    }

    // 4. Envoyer le push a chaque device
    const accessToken = await getAccessToken(sa);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let sent = 0;
    let failed = 0;
    let cleaned = 0;

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
              notification: {
                title: `🏛️ Mairie de ${notif.ville}`,
                body: notif.title + (notif.body ? ` — ${notif.body.substring(0, 100)}` : ""),
              },
              data: {
                type: "mairie_notification",
                notification_id: String(notif.id),
                ville: notif.ville,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: "pulz_reminders",
                },
              },
            },
          }),
        });

        if (fcmRes.ok) {
          sent++;
        } else {
          const errBody = await fcmRes.text();
          if (
            errBody.includes("UNREGISTERED") ||
            errBody.includes("INVALID_ARGUMENT") ||
            errBody.includes("NOT_FOUND")
          ) {
            await fetch(
              `${SUPABASE_URL}/rest/v1/user_fcm_tokens?token=eq.${encodeURIComponent(token)}`,
              { method: "DELETE", headers: sbHeaders },
            );
            cleaned++;
          }
          failed++;
        }
      } catch {
        failed++;
      }
    }

    return json({
      ville: notif.ville,
      habitants: users.length,
      tokens: tokens.length,
      sent,
      failed,
      cleaned,
    });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

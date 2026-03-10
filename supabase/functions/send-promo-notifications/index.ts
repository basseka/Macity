// supabase functions deploy send-promo-notifications --no-verify-jwt
//
// Notification promotionnelle toutes les 30 min, rotation sur 8 univers.
// Garde horaire : 9h00-22h30 (Europe/Paris).
//
// Secrets requis : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVICE_ACCOUNT_JSON

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
  const bytes = data;
  const len = bytes.length;
  for (let i = 0; i < len; i++) {
    b64 += String.fromCharCode(bytes[i]);
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

// ─── Universes ───────────────────────────────────────────────

const UNIVERSES = [
  "day",
  "sport",
  "culture",
  "family",
  "food",
  "gaming",
  "night",
  "tourisme",
] as const;

type Universe = (typeof UNIVERSES)[number];

const STATIC_PROMOS: Record<string, { title: string; body: string }[]> = {
  food: [
    { title: "🍽️ Food & Lifestyle", body: "Decouvrez les meilleurs restos et spots food de Toulouse !" },
    { title: "🍽️ Food & Lifestyle", body: "Envie de bien manger ? Explorez nos adresses gourmandes a Toulouse." },
    { title: "🍽️ Food & Lifestyle", body: "Brunch, street food, gastronomie… Trouvez votre bonheur sur Pulz !" },
  ],
  gaming: [
    { title: "🎮 Gaming & Pop Culture", body: "Retrouvez les events gaming et pop culture pres de chez vous !" },
    { title: "🎮 Gaming & Pop Culture", body: "Tournois, LAN, conventions… Ne ratez rien avec Pulz !" },
    { title: "🎮 Gaming & Pop Culture", body: "Decouvrez la scene gaming et geek de Toulouse sur Pulz." },
  ],
};

// ─── Helpers ─────────────────────────────────────────────────

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function parisHour(): number {
  const paris = new Date(
    new Date().toLocaleString("en-US", { timeZone: "Europe/Paris" }),
  );
  return paris.getHours();
}

function todayParis(): string {
  const paris = new Date(
    new Date().toLocaleString("en-US", { timeZone: "Europe/Paris" }),
  );
  const y = paris.getFullYear();
  const m = String(paris.getMonth() + 1).padStart(2, "0");
  const d = String(paris.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function formatDateFr(dateStr: string): string {
  try {
    const d = new Date(dateStr + "T12:00:00");
    return d.toLocaleDateString("fr-FR", {
      weekday: "short",
      day: "numeric",
      month: "long",
    });
  } catch {
    return dateStr;
  }
}

// ─── Fetch promo per universe ────────────────────────────────

interface PromoContent {
  title: string;
  body: string;
}

async function fetchPromoForUniverse(universe: Universe): Promise<PromoContent> {
  const today = todayParis();

  switch (universe) {
    case "day":
    case "culture":
    case "night":
    case "family":
      return await fetchScrapedEvent(universe, today);
    case "sport":
      return await fetchMatch(today);
    case "tourisme":
      return await fetchTouristicPoint();
    case "food":
    case "gaming": {
      try {
        const result = await fetchScrapedEvent(universe, today);
        if (result.body !== "") return result;
      } catch { /* fallback */ }
      const promos = STATIC_PROMOS[universe];
      return promos[Math.floor(Math.random() * promos.length)];
    }
  }
}

async function fetchScrapedEvent(rubrique: string, today: string): Promise<PromoContent> {
  const url =
    `${SUPABASE_URL}/rest/v1/scraped_events` +
    `?rubrique=eq.${rubrique}&date_debut=gte.${today}` +
    `&order=date_debut.asc&limit=10` +
    `&select=nom_de_la_manifestation,date_debut,lieu_nom`;

  const res = await fetch(url, { headers: sbHeaders });
  if (!res.ok) throw new Error(`scraped_events: ${await res.text()}`);

  const rows: { nom_de_la_manifestation: string; date_debut: string; lieu_nom: string }[] =
    await res.json();

  if (!rows.length) return fallbackForRubrique(rubrique);

  const evt = rows[Math.floor(Math.random() * rows.length)];
  const titles: Record<string, string> = {
    day: "☀️ Concerts & Spectacles",
    culture: "🎨 Culture & Arts",
    night: "🌙 Nuit & Sorties",
    family: "👨‍👩‍👧‍👦 En Famille",
    food: "🍽️ Food & Lifestyle",
    gaming: "🎮 Gaming & Pop Culture",
  };

  return {
    title: titles[rubrique] ?? rubrique,
    body: `${evt.nom_de_la_manifestation} - ${formatDateFr(evt.date_debut)} | ${evt.lieu_nom || "Toulouse"}`,
  };
}

async function fetchMatch(today: string): Promise<PromoContent> {
  const url =
    `${SUPABASE_URL}/rest/v1/matchs` +
    `?date=gte.${today}&order=date.asc,heure.asc&limit=10` +
    `&select=equipe_dom,equipe_ext,date,heure,lieu,competition`;

  const res = await fetch(url, { headers: sbHeaders });
  if (!res.ok) throw new Error(`matchs: ${await res.text()}`);

  const rows: { equipe_dom: string; equipe_ext: string; date: string; heure: string; lieu: string; competition: string }[] =
    await res.json();

  if (!rows.length) {
    return { title: "⚽ Sport", body: "Restez connectes pour les prochains matchs a Toulouse !" };
  }

  const m = rows[Math.floor(Math.random() * rows.length)];
  return {
    title: `⚽ Sport - ${m.competition}`,
    body: `${m.equipe_dom} vs ${m.equipe_ext} - ${formatDateFr(m.date)} ${m.heure || ""} | ${m.lieu || "Toulouse"}`,
  };
}

async function fetchTouristicPoint(): Promise<PromoContent> {
  const url =
    `${SUPABASE_URL}/rest/v1/touristic_points_toulouse` +
    `?is_active=eq.true&select=nom,description,adresse`;

  const res = await fetch(url, { headers: sbHeaders });
  if (!res.ok) throw new Error(`touristic_points: ${await res.text()}`);

  const rows: { nom: string; description: string; adresse: string }[] = await res.json();

  if (!rows.length) {
    return { title: "✈️ Tourisme", body: "Decouvrez les plus beaux lieux de Toulouse sur Pulz !" };
  }

  const pt = rows[Math.floor(Math.random() * rows.length)];
  const desc = pt.description && pt.description.length > 80
    ? pt.description.substring(0, 77) + "..."
    : pt.description || "";

  return {
    title: `✈️ A decouvrir : ${pt.nom}`,
    body: `${desc} | ${pt.adresse || "Toulouse"}`,
  };
}

function fallbackForRubrique(rubrique: string): PromoContent {
  const map: Record<string, PromoContent> = {
    day: { title: "☀️ Concerts & Spectacles", body: "Decouvrez les prochains evenements a Toulouse !" },
    culture: { title: "🎨 Culture & Arts", body: "Expos, spectacles, visites… La culture vous attend a Toulouse !" },
    night: { title: "🌙 Nuit & Sorties", body: "Concerts, soirees, DJ sets… Sortez ce soir a Toulouse !" },
    family: { title: "👨‍👩‍👧‍👦 En Famille", body: "Activites en famille ce week-end a Toulouse !" },
    food: { title: "🍽️ Food & Lifestyle", body: "Les meilleures adresses food de Toulouse vous attendent !" },
    gaming: { title: "🎮 Gaming & Pop Culture", body: "Tournois et events gaming a Toulouse !" },
  };
  return map[rubrique] ?? { title: "Pulz", body: "Decouvrez les events a Toulouse !" };
}

// ─── FCM v1 send ─────────────────────────────────────────────

async function sendFcmToAll(
  sa: ServiceAccount,
  notification: PromoContent,
  universe: string,
): Promise<{ sent: number; failed: number; cleaned: number; errors: string[] }> {
  const tokensRes = await fetch(
    `${SUPABASE_URL}/rest/v1/user_fcm_tokens?select=token`,
    { headers: sbHeaders },
  );
  if (!tokensRes.ok) throw new Error(`fetch tokens: ${await tokensRes.text()}`);

  const tokens: { token: string }[] = await tokensRes.json();
  if (!tokens.length) return { sent: 0, failed: 0, cleaned: 0, errors: ["no tokens"] };

  const accessToken = await getAccessToken(sa);
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  let sent = 0;
  let failed = 0;
  let cleaned = 0;
  const errors: string[] = [];

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
              title: notification.title,
              body: notification.body,
            },
            data: {
              type: "promo_notification",
              universe,
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
        if (errors.length < 3) errors.push(`http-${fcmRes.status}: ${errBody.substring(0, 200)}`);

        // Token invalide → supprimer
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
    } catch (e) {
      if (errors.length < 3) errors.push(`catch: ${String(e).substring(0, 200)}`);
      failed++;
    }
  }

  return { sent, failed, cleaned, errors };
}

// ─── Main handler ────────────────────────────────────────────

Deno.serve(async (_req) => {
  try {
    // Parse service account
    const sa: ServiceAccount = JSON.parse(FCM_SA_JSON);

    // Garde horaire : 10h-21h (Paris)
    const hour = parisHour();
    if (hour < 10 || hour >= 21) {
      return json({ skipped: true, reason: "outside 10h-21h Paris time" });
    }

    // Lire l'état courant
    const stateRes = await fetch(
      `${SUPABASE_URL}/rest/v1/promo_notification_state?id=eq.1&select=current_index,last_sent_at`,
      { headers: sbHeaders },
    );
    if (!stateRes.ok) throw new Error(`read state: ${await stateRes.text()}`);

    const stateRows = await stateRes.json();
    if (!stateRows.length) throw new Error("promo_notification_state row missing");

    const currentIndex: number = stateRows[0].current_index;
    const universe = UNIVERSES[currentIndex % UNIVERSES.length];

    // Fetch le contenu promo
    const promo = await fetchPromoForUniverse(universe);

    // Envoyer à tous les devices
    const result = await sendFcmToAll(sa, promo, universe);

    // Avancer l'index
    const nextIndex = (currentIndex + 1) % UNIVERSES.length;
    await fetch(
      `${SUPABASE_URL}/rest/v1/promo_notification_state?id=eq.1`,
      {
        method: "PATCH",
        headers: { ...sbHeaders, Prefer: "return=minimal" },
        body: JSON.stringify({
          current_index: nextIndex,
          last_sent_at: new Date().toISOString(),
        }),
      },
    );

    return json({
      universe,
      notification: promo,
      next_universe: UNIVERSES[nextIndex],
      ...result,
    });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

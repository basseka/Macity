// supabase functions deploy scrape-mairie-lunion --no-verify-jwt
//
// Scrape les actualités + agenda de la mairie de L'Union (31240)
// - Actualités : HTML scraping de /actualites/ (WordPress Divi)
// - Agenda : API REST tribe/events/v1 (The Events Calendar)
// Upsert dans mairie_notifications.

import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";
import { logScraperError } from "../_shared/db.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};

const BASE = "https://www.ville-lunion.fr";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

// ── Scrape Actualités (HTML) ──

async function scrapeActualites(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/actualites/`, 15000);
  const results: MairieRow[] = [];

  // WordPress Divi blog: <article class="et_pb_post ...">
  const articleRegex =
    /<article[^>]*class="[^"]*et_pb_post[^"]*"[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // Title + link
    const titleMatch = block.match(
      /<h2\s+class="entry-title">\s*<a\s+href="([^"]+)"[^>]*>(.*?)<\/a>/,
    );
    if (!titleMatch) continue;
    const linkUrl = titleMatch[1];
    const title = cleanHtml(titleMatch[2]);
    if (!title) continue;

    // Image
    const imgMatch = block.match(/<img[^>]*src="([^"]+)"/);
    let photoUrl = imgMatch ? imgMatch[1] : "";
    // Get higher-res version
    if (photoUrl) photoUrl = photoUrl.replace(/-\d+x\d+\./, ".");

    // Body
    const bodyMatch = block.match(
      /<div\s+class="post-content-inner">([\s\S]*?)<\/div>/,
    );
    const body = bodyMatch ? cleanHtml(bodyMatch[1]).substring(0, 300) : "";

    results.push({
      ville: "L'Union",
      title,
      body,
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  return results;
}

// ── Scrape Agenda (REST API) ──

interface TribeEvent {
  title: string;
  url: string;
  description: string;
  start_date: string;
  end_date: string;
  image?: { url?: string };
  venue?: { venue?: string; address?: string };
  categories?: { name: string }[];
}

async function scrapeAgenda(): Promise<MairieRow[]> {
  // Fetch upcoming events via The Events Calendar REST API
  const today = new Date().toISOString().substring(0, 10);
  const apiUrl = `${BASE}/wp-json/tribe/events/v1/events?per_page=50&start_date=${today}`;

  const res = await fetch(apiUrl, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120",
    },
  });

  if (!res.ok) {
    throw new Error(`Tribe API ${res.status}: ${await res.text()}`);
  }

  const data = await res.json();
  const events: TribeEvent[] = data.events ?? [];
  const results: MairieRow[] = [];

  for (const evt of events) {
    const title = cleanHtml(evt.title);
    if (!title) continue;

    const linkUrl = evt.url ?? "";
    const photoUrl = evt.image?.url ?? "";

    // Build body from description + venue + date
    const descClean = cleanHtml(evt.description).substring(0, 250);
    const venueName = evt.venue?.venue ?? "";
    const categories = (evt.categories ?? []).map((c) => c.name).join(", ");

    const bodyParts: string[] = [];
    if (categories) bodyParts.push(`[${categories}]`);

    // Format date
    const startDate = evt.start_date?.substring(0, 10) ?? "";
    const startTime = evt.start_date?.substring(11, 16) ?? "";
    if (startDate) {
      const [y, m, d] = startDate.split("-");
      bodyParts.push(`${d}/${m}/${y}`);
    }
    if (startTime && startTime !== "00:00") bodyParts.push(startTime);
    if (venueName) bodyParts.push(venueName);
    if (descClean) bodyParts.push(descClean);

    const body = bodyParts.join(" - ");

    results.push({
      ville: "L'Union",
      title,
      body: body.substring(0, 500),
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  return results;
}

// ── Upsert ──

async function upsertNotifications(rows: MairieRow[]): Promise<number> {
  if (rows.length === 0) return 0;

  // Deduplicate by title
  const seen = new Set<string>();
  const deduped = rows.filter((r) => {
    if (seen.has(r.title)) return false;
    seen.add(r.title);
    return true;
  });

  const res = await fetch(`${SUPABASE_URL}/rest/v1/mairie_notifications`, {
    method: "POST",
    headers: supabaseHeaders,
    body: JSON.stringify(deduped),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error(`Upsert failed: ${res.status} ${err}`);
    return 0;
  }
  return deduped.length;
}

// ── Handler ──

Deno.serve(async (_req) => {
  const errors: string[] = [];

  try {
    const [actus, events] = await Promise.all([
      scrapeActualites().catch((e) => {
        errors.push(`actualites: ${(e as Error).message}`);
        return [] as MairieRow[];
      }),
      scrapeAgenda().catch((e) => {
        errors.push(`agenda: ${(e as Error).message}`);
        return [] as MairieRow[];
      }),
    ]);

    const allRows = [...actus, ...events];
    console.log(
      `Scraped L'Union: ${actus.length} actualités + ${events.length} agenda = ${allRows.length}`,
    );

    const upserted = await upsertNotifications(allRows);

    return new Response(
      JSON.stringify({
        ville: "L'Union",
        actualites: actus.length,
        agenda: events.length,
        scraped: allRows.length,
        upserted,
        errors,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-mairie-lunion FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-lunion",
      source: "ville-lunion.fr",
      ville: "L'Union",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "L'Union",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// supabase functions deploy scrape-mairie-plaisance --no-verify-jwt
//
// Scrape les actualités + agenda de Plaisance-du-Touch (31830)
// depuis https://www.plaisancedutouch.fr/ma-ville/actualites/
//    et  https://www.plaisancedutouch.fr/sortir-bouger/agenda/
// et upsert dans mairie_notifications.

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

const BASE = "https://www.plaisancedutouch.fr";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

/** Ensure URL is absolute. */
function absUrl(path: string): string {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  if (path.startsWith("/")) return BASE + path;
  return BASE + "/" + path;
}

/** Extract best image URL from a block (handles lazy-loading). */
function extractImage(block: string): string {
  // Try data-lazy-src first
  let m = block.match(/data-lazy-src="([^"]+)"/);
  if (!m) {
    // Fallback: noscript img
    m = block.match(/<noscript><img[^>]*src="([^"]+)"/);
  }
  if (!m) return "";
  // Remove WP thumbnail suffix for higher-res
  return m[1].replace(/-\d+x\d+\./, ".");
}

// ── Scrape Actualités ──

async function scrapeActualites(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/ma-ville/actualites/`, 15000);
  const results: MairieRow[] = [];

  const articleRegex = /<article[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // URL
    const urlMatch = block.match(
      /<a[^>]*href="([^"]*actualites\/[^"]+)"/,
    );
    if (!urlMatch) continue;
    const linkUrl = absUrl(urlMatch[1]);

    // Title
    const titleMatch = block.match(/<h[23][^>]*>(.*?)<\/h[23]>/s);
    if (!titleMatch) continue;
    const title = cleanHtml(titleMatch[1]);
    if (!title) continue;

    // Image
    const photoUrl = extractImage(block);

    // Excerpt
    const descMatch = block.match(
      /<div\s+class="card-excerpt">\s*<p>(.*?)<\/p>/s,
    );
    const body = descMatch
      ? cleanHtml(descMatch[1]).substring(0, 300)
      : "";

    results.push({
      ville: "Plaisance-du-Touch",
      title,
      body,
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  return results;
}

// ── Scrape Agenda ──

async function scrapeAgenda(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/sortir-bouger/agenda/`, 15000);
  const results: MairieRow[] = [];

  const articleRegex = /<article[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // URL
    const urlMatch = block.match(
      /<a[^>]*href="([^"]*agenda\/[^"]+)"/,
    );
    if (!urlMatch) continue;
    const linkUrl = absUrl(urlMatch[1]);

    // Title
    const titleMatch = block.match(/<h[23][^>]*>(.*?)<\/h[23]>/s);
    if (!titleMatch) continue;
    const title = cleanHtml(titleMatch[1]);
    if (!title) continue;

    // Date from
    const dayFrom = block.match(
      /date-from[^>]*>\s*<span class="date-day">(\d+)<\/span>\s*<span class="date-month">(\w+)<\/span>/s,
    );
    // Date to
    const dayTo = block.match(
      /date-to[^>]*>\s*<span class="date-day">(\d+)<\/span>\s*<span class="date-month">(\w+)<\/span>/s,
    );

    let dateStr = "";
    if (dayFrom) {
      dateStr = `${dayFrom[1]} ${dayFrom[2]}`;
      if (dayTo) dateStr += ` → ${dayTo[1]} ${dayTo[2]}`;
    }

    // Image
    const photoUrl = extractImage(block);

    // Location
    const locMatch = block.match(
      /card-location[^>]*>\s*([\s\S]*?)\s*<\/div>/,
    );
    const location = locMatch ? cleanHtml(locMatch[1]) : "";

    const bodyParts: string[] = [];
    if (dateStr) bodyParts.push(dateStr);
    if (location) bodyParts.push(location);
    const body = bodyParts.join(" - ");

    results.push({
      ville: "Plaisance-du-Touch",
      title,
      body,
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
      `Scraped Plaisance-du-Touch: ${actus.length} actualités + ${events.length} agenda = ${allRows.length}`,
    );

    const upserted = await upsertNotifications(allRows);

    return new Response(
      JSON.stringify({
        ville: "Plaisance-du-Touch",
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
    console.error("scrape-mairie-plaisance FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-plaisance",
      source: "plaisancedutouch.fr",
      ville: "Plaisance-du-Touch",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "Plaisance-du-Touch",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

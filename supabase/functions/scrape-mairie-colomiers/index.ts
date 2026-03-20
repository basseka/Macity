// supabase functions deploy scrape-mairie-colomiers --no-verify-jwt
//
// Scrape les actualités + agenda de la mairie de Colomiers (31770)
// depuis https://www.ville-colomiers.fr/a-la-une/actualites
//    et  https://www.ville-colomiers.fr/a-la-une/agenda
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

const BASE = "https://www.ville-colomiers.fr";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

/** Ensure URL is absolute and well-formed. */
function absUrl(path: string): string {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  if (path.startsWith("/")) return BASE + path;
  return BASE + "/" + path;
}

// ── Parse <article> blocks (same structure for actus & agenda) ──

function parseArticles(html: string, sourceType: string): MairieRow[] {
  const results: MairieRow[] = [];
  const articleRegex = /<article[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // URL
    const urlMatch = block.match(/href="([^"]+)"/);
    if (!urlMatch) continue;
    const linkUrl = absUrl(urlMatch[1]);

    // Title: <h2 class="titre"> or <h3 class="titre">
    const titleMatch = block.match(
      /<h[23][^>]*class="titre"[^>]*>(.*?)<\/h[23]>/s,
    );
    if (!titleMatch) continue;
    const title = cleanHtml(titleMatch[1]);
    if (!title) continue;

    // Image
    const imgMatch = block.match(/<img[^>]*src="([^"]+)"/);
    const photoUrl = imgMatch ? absUrl(imgMatch[1]) : "";

    // Description
    const descMatch = block.match(
      /<div\s+class="thumb-desc">\s*([\s\S]*?)\s*<\/div>/,
    );
    const desc = descMatch ? cleanHtml(descMatch[1]) : "";

    // Date (if present)
    const dateMatch = block.match(
      /<span[^>]*class="[^"]*date[^"]*"[^>]*>(.*?)<\/span>/s,
    );
    const dateText = dateMatch ? cleanHtml(dateMatch[1]) : "";

    const bodyParts: string[] = [];
    if (sourceType) bodyParts.push(`[${sourceType}]`);
    if (dateText) bodyParts.push(dateText);
    if (desc) bodyParts.push(desc);
    const body = bodyParts.join(" - ").substring(0, 500);

    results.push({
      ville: "Colomiers",
      title,
      body,
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  return results;
}

// ── Scrape both pages ──

async function scrapeActualites(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/a-la-une/actualites`, 15000);
  return parseArticles(html, "Actualité");
}

async function scrapeAgenda(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/a-la-une/agenda`, 15000);
  return parseArticles(html, "Agenda");
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
      `Scraped Colomiers: ${actus.length} actualités + ${events.length} agenda = ${allRows.length}`,
    );

    const upserted = await upsertNotifications(allRows);

    return new Response(
      JSON.stringify({
        ville: "Colomiers",
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
    console.error("scrape-mairie-colomiers FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-colomiers",
      source: "ville-colomiers.fr",
      ville: "Colomiers",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "Colomiers",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

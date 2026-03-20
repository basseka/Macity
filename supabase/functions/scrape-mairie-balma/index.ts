// supabase functions deploy scrape-mairie-balma --no-verify-jwt
//
// Scrape les actualités + agenda de la mairie de Balma (31130)
// depuis https://www.mairie-balma.fr/systeme/actualites/
//    et  https://www.mairie-balma.fr/systeme/agenda/
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

const BASE = "https://www.mairie-balma.fr";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

// ── Helpers ──

/** Extract first real image URL from a card block (handles multiline src). */
function extractImage(block: string): string {
  const m = block.match(
    /https:\/\/www\.mairie-balma\.fr\/wp-content\/uploads\/[^\s"]+\.(?:webp|jpg|png)/
  );
  return m ? m[0].trim() : "";
}

// ── Scrape Actualités ──

async function scrapeActualites(): Promise<MairieRow[]> {
  const html = await fetchHtml(`${BASE}/systeme/actualites/`, 15000);
  const results: MairieRow[] = [];

  const articleRegex =
    /<article\s+class="card[^"]*actualites[^"]*"[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // URL
    const urlMatch = block.match(
      /<a\s+[^>]*href="(https:\/\/www\.mairie-balma\.fr\/actualites\/[^"]+)"/
    );
    if (!urlMatch) continue;
    const linkUrl = urlMatch[1];

    // Title
    const titleMatch = block.match(
      /<h3\s+class="card__title">(.*?)<\/h3>/s
    );
    if (!titleMatch) continue;
    const title = cleanHtml(titleMatch[1]);
    if (!title) continue;

    // Image
    const photoUrl = extractImage(block);

    // Description
    const descMatch = block.match(
      /<div\s+class="card__description">\s*<p>(.*?)<\/p>/s
    );
    const body = descMatch ? cleanHtml(descMatch[1]) : "";

    results.push({
      ville: "Balma",
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
  const html = await fetchHtml(`${BASE}/systeme/agenda/`, 15000);
  const results: MairieRow[] = [];

  const articleRegex =
    /<article\s+class="card[^"]*"[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // Only keep agenda items
    const urlMatch = block.match(
      /<a\s+[^>]*href="([^"]*\/agenda\/[^"]+)"/
    );
    if (!urlMatch) continue;
    let linkUrl = urlMatch[1];
    if (!linkUrl.startsWith("http")) linkUrl = BASE + linkUrl;

    // Title
    const titleMatch = block.match(
      /<h3\s+class="card__title">(.*?)<\/h3>/s
    );
    if (!titleMatch) continue;
    const title = cleanHtml(titleMatch[1]);
    if (!title) continue;

    // Category
    const catMatch = block.match(
      /<p\s+class="card__category">(.*?)<\/p>/s
    );
    const category = catMatch ? cleanHtml(catMatch[1]) : "";

    // Description
    const descMatch = block.match(
      /<div\s+class="card__description">\s*<p>(.*?)<\/p>/s
    );
    const desc = descMatch ? cleanHtml(descMatch[1]) : "";

    // Body: prepend category if present
    const body = category ? `[${category}] ${desc}` : desc;

    // Image (agenda cards may not have images)
    const photoUrl = extractImage(block);

    results.push({
      ville: "Balma",
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

  // Deduplicate by title (keep first)
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
  let totalScraped = 0;

  try {
    // Scrape both pages in parallel
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
    totalScraped = allRows.length;
    console.log(
      `Scraped Balma: ${actus.length} actualités + ${events.length} agenda = ${totalScraped}`
    );

    const upserted = await upsertNotifications(allRows);

    return new Response(
      JSON.stringify({
        ville: "Balma",
        actualites: actus.length,
        agenda: events.length,
        scraped: totalScraped,
        upserted,
        errors,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-mairie-balma FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-balma",
      source: "mairie-balma.fr",
      ville: "Balma",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "Balma",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// supabase functions deploy scrape-mairie-montrabe --no-verify-jwt
//
// Scrape l'agenda de la mairie de Montrabé (31850)
// depuis https://www.mairie-montrabe.fr/agenda/
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

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

// ── Scraper ──

async function scrapeMontrabeAgenda(): Promise<MairieRow[]> {
  const html = await fetchHtml(
    "https://www.mairie-montrabe.fr/agenda/",
    15000,
  );
  const results: MairieRow[] = [];

  // Find all h2.agenda__title positions, then extract context around each
  const titleRegex = /<h2[^>]*agenda__title[^>]*>(.*?)<\/h2>/gs;
  const titles: { index: number; raw: string }[] = [];
  let m;
  while ((m = titleRegex.exec(html)) !== null) {
    titles.push({ index: m.index, raw: m[1] });
  }

  for (const { index, raw } of titles) {
    const title = cleanHtml(raw);
    if (!title) continue;

    // Look back ~2000 chars for URL, date, category, image
    const before = html.substring(Math.max(0, index - 2000), index);
    // Look forward ~1000 chars for location, time
    const after = html.substring(
      index,
      Math.min(html.length, index + 1500),
    );

    // URL
    const urlMatch = before.match(
      /href=["']([^"']*mairie-montrabe\.fr\/agenda\/[^"']+)["']/,
    );
    const linkUrl = urlMatch ? urlMatch[1] : "";

    // Date: <span class="text-3xl">22.</span><span class="text-3xl">03</span><span class="text-lg">.2026</span>
    const dateNums = [...before.matchAll(/text-3xl[^>]*>(\d+)/g)].map(
      (dm) => dm[1],
    );
    const yearMatch = before.match(/text-lg[^>]*>[.\s]*(\d{4})/);
    let dateStr = "";
    if (dateNums.length >= 2 && yearMatch) {
      // Take the last two date numbers (closest to this title)
      const day = dateNums[dateNums.length - 2];
      const month = dateNums[dateNums.length - 1];
      dateStr = `${day}/${month}/${yearMatch[1]}`;
    }

    // Image (lazy-loaded)
    const imgMatch = before.match(/data-src="([^"]+)"/);
    const photoUrl = imgMatch ? imgMatch[1] : "";

    // Category
    const catMatch = before.match(
      /border-primaryYellow[^>]*>\s*([A-Za-zÀ-ÿ\s]+?)\s*<\/span>/,
    );
    const category = catMatch ? catMatch[1].trim() : "";

    // Location (fa-store-alt icon)
    const locMatch = after.match(
      /fa-store-alt[\s\S]*?<span>([^<]+)/,
    );
    const location = locMatch ? locMatch[1].trim() : "";

    // Time (fa-clock icon)
    const timeMatch = after.match(
      /fa-clock[\s\S]*?<span>\s*([\s\S]*?)<\/span>/,
    );
    let timeText = "";
    if (timeMatch) {
      timeText = timeMatch[1].replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    // Build body
    const bodyParts: string[] = [];
    if (category) bodyParts.push(`[${category}]`);
    if (dateStr) bodyParts.push(dateStr);
    if (timeText) bodyParts.push(timeText);
    if (location) bodyParts.push(location);
    const body = bodyParts.join(" - ");

    results.push({
      ville: "Montrabé",
      title,
      body,
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  // Deduplicate by title
  const seen = new Set<string>();
  return results.filter((r) => {
    if (seen.has(r.title)) return false;
    seen.add(r.title);
    return true;
  });
}

// ── Upsert ──

async function upsertNotifications(rows: MairieRow[]): Promise<number> {
  if (rows.length === 0) return 0;

  const res = await fetch(`${SUPABASE_URL}/rest/v1/mairie_notifications`, {
    method: "POST",
    headers: supabaseHeaders,
    body: JSON.stringify(rows),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error(`Upsert failed: ${res.status} ${err}`);
    return 0;
  }
  return rows.length;
}

// ── Handler ──

Deno.serve(async (_req) => {
  try {
    const rows = await scrapeMontrabeAgenda();
    console.log(`Scraped ${rows.length} events from Montrabé`);

    const upserted = await upsertNotifications(rows);

    return new Response(
      JSON.stringify({
        ville: "Montrabé",
        scraped: rows.length,
        upserted,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-mairie-montrabe FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-montrabe",
      source: "mairie-montrabe.fr",
      ville: "Montrabé",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "Montrabé",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

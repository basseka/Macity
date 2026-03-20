// supabase functions deploy scrape-mairie-beaupuy --no-verify-jwt
//
// Scrape les actualités de la mairie de Beaupuy (31850)
// depuis https://www.ville-beaupuy.fr/actualites/
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

async function scrapeBeaupuyActualites(): Promise<MairieRow[]> {
  const html = await fetchHtml("https://www.ville-beaupuy.fr/actualites/", 15000);
  const results: MairieRow[] = [];

  // WordPress Divi blog module: <article class="et_pb_post ..."> blocks
  const articleRegex = /<article[^>]*class="[^"]*et_pb_post[^"]*"[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // Title + link: <h2 class="entry-title"><a href="...">Title</a></h2>
    const titleMatch = block.match(
      /<h2\s+class="entry-title">\s*<a\s+href="([^"]+)"[^>]*>(.*?)<\/a>/
    );
    if (!titleMatch) continue;

    const linkUrl = titleMatch[1];
    const title = cleanHtml(titleMatch[2]);
    if (!title) continue;

    // Image: <img ... src="..."> (first image in article)
    const imgMatch = block.match(/<img[^>]*src="([^"]+)"/);
    let photoUrl = imgMatch ? imgMatch[1] : "";
    // Get higher-res version by removing WP thumbnail suffix (-400x250)
    if (photoUrl) {
      photoUrl = photoUrl.replace(/-\d+x\d+\./, ".");
    }

    // Body: <div class="post-content-inner">...</div>
    const bodyMatch = block.match(
      /<div\s+class="post-content-inner">([\s\S]*?)<\/div>/
    );
    const body = bodyMatch ? cleanHtml(bodyMatch[1]) : "";

    results.push({
      ville: "Beaupuy",
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

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/mairie_notifications`,
    {
      method: "POST",
      headers: supabaseHeaders,
      body: JSON.stringify(rows),
    },
  );

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
    const rows = await scrapeBeaupuyActualites();
    console.log(`Scraped ${rows.length} actualités from Beaupuy`);

    const count = await upsertNotifications(rows);

    return new Response(
      JSON.stringify({ ville: "Beaupuy", scraped: rows.length, upserted: count }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-mairie-beaupuy FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-beaupuy",
      source: "ville-beaupuy.fr",
      ville: "Beaupuy",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({ ville: "Beaupuy", scraped: 0, upserted: 0, error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

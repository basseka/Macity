// supabase functions deploy scrape-mairies --no-verify-jwt
//
// Scraper unifié pour toutes les mairies.
// Supporte 3 stratégies : wp-api, html-article (+ typo3/drupal), skip.
// Appelé quotidiennement via pg_cron.
// On peut aussi appeler avec POST { "ville": "Castres" } pour une seule ville.

import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";
import { logScraperError } from "../_shared/db.ts";
import { CITIES, type CityConfig } from "./config.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};

const UA =
  "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

// ════════════════════════════════════════════════════════════
// Strategy: WordPress REST API (custom post types)
// ════════════════════════════════════════════════════════════

interface WpPost {
  title?: { rendered?: string };
  link?: string;
  excerpt?: { rendered?: string };
  date?: string;
  _embedded?: { "wp:featuredmedia"?: { source_url?: string }[] };
}

async function fetchWpApi(url: string): Promise<WpPost[]> {
  const res = await fetch(url, {
    headers: { "User-Agent": UA, Accept: "application/json" },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

async function scrapeWpApi(city: CityConfig): Promise<MairieRow[]> {
  const results: MairieRow[] = [];

  for (const endpoint of [city.wpActusEndpoint, city.wpAgendaEndpoint]) {
    if (!endpoint) continue;
    try {
      const posts = await fetchWpApi(city.baseUrl + endpoint);
      for (const p of posts) {
        const title = cleanHtml(p.title?.rendered ?? "");
        if (!title) continue;
        const body = cleanHtml(p.excerpt?.rendered ?? "").substring(0, 400);
        const linkUrl = p.link ?? "";
        const photoUrl =
          p._embedded?.["wp:featuredmedia"]?.[0]?.source_url ?? "";

        results.push({
          ville: city.ville,
          title,
          body,
          photo_url: photoUrl,
          link_url: linkUrl,
        });
      }
    } catch (e) {
      console.error(`[${city.ville}] WP API error on ${endpoint}: ${(e as Error).message}`);
    }
  }

  return results;
}

// ════════════════════════════════════════════════════════════
// Strategy: Generic HTML scraping
// Works for WordPress/Divi, TYPO3, Drupal, SPIP, custom CMS
// Tries multiple common patterns.
// ════════════════════════════════════════════════════════════

function absUrl(base: string, path: string): string {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  if (path.startsWith("//")) return "https:" + path;
  if (path.startsWith("/")) return base + path;
  return base + "/" + path;
}

function extractArticlesFromHtml(
  html: string,
  baseUrl: string,
  ville: string,
): MairieRow[] {
  const results: MairieRow[] = [];

  // Strategy A: <article> blocks (WordPress, TYPO3 Stratis, many CMS)
  const articleRegex = /<article[^>]*>([\s\S]*?)<\/article>/g;
  let m;
  while ((m = articleRegex.exec(html)) !== null) {
    const block = m[1];
    const item = parseCardBlock(block, baseUrl, ville);
    if (item) results.push(item);
  }

  // If no articles found, try Strategy B: div.card or div.post blocks
  if (results.length === 0) {
    const cardRegex =
      /<div[^>]*class="[^"]*(?:card |post |item |bloc_actu|news-item)[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/g;
    while ((m = cardRegex.exec(html)) !== null) {
      const item = parseCardBlock(m[1], baseUrl, ville);
      if (item) results.push(item);
    }
  }

  // If still nothing, try Strategy C: list of <a> with <h2>/<h3>
  if (results.length === 0) {
    const linkRegex =
      /<a[^>]*href="([^"]+)"[^>]*>[\s\S]*?<h[23][^>]*>([\s\S]*?)<\/h[23]>/g;
    while ((m = linkRegex.exec(html)) !== null) {
      const url = absUrl(baseUrl, m[1]);
      const title = cleanHtml(m[2]);
      if (!title || title.length < 5) continue;
      results.push({
        ville,
        title,
        body: "",
        photo_url: "",
        link_url: url,
      });
    }
  }

  return results;
}

function parseCardBlock(
  block: string,
  baseUrl: string,
  ville: string,
): MairieRow | null {
  // URL: first <a href> in block
  const urlMatch = block.match(/<a[^>]*href="([^"]+)"/);
  if (!urlMatch) return null;
  const linkUrl = absUrl(baseUrl, urlMatch[1]);
  // Skip non-content links (assets, anchors, social)
  if (
    linkUrl.includes("/wp-content/") ||
    linkUrl.includes("#") ||
    linkUrl.includes("facebook.") ||
    linkUrl.includes("twitter.")
  )
    return null;

  // Title: h2 or h3
  const titleMatch = block.match(/<h[23][^>]*>([\s\S]*?)<\/h[23]>/);
  if (!titleMatch) return null;
  const title = cleanHtml(titleMatch[1]);
  if (!title || title.length < 3) return null;

  // Image: try multiple patterns (src, data-src, data-lazy-src, srcset)
  let photoUrl = "";
  const imgPatterns = [
    /data-lazy-src="([^"]+)"/,
    /data-src="([^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"/i,
    /<noscript><img[^>]*src="([^"]+)"/,
    /<img[^>]*src="(https?:\/\/[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"/i,
    /<img[^>]*src="(\/[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"/i,
  ];
  for (const pattern of imgPatterns) {
    const imgMatch = block.match(pattern);
    if (imgMatch) {
      photoUrl = absUrl(baseUrl, imgMatch[1].trim());
      // Remove WP thumbnail suffix for higher-res
      photoUrl = photoUrl.replace(/-\d+x\d+\./, ".");
      break;
    }
  }

  // Description: try multiple patterns
  let body = "";
  const descPatterns = [
    /<div[^>]*class="[^"]*(?:desc|excerpt|content-inner|thumb-desc|post-content)[^"]*"[^>]*>\s*(?:<p>)?([\s\S]*?)(?:<\/p>)?\s*<\/div>/,
    /<p[^>]*class="[^"]*(?:desc|excerpt|summary)[^"]*"[^>]*>([\s\S]*?)<\/p>/,
  ];
  for (const pattern of descPatterns) {
    const descMatch = block.match(pattern);
    if (descMatch) {
      body = cleanHtml(descMatch[1]).substring(0, 400);
      break;
    }
  }

  // Date
  const dateMatch = block.match(
    /<(?:time|span)[^>]*class="[^"]*(?:date|published|post-meta)[^"]*"[^>]*>([\s\S]*?)<\/(?:time|span)>/,
  );
  if (dateMatch) {
    const dateText = cleanHtml(dateMatch[1]);
    if (dateText && body) body = `${dateText} - ${body}`;
    else if (dateText) body = dateText;
  }

  return { ville, title, body, photo_url: photoUrl, link_url: linkUrl };
}

async function scrapeHtml(city: CityConfig): Promise<MairieRow[]> {
  const results: MairieRow[] = [];

  for (const url of [city.actusUrl, city.agendaUrl]) {
    if (!url) continue;
    try {
      const html = await fetchHtml(url, 15000);
      const items = extractArticlesFromHtml(html, city.baseUrl, city.ville);
      results.push(...items);
    } catch (e) {
      console.error(
        `[${city.ville}] HTML scrape error on ${url}: ${(e as Error).message}`,
      );
    }
  }

  return results;
}

// ════════════════════════════════════════════════════════════
// Upsert
// ════════════════════════════════════════════════════════════

async function upsertNotifications(rows: MairieRow[]): Promise<number> {
  if (rows.length === 0) return 0;

  // Deduplicate by ville+title
  const seen = new Set<string>();
  const deduped = rows.filter((r) => {
    const key = `${r.ville}::${r.title}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Batch in chunks of 100
  let total = 0;
  for (let i = 0; i < deduped.length; i += 100) {
    const chunk = deduped.slice(i, i + 100);
    const res = await fetch(`${SUPABASE_URL}/rest/v1/mairie_notifications`, {
      method: "POST",
      headers: supabaseHeaders,
      body: JSON.stringify(chunk),
    });
    if (res.ok) {
      total += chunk.length;
    } else {
      const err = await res.text();
      console.error(`Upsert failed chunk ${i}: ${res.status} ${err}`);
    }
  }
  return total;
}

// ════════════════════════════════════════════════════════════
// Scrape a single city
// ════════════════════════════════════════════════════════════

async function scrapeCity(
  city: CityConfig,
): Promise<{ ville: string; scraped: number; upserted: number; error?: string }> {
  if (city.strategy === "skip") {
    return { ville: city.ville, scraped: 0, upserted: 0 };
  }

  try {
    let rows: MairieRow[];

    if (city.strategy === "wp-api") {
      rows = await scrapeWpApi(city);
    } else {
      // html-article, typo3, drupal all use HTML scraping
      rows = await scrapeHtml(city);
    }

    console.log(`[${city.ville}] scraped ${rows.length} items`);
    const upserted = await upsertNotifications(rows);

    return { ville: city.ville, scraped: rows.length, upserted };
  } catch (e) {
    const err = e as Error;
    console.error(`[${city.ville}] FATAL: ${err.message}`);
    await logScraperError({
      scraper: "scrape-mairies",
      source: city.baseUrl,
      ville: city.ville,
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return { ville: city.ville, scraped: 0, upserted: 0, error: err.message };
  }
}

// ════════════════════════════════════════════════════════════
// Handler
// ════════════════════════════════════════════════════════════

Deno.serve(async (req) => {
  let targetVille: string | null = null;
  try {
    const body = await req.json();
    targetVille = body.ville ?? null;
  } catch {
    // No body or invalid JSON — scrape all
  }

  const citiesToScrape = targetVille
    ? CITIES.filter(
        (c) => c.ville.toLowerCase() === targetVille!.toLowerCase(),
      )
    : CITIES.filter((c) => c.strategy !== "skip");

  if (targetVille && citiesToScrape.length === 0) {
    return new Response(
      JSON.stringify({ error: `Ville inconnue: ${targetVille}` }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // Process cities sequentially to avoid overwhelming servers
  // (3 concurrent max)
  const results: Awaited<ReturnType<typeof scrapeCity>>[] = [];
  const batchSize = 3;

  for (let i = 0; i < citiesToScrape.length; i += batchSize) {
    const batch = citiesToScrape.slice(i, i + batchSize);
    const batchResults = await Promise.all(batch.map(scrapeCity));
    results.push(...batchResults);
  }

  const totalScraped = results.reduce((sum, r) => sum + r.scraped, 0);
  const totalUpserted = results.reduce((sum, r) => sum + r.upserted, 0);
  const errors = results.filter((r) => r.error);

  return new Response(
    JSON.stringify({
      cities: results.length,
      totalScraped,
      totalUpserted,
      errors: errors.length,
      details: results,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

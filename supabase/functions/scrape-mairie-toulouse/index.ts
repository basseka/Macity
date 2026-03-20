// supabase functions deploy scrape-mairie-toulouse --no-verify-jwt
//
// Scrape l'agenda de Toulouse Métropole depuis
// https://metropole.toulouse.fr/agenda
// et upsert dans mairie_notifications.
//
// Le site est Drupal, server-side rendered.
// On récupère les événements à venir (48 par page) avec pagination.

import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";
import { logScraperError } from "../_shared/db.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates,return=minimal",
};

const BASE = "https://metropole.toulouse.fr";

interface MairieRow {
  ville: string;
  title: string;
  body: string;
  photo_url: string;
  link_url: string;
}

// ── Helpers ──

/** Today as YYYY-MM-DD */
function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/** Date 3 months from now as YYYY-MM-DD */
function threeMonthsLater(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 3);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

// ── Scrape Agenda ──

async function scrapeAgendaPage(page: number): Promise<MairieRow[]> {
  const url =
    `${BASE}/agenda?date_debut=${todayStr()}&date_fin=${threeMonthsLater()}&items_per_page=48&page=${page}`;

  const html = await fetchHtml(url, 20000);
  const results: MairieRow[] = [];

  // Match each event card: <article class="item-list node list__card">
  const articleRegex =
    /<article\s+class="[^"]*item-list[^"]*node[^"]*list__card[^"]*"[^>]*>([\s\S]*?)<\/article>/g;
  let match;

  while ((match = articleRegex.exec(html)) !== null) {
    const block = match[1];

    // Title + URL
    const linkMatch = block.match(
      /<a\s+[^>]*href="([^"]+)"[^>]*class="[^"]*list__url[^"]*"[^>]*>([\s\S]*?)<\/a>/
    );
    if (!linkMatch) continue;
    let linkUrl = linkMatch[1].trim();
    if (!linkUrl.startsWith("http")) linkUrl = BASE + linkUrl;
    const title = cleanHtml(linkMatch[2]);
    if (!title) continue;

    // Category
    const catMatch = block.match(
      /<p\s+class="[^"]*list__category[^"]*">([\s\S]*?)<\/p>/
    );
    const category = catMatch ? cleanHtml(catMatch[1]) : "";

    // Dates
    const startMatch = block.match(
      /<time\s+class="start"[^>]*datetime="([^"]*)"[^>]*>/
    );
    const endMatch = block.match(
      /<time\s+class="end"[^>]*datetime="([^"]*)"[^>]*>/
    );
    const startDate = startMatch ? startMatch[1].slice(0, 10) : "";
    const endDate = endMatch ? endMatch[1].slice(0, 10) : "";

    // Location
    const lieuMatch = block.match(
      /<span\s+class="[^"]*list__lieux[^"]*">([\s\S]*?)<\/span>/
    );
    const villeMatch = block.match(
      /<span\s+class="[^"]*list__ville[^"]*">([\s\S]*?)<\/span>/
    );
    const lieu = lieuMatch ? cleanHtml(lieuMatch[1]) : "";
    const ville = villeMatch ? cleanHtml(villeMatch[1]) : "Toulouse";

    // Image
    const imgMatch = block.match(
      /<img\s+[^>]*src="([^"]+)"[^>]*class="[^"]*list__image[^"]*"/
    );
    // Also try reversed order (class before src)
    const imgMatch2 = block.match(
      /<img\s+[^>]*class="[^"]*list__image[^"]*"[^>]*src="([^"]+)"/
    );
    let photoUrl = imgMatch ? imgMatch[1] : imgMatch2 ? imgMatch2[1] : "";
    if (photoUrl && !photoUrl.startsWith("http")) photoUrl = BASE + photoUrl;

    // Build body: [Category] Lieu — Du start au end
    const parts: string[] = [];
    if (category) parts.push(`[${category}]`);
    if (lieu) parts.push(lieu);
    if (startDate && endDate && startDate !== endDate) {
      parts.push(`Du ${startDate} au ${endDate}`);
    } else if (startDate) {
      parts.push(startDate);
    }
    if (ville && ville !== "Toulouse") parts.push(`(${ville})`);
    const body = parts.join(" — ");

    results.push({
      ville: ville || "Toulouse",
      title,
      body,
      photo_url: photoUrl,
      link_url: linkUrl,
    });
  }

  return results;
}

async function scrapeAgenda(): Promise<MairieRow[]> {
  const allRows: MairieRow[] = [];
  const MAX_PAGES = 5; // 48 * 5 = 240 events max

  for (let page = 0; page < MAX_PAGES; page++) {
    const rows = await scrapeAgendaPage(page);
    console.log(`Page ${page}: ${rows.length} events`);
    allRows.push(...rows);
    // If we got less than 48, we've reached the last page
    if (rows.length < 48) break;
  }

  return allRows;
}

// ── Upsert ──

async function upsertNotifications(rows: MairieRow[]): Promise<number> {
  if (rows.length === 0) return 0;

  // Deduplicate by ville::title (keep first)
  const seen = new Set<string>();
  const deduped = rows.filter((r) => {
    const key = `${r.ville}::${r.title}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Upsert in chunks of 100
  let total = 0;
  for (let i = 0; i < deduped.length; i += 100) {
    const chunk = deduped.slice(i, i + 100);
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/mairie_notifications?on_conflict=ville,title`,
      {
        method: "POST",
        headers: supabaseHeaders,
        body: JSON.stringify(chunk),
      }
    );

    if (!res.ok) {
      const err = await res.text();
      console.error(`Upsert chunk ${i} failed: ${res.status} ${err}`);
    } else {
      total += chunk.length;
    }
  }

  return total;
}

// ── Handler ──

Deno.serve(async (_req) => {
  try {
    const events = await scrapeAgenda();
    console.log(`Scraped Toulouse Métropole: ${events.length} events`);

    const upserted = await upsertNotifications(events);

    return new Response(
      JSON.stringify({
        ville: "Toulouse",
        agenda: events.length,
        upserted,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-mairie-toulouse FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-mairie-toulouse",
      source: "metropole.toulouse.fr",
      ville: "Toulouse",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        ville: "Toulouse",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

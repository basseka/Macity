// supabase functions deploy scrape-sport --no-verify-jwt
//
// Scrape les galas de boxe depuis galadeboxetoulouse.com
// et les upsert dans la table `matchs` (pas `scraped_events`).
// Porte depuis gala_boxe_scraper.dart.

import { cleanHtml, frenchDateToIso, fetchHtml } from "../_shared/html-utils.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const headers = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};

interface SupabaseMatch {
  sport: string;
  competition: string;
  equipe1: string;
  equipe2: string;
  date: string;
  heure: string;
  lieu: string;
  ville: string;
  description: string;
  billetterie: string;
  source: string;
}

async function scrapeGalaBoxe(): Promise<SupabaseMatch[]> {
  try {
    const html = await fetchHtml("https://galadeboxetoulouse.com/services/");
    const results: SupabaseMatch[] = [];

    // Extract title
    const titleRegex = /<h2[^>]*>(.*?)<\/h2>/s;
    const titleMatch = titleRegex.exec(html);
    const title = titleMatch ? cleanHtml(titleMatch[1]) : "";

    // Extract date (French format "20 juin", "15 mars")
    const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/i;
    const dateMatch = dateRegex.exec(html);
    const dateText = dateMatch ? `${dateMatch[1]} ${dateMatch[2]}` : null;
    const dateFormatted = frenchDateToIso(dateText);

    // Extract time
    const timeRegex = /(\d{1,2}h\d{2})/;
    const timeMatch = timeRegex.exec(html);
    const heure = timeMatch?.[1] ?? "";

    // Extract venue
    const venuePatterns = [
      /Ch[aâ]teau\s+[^<,]{3,40}/i,
      /Salle\s+[^<,]{3,40}/i,
      /Palais\s+des\s+Sports[^<,]{0,40}/i,
      /Z[eé]nith[^<,]{0,40}/i,
      /Gymnase\s+[^<,]{3,40}/i,
      /Halle\s+[^<,]{3,40}/i,
    ];
    let lieu = "";
    for (const p of venuePatterns) {
      const m = p.exec(html);
      if (m) { lieu = cleanHtml(m[0].trim()); break; }
    }

    // Extract ticket link
    const billetterieRegex = /href="(https?:\/\/[^"]*)"[^>]*>[^<]*[Bb]illetterie/;
    const billetterieMatch = billetterieRegex.exec(html);
    const billetterie = billetterieMatch?.[1] ?? "";

    // Extract price
    const tarifRegex = /(\d+\s*€)/;
    const tarifMatch = tarifRegex.exec(html);
    const tarif = tarifMatch?.[1] ?? "";

    // Extract address
    const adresseRegex = /(\d+[^<]*\d{5}[^<]*)/;
    const adresseMatch = adresseRegex.exec(html);
    const adresse = adresseMatch?.[1] ?? "";

    if (title && dateFormatted) {
      const description = [
        "Gala de boxe professionnelle",
        adresse ? `- ${adresse}` : "",
        tarif ? `- A partir de ${tarif}` : "",
      ].filter(Boolean).join(" ");

      results.push({
        sport: "Boxe",
        competition: title,
        equipe1: "",
        equipe2: "",
        date: dateFormatted,
        heure,
        lieu,
        ville: "Toulouse",
        description,
        billetterie,
        source: "galadeboxetoulouse.com",
      });
    }

    // Filter upcoming only
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
  } catch (e) { console.error("gala_boxe:", e); return []; }
}

async function upsertMatches(matches: SupabaseMatch[]): Promise<number> {
  if (matches.length === 0) return 0;

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/matchs`,
    {
      method: "POST",
      headers,
      body: JSON.stringify(matches),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`Upsert matchs failed: ${err}`);
    return 0;
  }
  return matches.length;
}

Deno.serve(async (_req) => {
  const errors: string[] = [];
  let count = 0;

  try {
    const matches = await scrapeGalaBoxe();
    count = await upsertMatches(matches);
    console.log(`scrape-sport: upserted ${count} matches`);
  } catch (e) {
    errors.push(`gala_boxe: ${(e as Error).message}`);
  }

  return new Response(
    JSON.stringify({ count, errors }),
    { headers: { "Content-Type": "application/json" } },
  );
});

// supabase functions deploy scrape-night --no-verify-jwt
//
// Scrape les clubs de nuit de Toulouse : Nine Club + L'Etoile.
// Porte depuis nine_club_scraper.dart et etoile_scraper.dart.

import { type ScrapedEvent, makeEvent, upsertEvents, isFutureDate } from "../_shared/db.ts";
import { cleanHtml, fetchHtml, isoToDate, isoToTime } from "../_shared/html-utils.ts";

// ─────────────────────────────────────────────────────────────
// Nine Club (XML sitemap + JSON-LD)
// ─────────────────────────────────────────────────────────────
async function scrapeNineClub(): Promise<ScrapedEvent[]> {
  try {
    // 1. Fetch sitemap to get event URLs
    const xml = await fetchHtml("https://www.lenineclub.com/event-pages-sitemap.xml");
    const locRegex = /<loc>(.*?)<\/loc>/g;
    const lastmodRegex = /<lastmod>(.*?)<\/lastmod>/g;

    const locs: string[] = [];
    const lastmods: string[] = [];
    let m;
    while ((m = locRegex.exec(xml)) !== null) locs.push(m[1]);
    while ((m = lastmodRegex.exec(xml)) !== null) lastmods.push(m[1]);

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7);

    const entries: { url: string; mod: Date | null }[] = [];
    for (let i = 0; i < locs.length; i++) {
      let mod: Date | null = null;
      if (i < lastmods.length) {
        mod = new Date(lastmods[i]);
        if (!isNaN(mod.getTime()) && mod < cutoff) continue;
      }
      entries.push({ url: locs[i], mod });
    }

    // Sort by lastmod desc, take top 10
    entries.sort((a, b) => (b.mod?.getTime() ?? 0) - (a.mod?.getTime() ?? 0));
    const urls = entries.slice(0, 10).map(e => e.url);

    // 2. Fetch each page and extract JSON-LD
    const events: ScrapedEvent[] = [];
    const jsonLdRegex = /<script\s+type="application\/ld\+json">(.*?)<\/script>/s;

    const pages = await Promise.allSettled(
      urls.map(url => fetchHtml(url).then(html => ({ url, html })))
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { url, html } = result.value;

      const jm = jsonLdRegex.exec(html);
      if (!jm) continue;

      try {
        const decoded = JSON.parse(jm[1].trim());
        const jsonLd = Array.isArray(decoded)
          ? decoded.find((e: any) => e["@type"] === "Event")
          : (decoded["@type"] === "Event" ? decoded : null);
        if (!jsonLd) continue;

        const name = jsonLd.name ?? "";
        if (!name) continue;

        const startDate = jsonLd.startDate ?? "";
        const endDate = jsonLd.endDate ?? "";
        const dateDebut = isoToDate(startDate);
        const dateFin = isoToDate(endDate);
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        const heureDebut = isoToTime(startDate);
        const heureFin = isoToTime(endDate);
        const horaires = heureDebut && heureFin ? `${heureDebut} - ${heureFin}` : "23h00 - 06h00";

        const imageData = jsonLd.image;
        const _imageUrl = typeof imageData === "string" ? imageData : imageData?.url;

        const id = `nine_club_${dateDebut}`;

        events.push(makeEvent({
          identifiant: id, source: "nine_club", rubrique: "night",
          nom_de_la_manifestation: `Nine · ${name}`,
          descriptif_court: `${name} au Nine Club.`,
          descriptif_long: `${name} au NINE CLUB, l'une des plus grandes discotheques du sud de la France. Navette gratuite depuis le metro Compans-Caffarelli.`,
          date_debut: dateDebut, date_fin: dateFin || dateDebut,
          horaires,
          lieu_nom: "Le Nine Club", lieu_adresse_2: "26 Allee des Foulques, 31200 Toulouse",
          commune: "Toulouse", code_postal: 31200,
          type_de_manifestation: "Club Discotheque", categorie_de_la_manifestation: "musique",
          tarif_normal: "12\u20AC (avec une consommation)",
          reservation_site_internet: url,
          station_metro_tram_a_proximite: "Compans-Caffarelli (navette gratuite)",
        }));
      } catch { continue; }
    }
    return events;
  } catch (e) { console.error("nine_club:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// L'Etoile (FourVenues iframe JSON)
// ─────────────────────────────────────────────────────────────
async function scrapeEtoile(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://custom-iframe.fourvenues.com/iframe/letoile-club-toulouse?type=carrusel");
    const events: ScrapedEvent[] = [];

    // Find the events JSON array in the RSC data
    const eventsJsonRegex = /\\?"events\\?":\s*\[/;
    const eventsMatch = eventsJsonRegex.exec(html);
    if (!eventsMatch) {
      // Try regex fallback
      return scrapeEtoileRegexFallback(html);
    }

    // Extract the JSON array by counting brackets
    const startIdx = eventsMatch.index + eventsMatch[0].length - 1;
    let depth = 0;
    let endIdx = startIdx;

    for (let i = startIdx; i < html.length; i++) {
      if (i > 0 && html[i - 1] === "\\") continue;
      if (html[i] === "[") depth++;
      if (html[i] === "]") {
        depth--;
        if (depth === 0) { endIdx = i + 1; break; }
      }
    }

    if (endIdx <= startIdx) return scrapeEtoileRegexFallback(html);

    let jsonStr = html.substring(startIdx, endIdx)
      .replace(/\\"/g, '"')
      .replace(/\\\\n/g, "\n")
      .replace(/\\\\\\/g, "\\")
      .replace(/\\\//g, "/");

    try {
      const jsonList: any[] = JSON.parse(jsonStr);
      for (const item of jsonList) {
        const event = parseEtoileEvent(item);
        if (event) events.push(event);
      }
    } catch {
      return scrapeEtoileRegexFallback(html);
    }

    return events;
  } catch (e) { console.error("etoile:", e); return []; }
}

function parseEtoileEvent(json: any): ScrapedEvent | null {
  const name = json.name ?? "";
  if (!name) return null;

  const startDate = json.start_date ?? "";
  const endDate = json.end_date ?? "";
  const dateDebut = isoToDate(startDate);
  const dateFin = isoToDate(endDate);
  if (!dateDebut || !isFutureDate(dateDebut)) return null;

  const heureDebut = isoToTime(startDate);
  const heureFin = isoToTime(endDate);
  const horaires = heureDebut && heureFin ? `${heureDebut} - ${heureFin}` : "00h00 - 06h00";
  const description = json.description ?? "";
  const slug = json.slug ?? "";

  const id = `etoile_${dateDebut}`;

  return makeEvent({
    identifiant: id, source: "etoile", rubrique: "night",
    nom_de_la_manifestation: `Etoile · ${name}`,
    descriptif_court: description
      ? (description.length > 100 ? description.substring(0, 100) + "..." : description)
      : `${name} a L'Etoile Club Toulouse.`,
    descriptif_long: description || `${name} a L'ETOILE CLUB TOULOUSE. Club & Rooftop au coeur de Toulouse.`,
    date_debut: dateDebut, date_fin: dateFin || dateDebut,
    horaires,
    lieu_nom: "L'Etoile Club Toulouse", lieu_adresse_2: "2 Avenue d'Atlanta, 31200 Toulouse",
    commune: "Toulouse", code_postal: 31200,
    type_de_manifestation: "Club Discotheque", categorie_de_la_manifestation: "musique",
    reservation_site_internet: slug
      ? `https://custom-iframe.fourvenues.com/iframe/letoile-club-toulouse/${slug}`
      : "https://etoile-toulouse.com/billetterie/",
    station_metro_tram_a_proximite: "Ligne 1 - Arenes",
  });
}

function scrapeEtoileRegexFallback(html: string): ScrapedEvent[] {
  const events: ScrapedEvent[] = [];
  const pattern = /\\"_id\\":\\"([^\\]+)\\".*?\\"name\\":\\"([^\\]+)\\".*?\\"start_date\\":\\"([^\\]+)\\".*?\\"end_date\\":\\"([^\\]+)\\"/g;

  let match;
  while ((match = pattern.exec(html)) !== null) {
    const name = match[2];
    const startDate = match[3];
    const endDate = match[4];
    if (!name || !startDate) continue;

    const dateDebut = isoToDate(startDate);
    const dateFin = isoToDate(endDate);
    if (!dateDebut || !isFutureDate(dateDebut)) continue;

    const heureDebut = isoToTime(startDate);
    const heureFin = isoToTime(endDate);
    const horaires = heureDebut && heureFin ? `${heureDebut} - ${heureFin}` : "00h00 - 06h00";

    const id = `etoile_${dateDebut}`;

    events.push(makeEvent({
      identifiant: id, source: "etoile", rubrique: "night",
      nom_de_la_manifestation: `Etoile · ${name}`,
      descriptif_court: `${name} a L'Etoile Club Toulouse.`,
      descriptif_long: `${name} a L'ETOILE CLUB TOULOUSE. Club & Rooftop au coeur de Toulouse.`,
      date_debut: dateDebut, date_fin: dateFin || dateDebut,
      horaires,
      lieu_nom: "L'Etoile Club Toulouse", lieu_adresse_2: "2 Avenue d'Atlanta, 31200 Toulouse",
      commune: "Toulouse", code_postal: 31200,
      type_de_manifestation: "Club Discotheque", categorie_de_la_manifestation: "musique",
      reservation_site_internet: "https://etoile-toulouse.com/billetterie/",
      station_metro_tram_a_proximite: "Ligne 1 - Arenes",
    }));
  }
  return events;
}

// ─────────────────────────────────────────────────────────────
// Main handler
// ─────────────────────────────────────────────────────────────
Deno.serve(async (_req) => {
  const errors: string[] = [];

  const [nineClubEvents, etoileEvents] = await Promise.allSettled([
    scrapeNineClub(),
    scrapeEtoile(),
  ]).then(results => results.map((r, i) => {
    if (r.status === "fulfilled") return r.value;
    errors.push(`${["nine_club", "etoile"][i]}: ${r.reason}`);
    return [] as ScrapedEvent[];
  }));

  const allEvents = [...nineClubEvents, ...etoileEvents];
  const count = await upsertEvents(allEvents);
  console.log(`scrape-night: upserted ${count} events`);

  return new Response(
    JSON.stringify({ count, errors }),
    { headers: { "Content-Type": "application/json" } },
  );
});

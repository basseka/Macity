// Source commune : Eventbrite (embedded __SERVER_DATA__ JSON)
// Fonctionne pour toutes les villes via URL slug.

import { type ScrapedEvent, makeEvent, isFutureDate } from "../../_shared/db.ts";
import { fetchHtml } from "../../_shared/html-utils.ts";
import type { CityConfig } from "../config/cities.ts";

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

// Slugs Eventbrite pour les villes hub
const CITY_SLUGS: Record<string, string> = {
  toulouse: "france--toulouse",
  paris: "france--paris",
  lyon: "france--lyon",
  marseille: "france--marseille",
  bordeaux: "france--bordeaux",
  lille: "france--lille",
  nice: "france--nice",
  nantes: "france--nantes",
  montpellier: "france--montpellier",
  strasbourg: "france--strasbourg",
  rennes: "france--rennes",
  "aix-en-provence": "france--aix-en-provence",
  grenoble: "france--grenoble",
  dijon: "france--dijon",
  angers: "france--angers",
  reims: "france--reims",
  nimes: "france--nîmes",
  toulon: "france--toulon",
  brest: "france--brest",
  "le-havre": "france--le-havre",
  "le-mans": "france--le-mans",
  "clermont-ferrand": "france--clermont-ferrand",
  "saint-etienne": "france--saint-étienne",
  "saint-denis": "france--saint-denis",
};

/** Extract events from Eventbrite's __SERVER_DATA__ embedded JSON */
function extractServerData(html: string): any[] {
  // Look for window.__SERVER_DATA__ = {...}
  const match = html.match(/window\.__SERVER_DATA__\s*=\s*(\{[\s\S]*?\});\s*<\/script>/);
  if (!match) return [];

  try {
    const data = JSON.parse(match[1]);
    return data?.search_data?.events?.results ?? [];
  } catch {
    // Fallback: try extracting the events array directly
    const eventsMatch = html.match(/"results"\s*:\s*(\[[\s\S]*?\])\s*,\s*"promoted/);
    if (!eventsMatch) return [];
    try { return JSON.parse(eventsMatch[1]); } catch { return []; }
  }
}

export async function fetchEventbrite(city: CityConfig): Promise<ScrapedEvent[]> {
  const cityKey = city.nom.toLowerCase().replace(/[^a-zà-ÿ-]/g, "");
  // Resolve slug
  let slug: string | undefined;
  for (const [key, s] of Object.entries(CITY_SLUGS)) {
    if (key === cityKey || city.nom.toLowerCase() === key.replace(/-/g, " ")) {
      slug = s; break;
    }
  }
  if (!slug) {
    // Fallback: construct slug from city name
    slug = `france--${city.nom.toLowerCase().replace(/\s+/g, "-")}`;
  }

  try {
    // Fetch concerts + spectacles pages
    const [htmlConcerts, htmlSpectacles] = await Promise.all([
      fetchHtml(`https://www.eventbrite.fr/d/${slug}/concerts/`, 20000),
      fetchHtml(`https://www.eventbrite.fr/d/${slug}/performing-visual-arts/`, 20000),
    ]);

    const concertItems = extractServerData(htmlConcerts);
    const spectacleItems = extractServerData(htmlSpectacles);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();

    // Process concert events
    for (const item of concertItems) {
      const ev = parseEventbriteItem(item, city, "day_concert");
      if (ev && !seen.has(ev.identifiant)) {
        seen.add(ev.identifiant);
        events.push(ev);
      }
    }

    // Process spectacle events
    for (const item of spectacleItems) {
      const ev = parseEventbriteItem(item, city, "day_spectacle");
      if (ev && !seen.has(ev.identifiant)) {
        seen.add(ev.identifiant);
        events.push(ev);
      }
    }

    console.log(`eventbrite[${city.nom}]: ${events.length} events (${concertItems.length} concerts + ${spectacleItems.length} spectacles raw)`);
    return events;
  } catch (e) { console.error(`Eventbrite[${city.nom}] error:`, e); return []; }
}

function parseEventbriteItem(item: any, city: CityConfig, defaultSource: string): ScrapedEvent | null {
  try {
    const name = (item.name ?? "").trim();
    if (!name) return null;

    // Parse dates — Eventbrite uses various formats
    const startDate = parseEbDate(item.start_date, item.start_time);
    if (!startDate || !isFutureDate(startDate)) return null;

    const endDate = parseEbDate(item.end_date, item.end_time) || startDate;

    // Extract time
    let horaires = "";
    const startTime = item.start_time ?? "";
    if (startTime) {
      const parts = startTime.split(":");
      if (parts.length >= 2) horaires = `${parts[0]}h${parts[1]}`;
    }

    // Venue info
    const venue = item.primary_venue ?? {};
    const venueName = venue.name ?? "";
    const venueAddr = venue.address ?? {};
    const venueCity = venueAddr.city ?? city.nom;
    const postalCode = venueAddr.postal_code ?? "";
    const street = venueAddr.address_1 ?? "";

    // Image
    const photoUrl = item.image?.url ?? "";

    // Summary
    const summary = (item.summary ?? "").trim();
    const desc = summary.length > 200 ? summary.substring(0, 200) + "..." : summary;

    const id = `eb_${normalize(name).slice(0, 40)}_${startDate}`;

    return makeEvent({
      identifiant: id,
      source: defaultSource,
      rubrique: "day",
      nom_de_la_manifestation: name,
      descriptif_court: desc,
      date_debut: startDate,
      date_fin: endDate,
      horaires,
      lieu_nom: venueName,
      lieu_adresse_2: postalCode ? `${street}, ${postalCode} ${venueCity}` : street,
      commune: venueCity,
      type_de_manifestation: defaultSource === "day_concert" ? "Concert" : "Spectacle",
      categorie_de_la_manifestation: defaultSource === "day_concert" ? "Concert" : "Spectacle",
      manifestation_gratuite: item.is_free ? "oui" : "non",
      reservation_site_internet: item.url ?? item.tickets_url ?? "",
      photo_url: photoUrl,
    });
  } catch { return null; }
}

/** Parse Eventbrite date string to YYYY-MM-DD */
function parseEbDate(dateStr: string | undefined, timeStr?: string): string {
  if (!dateStr) return "";
  // Already ISO format "YYYY-MM-DD"
  if (/^\d{4}-\d{2}-\d{2}/.test(dateStr)) return dateStr.substring(0, 10);
  // "March 15, 2026" or similar
  try {
    const d = new Date(dateStr + (timeStr ? ` ${timeStr}` : ""));
    if (isNaN(d.getTime())) return "";
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  } catch { return ""; }
}

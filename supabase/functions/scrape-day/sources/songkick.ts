// Source commune : Songkick (JSON-LD MusicEvent)
// Fonctionne pour toutes les villes via metro area ID.

import { type ScrapedEvent, makeEvent, isFutureDate } from "../../_shared/db.ts";
import { fetchHtml, cleanHtml } from "../../_shared/html-utils.ts";
import type { CityConfig } from "../config/cities.ts";

// Metro area IDs Songkick pour les villes hub françaises
const METRO_IDS: Record<string, number> = {
  toulouse: 28930,
  paris: 28909,
  lyon: 28889,
  marseille: 156979,
  bordeaux: 28851,
  lille: 28886,
  nice: 28903,
  nantes: 28901,
  montpellier: 28896,
  strasbourg: 28928,
  rennes: 28916,
};

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

export async function fetchSongkick(city: CityConfig): Promise<ScrapedEvent[]> {
  const cityKey = city.nom.toLowerCase().replace(/[^a-z]/g, "");
  // Try exact key first, then fuzzy match
  let metroId = METRO_IDS[cityKey];
  if (!metroId) {
    for (const [key, id] of Object.entries(METRO_IDS)) {
      if (cityKey.includes(key) || key.includes(cityKey)) { metroId = id; break; }
    }
  }
  if (!metroId) {
    console.log(`songkick[${city.nom}]: no metro area ID, skipping`);
    return [];
  }

  try {
    const url = `https://www.songkick.com/metro-areas/${metroId}-france-${cityKey}`;
    const html = await fetchHtml(url, 20000);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();

    // Extract JSON-LD blocks
    const jsonLdRegex = /<script\s+type="application\/ld\+json"\s*>([\s\S]*?)<\/script>/gi;
    let m;
    while ((m = jsonLdRegex.exec(html)) !== null) {
      try {
        const data = JSON.parse(m[1].trim());
        const items = Array.isArray(data) ? data : [data];
        for (const item of items) {
          if (item["@type"] !== "MusicEvent") continue;

          const rawName = item.name ?? "";
          // Songkick format: "Artist @ Venue" — extract artist name
          const atIdx = rawName.indexOf(" @ ");
          const artistName = atIdx > 0 ? rawName.substring(0, atIdx).trim() : rawName;
          if (!artistName) continue;

          const startDate = (item.startDate ?? "").substring(0, 10);
          if (!startDate || !isFutureDate(startDate)) continue;

          // Dedup by artist + date
          const dedupKey = `${normalize(artistName)}|${startDate}`;
          if (seen.has(dedupKey)) continue;
          seen.add(dedupKey);

          const loc = item.location ?? {};
          const addr = loc.address ?? {};
          const venueName = loc.name ?? "";
          const venueCity = addr.addressLocality ?? city.nom;

          // Extract time from startDate if present (e.g. "2026-03-17T19:30:00")
          let horaires = "";
          const fullDate = item.startDate ?? "";
          if (fullDate.includes("T")) {
            const timePart = fullDate.substring(11, 16);
            if (timePart) {
              const parts = timePart.split(":");
              horaires = `${parts[0]}h${parts[1]}`;
            }
          }

          // Performers / genre
          const performers = item.performer ?? [];
          const genres = performers.flatMap((p: any) => p.genre ?? []).filter(Boolean);
          const genreStr = genres.slice(0, 3).join(", ");

          // Determine source category from genres
          let source = "day_concert";
          const genreLower = genreStr.toLowerCase();
          if (genreLower.includes("electro") || genreLower.includes("techno") || genreLower.includes("house") || genreLower.includes("dnb")) {
            source = "day_djset";
          }

          const id = `sk_${normalize(artistName).slice(0, 40)}_${startDate}`;

          events.push(makeEvent({
            identifiant: id,
            source,
            rubrique: "day",
            nom_de_la_manifestation: artistName,
            descriptif_court: genreStr ? `Genre : ${genreStr}` : "",
            date_debut: startDate,
            date_fin: startDate,
            horaires,
            lieu_nom: venueName,
            lieu_adresse_2: addr.streetAddress ?? "",
            commune: venueCity,
            type_de_manifestation: "Concert",
            categorie_de_la_manifestation: "Concert",
            manifestation_gratuite: "non",
            reservation_site_internet: item.url ?? "",
          }));
        }
      } catch { continue; }
    }

    console.log(`songkick[${city.nom}]: ${events.length} events`);
    return events;
  } catch (e) { console.error(`Songkick[${city.nom}] error:`, e); return []; }
}

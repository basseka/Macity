// Source commune : Festik (billetterie.festik.net)
// Fonctionne pour toutes les villes en filtrant par aliases.

import { type ScrapedEvent, makeEvent, isFutureDate } from "../../_shared/db.ts";
import { fetchHtml } from "../../_shared/html-utils.ts";
import type { CityConfig } from "../config/cities.ts";

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

export async function fetchFestik(city: CityConfig, categorie: string): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://billetterie.festik.net/", 15000);
    const jsonLdRegex = /<script\s+type="application\/ld\+json"\s*>(.*?)<\/script>/gs;
    const events: ScrapedEvent[] = [];
    const citySet = new Set(city.aliases.map(a => a.toLowerCase()));

    let m;
    while ((m = jsonLdRegex.exec(html)) !== null) {
      try {
        const decoded = JSON.parse(m[1].trim());
        const items = Array.isArray(decoded) ? decoded : [decoded];
        for (const item of items) {
          if (item["@type"] !== "Event") continue;
          const loc = item.location;
          const addr = loc?.address;
          const itemCity = (addr?.addressLocality ?? "").toLowerCase().trim();
          if (!citySet.has(itemCity)) continue;

          const name = item.name ?? "";
          if (!name) continue;

          const startDate = (item.startDate ?? "").substring(0, 10);
          const endDate = (item.endDate ?? "").substring(0, 10);
          if (!startDate || !isFutureDate(startDate)) continue;

          const venueName = loc?.name ?? "";
          const street = addr?.streetAddress ?? "";
          const postal = addr?.postalCode ?? "";
          const desc = item.description ?? "";

          events.push(makeEvent({
            identifiant: `festik_${normalize(name).slice(0, 30)}_${startDate}`,
            source: `day_${categorie.toLowerCase()}`, rubrique: "day",
            nom_de_la_manifestation: name,
            descriptif_court: desc.length > 200 ? desc.substring(0, 200) + "..." : desc,
            date_debut: startDate, date_fin: endDate || startDate,
            lieu_nom: venueName,
            lieu_adresse_2: postal ? `${street}, ${postal} ${itemCity}` : `${street}, ${itemCity}`,
            commune: itemCity[0].toUpperCase() + itemCity.slice(1),
            type_de_manifestation: categorie, categorie_de_la_manifestation: categorie,
            manifestation_gratuite: "non",
            reservation_site_internet: item.url ?? "",
          }));
        }
      } catch { continue; }
    }
    console.log(`festik[${city.nom}/${categorie}]: ${events.length} events`);
    return events;
  } catch (e) { console.error(`Festik[${city.nom}] error:`, e); return []; }
}

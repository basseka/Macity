// Source commune : Ticketmaster Discovery API
// Fonctionne pour toutes les villes via lat/lng + radius.

import { type ScrapedEvent, makeEvent, isFutureDate } from "../../_shared/db.ts";
import { fetchJson, isoToDate, isoToTime } from "../../_shared/html-utils.ts";
import type { CityConfig } from "../config/cities.ts";

const TICKETMASTER_API_KEY = Deno.env.get("TICKETMASTER_API_KEY") ?? "";

export async function fetchTicketmaster(city: CityConfig): Promise<ScrapedEvent[]> {
  if (!TICKETMASTER_API_KEY) return [];
  try {
    const url = `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${TICKETMASTER_API_KEY}&latlong=${city.lat},${city.lng}&radius=${city.radius}&unit=km&countryCode=FR&classificationName=Music&sort=date,asc&size=50`;
    const data = await fetchJson<any>(url, 15000);
    const events = data._embedded?.events ?? [];
    const result: ScrapedEvent[] = [];

    for (const e of events) {
      const name = e.name ?? "";
      const localDate = e.dates?.start?.localDate ?? "";
      const localTime = e.dates?.start?.localTime ?? "";
      if (!name || !localDate || !isFutureDate(localDate)) continue;

      const venue = e._embedded?.venues?.[0] ?? {};
      const venueName = venue.name ?? "";
      const venueAddress = venue.address?.line1 ?? "";
      const venueCity = venue.city?.name ?? city.nom;

      let horaires = "";
      if (localTime) {
        const parts = localTime.split(":");
        if (parts.length >= 2) horaires = `${parts[0]}h${parts[1]}`;
      }

      let tarif = "";
      if (e.priceRanges?.length) {
        const pr = e.priceRanges[0];
        if (pr.min != null && pr.max != null) tarif = `${Math.round(pr.min)}-${Math.round(pr.max)}EUR`;
        else if (pr.min != null) tarif = `A partir de ${Math.round(pr.min)}EUR`;
      }

      const imgs = (e.images ?? []) as any[];
      const photoUrl = imgs.sort((a: any, b: any) => (b.width ?? 0) - (a.width ?? 0))[0]?.url ?? "";

      result.push(makeEvent({
        identifiant: `tm_${e.id}`, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: name,
        date_debut: localDate, date_fin: localDate,
        horaires,
        lieu_nom: venueName, lieu_adresse_2: venueAddress,
        commune: venueCity,
        type_de_manifestation: "Concert", categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        tarif_normal: tarif,
        reservation_site_internet: e.url ?? "",
        photo_url: photoUrl,
      }));
    }
    console.log(`ticketmaster[${city.nom}]: ${result.length} events`);
    return result;
  } catch (e) { console.error(`Ticketmaster[${city.nom}] error:`, e); return []; }
}

/** Search Ticketmaster for artist photo by name. */
export async function searchArtistPhoto(artistName: string): Promise<string> {
  if (!TICKETMASTER_API_KEY) return "";
  try {
    const url = `https://app.ticketmaster.com/discovery/v2/attractions.json?apikey=${TICKETMASTER_API_KEY}&keyword=${encodeURIComponent(artistName)}&countryCode=FR&size=1`;
    const data = await fetchJson<any>(url, 8000);
    const attraction = data._embedded?.attractions?.[0];
    if (!attraction?.images?.length) return "";
    const imgs = attraction.images as any[];
    return imgs.sort((a: any, b: any) => (b.width ?? 0) - (a.width ?? 0))[0]?.url ?? "";
  } catch { return ""; }
}

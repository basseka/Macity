// supabase functions deploy scrape-day --no-verify-jwt
//
// Scrape les evenements "day" de Toulouse : concerts, festivals, operas,
// DJ sets, showcases, spectacles via OpenDataSoft API + Festik + Ticketmaster + curated.
// Porte depuis les 6 services Dart day_*.

import { type ScrapedEvent, makeEvent, upsertEvents, isFutureDate } from "../_shared/db.ts";
import { fetchHtml, fetchJson } from "../_shared/html-utils.ts";

const TICKETMASTER_API_KEY = Deno.env.get("TICKETMASTER_API_KEY") ?? "";
const ODS_BASE = "https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records";

function todayStr(): string {
  const n = new Date();
  return `${n.getFullYear()}-${String(n.getMonth()+1).padStart(2,"0")}-${String(n.getDate()).padStart(2,"0")}`;
}

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

// ─────────────────────────────────────────────────────────────
// OpenDataSoft helper
// ─────────────────────────────────────────────────────────────
async function fetchODS(where: string, limit = 100): Promise<ScrapedEvent[]> {
  try {
    const url = `${ODS_BASE}?where=${encodeURIComponent(where)}&order_by=date_debut&limit=${limit}`;
    const data = await fetchJson<any>(url, 20000);
    if (data.error_code) {
      console.error(`ODS API error: ${data.error_code}: ${data.message}`);
      return [];
    }
    const events: ScrapedEvent[] = [];

    for (const r of data.results ?? []) {
      const titre = r.nom_de_la_manifestation ?? "";
      if (!titre) continue;
      const dateDebut = (r.date_debut ?? "").substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const id = `ods_${normalize(titre).slice(0, 40)}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "day_ods", rubrique: "day",
        nom_de_la_manifestation: titre,
        descriptif_court: r.descriptif_court ?? "",
        descriptif_long: r.descriptif_long ?? "",
        date_debut: dateDebut,
        date_fin: (r.date_fin ?? "").substring(0, 10) || dateDebut,
        horaires: r.horaires ?? "",
        dates_affichage_horaires: r.dates_affichage_horaires ?? "",
        lieu_nom: r.lieu_nom ?? "",
        lieu_adresse_2: r.lieu_adresse_2 ?? "",
        code_postal: Number(r.code_postal) || 0,
        commune: r.commune ?? "Toulouse",
        type_de_manifestation: r.type_de_manifestation ?? "",
        categorie_de_la_manifestation: r.categorie_de_la_manifestation ?? "",
        theme_de_la_manifestation: r.theme_de_la_manifestation ?? "",
        manifestation_gratuite: r.manifestation_gratuite ?? "",
        tarif_normal: r.tarif_normal ?? "",
        reservation_site_internet: r.reservation_site_internet ?? "",
        reservation_telephone: r.reservation_telephone ?? "",
        station_metro_tram_a_proximite: r.station_metro_tram_a_proximite ?? "",
      }));
    }
    return events;
  } catch (e) { console.error("ODS fetch error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Ticketmaster
// ─────────────────────────────────────────────────────────────
async function fetchTicketmaster(): Promise<ScrapedEvent[]> {
  if (!TICKETMASTER_API_KEY) return [];
  try {
    const url = `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${TICKETMASTER_API_KEY}&city=Toulouse&countryCode=FR&classificationName=Music&sort=date,asc&size=50`;
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
      const venueCity = venue.city?.name ?? "Toulouse";

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
      }));
    }
    return result;
  } catch (e) { console.error("Ticketmaster error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Festik (JSON-LD from HTML)
// ─────────────────────────────────────────────────────────────
const TOULOUSE_CITIES = new Set([
  "toulouse", "ramonville", "ramonville-saint-agne", "balma", "colomiers",
  "blagnac", "tournefeuille", "labege", "castanet-tolosan", "saint-orens",
  "l'union", "aucamville", "fenouillet", "cugnaux", "portet-sur-garonne",
  "muret", "plaisance-du-touch", "bruguieres", "cornebarrieu", "pibrac",
]);

async function fetchFestik(categorie: string): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://billetterie.festik.net/", 15000);
    const jsonLdRegex = /<script\s+type="application\/ld\+json"\s*>(.*?)<\/script>/gs;
    const events: ScrapedEvent[] = [];

    let m;
    while ((m = jsonLdRegex.exec(html)) !== null) {
      try {
        const decoded = JSON.parse(m[1].trim());
        const items = Array.isArray(decoded) ? decoded : [decoded];
        for (const item of items) {
          if (item["@type"] !== "Event") continue;
          const loc = item.location;
          const addr = loc?.address;
          const city = (addr?.addressLocality ?? "").toLowerCase().trim();
          if (!TOULOUSE_CITIES.has(city)) continue;

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
            identifiant: `festik_${String(name.hashCode ?? name.length)}_${startDate}`,
            source: `day_${categorie.toLowerCase()}`, rubrique: "day",
            nom_de_la_manifestation: name,
            descriptif_court: desc.length > 200 ? desc.substring(0, 200) + "..." : desc,
            date_debut: startDate, date_fin: endDate || startDate,
            lieu_nom: venueName,
            lieu_adresse_2: postal ? `${street}, ${postal} ${city}` : `${street}, ${city}`,
            commune: city[0].toUpperCase() + city.slice(1),
            type_de_manifestation: categorie, categorie_de_la_manifestation: categorie,
            manifestation_gratuite: "non",
            reservation_site_internet: item.url ?? "",
          }));
        }
      } catch { continue; }
    }
    return events;
  } catch (e) { console.error("Festik error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Categorize ODS events by type/category
// ─────────────────────────────────────────────────────────────
function categorizeEvent(e: ScrapedEvent): string {
  const type = (e.type_de_manifestation || "").toLowerCase();
  const cat = (e.categorie_de_la_manifestation || "").toLowerCase();
  const lieu = (e.lieu_nom || "").toLowerCase();

  // Theatre events are excluded (handled by scrape-culture)
  if (cat.includes("theatre") || type.includes("theatre") || lieu.includes("theatre")) return "skip";

  if (cat.includes("concert") || type.includes("musique") || type.includes("concert")) return "day_concert";
  if (cat.includes("festival") || type.includes("festival")) return "day_festival";
  if (cat.includes("opera") || type.includes("opera") || type.includes("lyrique")) return "day_opera";
  if (type.includes("dj") || type.includes("electro") || type.includes("techno") || cat.includes("dj")) return "day_djset";
  if (type.includes("showcase") || type.includes("acoustique") || cat.includes("showcase")) return "day_showcase";
  if (cat.includes("spectacle") || type.includes("spectacle") || type.includes("humour") || type.includes("cirque") || type.includes("danse") || type.includes("magie")) return "day_spectacle";

  return "day_other";
}

// ─────────────────────────────────────────────────────────────
// Fetch all ODS + Ticketmaster + Festik and categorize
// ─────────────────────────────────────────────────────────────
async function scrapeAllDay(): Promise<ScrapedEvent[]> {
  const today = todayStr();
  const where = `date_debut >= "${today}"`;

  const [ods, tm, festikConcert, festikFestival, festikSpectacle] = await Promise.all([
    fetchODS(where),
    fetchTicketmaster(),
    fetchFestik("Concert"),
    fetchFestik("Festival"),
    fetchFestik("Spectacle"),
  ]);

  // Tag ODS events by category
  const taggedOds = ods.map(e => {
    const source = categorizeEvent(e);
    return source === "skip" ? null : { ...e, source };
  }).filter(Boolean) as ScrapedEvent[];

  // Tag external sources
  const taggedTm = tm.map(e => ({ ...e, source: "day_concert" }));
  const taggedFestikC = festikConcert.map(e => ({ ...e, source: "day_concert" }));
  const taggedFestikF = festikFestival.map(e => ({ ...e, source: "day_festival" }));
  const taggedFestikS = festikSpectacle.filter(e => {
    const t = e.nom_de_la_manifestation.toLowerCase();
    return !t.includes("theatre");
  }).map(e => ({ ...e, source: "day_spectacle" }));

  const all = [...taggedOds, ...taggedTm, ...taggedFestikC, ...taggedFestikF, ...taggedFestikS];
  return dedup(all);
}

// ─────────────────────────────────────────────────────────────
// Dedup helper
// ─────────────────────────────────────────────────────────────
function dedup(events: ScrapedEvent[]): ScrapedEvent[] {
  const seen = new Set<string>();
  return events.filter(e => {
    const key = `${normalize(e.nom_de_la_manifestation)}|${e.date_debut}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

// ─────────────────────────────────────────────────────────────
// Main handler
// ─────────────────────────────────────────────────────────────
Deno.serve(async (_req) => {
  const errors: string[] = [];

  let allEvents: ScrapedEvent[] = [];
  try {
    allEvents = await scrapeAllDay();
    console.log(`scrape-day: found ${allEvents.length} events`);
  } catch (e) {
    errors.push(`scrapeAllDay: ${(e as Error).message}`);
  }

  const count = await upsertEvents(allEvents);
  console.log(`scrape-day: upserted ${count} events total`);

  return new Response(
    JSON.stringify({ count, errors }),
    { headers: { "Content-Type": "application/json" } },
  );
});

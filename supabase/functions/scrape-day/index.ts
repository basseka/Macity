// supabase functions deploy scrape-day --no-verify-jwt
//
// Scrape les evenements "day" de Toulouse : concerts, festivals, operas,
// DJ sets, showcases, spectacles via OpenDataSoft API + Festik + Ticketmaster + curated.
// Porte depuis les 6 services Dart day_*.

import { type ScrapedEvent, makeEvent, upsertEvents, isFutureDate } from "../_shared/db.ts";
import { fetchHtml, fetchJson, cleanHtml, isoToDate, isoToTime, buildIsoDate, frenchMonths, frenchDateToIso } from "../_shared/html-utils.ts";

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
// Le Bikini (Next.js RSC embedded JSON from Sanity CMS)
// ─────────────────────────────────────────────────────────────
async function fetchBikini(): Promise<ScrapedEvent[]> {
  try {
    // Fetch the RSC (React Server Components) endpoint directly — it contains
    // structured JSON with all events, unlike the HTML which is client-rendered.
    const rscText = await fetchHtml("https://www.lebikini.com/programmation/bikini/-/-.rsc", 15000);
    const events: ScrapedEvent[] = [];

    // Find the "events":[ array in the RSC stream
    const idx = rscText.indexOf('"events":[');
    if (idx < 0) {
      console.log("bikini: no events array found in RSC response");
      return [];
    }

    // Extract events array by bracket counting
    const start = idx + '"events":'.length;
    let bracket = 0;
    let end = start;
    for (let i = start; i < rscText.length; i++) {
      if (rscText[i] === "[") bracket++;
      else if (rscText[i] === "]") bracket--;
      if (bracket === 0) { end = i + 1; break; }
    }
    const eventsJson = rscText.substring(start, end);

    let parsed: any[];
    try { parsed = JSON.parse(eventsJson); }
    catch { console.error("bikini: JSON parse error"); return []; }

    for (const e of parsed) {
      const title = (e.title ?? "").replace(/\\u0026/g, "&").trim();
      if (!title) continue;

      const dateIso = e.date ?? "";
      const startDate = isoToDate(dateIso);
      if (!startDate || !isFutureDate(startDate)) continue;

      const horaires = isoToTime(dateIso);
      const style = (e.style ?? "").toLowerCase();
      const typeNames = (e.eventTypes ?? []).map((t: any) => (t.name ?? "").toLowerCase());

      // Determine source based on style/type
      let source = "day_concert";
      if (style.includes("techno") || style.includes("electro") || style.includes("house") || style.includes("dnb") || style.includes("drum")) {
        source = "day_djset";
      } else if (typeNames.some((t: string) => t.includes("spectacle") || t.includes("humour"))) {
        source = "day_spectacle";
      } else if (typeNames.some((t: string) => t.includes("festival")) || style.includes("festival")) {
        source = "day_festival";
      }

      const prices = e.prices ?? [];
      const tarif = prices.length > 0 ? prices[0].replace(/à partir de /i, "").trim() : "";
      const free = e.free === true ? "oui" : "non";
      const ticketUrl = e.ticketUrl ?? "";
      const slug = e.slug?.current ?? "";

      const id = `bikini_${normalize(title).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source, rubrique: "day",
        nom_de_la_manifestation: title,
        descriptif_court: style ? `Style : ${e.style}` : "",
        date_debut: startDate, date_fin: startDate,
        horaires,
        lieu_nom: "Le Bikini",
        lieu_adresse_2: "Parc Technologique du Canal, Ramonville-Saint-Agne",
        commune: "Ramonville-Saint-Agne",
        code_postal: 31520,
        type_de_manifestation: typeNames[0] ?? "Concert",
        categorie_de_la_manifestation: typeNames[0] ?? "Concert",
        manifestation_gratuite: free,
        tarif_normal: tarif,
        reservation_site_internet: ticketUrl || (slug ? `https://www.lebikini.com/2026/${startDate.substring(5, 7)}/${startDate.substring(8, 10)}/${slug}` : ""),
      }));
    }

    console.log(`bikini: ${events.length} events from ${parsed.length} total`);
    return events;
  } catch (e) { console.error("Bikini error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Opéra de Toulouse (schema.org microdata)
// ─────────────────────────────────────────────────────────────
async function fetchOperaToulouse(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://opera.toulouse.fr/agenda/type/operas/", 15000);
    const events: ScrapedEvent[] = [];

    // Split by card-item Event blocks
    const blocks = html.split(/class="card-item"[^>]*itemtype/);

    for (let i = 1; i < blocks.length; i++) {
      const block = blocks[i];

      const titleMatch = block.match(/<h3[^>]*class="card-item-title"[^>]*>(.*?)<\/h3>/s);
      const name = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!name) continue;

      // <time> tag spans multiple lines: datetime="..." on a separate line
      const timeMatch = block.match(/datetime="([^"]+)"/);
      const startIso = timeMatch ? timeMatch[1] : "";
      const startDate = isoToDate(startIso);
      if (!startDate) continue;

      const horaires = isoToTime(startIso);

      // End date from "20 février → 1 mars 2026" or "14 → 26 avril 2026"
      const dateTextMatch = block.match(/<p[^>]*class="card-item-date-date"[^>]*>(.*?)<\/p>/s);
      let endDate = startDate;
      if (dateTextMatch) {
        const dateText = cleanHtml(dateTextMatch[1]).replace(/&rarr;/g, "→");
        // "20 février → 1 mars 2026" or "14 → 26 avril 2026" or "26 juin → 5 juillet 2026"
        const arrowMatch = dateText.match(/→\s*(\d{1,2})\s+(\w+)\s+(\d{4})/);
        if (arrowMatch) {
          const built = buildIsoDate(arrowMatch[1], arrowMatch[2], arrowMatch[3]);
          if (built) endDate = built;
        }
      }

      // Keep if start OR end is in the future (opera runs for several days)
      if (!isFutureDate(startDate) && !isFutureDate(endDate)) continue;

      const descMatch = block.match(/<p[^>]*class="card-item-description"[^>]*>(.*?)<\/p>/s);
      const desc = descMatch ? cleanHtml(descMatch[1]) : "";

      const linkMatch = block.match(/<a[^>]*class="card-item-link"[^>]*href="([^"]+)"/);
      const url = linkMatch ? linkMatch[1] : "";

      const id = `opera_tls_${normalize(name).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "day_opera", rubrique: "day",
        nom_de_la_manifestation: name,
        descriptif_court: desc,
        date_debut: startDate, date_fin: endDate,
        horaires,
        lieu_nom: "Théâtre du Capitole",
        lieu_adresse_2: "Place du Capitole",
        commune: "Toulouse",
        code_postal: 31000,
        type_de_manifestation: "Opéra", categorie_de_la_manifestation: "Opéra",
        manifestation_gratuite: "non",
        reservation_site_internet: url,
      }));
    }

    console.log(`opera.toulouse.fr: ${events.length} operas from ${blocks.length - 1} blocks`);
    return events;
  } catch (e) { console.error("Opera Toulouse error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// TimeForGig (timeforgig.com/toulouse)
// ─────────────────────────────────────────────────────────────
const ENGLISH_MONTHS: Record<string, number> = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
  jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12,
};

function parseEnglishDate(text: string): string | null {
  // "Sat 28 Feb 2026"
  const m = text.match(/(\d{1,2})\s+(\w{3})\s+(\d{4})/);
  if (!m) return null;
  const day = parseInt(m[1], 10);
  const month = ENGLISH_MONTHS[m[2].toLowerCase()];
  const year = parseInt(m[3], 10);
  if (!month || isNaN(day) || isNaN(year)) return null;
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

async function fetchTimeForGig(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.timeforgig.com/toulouse/cities/ygyeww", 15000);
    const parts = html.split('class="event_list"');
    if (parts.length < 2) {
      console.log("timeforgig: no event_list found");
      return [];
    }

    const eventSection = parts[1];
    const rows = eventSection.split('<div class="row align-items-center">');
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();

    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];

      // Extract text nodes
      const textMatches = [...row.matchAll(/>([^<]+)</g)];
      const texts = textMatches
        .map(m => m[1].trim())
        .filter(t => t && !t.startsWith("{"));
      if (texts.length < 2) continue;

      const artist = cleanHtml(texts[0]);
      if (!artist) continue;

      const info = texts[1]; // "Sat 28 Feb 2026 - ZENITH TOULOUSE METROPOLE"
      const dashIdx = info.indexOf(" - ");
      if (dashIdx < 0) continue;

      const dateStr = info.substring(0, dashIdx).trim();
      const venue = info.substring(dashIdx + 3).trim();
      const startDate = parseEnglishDate(dateStr);
      if (!startDate || !isFutureDate(startDate)) continue;

      // Dedup
      const dedupKey = `${normalize(artist)}|${startDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);

      const linkMatch = row.match(/href="(\/[^"]+\/events\/[^"]+)"/);
      const url = linkMatch ? `https://www.timeforgig.com${linkMatch[1]}` : "";

      const id = `tfg_${normalize(artist).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: artist,
        date_debut: startDate, date_fin: startDate,
        lieu_nom: venue,
        commune: "Toulouse",
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        reservation_site_internet: url,
      }));
    }

    console.log(`timeforgig: ${events.length} events from ${rows.length - 1} rows`);
    return events;
  } catch (e) { console.error("TimeForGig error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Zénith Toulouse Métropole (HTML card-show blocks)
// ─────────────────────────────────────────────────────────────
function parseFrenchDate(text: string): string | null {
  // "Samedi 28 févr. 2026" or "Vendredi 06 mars 2026"
  // \w+ ne matche pas les accents (é, û, etc.) → utiliser [^\s.]+
  const m = text.match(/(\d{1,2})\s+([^\s.]+)\.?\s+(\d{4})/);
  if (!m) return null;
  return buildIsoDate(m[1], m[2], m[3]);
}

async function fetchZenith(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://zenith-toulousemetropole.com/program", 15000);
    const blocks = html.split('class="card-show"');
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();

    for (let i = 1; i < blocks.length; i++) {
      const block = blocks[i].substring(0, 3000);

      const artistMatch = block.match(/class="card-show__artist">(.*?)<\/div>/);
      const name = artistMatch ? cleanHtml(artistMatch[1]) : "";
      if (!name) continue;

      const dateMatch = block.match(/class="card-show__date">(.*?)<\/div>/s);
      const dateText = dateMatch ? cleanHtml(dateMatch[1]) : "";
      const startDate = parseFrenchDate(dateText);
      if (!startDate || !isFutureDate(startDate)) continue;

      // Skip cancelled events
      const stateMatch = block.match(/class="card-show__state">(.*?)<\/div>/s);
      const state = stateMatch ? cleanHtml(stateMatch[1]).toLowerCase() : "";
      if (state.includes("annul")) continue;

      // Dedup (Holiday on Ice has multiple slots)
      const dedupKey = `${normalize(name)}|${startDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);

      // Extract ticket URL
      const linkMatch = block.match(/href="(\/shows\/[^"]+)"/);
      const showUrl = linkMatch
        ? `https://zenith-toulousemetropole.com${decodeURIComponent(linkMatch[1])}`
        : "";

      const id = `zenith_${normalize(name).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: name,
        date_debut: startDate, date_fin: startDate,
        lieu_nom: "ZENITH TOULOUSE METROPOLE",
        lieu_adresse_2: "11 Avenue Raymond Badiou",
        commune: "Toulouse",
        code_postal: 31100,
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        reservation_site_internet: showUrl,
      }));
    }

    console.log(`zenith: ${events.length} events from ${blocks.length - 1} blocks`);
    return events;
  } catch (e) { console.error("Zenith error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Toulouse Tourisme (FacetWP API — festivals)
// ─────────────────────────────────────────────────────────────
/** Fetch the "A propos" description from a toulouse-tourisme.com detail page. */
async function fetchToulouseTourismeDescription(url: string): Promise<{ short: string; long: string }> {
  try {
    const html = await fetchHtml(url, 12000);
    // Section: <section class='about ...'> → <div class="description">...</div>
    const descMatch = html.match(/<section[^>]*class=['"]about[^'"]*['"][^>]*>.*?<div[^>]*class="description"[^>]*>(.*?)<\/div>/s);
    if (!descMatch) return { short: "", long: "" };

    const raw = descMatch[1];
    // Extract <strong> as short description
    const strongMatch = raw.match(/<strong>(.*?)<\/strong>/s);
    const shortDesc = strongMatch ? cleanHtml(strongMatch[1]) : "";
    // Full text as long description
    const longDesc = cleanHtml(raw);
    return { short: shortDesc, long: longDesc };
  } catch { return { short: "", long: "" }; }
}

async function fetchToulouseTourisme(): Promise<ScrapedEvent[]> {
  try {
    const controller = new AbortController();
    const tid = setTimeout(() => controller.abort(), 20000);
    let responseText: string;
    try {
      const res = await fetch("https://www.toulouse-tourisme.com/wp-json/facetwp/v1/refresh", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120",
        },
        body: JSON.stringify({
          action: "facetwp_refresh",
          data: {
            facets: { categoriesfma: ["8bc78750-3546-4234-8277-bf433e6374cc"] },
            http_params: { uri: "sortir-a-toulouse/agenda-sorties-toulouse", lang: "fr" },
            template: "agenda",
            paged: 1,
            per_page: 100,
          },
        }),
        signal: controller.signal,
      });
      responseText = await res.text();
    } finally {
      clearTimeout(tid);
    }

    const data = JSON.parse(responseText);
    const html: string = data.template ?? "";
    if (!html) {
      console.log("toulouse-tourisme: no template in response");
      return [];
    }

    // ── Phase 1 : parse la liste ──
    interface RawFestival {
      name: string; url: string; location: string;
      startDate: string; endDate: string; eventId: string;
    }
    const raw: RawFestival[] = [];
    const articles = html.split("<article");

    for (let i = 1; i < articles.length; i++) {
      const article = articles[i].substring(0, 3000);

      // Title (class="title wp-block-heading is-style-h3" — partial match)
      const titleMatch = article.match(/<h3[^>]*class="title[^"]*"[^>]*>.*?<a[^>]*>(.*?)<\/a>/s);
      const name = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!name) continue;

      // URL
      const urlMatch = article.match(/<h3[^>]*>.*?<a[^>]*href="([^"]+)"/s);
      const url = urlMatch ? urlMatch[1] : "";

      // Location
      const locMatch = article.match(/<div[^>]*class="location[^"]*"[^>]*>(.*?)<\/div>/s);
      const location = locMatch ? cleanHtml(locMatch[1]) : "";

      // Start date from dates-sticker (class="start")
      const startDayMatch = article.match(
        /<div[^>]*class="start"[^>]*>\s*<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s
      );
      let startDate: string | null = null;
      if (startDayMatch) {
        startDate = frenchDateToIso(`${startDayMatch[1]} ${startDayMatch[2].trim()}`);
      }

      // End date (class="end")
      let endDate: string | null = null;
      const endDayMatch = article.match(
        /<div[^>]*class="end"[^>]*>\s*<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s
      );
      if (endDayMatch) {
        endDate = frenchDateToIso(`${endDayMatch[1]} ${endDayMatch[2].trim()}`);
      }

      // "Jusqu'au" format: no start, only end date → event already started
      if (!startDate) {
        const untilMatch = article.match(
          /<div[^>]*class="until"[^>]*>.*?<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s
        );
        if (untilMatch) {
          endDate = frenchDateToIso(`${untilMatch[1]} ${untilMatch[2].trim()}`);
          startDate = todayStr(); // already started
        }
      }

      if (!startDate) continue;
      if (!endDate) endDate = startDate;

      // Keep if start OR end is in the future (festivals span multiple days)
      if (!isFutureDate(startDate) && !isFutureDate(endDate)) continue;

      const eventId = `tltourisme_${normalize(name).slice(0, 40)}_${startDate}`;
      raw.push({ name, url, location, startDate, endDate, eventId });
    }

    // ── Phase 2 : fetch descriptions from detail pages (parallel, batched) ──
    const BATCH = 5;
    const descriptions = new Map<string, { short: string; long: string }>();
    for (let b = 0; b < raw.length; b += BATCH) {
      const batch = raw.slice(b, b + BATCH);
      const results = await Promise.all(
        batch.map(f => f.url ? fetchToulouseTourismeDescription(f.url) : Promise.resolve({ short: "", long: "" }))
      );
      for (let j = 0; j < batch.length; j++) {
        descriptions.set(batch[j].eventId, results[j]);
      }
    }

    // ── Phase 3 : build events ──
    const events: ScrapedEvent[] = [];
    for (const f of raw) {
      const desc = descriptions.get(f.eventId) ?? { short: "", long: "" };
      events.push(makeEvent({
        identifiant: f.eventId, source: "day_festival", rubrique: "day",
        nom_de_la_manifestation: f.name,
        descriptif_court: desc.short,
        descriptif_long: desc.long,
        date_debut: f.startDate, date_fin: f.endDate,
        lieu_nom: f.location,
        commune: "Toulouse",
        type_de_manifestation: "Festival",
        categorie_de_la_manifestation: "Festival",
        manifestation_gratuite: "non",
        reservation_site_internet: f.url,
      }));
    }

    const withDesc = events.filter(e => e.descriptif_court || e.descriptif_long).length;
    console.log(`toulouse-tourisme: ${events.length} festivals (${withDesc} with description) from ${articles.length - 1} articles`);
    return events;
  } catch (e) { console.error("Toulouse Tourisme error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Categorize ODS events by type/category
// ─────────────────────────────────────────────────────────────
function categorizeEvent(e: ScrapedEvent): string {
  const type = (e.type_de_manifestation || "").toLowerCase();
  const cat = (e.categorie_de_la_manifestation || "").toLowerCase();
  const lieu = (e.lieu_nom || "").toLowerCase();

  // Festival check FIRST — a festival is a festival even if it's also tagged as music/theatre
  if (cat.includes("festival") || type.includes("festival")) return "day_festival";

  // Theatre events are excluded (handled by scrape-culture) — but only if not a festival
  if (cat.includes("theatre") || type.includes("theatre") || lieu.includes("theatre")) return "skip";

  if (cat.includes("opera") || type.includes("opera") || type.includes("lyrique")) return "day_opera";
  if (type.includes("dj") || type.includes("electro") || type.includes("techno") || cat.includes("dj")) return "day_djset";
  if (type.includes("showcase") || type.includes("acoustique") || cat.includes("showcase")) return "day_showcase";
  if (cat.includes("concert") || type.includes("musique") || type.includes("concert")) return "day_concert";
  if (cat.includes("spectacle") || type.includes("spectacle") || type.includes("humour") || type.includes("cirque") || type.includes("danse") || type.includes("magie")) return "day_spectacle";

  return "day_other";
}

// ─────────────────────────────────────────────────────────────
// Fetch all ODS + Ticketmaster + Festik and categorize
// ─────────────────────────────────────────────────────────────
async function scrapeAllDay(): Promise<ScrapedEvent[]> {
  const today = todayStr();
  const where = `date_debut >= "${today}"`;

  const [ods, tm, festikConcert, festikFestival, festikSpectacle, operaTls, bikini, zenith, tfg, tlTourisme] = await Promise.all([
    fetchODS(where),
    fetchTicketmaster(),
    fetchFestik("Concert"),
    fetchFestik("Festival"),
    fetchFestik("Spectacle"),
    fetchOperaToulouse(),
    fetchBikini(),
    fetchZenith(),
    fetchTimeForGig(),
    fetchToulouseTourisme(),
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

  // Curated sources first so they win dedup over generic ODS tags
  const all = [...zenith, ...tfg, ...operaTls, ...bikini, ...tlTourisme, ...taggedOds, ...taggedTm, ...taggedFestikC, ...taggedFestikF, ...taggedFestikS];
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

  // Count by source for monitoring
  const bySource: Record<string, number> = {};
  for (const e of allEvents) {
    bySource[e.source] = (bySource[e.source] || 0) + 1;
  }

  return new Response(
    JSON.stringify({ count, errors, bySource }),
    { headers: { "Content-Type": "application/json" } },
  );
});

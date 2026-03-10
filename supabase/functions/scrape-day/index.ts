// supabase functions deploy scrape-day --no-verify-jwt
//
// Scrape les evenements "day" de Toulouse : concerts, festivals, operas,
// DJ sets, showcases, spectacles via OpenDataSoft API + Festik + Ticketmaster + curated.
// Porte depuis les 6 services Dart day_*.

import { type ScrapedEvent, makeEvent, upsertEvents, isFutureDate, supabaseHeaders } from "../_shared/db.ts";
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
// ONCT / Halle aux Grains — photo enrichment
// ─────────────────────────────────────────────────────────────
async function fetchONCTPhotos(): Promise<Map<string, string>> {
  const dateToImg = new Map<string, string>();
  try {
    const html = await fetchHtml("https://onct.toulouse.fr/la-halle-aux-grains/programmation-halle-aux-grains/", 15000);
    const year = new Date().getFullYear();

    // Split HTML by image tags from ONCT uploads
    const imgRegex = /src="(https:\/\/onct\.toulouse\.fr\/wp-content\/uploads\/[^"]+\.(png|jpg|jpeg|webp))"/gi;
    const imgPositions: { url: string; pos: number }[] = [];
    let m;
    while ((m = imgRegex.exec(html)) !== null) {
      imgPositions.push({ url: m[1], pos: m.index });
    }

    // For each image, look at the text after it to find French date pattern
    const dateRegex = /(?:lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)\s+(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
    for (let i = 0; i < imgPositions.length; i++) {
      const start = imgPositions[i].pos;
      const end = i + 1 < imgPositions.length ? imgPositions[i + 1].pos : start + 2000;
      const block = html.substring(start, end);
      dateRegex.lastIndex = 0;
      const dm = dateRegex.exec(block);
      if (dm) {
        const day = parseInt(dm[1], 10);
        const monthName = dm[2].toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        const monthNum = frenchMonths[monthName] ?? 0;
        if (monthNum > 0) {
          const isoDate = `${year}-${String(monthNum).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
          if (!dateToImg.has(isoDate)) {
            dateToImg.set(isoDate, imgPositions[i].url);
          }
        }
      }
    }
    console.log(`ONCT photos: found ${dateToImg.size} date→image mappings`);
  } catch (e) {
    console.error("ONCT photo fetch error:", e);
  }
  return dateToImg;
}

/** Enrich ODS events at Halle aux Grains with ONCT poster images. */
function enrichHallePhotos(events: ScrapedEvent[], onctPhotos: Map<string, string>): ScrapedEvent[] {
  if (onctPhotos.size === 0) return events;
  return events.map(e => {
    if (e.lieu_nom.toUpperCase().includes("HALLE") && e.lieu_nom.toUpperCase().includes("GRAINS") && !e.photo_url) {
      const img = onctPhotos.get(e.date_debut);
      if (img) return { ...e, photo_url: img };
    }
    return e;
  });
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

      // Pick best image (prefer 16_9, largest width)
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
      const photoUrl = e.image?.asset?.url ?? "";

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
        photo_url: photoUrl,
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
// COMDT — Centre Occitan des Musiques et Danses Traditionnelles
// ─────────────────────────────────────────────────────────────
async function fetchCOMDT(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.comdt.org/saison/les-concerts/", 15000);
    const events: ScrapedEvent[] = [];

    // Extract JSON-LD block
    const ldMatch = html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/);
    if (!ldMatch) { console.log("comdt: no JSON-LD found"); return []; }

    let data: any[];
    try { data = JSON.parse(ldMatch[1]); } catch { console.error("comdt: JSON-LD parse error"); return []; }
    if (!Array.isArray(data)) data = [data];

    for (const ev of data) {
      if (ev["@type"] !== "Event") continue;
      const name = (ev.name ?? "").replace(/&#\d+;/g, "").trim();
      if (!name) continue;

      const startDate = (ev.startDate ?? "").substring(0, 10);
      if (!startDate || !isFutureDate(startDate)) continue;

      // Time from startDate ISO (e.g. "2026-03-27T20:30:00+01:00")
      const timePart = (ev.startDate ?? "").substring(11, 16);
      const horaires = timePart && timePart !== "00:00" ? timePart.replace(":", "h") : "";

      const photoUrl = ev.image ?? "";
      const eventUrl = ev.url ?? "";

      // Description: strip HTML entities
      let desc = (ev.description ?? "")
        .replace(/&lt;p&gt;/g, "").replace(/&lt;\/p&gt;/g, "")
        .replace(/&lt;[^&]*&gt;/g, "").replace(/&amp;/g, "&")
        .replace(/&hellip;/g, "…").replace(/\\n/g, " ").trim();

      // Location
      const loc = ev.location ?? {};
      const locName = (loc.name ?? "COMDT").replace(/&#\d+;/g, " ").replace(/\s+/g, " ").trim();
      const locAddr = loc.address?.streetAddress ?? "5 Impasse Boudeville";
      const locCity = loc.address?.addressLocality ?? "Toulouse";
      const locZip = parseInt(loc.address?.postalCode ?? "31200", 10);

      const id = `comdt_${normalize(name).slice(0, 35)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: name.toUpperCase(),
        descriptif_court: desc.slice(0, 200),
        descriptif_long: desc,
        date_debut: startDate, date_fin: (ev.endDate ?? "").substring(0, 10) || startDate,
        horaires,
        lieu_nom: locName.toUpperCase(),
        lieu_adresse_2: locAddr,
        commune: locCity,
        code_postal: locZip,
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        reservation_site_internet: eventUrl,
        photo_url: photoUrl,
      }));
    }

    // Cleanup stale COMDT records
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const currentIds = events.map(e => `"${e.identifiant}"`).join(",");
    if (currentIds) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/scraped_events?identifiant=like.comdt_*&identifiant=not.in.(${currentIds})`,
        { method: "DELETE", headers: supabaseHeaders },
      );
    }

    console.log(`comdt: ${events.length} events`);
    return events;
  } catch (e) { console.error("COMDT error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Le Bascala (Bruguières) — JetEngine/Elementor page
// ─────────────────────────────────────────────────────────────
async function fetchBascala(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://spectacles.le-bascala.com/programmation/cette-saison/", 15000);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();
    const year = new Date().getFullYear();

    // Extract dynamic field contents in order (6 per event: day, month, time, title, subtitle, producer)
    const fields = [...html.matchAll(/dynamic-field__content[^>]*>([^<]*)</g)].map(m => m[1].trim());

    // Extract event images (skip first 2 which are logos)
    const imgs = [...html.matchAll(/src="(https:\/\/spectacles\.le-bascala\.com\/wp-content\/uploads\/20[^"]+)"/g)].map(m => m[1]);
    const eventImgs = imgs.slice(2); // skip logo/favicon

    // Extract ticket links (external billetterie)
    const ticketLinks = [...html.matchAll(/href="(https:\/\/(?:www\.fnac|www\.ticketmaster|billetterie\.|www\.billetweb|shotgun)[^"]+)"/g)].map(m => m[1]);

    // French month abbrevs on this site: "Mar" "Avr" "Mai" "Jun" "Oct" etc.
    const monthMap: Record<string, number> = {
      jan: 1, fev: 2, fév: 2, mar: 3, avr: 4, mai: 5, jun: 6, juin: 6,
      jul: 7, juil: 7, aou: 8, août: 8, sep: 9, oct: 10, nov: 11, dec: 12, déc: 12,
    };

    let ticketIdx = 0;
    for (let i = 0; i + 5 < fields.length; i += 6) {
      const dayText = fields[i];   // "dim 1" or "mer 11"
      const monthText = fields[i + 1]; // "Mar" or "Avr"
      const timeText = fields[i + 2]; // "20h30" or "21h00 - 00h00"
      const title = fields[i + 3];
      const subtitle = fields[i + 4];
      const producer = fields[i + 5];

      // Parse date
      const dayMatch = dayText.match(/(\d{1,2})/);
      if (!dayMatch) continue;
      const day = parseInt(dayMatch[1], 10);
      const monthKey = monthText.toLowerCase().substring(0, 3);
      const monthNum = monthMap[monthKey] ?? 0;
      if (monthNum === 0) continue;

      // Determine year: if month < current month, it's next year
      const eventYear = monthNum < new Date().getMonth() + 1 ? year + 1 : year;
      const isoDate = `${eventYear}-${String(monthNum).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      if (!isFutureDate(isoDate)) continue;

      // Parse time (take first time: "20h30" from "20h30 (1ere partie à 19h45)")
      const timeMatch = timeText.match(/(\d{1,2})[hH](\d{2})/);
      const horaires = timeMatch ? `${timeMatch[1]}h${timeMatch[2]}` : "";

      if (!title) continue;

      // Dedup
      const dedupKey = `${normalize(title)}|${isoDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);

      const eventIdx = Math.floor(i / 6);
      const photoUrl = eventIdx < eventImgs.length ? eventImgs[eventIdx] : "";

      const id = `bascala_${normalize(title).slice(0, 35)}_${isoDate}`;

      // Categorize: comedy/impro/spectacle → day_spectacle, music → day_concert
      const titleLower = title.toLowerCase() + " " + subtitle.toLowerCase();
      let source = "day_spectacle"; // default for Bascala (mostly spectacles)
      if (titleLower.includes("concert") || titleLower.includes("orchestre") || titleLower.includes("quartet") || titleLower.includes("jazz")) {
        source = "day_concert";
      } else if (titleLower.includes("dj") || titleLower.includes("soirée 80") || titleLower.includes("club")) {
        source = "day_djset";
      }

      events.push(makeEvent({
        identifiant: id, source, rubrique: "day",
        nom_de_la_manifestation: title.toUpperCase(),
        descriptif_court: subtitle,
        descriptif_long: producer ? `Produit par : ${producer}` : "",
        date_debut: isoDate, date_fin: isoDate,
        horaires,
        lieu_nom: "LE BASCALA",
        lieu_adresse_2: "Chemin de Fournaulis",
        commune: "Bruguières",
        code_postal: 31150,
        type_de_manifestation: source === "day_concert" ? "Concert" : source === "day_djset" ? "DJ Set" : "Spectacle",
        categorie_de_la_manifestation: source === "day_concert" ? "Concert" : source === "day_djset" ? "DJ Set" : "Spectacle",
        manifestation_gratuite: "non",
        reservation_site_internet: ticketIdx < ticketLinks.length ? ticketLinks[ticketIdx] : "",
        photo_url: photoUrl,
      }));
      ticketIdx++;
    }

    // Cleanup stale Bascala records
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const currentIds = events.map(e => `"${e.identifiant}"`).join(",");
    if (currentIds) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/scraped_events?identifiant=like.bascala_*&identifiant=not.in.(${currentIds})`,
        { method: "DELETE", headers: supabaseHeaders },
      );
    }

    console.log(`bascala: ${events.length} events from ${fields.length / 6} blocks`);
    return events;
  } catch (e) { console.error("Bascala error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Le Rex de Toulouse
// ─────────────────────────────────────────────────────────────
async function fetchLeRex(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.lerextoulouse.com/fr/programmation/", 15000);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();

    // Split by image blocks
    const imgRegex = /<img[^>]+src="(https:\/\/www\.lerextoulouse\.com\/media\/data\/spectacles\/images\/[^?"]+)[^"]*"[^>]*>/g;
    const imgPositions: { url: string; pos: number }[] = [];
    let m;
    while ((m = imgRegex.exec(html)) !== null) {
      imgPositions.push({ url: m[1], pos: m.index });
    }

    for (let i = 0; i < imgPositions.length; i++) {
      const start = imgPositions[i].pos;
      const end = i + 1 < imgPositions.length ? imgPositions[i + 1].pos : start + 3000;
      const block = html.substring(start, Math.min(end, start + 3000));

      // Date: <span class="date_list">mar 3 mars 2026 - 19H30</span>
      const dateMatch = block.match(/class="date_list">([^<]+)<\/span>/);
      if (!dateMatch) continue;
      const dateText = dateMatch[1].trim();
      // Parse: "mar 3 mars 2026 - 19H30"
      const dp = dateText.match(/\w+\s+(\d{1,2})\s+([a-zéûà]+)\s+(\d{4})\s*-\s*(\d{1,2})[Hh](\d{2})?/);
      if (!dp) continue;
      const isoDate = buildIsoDate(dp[1], dp[2], dp[3]);
      if (!isoDate || !isFutureDate(isoDate)) continue;
      const horaires = `${dp[4]}h${dp[5] || "00"}`;

      // Artist: <span class="artiste">NAME <span class="styles_list">(genres)</span></span>
      const artistMatch = block.match(/class="artiste">([^<]+)/);
      const artist = artistMatch ? artistMatch[1].trim() : "";
      if (!artist) continue;

      // Genre
      const genreMatch = block.match(/class="styles_list">\(([^)]+)\)/);
      const genres = genreMatch ? genreMatch[1] : "";

      // Type: "live" or "Club" (last link in lien_agenda)
      const typeMatch = block.match(/>(\w+)<\/a>\s*<\/p>/);
      const eventType = typeMatch ? typeMatch[1].toLowerCase() : "live";

      // Determine source: "Club" → day_djset, "live" → day_concert
      const source = eventType === "club" ? "day_djset" : "day_concert";

      // Price
      const priceMatch = block.match(/<strong>([^<]+)<\/strong>/);
      const price = priceMatch ? priceMatch[1].replace(/&euro;/g, "€").trim() : "";

      // Ticket URL
      const ticketMatch = block.match(/class="external"[^>]*href="([^"]+)"/);
      if (!ticketMatch) {
        // try href before class
        const ticketMatch2 = block.match(/href="(https?:\/\/[^"]+)"[^>]*class="external"/);
        var ticketUrl = ticketMatch2 ? ticketMatch2[1] : "";
      } else {
        var ticketUrl = ticketMatch[1];
      }

      // Image
      const photoUrl = imgPositions[i].url;

      // Dedup
      const dedupKey = `${normalize(artist)}|${isoDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);

      const id = `rex_${normalize(artist).slice(0, 40)}_${isoDate}`;

      events.push(makeEvent({
        identifiant: id, source, rubrique: "day",
        nom_de_la_manifestation: artist.toUpperCase(),
        date_debut: isoDate, date_fin: isoDate,
        horaires,
        lieu_nom: "LE REX DE TOULOUSE",
        lieu_adresse_2: "15 Avenue Honoré Serres",
        commune: "Toulouse",
        code_postal: 31000,
        type_de_manifestation: eventType === "club" ? "DJ Set" : "Concert",
        categorie_de_la_manifestation: genres || (eventType === "club" ? "DJ Set" : "Concert"),
        manifestation_gratuite: "non",
        tarif_normal: price,
        reservation_site_internet: ticketUrl,
        photo_url: photoUrl,
      }));
    }

    // Cleanup stale Rex records
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const currentIds = events.map(e => `"${e.identifiant}"`).join(",");
    if (currentIds) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/scraped_events?identifiant=like.rex_*&identifiant=not.in.(${currentIds})`,
        { method: "DELETE", headers: supabaseHeaders },
      );
    }

    console.log(`lerex: ${events.length} events from ${imgPositions.length} blocks`);
    return events;
  } catch (e) { console.error("LeRex error:", e); return []; }
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

      // Extract poster image
      const imgMatch = block.match(/card-show__img[^>]*>[\s\S]*?<img[^>]+src="([^"]+)"/);
      const photoUrl = imgMatch ? imgMatch[1] : "";

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
        photo_url: photoUrl,
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
// Interférence Toulouse (API with pagination)
// ─────────────────────────────────────────────────────────────
async function fetchInterference(): Promise<ScrapedEvent[]> {
  try {
    const apiUrl = "https://api.interference-toulouse.fr/events/search";
    const allRaw: any[] = [];

    // Fetch all pages from the API
    let page = 1;
    let lastPage = 1;
    while (page <= lastPage) {
      const resp = await fetch(apiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({ page, eventCategory: "all", dateFilter: "upcoming", searchFilter: "" }),
      });
      if (!resp.ok) { console.error(`interference: API page ${page} returned ${resp.status}`); break; }
      const json = await resp.json();
      const pageData = json.data ?? [];
      allRaw.push(...pageData);
      lastPage = json.pagination?.lastPage ?? page;
      page++;
    }

    console.log(`interference: fetched ${allRaw.length} raw events from API (${page - 1} pages)`);
    const events: ScrapedEvent[] = [];

    for (const e of allRaw) {
      const rawName = (e.event_name ?? "").trim();
      if (!rawName) continue;

      // Remove [COMPLET] anywhere in name
      const complet = /\[complet\]/i.test(rawName);
      const name = rawName.replace(/\[COMPLET\]\s*[-–—]?\s*/gi, "").trim().toUpperCase();

      const startIso = e.event_starting ?? "";
      const startDate = isoToDate(startIso);
      if (!startDate || !isFutureDate(startDate)) continue;

      const horaires = isoToTime(startIso);

      // Determine source by event type
      const eventType = (e.event_type ?? "").toLowerCase();
      let source = "day_concert";
      let typeName = "Concert";
      if (eventType === "club") {
        source = "day_djset";
        typeName = "DJ Set";
      } else if (eventType === "show" || eventType === "spectacle") {
        source = "day_spectacle";
        typeName = "Spectacle";
      }

      const ticketUrl = e.event_external_ticketing_url ?? "";
      const photoUrl = e.tile_url ?? "";
      const id = `interf_${normalize(name).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source, rubrique: "day",
        nom_de_la_manifestation: name,
        descriptif_court: complet ? "COMPLET" : "",
        date_debut: startDate, date_fin: startDate,
        horaires,
        lieu_nom: "Interference",
        lieu_adresse_2: "56 Route de Lavaur",
        commune: "Toulouse",
        code_postal: 31130,
        type_de_manifestation: typeName,
        categorie_de_la_manifestation: typeName,
        manifestation_gratuite: "non",
        reservation_site_internet: ticketUrl,
        photo_url: photoUrl,
      }));
    }

    // Cleanup stale Interference records not in current batch
    if (events.length > 0) {
      const currentIds = events.map(e => e.identifiant);
      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const delUrl = `${SUPABASE_URL}/rest/v1/scraped_events?lieu_nom=eq.Interference&identifiant=not.in.(${currentIds.join(",")})`;
      const delRes = await fetch(delUrl, { method: "DELETE", headers: supabaseHeaders });
      if (delRes.ok) {
        console.log(`interference: cleaned up stale records`);
      }
    }

    console.log(`interference: ${events.length} future events from ${allRaw.length} total`);
    return events;
  } catch (e) { console.error("Interference error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Le Metronum (WordPress Tribe Events API)
// ─────────────────────────────────────────────────────────────
async function fetchMetronum(): Promise<ScrapedEvent[]> {
  try {
    const apiUrl = "https://lemetronum.fr/wp-json/tribe/events/v1/events?per_page=50&start_date=now";
    const resp = await fetch(apiUrl, {
      headers: { "Accept": "application/json" },
    });
    if (!resp.ok) { console.error(`metronum: API returned ${resp.status}`); return []; }
    const json = await resp.json();
    const rawEvents = json.events ?? [];

    console.log(`metronum: fetched ${rawEvents.length} raw events from API`);
    const events: ScrapedEvent[] = [];

    for (const e of rawEvents) {
      const rawTitle = (e.title ?? "").replace(/&#\d+;|&[a-z]+;/gi, " ").replace(/\s+/g, " ").trim();
      if (!rawTitle) continue;
      const name = rawTitle.toUpperCase();

      const startDate = (e.start_date ?? "").substring(0, 10);
      if (!startDate || !isFutureDate(startDate)) continue;

      const startTime = (e.start_date ?? "").substring(11, 16);
      const horaires = startTime ? `${startTime.replace(":", "h")}` : "";

      // Category mapping
      const cats = (e.categories ?? []).map((c: any) => (c.name ?? "").toLowerCase());
      let source = "day_concert";
      let typeName = "Concert";
      if (cats.some((c: string) => c.includes("club") || c.includes("dj"))) {
        source = "day_djset";
        typeName = "DJ Set";
      } else if (cats.some((c: string) => c.includes("spectacle"))) {
        source = "day_spectacle";
        typeName = "Spectacle";
      }

      // Skip non-event categories (ateliers, portes ouvertes...)
      if (cats.some((c: string) => c.includes("ateliers")) && !cats.some((c: string) => c.includes("concert"))) continue;

      const description = (e.excerpt ?? e.description ?? "").replace(/<[^>]+>/g, "").trim().substring(0, 300);
      const ticketUrl = e.website ?? e.url ?? "";
      const cost = e.cost ?? "";
      const gratuit = cost.toLowerCase().includes("gratuit") || cost === "" ? "oui" : "non";
      const photoUrl = e.image?.url ?? "";

      const id = `metronum_${normalize(rawTitle).slice(0, 40)}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source, rubrique: "day",
        nom_de_la_manifestation: name,
        descriptif_court: description.substring(0, 150),
        descriptif_long: description,
        date_debut: startDate, date_fin: startDate,
        horaires,
        lieu_nom: "Le Metronum",
        lieu_adresse_2: "2 Rond-point Madame de Mondonville",
        commune: "Toulouse",
        code_postal: 31200,
        type_de_manifestation: typeName,
        categorie_de_la_manifestation: typeName,
        manifestation_gratuite: gratuit,
        reservation_site_internet: ticketUrl,
        photo_url: photoUrl,
      }));
    }

    // Cleanup stale Metronum records
    if (events.length > 0) {
      const currentIds = events.map(e => e.identifiant);
      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const delUrl = `${SUPABASE_URL}/rest/v1/scraped_events?lieu_nom=eq.Le Metronum&identifiant=not.in.(${currentIds.join(",")})`;
      const delRes = await fetch(delUrl, { method: "DELETE", headers: supabaseHeaders });
      if (delRes.ok) console.log(`metronum: cleaned up stale records`);
    }

    console.log(`metronum: ${events.length} future events from ${rawEvents.length} total`);
    return events;
  } catch (e) { console.error("Metronum error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Casino Barrière Toulouse (Storyblok CDN API)
// ─────────────────────────────────────────────────────────────
const STORYBLOK_TOKEN = "zbxp5eNhyKynscv1EpOhsAtt";

async function fetchCasinoBarriere(): Promise<ScrapedEvent[]> {
  try {
    // Fetch all spectacle stories from Storyblok CDN API (paginated, 100 per page)
    const allStories: any[] = [];
    for (let page = 1; page <= 5; page++) {
      const url = `https://api.storyblok.com/v2/cdn/stories?starts_with=website-casinos/spectacles/&token=${STORYBLOK_TOKEN}&per_page=100&page=${page}`;
      const res = await fetch(url, { redirect: "follow" });
      if (!res.ok) { console.error(`casino-barriere: storyblok page ${page} status=${res.status}`); break; }
      const data = await res.json();
      const stories = data.stories || [];
      allStories.push(...stories);
      if (stories.length < 100) break; // last page
    }
    console.log(`casino-barriere: fetched ${allStories.length} stories from Storyblok`);

    const events: ScrapedEvent[] = [];

    for (const story of allStories) {
      const content = story.content;
      if (!content) continue;

      const title = content.title || content.artist || story.name || "";
      if (!title) continue;

      const subtitle = content.subtitle || "";
      const genre = (content.genre || "").toLowerCase();
      const seoDesc = content.seoDescription || content.previewDescription || "";
      const slug = story.slug || "";

      // Get thumbnail/image
      let photoUrl = "";
      if (content.thumbnail && typeof content.thumbnail === "object") {
        photoUrl = content.thumbnail.filename || "";
      }
      if (!photoUrl && content.mainVisual && typeof content.mainVisual === "object") {
        photoUrl = content.mainVisual.filename || "";
      }

      // Resolve shows for Toulouse
      const shows = content.shows;
      if (!Array.isArray(shows)) continue;

      for (const show of shows) {
        if (typeof show !== "object" || !show) continue;
        const city = (show.city || "").toLowerCase();
        if (city !== "toulouse") continue;

        const price = show.price || "";
        const schedule = show.schedule;
        if (!Array.isArray(schedule)) continue;

        for (const sched of schedule) {
          if (typeof sched !== "object" || !sched) continue;
          const rawDate = sched.date || "";
          if (!rawDate) continue;

          const dateStr = rawDate.substring(0, 10);
          if (!dateStr || !isFutureDate(dateStr)) continue;

          const timeStr = rawDate.substring(11, 16);
          const horaires = timeStr ? timeStr.replace(":", "h") : "";

          // Map genre to source
          let source = "day_spectacle";
          let typeName = "Spectacle";
          if (genre === "concert" || genre === "classic") {
            source = "day_concert";
            typeName = "Concert";
          }

          const displayName = subtitle ? `${title} - ${subtitle}` : title;
          const id = `casino_${normalize(displayName).slice(0, 40)}_${dateStr}`;

          const gratuit = "non";
          const tarif = price ? `A partir de ${price}€` : "";

          events.push(makeEvent({
            identifiant: id, source, rubrique: "day",
            nom_de_la_manifestation: displayName.toUpperCase(),
            descriptif_court: seoDesc.substring(0, 150),
            descriptif_long: seoDesc,
            date_debut: dateStr, date_fin: dateStr,
            horaires,
            lieu_nom: "Casino Barriere",
            lieu_adresse_2: "18 Chemin de la Loge",
            commune: "Toulouse",
            code_postal: 31100,
            type_de_manifestation: typeName,
            categorie_de_la_manifestation: genre || typeName,
            manifestation_gratuite: gratuit,
            tarif_normal: tarif,
            reservation_site_internet: `https://www.casinosbarriere.com/toulouse/spectacle/${slug}`,
            photo_url: photoUrl,
          }));
        }
      }
    }

    // Dedup by identifiant
    const seen = new Set<string>();
    const deduped = events.filter(e => {
      if (seen.has(e.identifiant)) return false;
      seen.add(e.identifiant);
      return true;
    });

    // Cleanup stale Casino Barriere records
    if (deduped.length > 0) {
      const currentIds = deduped.map(e => e.identifiant);
      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const delUrl = `${SUPABASE_URL}/rest/v1/scraped_events?lieu_nom=eq.Casino Barriere&identifiant=not.in.(${currentIds.join(",")})`;
      const delRes = await fetch(delUrl, { method: "DELETE", headers: supabaseHeaders });
      if (delRes.ok) console.log(`casino-barriere: cleaned up stale records`);
    }

    console.log(`casino-barriere: ${deduped.length} future events`);
    return deduped;
  } catch (e) { console.error("Casino Barriere error:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Categorize ODS events by type/category
// ─────────────────────────────────────────────────────────────
function categorizeEvent(e: ScrapedEvent): string {
  const type = (e.type_de_manifestation || "").toLowerCase();
  const cat = (e.categorie_de_la_manifestation || "").toLowerCase();
  const lieu = (e.lieu_nom || "").toLowerCase();

  // Fête de la musique — check before festival/concert
  const nom = (e.nom_de_la_manifestation || "").toLowerCase();
  if (nom.includes("fête de la musique") || nom.includes("fete de la musique") || cat.includes("fête de la musique") || type.includes("fête de la musique")) return "day_fete_musique";

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

  const [ods, tm, festikConcert, festikFestival, festikSpectacle, operaTls, bikini, zenith, tfg, tlTourisme, interference, metronum, leRex, bascala, comdt, casinoBarriere, onctPhotos] = await Promise.all([
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
    fetchInterference(),
    fetchMetronum(),
    fetchLeRex(),
    fetchBascala(),
    fetchCOMDT(),
    fetchCasinoBarriere(),
    fetchONCTPhotos(),
  ]);

  // Tag ODS events by category + enrich Halle aux Grains photos
  const taggedOds = enrichHallePhotos(
    ods.map(e => {
      const source = categorizeEvent(e);
      return source === "skip" ? null : { ...e, source };
    }).filter(Boolean) as ScrapedEvent[],
    onctPhotos,
  );

  // Tag external sources
  const taggedTm = tm.map(e => ({ ...e, source: "day_concert" }));
  const taggedFestikC = festikConcert.map(e => ({ ...e, source: "day_concert" }));
  const taggedFestikF = festikFestival.map(e => ({ ...e, source: "day_festival" }));
  const taggedFestikS = festikSpectacle.filter(e => {
    const t = e.nom_de_la_manifestation.toLowerCase();
    return !t.includes("theatre");
  }).map(e => ({ ...e, source: "day_spectacle" }));

  // Curated sources first so they win dedup over generic ODS tags
  const allRaw = [...zenith, ...leRex, ...bascala, ...comdt, ...casinoBarriere, ...tfg, ...operaTls, ...bikini, ...interference, ...metronum, ...tlTourisme, ...taggedOds, ...taggedTm, ...taggedFestikC, ...taggedFestikF, ...taggedFestikS];

  // Re-tag "Fête de la musique" events regardless of original source
  const all = allRaw.map(e => {
    const nom = (e.nom_de_la_manifestation || "").toLowerCase();
    if (nom.includes("fête de la musique") || nom.includes("fete de la musique")) {
      return { ...e, source: "day_fete_musique" };
    }
    return e;
  });
  const deduped = dedup(all);

  // Enrich TFG events without photos using Ticketmaster artist images
  return enrichTfgPhotos(deduped);
}

// ─────────────────────────────────────────────────────────────
// Ticketmaster artist image enrichment for events without photos
// ─────────────────────────────────────────────────────────────
const MANUAL_ARTIST_PHOTOS: Record<string, string> = {
  florentpagny: "https://blog.ticketmaster.fr/wp-content/uploads/2024/12/TKM_800x400.jpg",
};

async function enrichTfgPhotos(events: ScrapedEvent[]): Promise<ScrapedEvent[]> {
  // First apply manual overrides
  const withManual = events.map(e => {
    if (e.photo_url || !e.identifiant.startsWith("tfg_")) return e;
    const key = normalize(e.nom_de_la_manifestation);
    const manual = MANUAL_ARTIST_PHOTOS[key];
    return manual ? { ...e, photo_url: manual } : e;
  });

  if (!TICKETMASTER_API_KEY) return withManual;

  // Collect unique artist names that still need photos (after manual overrides)
  const needPhoto = new Map<string, string[]>(); // normalized name → [indices]
  for (let i = 0; i < withManual.length; i++) {
    const e = withManual[i];
    if (e.photo_url || !e.identifiant.startsWith("tfg_")) continue;
    const key = normalize(e.nom_de_la_manifestation);
    if (!needPhoto.has(key)) needPhoto.set(key, []);
    needPhoto.get(key)!.push(String(i));
  }

  if (needPhoto.size === 0) return withManual;
  console.log(`TFG photo enrichment: ${needPhoto.size} unique artists need photos`);

  // Sequential search to avoid Ticketmaster rate limits (max 20 artists)
  const artists = [...needPhoto.entries()].slice(0, 20);
  const enriched = [...withManual];
  let count = 0;

  for (const [_, indices] of artists) {
    const name = withManual[Number(indices[0])].nom_de_la_manifestation;
    try {
      const url = `https://app.ticketmaster.com/discovery/v2/attractions.json?apikey=${TICKETMASTER_API_KEY}&keyword=${encodeURIComponent(name)}&countryCode=FR&size=1`;
      const data = await fetchJson<any>(url, 8000);
      const attraction = data._embedded?.attractions?.[0];
      if (!attraction?.images?.length) continue;
      const imgs = attraction.images as any[];
      const best = imgs.sort((a: any, b: any) => (b.width ?? 0) - (a.width ?? 0))[0];
      const photoUrl = best?.url ?? "";
      if (!photoUrl) continue;
      for (const idx of indices) {
        enriched[Number(idx)] = { ...enriched[Number(idx)], photo_url: photoUrl };
        count++;
      }
    } catch { /* skip on error */ }
  }
  console.log(`TFG photo enrichment: found photos for ${count} events`);
  return enriched;
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

  // Preserve existing photos: don't overwrite non-empty photo_url with empty
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/scraped_events?select=identifiant,photo_url&photo_url=neq.`,
      { headers: supabaseHeaders },
    );
    if (res.ok) {
      const existing = await res.json() as { identifiant: string; photo_url: string }[];
      const photoMap = new Map(existing.map(e => [e.identifiant, e.photo_url]));
      for (let i = 0; i < allEvents.length; i++) {
        if (!allEvents[i].photo_url) {
          const saved = photoMap.get(allEvents[i].identifiant);
          if (saved) allEvents[i] = { ...allEvents[i], photo_url: saved };
        }
      }
      console.log(`Preserved ${photoMap.size} existing photos`);
    }
  } catch (e) { console.error("Photo preservation error:", e); }

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

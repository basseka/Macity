// Edge Function: scrape-concerts (multi-ville)
// Scrape concerts pour n'importe quelle ville depuis plusieurs sources.
// Usage: POST /scrape-concerts { "ville": "Lyon" }
//        POST /scrape-concerts { "ville": "all" }  ← toutes les villes
//
// Sources :
//   1. offi.fr — listing pagine, Schema.org MusicEvent
//   2. OpenAgenda (OpenDataSoft) — API publique, events par ville
//   3. BilletReduc — listing concerts par ville
//
// Deploy: supabase functions deploy scrape-concerts --no-verify-jwt

import { makeEvent, upsertEvents, withErrorLogging, isFutureDate } from "../_shared/db.ts";
import { cleanHtml, fetchHtml, frenchDateToIso } from "../_shared/html-utils.ts";

const SCRAPER = "scrape-concerts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ── DB source types ─────────────────────────────────────────────
interface DbSource {
  source_name: string;
  source_type: string;
  url_template: string;
  config: Record<string, unknown>;
  category: string;
  max_pages: number;
  priority: number;
  ville: string;
}

async function fetchDbSources(ville: string): Promise<DbSource[]> {
  try {
    const url = `${SUPABASE_URL}/rest/v1/scraper_concert_specific_source?is_active=eq.true&or=(ville.eq.${ville},ville.eq.all)&order=priority.desc`;
    const res = await fetch(url, {
      headers: {
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return [];
    return await res.json();
  } catch (e) {
    console.log(`[db-sources] error: ${(e as Error).message}`);
    return [];
  }
}

// ── Scraper generique JSON-LD depuis une URL ────────────────────
async function scrapeJsonLdSource(
  source: DbSource,
  ville: string,
  config: CityConfig,
): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const cfg = source.config as Record<string, unknown>;
  const eventType = (cfg.event_type as string) || "MusicEvent";
  const twoPass = cfg.two_pass === true;
  const maxPages = source.max_pages || 1;

  for (let page = 0; page < maxPages; page++) {
    const url = source.url_template
      .replace("{page}", String(page))
      .replace("{ville}", ville.toLowerCase())
      .replace("{slug}", ville.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z]+/g, "-"));

    // Headers custom (cookie, User-Agent)
    const headers: Record<string, string> = {
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
    };
    const cookie = cfg.country_cookie as string;
    if (cookie) headers["Cookie"] = cookie;
    const baseUrl = (cfg.base_url as string) || "";

    let html: string;
    try {
      const res = await fetch(url, { headers, signal: AbortSignal.timeout(10000) });
      html = await res.text();
    } catch {
      break;
    }

    if (twoPass) {
      // Collecter les URLs de detail, puis fetcher chaque page
      const linkRegex = cfg.detail_url_regex as string;
      if (!linkRegex) break;
      const re = new RegExp(linkRegex, "g");
      const detailUrls: string[] = [];
      let m: RegExpExecArray | null;
      while ((m = re.exec(html)) !== null) {
        let foundUrl = m[1] || m[0];
        // Construire URL complete si relative
        if (foundUrl.startsWith("/")) foundUrl = baseUrl + foundUrl;
        else if (!foundUrl.startsWith("http")) foundUrl = baseUrl + "/" + foundUrl;
        if (!detailUrls.includes(foundUrl)) detailUrls.push(foundUrl);
      }
      for (const detailUrl of detailUrls.slice(0, 20)) {
        try {
          const res = await fetch(detailUrl, { headers, signal: AbortSignal.timeout(8000) });
          const detailHtml = await res.text();
          const parsed = extractJsonLdEvents(detailHtml, eventType, source, ville, detailUrl, cfg);
          events.push(...parsed);
        } catch { /* skip */ }
      }
    } else {
      const parsed = extractJsonLdEvents(html, eventType, source, ville, url, cfg);
      events.push(...parsed);
      if (parsed.length === 0) break;
    }
  }

  console.log(`[db:${source.source_name}/${ville}] ${events.length} events`);
  return events;
}

function extractJsonLdEvents(
  html: string,
  eventType: string,
  source: DbSource,
  ville: string,
  pageUrl: string,
  cfg: Record<string, unknown>,
): ReturnType<typeof makeEvent>[] {
  const events: ReturnType<typeof makeEvent>[] = [];
  const ldRegex = /<script\s+type="application\/ld\+json">([\s\S]*?)<\/script>/g;
  let match: RegExpExecArray | null;

  while ((match = ldRegex.exec(html)) !== null) {
    try {
      const json = JSON.parse(match[1]);
      const items = Array.isArray(json) ? json : [json];
      for (const item of items) {
        if (item["@type"] !== eventType) continue;

        const title = item.name || "";
        if (!title) continue;

        const rawDate = item.startDate || "";
        const dateDebut = rawDate.substring(0, 10);
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        const dateFin = (item.endDate || rawDate).substring(0, 10);
        const lieuNom = item.location?.name || "";
        let photoUrl = typeof item.image === "string" ? item.image : (item.image?.[0] || "");
        const link = item.url || pageUrl;
        const description = item.description ? cleanHtml(String(item.description)).substring(0, 300) : "";

        // Fallback image
        if (!photoUrl) {
          const ogImg = html.match(/property="og:image"[^>]*content="([^"]+)"/)
            || html.match(/content="([^"]+)"[^>]*property="og:image"/);
          if (ogImg) photoUrl = ogImg[1];
        }
        if (!photoUrl && cfg.image_fallback_regex) {
          const imgRe = new RegExp(cfg.image_fallback_regex as string);
          const imgMatch = html.match(imgRe);
          if (imgMatch) photoUrl = imgMatch[1];
        }

        // Prix
        const lowPrice = item.offers?.lowPrice || item.offers?.price;
        const tarif = lowPrice ? `${lowPrice}\u20AC` : "";

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        events.push(makeEvent({
          identifiant: `${source.source_name}_${slug}_${dateDebut}`,
          source: source.source_name,
          rubrique: "day",
          nom_de_la_manifestation: title,
          descriptif_court: description,
          date_debut: dateDebut,
          date_fin: dateFin,
          horaires: rawDate.length > 10 ? rawDate.substring(11, 16).replace(":", "h") : "",
          lieu_nom: lieuNom,
          commune: ville,
          ville,
          type_de_manifestation: source.category,
          categorie_de_la_manifestation: source.category,
          tarif_normal: tarif,
          manifestation_gratuite: tarif ? "non" : "",
          photo_url: photoUrl,
          reservation_site_internet: link,
        }));
      }
    } catch { /* parse error */ }
  }
  return events;
}

// ── Helper : parse date francaise → YYYY-MM-DD ──────────────────
const FR_MONTHS: Record<string, string> = {
  janv: "01", jan: "01", janvier: "01",
  fevr: "02", fev: "02", fevrier: "02", "févr": "02", "février": "02",
  mars: "03", mar: "03",
  avri: "04", avr: "04", avril: "04",
  mai: "05",
  juin: "06",
  juil: "07", juillet: "07",
  aout: "08", "août": "08",
  sept: "09", septembre: "09",
  octo: "10", oct: "10", octobre: "10",
  nove: "11", nov: "11", novembre: "11",
  dece: "12", dec: "12", decembre: "12", "déce": "12", "décembre": "12",
};

function parseFrenchDate(text: string): string {
  const m = text.match(/(\d{1,2})\s*([a-zéûôâîè]+)\.?\s*(\d{4})?/i);
  if (!m) return "";
  const day = m[1].padStart(2, "0");
  const monthKey = m[2].toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").substring(0, 4);
  const month = FR_MONTHS[monthKey] || FR_MONTHS[m[2].toLowerCase()] || "";
  if (!month) return "";
  const year = m[3] || new Date().getFullYear().toString();
  return `${year}-${month}-${day}`;
}

// ── Scraper generique HTML depuis une URL ────────────────────────
async function scrapeHtmlSource(
  source: DbSource,
  ville: string,
  _config: CityConfig,
): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const cfg = source.config as Record<string, unknown>;
  const isTwoPass = cfg.two_pass === true;

  // ── Mode two-pass : listing → collecte URLs → fetch detail pages ──
  if (isTwoPass) {
    const url = source.url_template.replace("{page}", "1");
    let html: string;
    try {
      html = await fetchHtml(url, 10000);
    } catch {
      return events;
    }

    // Collecter les URLs de detail
    const detailUrlRegex = cfg.detail_url_regex as string;
    if (!detailUrlRegex) return events;
    const re = new RegExp(detailUrlRegex, "g");
    const detailUrls: string[] = [];
    let m: RegExpExecArray | null;
    while ((m = re.exec(html)) !== null) {
      // m[1] si capture group, sinon m[0]
      let foundUrl = m[1] || m[0];
      if (!foundUrl.startsWith("http")) foundUrl = `https://www.${foundUrl}`;
      if (!detailUrls.includes(foundUrl)) detailUrls.push(foundUrl);
    }

    // Extraire aussi le genre et le lieu depuis le listing si possible
    const genreRegex = cfg.genre_regex as string;
    const titleRegex = cfg.title_regex as string;
    const listingMeta = new Map<string, { genre: string; lieuFromListing: string }>();
    if (titleRegex) {
      const blocks = html.split("blog-post");
      for (const block of blocks) {
        const tm = block.match(new RegExp(titleRegex));
        if (!tm) continue;
        const t = cleanHtml(tm[1]).trim();
        const gm = genreRegex ? block.match(new RegExp(genreRegex)) : null;
        const genre = gm ? cleanHtml(gm[1]) : "";
        // Lieu depuis les category tags
        const lieuMatch = block.match(/category tag">([^<]+)/);
        const lieu = lieuMatch ? cleanHtml(lieuMatch[1]) : "";
        listingMeta.set(t, { genre, lieuFromListing: lieu });
      }
    }

    // Venue keywords pour fallback
    const venueKeywords = (cfg.venue_keywords as string[]) || [];

    // Fetcher les detail pages (max 20 pour rester dans le timeout)
    for (const detailUrl of detailUrls.slice(0, 20)) {
      try {
        const detailHtml = await fetchHtml(detailUrl, 8000);

        // Titre depuis la page detail
        const h1Match = detailHtml.match(/<h1[^>]*>([^<]+)<\/h1>/);
        const title = h1Match ? cleanHtml(h1Match[1]).trim() : "";
        if (!title) continue;

        // Date : chercher format francais dans le HTML
        const dateTexts = detailHtml.match(/(\d{1,2})\s*(janv|f[ée]vr|mars|avri|mai|juin|juil|ao[uû]t|sept|octo|nove|d[ée]ce)[a-zé]*\.?\s*(\d{4})/gi) || [];
        let dateDebut = "";
        for (const dt of dateTexts) {
          const parsed = parseFrenchDate(dt);
          if (parsed && isFutureDate(parsed)) {
            dateDebut = parsed;
            break;
          }
        }
        if (!dateDebut) continue;

        // Lieu : chercher dans le texte les mots-cles de salles
        let lieuNom = "";
        for (const kw of venueKeywords) {
          if (detailHtml.includes(kw)) { lieuNom = kw; break; }
        }
        // Ou depuis le listing
        if (!lieuNom) {
          const meta = listingMeta.get(title);
          if (meta?.lieuFromListing) lieuNom = meta.lieuFromListing;
        }

        // Genre depuis le listing
        const meta = listingMeta.get(title);
        const genre = meta?.genre || "";

        // Image : og:image ou premiere image de contenu
        const ogImg = detailHtml.match(/property="og:image"[^>]*content="([^"]+)"/)
          || detailHtml.match(/content="([^"]+)"[^>]*property="og:image"/);
        let photoUrl = ogImg ? ogImg[1] : "";
        if (!photoUrl) {
          const contentImg = detailHtml.match(/<img[^>]*src="(https?:\/\/[^"]+(?:\.jpg|\.jpeg|\.png|\.webp)[^"]*)"/i);
          if (contentImg && !contentImg[1].includes("logo") && !contentImg[1].includes("svg")) {
            photoUrl = contentImg[1];
          }
        }

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        events.push(makeEvent({
          identifiant: `${source.source_name}_${slug}_${dateDebut}`,
          source: source.source_name,
          rubrique: "day",
          nom_de_la_manifestation: title,
          descriptif_court: genre ? `Genre : ${genre}` : "",
          date_debut: dateDebut,
          date_fin: dateDebut,
          lieu_nom: lieuNom,
          commune: ville,
          ville,
          type_de_manifestation: source.category,
          categorie_de_la_manifestation: genre || source.category,
          photo_url: photoUrl,
          reservation_site_internet: detailUrl,
        }));
      } catch { /* skip */ }
    }

    console.log(`[db:${source.source_name}/${ville}] ${events.length} events (two-pass)`);
    return events;
  }

  // ── Mode simple : parse directement le listing ──
  for (let page = 1; page <= source.max_pages; page++) {
    const url = source.url_template.replace("{page}", String(page));

    let html: string;
    try {
      html = await fetchHtml(url, 10000);
    } catch {
      break;
    }

    const cardSplit = cfg.card_split as string;
    const parts = cardSplit ? html.split(cardSplit) : [html];
    let found = 0;

    for (let k = cardSplit ? 1 : 0; k < parts.length; k++) {
      const card = parts[k];

      const titleRegex = cfg.title_regex as string;
      const dateRegex = cfg.date_regex as string;
      if (!titleRegex || !dateRegex) break;

      const titleMatch = card.match(new RegExp(titleRegex));
      const title = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!title) continue;

      const dateMatch = card.match(new RegExp(dateRegex));
      let dateDebut = dateMatch ? dateMatch[1] : "";

      // Si date_format fr, parser la date francaise
      if (cfg.date_format === "fr" || cfg.date_format === "fr_long") {
        const rawDate = dateMatch ? dateMatch[0] : "";
        dateDebut = parseFrenchDate(rawDate);
      }
      if (!dateDebut || !isFutureDate(dateDebut)) continue;
      found++;

      const venueRegex = cfg.venue_regex as string;
      const venueMatch = venueRegex ? card.match(new RegExp(venueRegex)) : null;
      const lieuNom = venueMatch ? cleanHtml(venueMatch[1]) : "";

      const imageRegex = cfg.image_regex as string;
      const imgMatch = imageRegex ? card.match(new RegExp(imageRegex)) : null;
      const photoUrl = imgMatch ? imgMatch[1] : "";

      const linkRegex = cfg.link_regex as string;
      const linkMatch = linkRegex ? card.match(new RegExp(linkRegex)) : null;
      const link = linkMatch ? linkMatch[1] : "";

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
      events.push(makeEvent({
        identifiant: `${source.source_name}_${slug}_${dateDebut}`,
        source: source.source_name,
        rubrique: "day",
        nom_de_la_manifestation: title,
        date_debut: dateDebut,
        date_fin: dateDebut,
        lieu_nom: lieuNom,
        commune: ville,
        ville,
        type_de_manifestation: source.category,
        categorie_de_la_manifestation: source.category,
        photo_url: photoUrl,
        reservation_site_internet: link.startsWith("http") ? link : "",
      }));
    }

    if (found === 0) break;
  }

  console.log(`[db:${source.source_name}/${ville}] ${events.length} events`);
  return events;
}

// ── Execute une source DB ────────────────────────────────────────
async function executeDbSource(
  source: DbSource,
  ville: string,
  config: CityConfig,
): Promise<ReturnType<typeof makeEvent>[]> {
  switch (source.source_type) {
    case "json_ld":
      return scrapeJsonLdSource(source, ville, config);
    case "html_scraper":
      return scrapeHtmlSource(source, ville, config);
    default:
      console.log(`[db:${source.source_name}] type '${source.source_type}' non supporte`);
      return [];
  }
}

// ── Villes supportees avec slug offi.fr ─────────────────────────
interface CityConfig {
  offiSlug: string;         // slug pour offi.fr
  billetReducSlug: string;  // slug pour billetreduc.com
  lat: number;
  lon: number;
}

const CITIES: Record<string, CityConfig> = {
  "Toulouse":         { offiSlug: "toulouse",         billetReducSlug: "toulouse",         lat: 43.6047, lon: 1.4442 },
  "Paris":            { offiSlug: "paris",             billetReducSlug: "paris",             lat: 48.8566, lon: 2.3522 },
  "Lyon":             { offiSlug: "lyon",              billetReducSlug: "lyon",              lat: 45.7640, lon: 4.8357 },
  "Marseille":        { offiSlug: "marseille",         billetReducSlug: "marseille",         lat: 43.2965, lon: 5.3698 },
  "Bordeaux":         { offiSlug: "bordeaux",          billetReducSlug: "bordeaux",          lat: 44.8378, lon: -0.5792 },
  "Lille":            { offiSlug: "lille",              billetReducSlug: "lille",              lat: 50.6292, lon: 3.0573 },
  "Nantes":           { offiSlug: "nantes",            billetReducSlug: "nantes",            lat: 47.2184, lon: -1.5536 },
  "Strasbourg":       { offiSlug: "strasbourg",        billetReducSlug: "strasbourg",        lat: 48.5734, lon: 7.7521 },
  "Nice":             { offiSlug: "nice",              billetReducSlug: "nice",              lat: 43.7102, lon: 7.2620 },
  "Montpellier":      { offiSlug: "montpellier",       billetReducSlug: "montpellier",       lat: 43.6108, lon: 3.8767 },
  "Rennes":           { offiSlug: "rennes",            billetReducSlug: "rennes",            lat: 48.1173, lon: -1.6778 },
  "Grenoble":         { offiSlug: "grenoble",          billetReducSlug: "grenoble",          lat: 45.1885, lon: 5.7245 },
  "Dijon":            { offiSlug: "dijon",             billetReducSlug: "dijon",             lat: 47.3220, lon: 5.0415 },
  "Angers":           { offiSlug: "angers",            billetReducSlug: "angers",            lat: 47.4784, lon: -0.5632 },
  "Reims":            { offiSlug: "reims",             billetReducSlug: "reims",             lat: 49.2583, lon: 3.5170 },
  "Toulon":           { offiSlug: "toulon",            billetReducSlug: "toulon",            lat: 43.1242, lon: 5.9280 },
  "Saint-Etienne":    { offiSlug: "saint-etienne",     billetReducSlug: "saint-etienne",     lat: 45.4397, lon: 4.3872 },
  "Clermont-Ferrand": { offiSlug: "clermont-ferrand",  billetReducSlug: "clermont-ferrand",  lat: 45.7772, lon: 3.0870 },
  "Le Havre":         { offiSlug: "le-havre",          billetReducSlug: "le-havre",          lat: 49.4944, lon: 0.1079 },
  "Aix-en-Provence":  { offiSlug: "aix-en-provence",   billetReducSlug: "aix-en-provence",   lat: 43.5297, lon: 5.4474 },
  "Brest":            { offiSlug: "brest",             billetReducSlug: "brest",             lat: 48.3904, lon: -4.4861 },
  "Amiens":           { offiSlug: "amiens",            billetReducSlug: "amiens",            lat: 49.8941, lon: 2.2958 },
  "Annecy":           { offiSlug: "annecy",            billetReducSlug: "annecy",            lat: 45.8992, lon: 6.1294 },
  "Besancon":         { offiSlug: "besancon",          billetReducSlug: "besancon",          lat: 47.2378, lon: 6.0241 },
  "Metz":             { offiSlug: "metz",              billetReducSlug: "metz",              lat: 49.1193, lon: 6.1757 },
  "Rouen":            { offiSlug: "rouen",             billetReducSlug: "rouen",             lat: 49.4432, lon: 1.0999 },
  "Nancy":            { offiSlug: "nancy",             billetReducSlug: "nancy",             lat: 48.6921, lon: 6.1844 },
  "Avignon":          { offiSlug: "avignon",           billetReducSlug: "avignon",           lat: 43.9493, lon: 4.8055 },
  "Colmar":           { offiSlug: "colmar",            billetReducSlug: "colmar",            lat: 48.0794, lon: 7.3558 },
  "Bayonne":          { offiSlug: "bayonne",           billetReducSlug: "bayonne",           lat: 43.4933, lon: -1.4753 },
  "Carcassonne":      { offiSlug: "carcassonne",       billetReducSlug: "carcassonne",       lat: 43.2130, lon: 2.3491 },
  "Nimes":            { offiSlug: "nimes",             billetReducSlug: "nimes",             lat: 43.8367, lon: 4.3601 },
  "Geneve":           { offiSlug: "geneve",            billetReducSlug: "geneve",            lat: 46.2044, lon: 6.1432 },
};

// ─── 1. OFFI.FR ────────────────────────────────────────────────
// /concerts/programme-{ville}.html?npage=N

async function scrapeOffi(ville: string, config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const maxPages = 10;

  for (let page = 1; page <= maxPages; page++) {
    const url = `https://www.offi.fr/concerts/programme.html?npage=${page}`;
    let html: string;
    try {
      html = await fetchHtml(url, 10000);
    } catch {
      break;
    }

    const parts = html.split(/id="minifiche_\d+"/);
    let found = 0;

    for (let k = 1; k < parts.length; k++) {
      const card = parts[k];
      found++;

      const titleMatch = card.match(/<span\s+itemprop="name">([^<]+)<\/span>/);
      const title = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!title) continue;

      const dateMatch = card.match(/itemprop="startDate"\s+content="(\d{4}-\d{2}-\d{2})/);
      const dateDebut = dateMatch ? dateMatch[1] : "";
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const timeMatch = card.match(/itemprop="startDate"\s+content="\d{4}-\d{2}-\d{2}\s+(\d{2}):(\d{2})/);
      const horaires = timeMatch ? `${timeMatch[1]}h${timeMatch[2]}` : "";

      const venueMatch = card.match(/event-place[^>]*>\s*<a[^>]*>\s*([^<]+)/);
      const lieuNom = venueMatch ? cleanHtml(venueMatch[1]) : "";

      const genres: string[] = [];
      const genreRe = /item-info[^>]*>([^<]+)</g;
      let gm: RegExpExecArray | null;
      while ((gm = genreRe.exec(card)) !== null) genres.push(cleanHtml(gm[1]));
      const genre = genres.join(", ");

      const imgMatch = card.match(/itemprop="image"\s+src="([^"]+)"/);
      const photoUrl = imgMatch ? imgMatch[1] : "";

      const linkMatch = card.match(/itemprop="url"[^>]*href="([^"]+)"/);
      const rawLink = linkMatch ? linkMatch[1] : "";
      const link = rawLink.startsWith("http") ? rawLink : (rawLink ? `https://www.offi.fr${rawLink}` : "");

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
      events.push(makeEvent({
        identifiant: `offi_${config.offiSlug}_${slug}_${dateDebut}`,
        source: "day_concert",
        rubrique: "day",
        nom_de_la_manifestation: title,
        date_debut: dateDebut,
        date_fin: dateDebut,
        horaires,
        lieu_nom: lieuNom,
        commune: ville,
        ville,
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: genre || "Concert",
        theme_de_la_manifestation: genre,
        photo_url: photoUrl,
        reservation_site_internet: link,
      }));
    }

    if (found === 0) break;
  }

  console.log(`[offi/${ville}] ${events.length} concerts`);
  return events;
}

// ─── 2. OPENAGENDA (API v2) ────────────────────────────────────
// API officielle avec cle API — concerts par geo-point

const OPENAGENDA_KEY = Deno.env.get("OPENAGENDA_API_KEY") || "";

async function scrapeOpenAgenda(ville: string, config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  if (!OPENAGENDA_KEY) {
    console.log(`[openagenda/${ville}] pas de cle API configuree`);
    return events;
  }

  // Si pas de cle API, utiliser le fallback OpenDataSoft
  if (OPENAGENDA_KEY === "" || OPENAGENDA_KEY === "none") {
    return scrapeOpenAgendaFallback(ville, config);
  }

  // Recherche par mots-cles concert/musique pres de la ville
  const searches = ["concert", "musique live", "festival musique"];
  const seen = new Set<string>();

  for (const search of searches) {
    try {
      const params = new URLSearchParams({
        key: OPENAGENDA_KEY,
        search,
        "geo[lat]": config.lat.toString(),
        "geo[lng]": config.lon.toString(),
        "geo[radius]": "20000",
        "relative[0]": "current",
        "relative[1]": "upcoming",
        size: "50",
        sort: "timings.asc",
      });

      const res = await fetch(`https://api.openagenda.com/v2/events?${params.toString()}`, {
        headers: { "User-Agent": "MaCityApp/1.0" },
        signal: AbortSignal.timeout(12000),
      });

      if (!res.ok) {
        const errText = await res.text();
        console.log(`[openagenda/${ville}] HTTP ${res.status}: ${errText.substring(0, 100)}`);
        continue;
      }

      const data = await res.json();
      const records = data.events || [];

      for (const e of records) {
        const title = e.title?.fr || e.title?.en || "";
        if (!title) continue;

        // Timings
        const timings = e.timings || [];
        const firstTiming = timings[0];
        if (!firstTiming) continue;

        const dateDebut = (firstTiming.begin || "").substring(0, 10);
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        const lastTiming = timings[timings.length - 1];
        const dateFin = (lastTiming?.end || firstTiming.begin || "").substring(0, 10);

        // Horaires
        const timeStr = (firstTiming.begin || "").substring(11, 16);
        const horaires = timeStr ? timeStr.replace(":", "h") : "";

        // Location
        const loc = e.location || {};
        const lieuNom = loc.name || "";

        // Image
        const image = e.image || {};
        const photoUrl = image.base ? `${image.base}${image.filename}` : "";

        // Description
        const desc = e.description?.fr || e.description?.en || "";
        const description = desc ? cleanHtml(desc).substring(0, 400) : "";

        // Lien
        const link = e.canonicalUrl || "";

        // Gratuit ?
        const conditions = e.conditions?.fr || "";
        const isFree = conditions.toLowerCase().includes("gratuit") || e.accessibility?.pricing === "free";

        // Keywords
        const keywords = (e.keywords?.fr || []).join(", ");

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        const dedupKey = `${slug}_${dateDebut}`;
        if (seen.has(dedupKey)) continue;
        seen.add(dedupKey);

        events.push(makeEvent({
          identifiant: `oa_${config.offiSlug}_${slug}_${dateDebut}`,
          source: "openagenda",
          rubrique: "day",
          nom_de_la_manifestation: title,
          descriptif_court: description,
          date_debut: dateDebut,
          date_fin: dateFin,
          horaires,
          lieu_nom: lieuNom,
          commune: loc.city || ville,
          ville,
          type_de_manifestation: "Concert",
          categorie_de_la_manifestation: keywords.includes("festival") ? "Festival" : "Concert",
          theme_de_la_manifestation: keywords,
          photo_url: photoUrl,
          reservation_site_internet: link,
          manifestation_gratuite: isFree ? "oui" : "non",
        }));
      }
    } catch (e) {
      console.log(`[openagenda/${ville}] search '${search}' error: ${(e as Error).message}`);
    }
  }

  console.log(`[openagenda/${ville}] ${events.length} concerts`);
  return events;
}

// ─── 2b. OPENAGENDA FALLBACK (OpenDataSoft, sans cle) ──────────
// Utilise le miroir OpenDataSoft quand pas de cle API secrete

async function scrapeOpenAgendaFallback(ville: string, config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const baseUrl = "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/evenements-publics-openagenda/records";

  // Recherche large : tous les events proches, puis filtrer cote code
  try {
    const params = new URLSearchParams({
      select: "title_fr,description_fr,firstdate_begin,lastdate_end,location_name,location_city,image,canonicalurl,keywords_fr,conditions_fr",
      where: `within_distance(location_coordinates, geom'POINT(${config.lon} ${config.lat})', 20km) AND firstdate_begin > NOW()`,
      order_by: "firstdate_begin ASC",
      limit: "100",
    });

    const res = await fetch(`${baseUrl}?${params.toString()}`, {
      headers: { "User-Agent": "MaCityApp/1.0" },
      signal: AbortSignal.timeout(12000),
    });

    if (!res.ok) {
      console.log(`[oa-fallback/${ville}] HTTP ${res.status}`);
      return events;
    }

    const data = await res.json();
    const records = data.results || [];

    for (const r of records) {
      const title = (r.title_fr || "").trim();
      if (!title) continue;

      // Filtrer : garder seulement ce qui ressemble a un concert/musique/festival
      const titleLower = title.toLowerCase();
      const keywords = (r.keywords_fr || "").toLowerCase();
      const descLower = (r.description_fr || "").toLowerCase();
      const isMusic = ["concert", "musique", "festival", "dj", "live", "jazz", "rock", "rap", "electro", "orchestre", "chorale", "recital", "opera"]
        .some((k) => titleLower.includes(k) || keywords.includes(k));
      if (!isMusic) continue;

      const dateDebut = (r.firstdate_begin || "").substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const dateFin = (r.lastdate_end || dateDebut).substring(0, 10);
      const lieuNom = r.location_name || "";
      const photoUrl = r.image || "";
      const link = r.canonicalurl || "";
      const description = r.description_fr ? cleanHtml(r.description_fr).substring(0, 400) : "";
      const isFree = (r.conditions_fr || "").toLowerCase().includes("gratuit");

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
      events.push(makeEvent({
        identifiant: `oads_${config.offiSlug}_${slug}_${dateDebut}`,
        source: "openagenda",
        rubrique: "day",
        nom_de_la_manifestation: title,
        descriptif_court: description,
        date_debut: dateDebut,
        date_fin: dateFin,
        lieu_nom: lieuNom,
        commune: r.location_city || ville,
        ville,
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: titleLower.includes("festival") ? "Festival" : "Concert",
        photo_url: photoUrl,
        reservation_site_internet: link,
        manifestation_gratuite: isFree ? "oui" : "non",
      }));
    }
  } catch (e) {
    console.log(`[oa-fallback/${ville}] error: ${(e as Error).message}`);
  }

  console.log(`[oa-fallback/${ville}] ${events.length} concerts`);
  return events;
}

// ─── 3. BILLETREDUC ────────────────────────────────────────────
// /lieu/{ville}/concerts.htm

async function scrapeBilletReduc(ville: string, config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const maxPages = 5;

  for (let page = 1; page <= maxPages; page++) {
    const pageParam = page > 1 ? `?page=${page}` : "";
    const url = `https://www.billetreduc.com/lieu/${config.billetReducSlug}/concerts.htm${pageParam}`;
    let html: string;
    try {
      html = await fetchHtml(url, 10000);
    } catch {
      break;
    }

    // BilletReduc : chaque event est dans un bloc <div class="evt_affiche"> ou <a class="result-event">
    // Essayons de parser les JSON-LD d'abord
    const ldRegex = /<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/g;
    let match: RegExpExecArray | null;
    let found = 0;

    while ((match = ldRegex.exec(html)) !== null) {
      try {
        const json = JSON.parse(match[1]);
        const items = Array.isArray(json) ? json : [json];
        for (const item of items) {
          if (item["@type"] !== "MusicEvent" && item["@type"] !== "Event") continue;
          found++;

          const title = item.name || "";
          if (!title) continue;

          const rawDate = item.startDate || "";
          const dateDebut = rawDate.substring(0, 10);
          if (!dateDebut || !isFutureDate(dateDebut)) continue;

          const lieuNom = item.location?.name || "";
          const photoUrl = typeof item.image === "string" ? item.image : (item.image?.url || "");
          const link = item.url || "";
          const price = item.offers?.lowPrice || item.offers?.price || "";
          const tarif = price ? `${price}\u20AC` : "";

          const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
          events.push(makeEvent({
            identifiant: `billetreduc_${config.billetReducSlug}_${slug}_${dateDebut}`,
            source: "billetreduc",
            rubrique: "day",
            nom_de_la_manifestation: title,
            date_debut: dateDebut,
            date_fin: dateDebut,
            lieu_nom: lieuNom,
            commune: ville,
            ville,
            type_de_manifestation: "Concert",
            categorie_de_la_manifestation: "Concert",
            tarif_normal: tarif,
            manifestation_gratuite: tarif ? "non" : "",
            photo_url: photoUrl,
            reservation_site_internet: link,
          }));
        }
      } catch {
        // JSON parse error
      }
    }

    // Fallback : parser les cards HTML si pas de JSON-LD
    if (found === 0) {
      // Chercher les liens d'events avec date
      const cardRegex = /class="[^"]*result-event[^"]*"[\s\S]*?<\/a>/g;
      let cardMatch: RegExpExecArray | null;
      while ((cardMatch = cardRegex.exec(html)) !== null) {
        found++;
        const card = cardMatch[0];

        const titleMatch = card.match(/title="([^"]+)"/);
        const title = titleMatch ? cleanHtml(titleMatch[1]) : "";
        if (!title) continue;

        const dateMatch = card.match(/(\d{1,2})\s+(janv|f[ée]vr|mars|avr|mai|juin|juil|ao[uû]t|sept|oct|nov|d[ée]c)[a-z]*/i);
        const dateDebut = dateMatch ? frenchDateToIso(`${dateMatch[1]} ${dateMatch[2]}`) || "" : "";
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        const imgMatch = card.match(/src="([^"]+)"/);
        const photoUrl = imgMatch ? imgMatch[1] : "";

        const linkMatch = card.match(/href="([^"]+)"/);
        const link = linkMatch ? (linkMatch[1].startsWith("http") ? linkMatch[1] : `https://www.billetreduc.com${linkMatch[1]}`) : "";

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        events.push(makeEvent({
          identifiant: `billetreduc_${config.billetReducSlug}_${slug}_${dateDebut}`,
          source: "billetreduc",
          rubrique: "day",
          nom_de_la_manifestation: title,
          date_debut: dateDebut,
          date_fin: dateDebut,
          commune: ville,
          ville,
          type_de_manifestation: "Concert",
          categorie_de_la_manifestation: "Concert",
          photo_url: photoUrl,
          reservation_site_internet: link,
        }));
      }
    }

    if (found === 0) break;
  }

  console.log(`[billetreduc/${ville}] ${events.length} concerts`);
  return events;
}

// ─── 4. SONGKICK (API publique) ────────────────────────────────
// Recherche par geo-point, retourne des concerts a venir

async function scrapeSongkick(ville: string, config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];

  try {
    // Songkick metro area search via their public calendar page
    const slug = ville.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z]+/g, "-");
    const url = `https://www.songkick.com/metro-areas/${slug}/calendar`;
    const html = await fetchHtml(url, 10000);

    // Parse JSON-LD events
    const ldRegex = /<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/g;
    let match: RegExpExecArray | null;

    while ((match = ldRegex.exec(html)) !== null) {
      try {
        const json = JSON.parse(match[1]);
        const items = Array.isArray(json) ? json : [json];
        for (const item of items) {
          if (item["@type"] !== "MusicEvent" && item["@type"] !== "Event") continue;

          const title = item.name || "";
          if (!title) continue;

          const rawDate = item.startDate || "";
          const dateDebut = rawDate.substring(0, 10);
          if (!dateDebut || !isFutureDate(dateDebut)) continue;

          const lieuNom = item.location?.name || "";
          const photoUrl = typeof item.image === "string" ? item.image : (item.image?.[0] || "");
          const link = item.url || "";

          const eventSlug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
          events.push(makeEvent({
            identifiant: `songkick_${slug}_${eventSlug}_${dateDebut}`,
            source: "songkick",
            rubrique: "day",
            nom_de_la_manifestation: title,
            date_debut: dateDebut,
            date_fin: dateDebut,
            lieu_nom: lieuNom,
            commune: ville,
            ville,
            type_de_manifestation: "Concert",
            categorie_de_la_manifestation: "Concert",
            photo_url: photoUrl,
            reservation_site_internet: link,
          }));
        }
      } catch {
        // JSON parse error
      }
    }
  } catch (e) {
    console.log(`[songkick/${ville}] error: ${(e as Error).message}`);
  }

  console.log(`[songkick/${ville}] ${events.length} concerts`);
  return events;
}

// ─── DEDUP CROSS-SOURCE ────────────────────────────────────────

function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/\(.*?\)/g, "")
    .replace(/\bfeat\.?\b|\bft\.?\b/gi, "")
    .replace(/[^a-z0-9]/g, "")
    .trim();
}

function deduplicateAcrossSources(events: ReturnType<typeof makeEvent>[]): ReturnType<typeof makeEvent>[] {
  const seen = new Map<string, ReturnType<typeof makeEvent>>();
  const priority: Record<string, number> = { day_concert: 3, billetreduc: 2, openagenda: 1 };

  for (const e of events) {
    const key = `${normalizeName(e.nom_de_la_manifestation)}_${e.date_debut}`;
    const existing = seen.get(key);
    if (!existing || (priority[e.source] || 0) > (priority[existing.source] || 0)) {
      if (existing?.tarif_normal && !e.tarif_normal) e.tarif_normal = existing.tarif_normal;
      if (existing?.photo_url && !e.photo_url) e.photo_url = existing.photo_url;
      if (existing?.reservation_site_internet && !e.reservation_site_internet) e.reservation_site_internet = existing.reservation_site_internet;
      seen.set(key, e);
    } else {
      if (e.tarif_normal && !existing.tarif_normal) existing.tarif_normal = e.tarif_normal;
      if (e.photo_url && !existing.photo_url) existing.photo_url = e.photo_url;
    }
  }

  return [...seen.values()];
}

// ─── SCRAPE UNE VILLE ──────────────────────────────────────────

async function scrapeCity(ville: string, config: CityConfig): Promise<{ count: number; sources: Record<string, number> }> {
  // Sources universelles
  const promises: Promise<ReturnType<typeof makeEvent>[]>[] = [
    withErrorLogging(SCRAPER, "openagenda", ville, () => scrapeOpenAgenda(ville, config)),
    withErrorLogging(SCRAPER, "billetreduc", ville, () => scrapeBilletReduc(ville, config)),
    withErrorLogging(SCRAPER, "songkick", ville, () => scrapeSongkick(ville, config)),
  ];

  // offi.fr = Paris uniquement
  if (ville === "Paris") {
    promises.push(withErrorLogging(SCRAPER, "offi", ville, () => scrapeOffi(ville, config)));
  }

  // Sources specifiques par ville (hardcodees — legacy)
  const citySpecificSources = CITY_SOURCES[ville];
  if (citySpecificSources) {
    for (const src of citySpecificSources) {
      promises.push(withErrorLogging(SCRAPER, src.name, ville, () => src.scrape(ville, config)));
    }
  }

  // Sources dynamiques depuis la DB (table scraper_concert_specific_source)
  const dbSources = await fetchDbSources(ville);
  for (const dbSrc of dbSources) {
    promises.push(withErrorLogging(SCRAPER, `db:${dbSrc.source_name}`, ville, () => executeDbSource(dbSrc, ville, config)));
  }

  const results = await Promise.all(promises);

  const sourceCounts: Record<string, number> = {};
  const labels = ["openagenda", "billetreduc", "songkick"];
  if (ville === "Paris") labels.push("offi");
  if (citySpecificSources) labels.push(...citySpecificSources.map((s) => s.name));
  for (const dbSrc of dbSources) labels.push(`db:${dbSrc.source_name}`);

  const allEvents: ReturnType<typeof makeEvent>[] = [];
  for (let i = 0; i < results.length; i++) {
    allEvents.push(...results[i]);
    sourceCounts[labels[i]] = results[i].length;
  }

  const deduped = deduplicateAcrossSources(allEvents);
  console.log(`[${ville}] Total: ${allEvents.length} brut -> ${deduped.length} apres dedup`);

  const count = await upsertEvents(deduped);
  sourceCounts["deduped"] = deduped.length;

  return { count, sources: sourceCounts };
}

// ─── SOURCES SPECIFIQUES PAR VILLE (extensible) ────────────────
// Pour ajouter une source specifique a une ville, ajouter une entree ici.
// Ex: un site local de concerts a Lyon, un agenda culturel a Bordeaux, etc.

interface CitySource {
  name: string;
  scrape: (ville: string, config: CityConfig) => Promise<ReturnType<typeof makeEvent>[]>;
}

// ─── JDS.FR (Strasbourg, Colmar, Mulhouse) ─────────────────────
// JSON-LD MusicEvent directement dans le listing

async function scrapeJds(ville: string, _config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const citySlug = ville.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z]+/g, "-");
  const url = `https://www.jds.fr/${citySlug}/concerts`;

  let html: string;
  try {
    html = await fetchHtml(url, 12000);
  } catch {
    console.log(`[jds/${ville}] fetch error`);
    return events;
  }

  const ldRegex = /<script\s+type="application\/ld\+json">([\s\S]*?)<\/script>/g;
  let match: RegExpExecArray | null;

  while ((match = ldRegex.exec(html)) !== null) {
    try {
      const json = JSON.parse(match[1]);
      if (json["@type"] !== "MusicEvent") continue;

      const title = json.name || "";
      if (!title) continue;

      const rawDate = json.startDate || "";
      const dateDebut = rawDate.substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const lieuNom = json.location?.name || "";
      const photoUrl = json.image || "";
      const link = json.url || "";
      const lowPrice = json.offers?.lowPrice;
      const highPrice = json.offers?.highPrice;
      const tarif = lowPrice ? (highPrice && highPrice !== lowPrice ? `${lowPrice}-${highPrice}\u20AC` : `${lowPrice}\u20AC`) : "";
      const performer = json.performer?.name || "";

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
      events.push(makeEvent({
        identifiant: `jds_${citySlug}_${slug}_${dateDebut}`,
        source: "jds",
        rubrique: "day",
        nom_de_la_manifestation: title,
        descriptif_court: performer ? `Artiste: ${performer}` : "",
        date_debut: dateDebut,
        date_fin: dateDebut,
        horaires: rawDate.length > 10 ? rawDate.substring(11, 16).replace(":", "h") : "",
        lieu_nom: lieuNom,
        commune: ville,
        ville,
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: "Concert",
        tarif_normal: tarif,
        manifestation_gratuite: tarif ? "non" : "",
        photo_url: photoUrl,
        reservation_site_internet: link,
      }));
    } catch {
      // JSON parse error
    }
  }

  console.log(`[jds/${ville}] ${events.length} concerts`);
  return events;
}

// ─── BORDEAUX TOURISME ──────────────────────────────────────────
// Listing pagine, detail pages avec JSON-LD Event

async function scrapeBordeauxTourisme(ville: string, _config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];

  // Collecter les URLs des events depuis les pages listing
  const eventUrls: string[] = [];
  for (let page = 0; page < 3; page++) {
    const url = `https://www.bordeaux-tourisme.com/agenda?thematiques=Musique&context=ajax_pager&page=${page}`;
    let html: string;
    try {
      html = await fetchHtml(url, 10000);
    } catch {
      break;
    }

    const linkRegex = /href="(https:\/\/www\.bordeaux-tourisme\.com\/evenements\/[^"]+\.html)"/g;
    let m: RegExpExecArray | null;
    while ((m = linkRegex.exec(html)) !== null) {
      if (!eventUrls.includes(m[1])) eventUrls.push(m[1]);
    }
    if (eventUrls.length === 0) break;
  }

  // Fetcher les detail pages (max 30 pour ne pas timeout)
  const toFetch = eventUrls.slice(0, 30);
  for (const eventUrl of toFetch) {
    try {
      const html = await fetchHtml(eventUrl, 8000);

      const ldMatch = html.match(/<script\s+type="application\/ld\+json">([\s\S]*?)<\/script>/);
      if (!ldMatch) continue;

      const json = JSON.parse(ldMatch[1]);
      if (json["@type"] !== "Event") continue;

      const title = json.name || "";
      if (!title) continue;

      const rawDate = json.startDate || "";
      const dateDebut = rawDate.substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const dateFin = (json.endDate || rawDate).substring(0, 10);
      const lieuNom = json.location?.name || "";
      const description = json.description ? cleanHtml(json.description).substring(0, 300) : "";

      // Image : og:image, ou image du JSON-LD, ou premiere image large
      const imgMatch = html.match(/property="og:image"[^>]*content="([^"]+)"/)
        || html.match(/content="([^"]+)"[^>]*property="og:image"/)
        || html.match(/"image"\s*:\s*"(https?:\/\/[^"]+)"/);
      let photoUrl = imgMatch ? imgMatch[1] : "";
      // Fallback : premiere image de contenu
      if (!photoUrl) {
        const fallbackImg = html.match(/<img[^>]*src="(https:\/\/www\.bordeaux-tourisme\.com\/sites\/[^"]+)"/);
        if (fallbackImg) photoUrl = fallbackImg[1];
      }

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
      events.push(makeEvent({
        identifiant: `bdxtourisme_${slug}_${dateDebut}`,
        source: "bordeaux_tourisme",
        rubrique: "day",
        nom_de_la_manifestation: title,
        descriptif_court: description,
        date_debut: dateDebut,
        date_fin: dateFin,
        lieu_nom: lieuNom,
        commune: "Bordeaux",
        ville: "Bordeaux",
        type_de_manifestation: "Concert",
        categorie_de_la_manifestation: "Concert",
        photo_url: photoUrl,
        reservation_site_internet: eventUrl,
      }));
    } catch {
      // fetch or parse error
    }
  }

  console.log(`[bordeaux-tourisme] ${events.length} concerts`);
  return events;
}

// ─── LE VOYAGE A NANTES ─────────────────────────────────────────
// Cards HTML simples avec date/categorie/titre/lieu

async function scrapeVoyageNantes(ville: string, _config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];
  const url = "https://www.levoyageanantes.fr/agenda/?categories=concert";

  let html: string;
  try {
    html = await fetchHtml(url, 10000);
  } catch {
    console.log(`[voyage-nantes] fetch error`);
    return events;
  }

  // Chercher les liens vers /activites/
  const cardRegex = /<a\s+[^>]*href="(https:\/\/www\.levoyageanantes\.fr\/activites\/[^"]+\/?)"[^>]*>([\s\S]*?)<\/a>/g;
  let match: RegExpExecArray | null;

  while ((match = cardRegex.exec(html)) !== null) {
    const link = match[1];
    const cardHtml = match[2];

    // Extraire les divs enfants (date, categorie, titre, lieu)
    const divs = cardHtml.match(/<div[^>]*>([\s\S]*?)<\/div>/g) || [];
    const texts = divs.map((d) => cleanHtml(d));

    if (texts.length < 3) continue;

    // Identifier la categorie — chercher "Concert"
    const hasConcert = texts.some((t) => t.toLowerCase().includes("concert"));
    if (!hasConcert) continue;

    // Date : format "19 SEP. 2024 -- 31 DEC 2026" ou "07 FEV. -- 15 NOV. 2026"
    const dateText = texts[0] || "";
    const dateDebut = parseVoyageDateFr(dateText);
    if (!dateDebut || !isFutureDate(dateDebut)) continue;

    // Titre : generalement le 3e div (apres date et categorie)
    const title = texts.find((t) => !t.toLowerCase().includes("concert") && t !== dateText && t.length > 3) || "";
    if (!title) continue;

    // Lieu
    const lieuNom = texts[texts.length - 1] || "";

    const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
    events.push(makeEvent({
      identifiant: `voyagenantes_${slug}_${dateDebut}`,
      source: "voyage_nantes",
      rubrique: "day",
      nom_de_la_manifestation: title,
      date_debut: dateDebut,
      date_fin: dateDebut,
      lieu_nom: lieuNom.includes("Concert") ? "" : lieuNom,
      commune: "Nantes",
      ville: "Nantes",
      type_de_manifestation: "Concert",
      categorie_de_la_manifestation: "Concert",
      reservation_site_internet: link,
    }));
  }

  console.log(`[voyage-nantes] ${events.length} concerts`);
  return events;
}

/** Parse Voyage a Nantes date format: "19 SEP. 2024" or "07 FEV. -- 15 NOV. 2026" */
function parseVoyageDateFr(text: string): string {
  const monthMap: Record<string, string> = {
    "JAN": "01", "FEV": "02", "MAR": "03", "AVR": "04",
    "MAI": "05", "JUIN": "06", "JUI": "07", "JUIL": "07",
    "AOU": "08", "SEP": "09", "OCT": "10", "NOV": "11", "DEC": "12",
  };

  // Prendre la premiere date si format "du X au Y"
  const firstDate = text.split(/--|\u2013/)[0].trim();
  const m = firstDate.match(/(\d{1,2})\s+([A-Z]{3,4})\.?\s*(\d{4})?/i);
  if (!m) return "";

  const day = m[1].padStart(2, "0");
  const monthKey = m[2].toUpperCase().replace(".", "");
  const month = monthMap[monthKey] || "";
  if (!month) return "";

  const year = m[3] || new Date().getFullYear().toString();
  return `${year}-${month}-${day}`;
}

// ─── BRANCHEMENT DES SOURCES PAR VILLE ──────────────────────────

// ─── LADECADANSE.CH (Geneve) ─────────────────────────────────────
// Flux RSS avec images et dates dans le titre

async function scrapeLadecadanse(_ville: string, _config: CityConfig): Promise<ReturnType<typeof makeEvent>[]> {
  const events: ReturnType<typeof makeEvent>[] = [];

  let xml: string;
  try {
    const res = await fetch("https://www.ladecadanse.ch/event/rss.php?type=evenements_auj", {
      headers: { "User-Agent": "Mozilla/5.0" },
      signal: AbortSignal.timeout(10000),
    });
    xml = await res.text();
  } catch {
    console.log("[ladecadanse] fetch error");
    return events;
  }

  const items = xml.match(/<item>([\s\S]*?)<\/item>/g) || [];

  for (const item of items) {
    const titleMatch = item.match(/<title>(.*?)<\/title>/s);
    const linkMatch = item.match(/<link>(.*?)<\/link>/s);
    const descMatch = item.match(/<!\[CDATA\[([\s\S]*?)\]\]>/);

    const rawTitle = titleMatch ? titleMatch[1].trim() : "";
    if (!rawTitle) continue;

    const link = linkMatch ? linkMatch[1].trim() : "";
    const descHtml = descMatch ? descMatch[1] : "";

    // Titre format: "Mercredi 1er avril - concert : NOM DE L'EVENT dès 20h00"
    // Extraire la date du titre
    const dateInTitle = rawTitle.match(/(\d{1,2})(?:er)?\s+(janv|f[ée]vr|mars|avri|mai|juin|juil|ao[uû]t|sept|octo|nove|d[ée]ce)[a-zé]*/i);
    const dateDebut = dateInTitle ? parseFrenchDate(dateInTitle[0]) : "";

    // Si pas de date, utiliser aujourd'hui (le RSS est "evenements_auj")
    const today = new Date();
    const fallbackDate = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,"0")}-${String(today.getDate()).padStart(2,"0")}`;
    const finalDate = (dateDebut && isFutureDate(dateDebut)) ? dateDebut : fallbackDate;
    if (!isFutureDate(finalDate)) continue;

    // Extraire le type et le nom de l'event
    // "Mercredi 1er avril - concert : Nom de l'event dès 20h00"
    const typeAndName = rawTitle.match(/[-–]\s*(concert|fête|soirée|festival|dj|musique|spectacle|live)\s*:\s*(.*?)(?:\s+dès\s+|$)/i);
    const eventType = typeAndName ? typeAndName[1] : "";
    let eventName = typeAndName ? typeAndName[2].trim() : "";

    // Si pas de match, prendre tout après le tiret
    if (!eventName) {
      const afterDash = rawTitle.match(/[-–]\s*(?:concert|fête|soirée|festival|dj|musique|spectacle|live)\s*:\s*(.*)/i)
        || rawTitle.match(/[-–]\s*(.*)/);
      eventName = afterDash ? afterDash[1].replace(/\s+dès\s+\d+h\d*/, "").trim() : rawTitle;
    }
    if (!eventName || eventName.length < 3) continue;

    // Horaires
    const timeMatch = rawTitle.match(/dès\s+(\d{1,2}h\d{0,2})/i);
    const horaires = timeMatch ? timeMatch[1] : "";

    // Image depuis la description HTML
    const imgMatch = descHtml.match(/<img[^>]*src="([^"]+)"/);
    const photoUrl = imgMatch ? imgMatch[1] : "";

    // Lieu depuis la description
    const lieuMatch = descHtml.match(/<h3>([^<]+)<\/h3>/) || descHtml.match(/<b>([^<]+)<\/b>/);
    const lieuNom = lieuMatch ? cleanHtml(lieuMatch[1]) : "";

    // Filtrer : garder concerts, soirées, musique, DJ
    const isMusic = /concert|musique|dj|live|jazz|rock|electro|hip.hop|rap|reggae|soul|funk|techno|house|soirée|fête|festival/i.test(rawTitle);
    if (!isMusic) continue;

    const slug = eventName.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
    events.push(makeEvent({
      identifiant: `ladecadanse_${slug}_${finalDate}`,
      source: "ladecadanse",
      rubrique: "day",
      nom_de_la_manifestation: eventName,
      date_debut: finalDate,
      date_fin: finalDate,
      horaires,
      lieu_nom: lieuNom,
      commune: "Geneve",
      ville: "Geneve",
      type_de_manifestation: "Concert",
      categorie_de_la_manifestation: eventType || "Concert",
      photo_url: photoUrl,
      reservation_site_internet: link,
    }));
  }

  console.log(`[ladecadanse] ${events.length} concerts`);
  return events;
}

const CITY_SOURCES: Record<string, CitySource[]> = {
  "Strasbourg": [
    { name: "jds", scrape: scrapeJds },
  ],
  "Colmar": [
    { name: "jds", scrape: scrapeJds },
  ],
  "Bordeaux": [
    { name: "bordeaux-tourisme", scrape: scrapeBordeauxTourisme },
  ],
  "Nantes": [
    { name: "voyage-nantes", scrape: scrapeVoyageNantes },
  ],
  "Geneve": [
    { name: "ladecadanse", scrape: scrapeLadecadanse },
  ],
};

// ─── MAIN ──────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}));
    const ville: string = body.ville || "";

    if (!ville) {
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis. Ex: {\"ville\": \"Lyon\"} ou {\"ville\": \"all\"}" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Mode "all" : scraper toutes les villes sequentiellement
    if (ville === "all") {
      const results: Record<string, { count: number; sources: Record<string, number> }> = {};
      let totalCount = 0;

      for (const [cityName, config] of Object.entries(CITIES)) {
        try {
          const result = await scrapeCity(cityName, config);
          results[cityName] = result;
          totalCount += result.count;
        } catch (e) {
          console.error(`[${cityName}] error: ${(e as Error).message}`);
          results[cityName] = { count: 0, sources: { error: 1 } };
        }
      }

      return new Response(
        JSON.stringify({ success: true, total: totalCount, cities: results }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // Mode ville unique
    const config = CITIES[ville];
    if (!config) {
      return new Response(
        JSON.stringify({
          error: `Ville '${ville}' inconnue. Disponibles: ${Object.keys(CITIES).join(", ")}`,
        }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const result = await scrapeCity(ville, config);

    return new Response(
      JSON.stringify({ success: true, ville, ...result }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error(`${SCRAPER} error: ${err.message}`);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

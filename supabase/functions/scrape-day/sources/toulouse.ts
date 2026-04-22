// Sources spécifiques à Toulouse et sa métropole.
// Chaque fonction est exportée individuellement pour pouvoir être composée.

import { type ScrapedEvent, makeEvent, isFutureDate, supabaseHeaders, withErrorLogging } from "../../_shared/db.ts";
import { fetchHtml, fetchJson, cleanHtml, isoToDate, isoToTime, buildIsoDate, frenchMonths, frenchDateToIso } from "../../_shared/html-utils.ts";

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}
function todayStr(): string {
  const n = new Date();
  return `${n.getFullYear()}-${String(n.getMonth()+1).padStart(2,"0")}-${String(n.getDate()).padStart(2,"0")}`;
}

const ODS_BASE = "https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records";

// ── OpenDataSoft Toulouse ──
export async function fetchODS(): Promise<ScrapedEvent[]> {
  try {
    const today = todayStr();
    const where = `date_debut >= "${today}"`;
    const url = `${ODS_BASE}?where=${encodeURIComponent(where)}&order_by=date_debut&limit=100`;
    const data = await fetchJson<any>(url, 20000);
    if (data.error_code) { console.error(`ODS: ${data.error_code}`); return []; }
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
        descriptif_court: r.descriptif_court ?? "", descriptif_long: r.descriptif_long ?? "",
        date_debut: dateDebut, date_fin: (r.date_fin ?? "").substring(0, 10) || dateDebut,
        horaires: r.horaires ?? "", dates_affichage_horaires: r.dates_affichage_horaires ?? "",
        lieu_nom: r.lieu_nom ?? "", lieu_adresse_2: r.lieu_adresse_2 ?? "",
        code_postal: Number(r.code_postal) || 0, commune: r.commune ?? "Toulouse",
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
    console.log(`ods-toulouse: ${events.length} events`);
    return events;
  } catch (e) { console.error("ODS error:", e); return []; }
}

// ── ONCT / Halle aux Grains photos ──
export async function fetchONCTPhotos(): Promise<Map<string, string>> {
  const dateToImg = new Map<string, string>();
  try {
    const html = await fetchHtml("https://onct.toulouse.fr/la-halle-aux-grains/programmation-halle-aux-grains/", 15000);
    const year = new Date().getFullYear();
    const imgRegex = /src="(https:\/\/onct\.toulouse\.fr\/wp-content\/uploads\/[^"]+\.(png|jpg|jpeg|webp))"/gi;
    const imgPositions: { url: string; pos: number }[] = [];
    let m;
    while ((m = imgRegex.exec(html)) !== null) imgPositions.push({ url: m[1], pos: m.index });
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
          if (!dateToImg.has(isoDate)) dateToImg.set(isoDate, imgPositions[i].url);
        }
      }
    }
    console.log(`ONCT photos: ${dateToImg.size} mappings`);
  } catch (e) { console.error("ONCT photo error:", e); }
  return dateToImg;
}

export function enrichHallePhotos(events: ScrapedEvent[], onctPhotos: Map<string, string>): ScrapedEvent[] {
  if (onctPhotos.size === 0) return events;
  return events.map(e => {
    if (e.lieu_nom.toUpperCase().includes("HALLE") && e.lieu_nom.toUpperCase().includes("GRAINS") && !e.photo_url) {
      const img = onctPhotos.get(e.date_debut);
      if (img) return { ...e, photo_url: img };
    }
    return e;
  });
}

// ── Le Bikini ──
export async function fetchBikini(): Promise<ScrapedEvent[]> {
  try {
    const rscText = await fetchHtml("https://www.lebikini.com/programmation/bikini/-/-.rsc", 15000);
    const events: ScrapedEvent[] = [];
    const idx = rscText.indexOf('"events":[');
    if (idx < 0) return [];
    const start = idx + '"events":'.length;
    let bracket = 0, end = start;
    for (let i = start; i < rscText.length; i++) {
      if (rscText[i] === "[") bracket++;
      else if (rscText[i] === "]") bracket--;
      if (bracket === 0) { end = i + 1; break; }
    }
    let parsed: any[];
    try { parsed = JSON.parse(rscText.substring(start, end)); } catch { return []; }
    for (const e of parsed) {
      const title = (e.title ?? "").replace(/\\u0026/g, "&").trim();
      if (!title) continue;
      const dateIso = e.date ?? "";
      const startDate = isoToDate(dateIso);
      if (!startDate || !isFutureDate(startDate)) continue;
      const horaires = isoToTime(dateIso);
      const style = (e.style ?? "").toLowerCase();
      const typeNames = (e.eventTypes ?? []).map((t: any) => (t.name ?? "").toLowerCase());
      let source = "day_concert";
      if (style.includes("techno") || style.includes("electro") || style.includes("house") || style.includes("dnb")) source = "day_djset";
      else if (typeNames.some((t: string) => t.includes("spectacle") || t.includes("humour"))) source = "day_spectacle";
      else if (typeNames.some((t: string) => t.includes("festival")) || style.includes("festival")) source = "day_festival";
      const prices = e.prices ?? [];
      const tarif = prices.length > 0 ? prices[0].replace(/à partir de /i, "").trim() : "";
      const slug = e.slug?.current ?? "";
      events.push(makeEvent({
        identifiant: `bikini_${normalize(title).slice(0, 40)}_${startDate}`, source, rubrique: "day",
        nom_de_la_manifestation: title,
        descriptif_court: style ? `Style : ${e.style}` : "",
        date_debut: startDate, date_fin: startDate, horaires,
        lieu_nom: "Le Bikini", lieu_adresse_2: "Parc Technologique du Canal, Ramonville-Saint-Agne",
        commune: "Ramonville-Saint-Agne", code_postal: 31520,
        type_de_manifestation: typeNames[0] ?? "Concert", categorie_de_la_manifestation: typeNames[0] ?? "Concert",
        manifestation_gratuite: e.free === true ? "oui" : "non", tarif_normal: tarif,
        reservation_site_internet: e.ticketUrl ?? (slug ? `https://www.lebikini.com/2026/${startDate.substring(5, 7)}/${startDate.substring(8, 10)}/${slug}` : ""),
        photo_url: e.image?.asset?.url ?? "",
      }));
    }
    console.log(`bikini: ${events.length} events`);
    return events;
  } catch (e) { console.error("Bikini error:", e); return []; }
}

// ── Opéra de Toulouse ──
export async function fetchOperaToulouse(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://opera.toulouse.fr/agenda/type/operas/", 15000);
    const events: ScrapedEvent[] = [];
    const blocks = html.split(/class="card-item"[^>]*itemtype/);
    for (let i = 1; i < blocks.length; i++) {
      const block = blocks[i];
      const titleMatch = block.match(/<h3[^>]*class="card-item-title"[^>]*>(.*?)<\/h3>/s);
      const name = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!name) continue;
      const timeMatch = block.match(/datetime="([^"]+)"/);
      const startDate = isoToDate(timeMatch ? timeMatch[1] : "");
      if (!startDate) continue;
      const horaires = isoToTime(timeMatch ? timeMatch[1] : "");
      const dateTextMatch = block.match(/<p[^>]*class="card-item-date-date"[^>]*>(.*?)<\/p>/s);
      let endDate = startDate;
      if (dateTextMatch) {
        const dateText = cleanHtml(dateTextMatch[1]).replace(/&rarr;/g, "→");
        const arrowMatch = dateText.match(/→\s*(\d{1,2})\s+(\w+)\s+(\d{4})/);
        if (arrowMatch) { const built = buildIsoDate(arrowMatch[1], arrowMatch[2], arrowMatch[3]); if (built) endDate = built; }
      }
      if (!isFutureDate(startDate) && !isFutureDate(endDate)) continue;
      const descMatch = block.match(/<p[^>]*class="card-item-description"[^>]*>(.*?)<\/p>/s);
      const linkMatch = block.match(/<a[^>]*class="card-item-link"[^>]*href="([^"]+)"/);
      events.push(makeEvent({
        identifiant: `opera_tls_${normalize(name).slice(0, 40)}_${startDate}`, source: "day_opera", rubrique: "day",
        nom_de_la_manifestation: name, descriptif_court: descMatch ? cleanHtml(descMatch[1]) : "",
        date_debut: startDate, date_fin: endDate, horaires,
        lieu_nom: "Théâtre du Capitole", lieu_adresse_2: "Place du Capitole",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Opéra", categorie_de_la_manifestation: "Opéra",
        manifestation_gratuite: "non", reservation_site_internet: linkMatch ? linkMatch[1] : "",
      }));
    }
    console.log(`opera-toulouse: ${events.length} operas`);
    return events;
  } catch (e) { console.error("Opera Toulouse error:", e); return []; }
}

// ── TimeForGig ──
const ENGLISH_MONTHS: Record<string, number> = { jan:1,feb:2,mar:3,apr:4,may:5,jun:6,jul:7,aug:8,sep:9,oct:10,nov:11,dec:12 };
function parseEnglishDate(text: string): string | null {
  const m = text.match(/(\d{1,2})\s+(\w{3})\s+(\d{4})/);
  if (!m) return null;
  const month = ENGLISH_MONTHS[m[2].toLowerCase()];
  if (!month) return null;
  return `${m[3]}-${String(month).padStart(2,"0")}-${String(parseInt(m[1])).padStart(2,"0")}`;
}
export async function fetchTimeForGig(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.timeforgig.com/toulouse/cities/ygyeww", 15000);
    const parts = html.split('class="event_list"');
    if (parts.length < 2) return [];
    const rows = parts[1].split('<div class="row align-items-center">');
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      const texts = [...row.matchAll(/>([^<]+)</g)].map(m => m[1].trim()).filter(t => t && !t.startsWith("{"));
      if (texts.length < 2) continue;
      const artist = cleanHtml(texts[0]);
      if (!artist) continue;
      const info = texts[1];
      const dashIdx = info.indexOf(" - ");
      if (dashIdx < 0) continue;
      const startDate = parseEnglishDate(info.substring(0, dashIdx).trim());
      const venue = info.substring(dashIdx + 3).trim();
      if (!startDate || !isFutureDate(startDate)) continue;
      const dedupKey = `${normalize(artist)}|${startDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);
      const linkMatch = row.match(/href="(\/[^"]+\/events\/[^"]+)"/);
      events.push(makeEvent({
        identifiant: `tfg_${normalize(artist).slice(0, 40)}_${startDate}`, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: artist, date_debut: startDate, date_fin: startDate,
        lieu_nom: venue, commune: "Toulouse",
        type_de_manifestation: "Concert", categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        reservation_site_internet: linkMatch ? `https://www.timeforgig.com${linkMatch[1]}` : "",
      }));
    }
    console.log(`timeforgig: ${events.length} events`);
    return events;
  } catch (e) { console.error("TimeForGig error:", e); return []; }
}

// ── COMDT ──
export async function fetchCOMDT(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.comdt.org/saison/les-concerts/", 15000);
    const ldMatch = html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/);
    if (!ldMatch) return [];
    let data: any[];
    try { data = JSON.parse(ldMatch[1]); } catch { return []; }
    if (!Array.isArray(data)) data = [data];
    const events: ScrapedEvent[] = [];
    for (const ev of data) {
      if (ev["@type"] !== "Event") continue;
      const name = (ev.name ?? "").replace(/&#\d+;/g, "").trim();
      if (!name) continue;
      const startDate = (ev.startDate ?? "").substring(0, 10);
      if (!startDate || !isFutureDate(startDate)) continue;
      const timePart = (ev.startDate ?? "").substring(11, 16);
      const horaires = timePart && timePart !== "00:00" ? timePart.replace(":", "h") : "";
      let desc = (ev.description ?? "").replace(/&lt;[^&]*&gt;/g, "").replace(/&amp;/g, "&").replace(/&hellip;/g, "…").replace(/\\n/g, " ").trim();
      const loc = ev.location ?? {};
      events.push(makeEvent({
        identifiant: `comdt_${normalize(name).slice(0, 35)}_${startDate}`, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: name.toUpperCase(),
        descriptif_court: desc.slice(0, 200), descriptif_long: desc,
        date_debut: startDate, date_fin: (ev.endDate ?? "").substring(0, 10) || startDate, horaires,
        lieu_nom: (loc.name ?? "COMDT").replace(/&#\d+;/g, " ").replace(/\s+/g, " ").trim().toUpperCase(),
        lieu_adresse_2: loc.address?.streetAddress ?? "5 Impasse Boudeville",
        commune: loc.address?.addressLocality ?? "Toulouse",
        code_postal: parseInt(loc.address?.postalCode ?? "31200", 10),
        type_de_manifestation: "Concert", categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non", reservation_site_internet: ev.url ?? "",
        photo_url: ev.image ?? "",
      }));
    }
    console.log(`comdt: ${events.length} events`);
    return events;
  } catch (e) { console.error("COMDT error:", e); return []; }
}

// ── Le Bascala ──
export async function fetchBascala(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://spectacles.le-bascala.com/programmation/cette-saison/", 15000);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();
    const year = new Date().getFullYear();
    const fields = [...html.matchAll(/dynamic-field__content[^>]*>([^<]*)</g)].map(m => m[1].trim());
    const imgs = [...html.matchAll(/src="(https:\/\/spectacles\.le-bascala\.com\/wp-content\/uploads\/20[^"]+)"/g)].map(m => m[1]);
    const eventImgs = imgs.slice(2);
    const ticketLinks = [...html.matchAll(/href="(https:\/\/(?:www\.fnac|www\.ticketmaster|billetterie\.|www\.billetweb|shotgun)[^"]+)"/g)].map(m => m[1]);
    const monthMap: Record<string, number> = { jan:1,fev:2,fév:2,mar:3,avr:4,mai:5,jun:6,juin:6,jul:7,juil:7,aou:8,août:8,sep:9,oct:10,nov:11,dec:12,déc:12 };
    let ticketIdx = 0;
    for (let i = 0; i + 5 < fields.length; i += 6) {
      const dayMatch = fields[i].match(/(\d{1,2})/);
      if (!dayMatch) continue;
      const monthNum = monthMap[fields[i+1].toLowerCase().substring(0, 3)] ?? 0;
      if (monthNum === 0) continue;
      const day = parseInt(dayMatch[1], 10);
      const eventYear = monthNum < new Date().getMonth() + 1 ? year + 1 : year;
      const isoDate = `${eventYear}-${String(monthNum).padStart(2,"0")}-${String(day).padStart(2,"0")}`;
      if (!isFutureDate(isoDate)) continue;
      const timeMatch = fields[i+2].match(/(\d{1,2})[hH](\d{2})/);
      const title = fields[i+3];
      const subtitle = fields[i+4];
      if (!title) continue;
      const dedupKey = `${normalize(title)}|${isoDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);
      const eventIdx = Math.floor(i / 6);
      const titleLower = title.toLowerCase() + " " + subtitle.toLowerCase();
      let source = "day_spectacle";
      if (titleLower.includes("concert") || titleLower.includes("orchestre") || titleLower.includes("jazz")) source = "day_concert";
      else if (titleLower.includes("dj") || titleLower.includes("club")) source = "day_djset";
      events.push(makeEvent({
        identifiant: `bascala_${normalize(title).slice(0, 35)}_${isoDate}`, source, rubrique: "day",
        nom_de_la_manifestation: title.toUpperCase(), descriptif_court: subtitle,
        descriptif_long: fields[i+5] ? `Produit par : ${fields[i+5]}` : "",
        date_debut: isoDate, date_fin: isoDate,
        horaires: timeMatch ? `${timeMatch[1]}h${timeMatch[2]}` : "",
        lieu_nom: "LE BASCALA", lieu_adresse_2: "Chemin de Fournaulis",
        commune: "Bruguières", code_postal: 31150,
        type_de_manifestation: source === "day_concert" ? "Concert" : source === "day_djset" ? "DJ Set" : "Spectacle",
        categorie_de_la_manifestation: source === "day_concert" ? "Concert" : source === "day_djset" ? "DJ Set" : "Spectacle",
        manifestation_gratuite: "non",
        reservation_site_internet: ticketIdx < ticketLinks.length ? ticketLinks[ticketIdx] : "",
        photo_url: eventIdx < eventImgs.length ? eventImgs[eventIdx] : "",
      }));
      ticketIdx++;
    }
    console.log(`bascala: ${events.length} events`);
    return events;
  } catch (e) { console.error("Bascala error:", e); return []; }
}

// ── Le Rex ──
export async function fetchLeRex(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.lerextoulouse.com/fr/programmation/", 15000);
    const events: ScrapedEvent[] = [];
    const seen = new Set<string>();
    const imgRegex = /<img[^>]+src="(https:\/\/www\.lerextoulouse\.com\/media\/data\/spectacles\/images\/[^?"]+)[^"]*"[^>]*>/g;
    const imgPositions: { url: string; pos: number }[] = [];
    let m;
    while ((m = imgRegex.exec(html)) !== null) imgPositions.push({ url: m[1], pos: m.index });
    for (let i = 0; i < imgPositions.length; i++) {
      const start = imgPositions[i].pos;
      const end = i + 1 < imgPositions.length ? imgPositions[i+1].pos : start + 3000;
      const block = html.substring(start, Math.min(end, start + 3000));
      const dateMatch = block.match(/class="date_list">([^<]+)<\/span>/);
      if (!dateMatch) continue;
      const dp = dateMatch[1].trim().match(/\w+\s+(\d{1,2})\s+([a-zéûà]+)\s+(\d{4})\s*-\s*(\d{1,2})[Hh](\d{2})?/);
      if (!dp) continue;
      const isoDate = buildIsoDate(dp[1], dp[2], dp[3]);
      if (!isoDate || !isFutureDate(isoDate)) continue;
      const artistMatch = block.match(/class="artiste">([^<]+)/);
      const artist = artistMatch ? artistMatch[1].trim() : "";
      if (!artist) continue;
      const genreMatch = block.match(/class="styles_list">\(([^)]+)\)/);
      const typeMatch = block.match(/>(\w+)<\/a>\s*<\/p>/);
      const eventType = typeMatch ? typeMatch[1].toLowerCase() : "live";
      const source = eventType === "club" ? "day_djset" : "day_concert";
      const dedupKey = `${normalize(artist)}|${isoDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);
      const priceMatch = block.match(/<strong>([^<]+)<\/strong>/);
      const ticketMatch = block.match(/class="external"[^>]*href="([^"]+)"/) || block.match(/href="(https?:\/\/[^"]+)"[^>]*class="external"/);
      events.push(makeEvent({
        identifiant: `rex_${normalize(artist).slice(0, 40)}_${isoDate}`, source, rubrique: "day",
        nom_de_la_manifestation: artist.toUpperCase(),
        date_debut: isoDate, date_fin: isoDate,
        horaires: `${dp[4]}h${dp[5] || "00"}`,
        lieu_nom: "LE REX DE TOULOUSE", lieu_adresse_2: "15 Avenue Honoré Serres",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: eventType === "club" ? "DJ Set" : "Concert",
        categorie_de_la_manifestation: genreMatch ? genreMatch[1] : (eventType === "club" ? "DJ Set" : "Concert"),
        manifestation_gratuite: "non", tarif_normal: priceMatch ? priceMatch[1].replace(/&euro;/g, "€").trim() : "",
        reservation_site_internet: ticketMatch ? ticketMatch[1] : "",
        photo_url: imgPositions[i].url,
      }));
    }
    console.log(`lerex: ${events.length} events`);
    return events;
  } catch (e) { console.error("LeRex error:", e); return []; }
}

// ── Zénith ──
function parseFrenchDate(text: string): string | null {
  const m = text.match(/(\d{1,2})\s+([^\s.]+)\.?\s+(\d{4})/);
  if (!m) return null;
  return buildIsoDate(m[1], m[2], m[3]);
}
export async function fetchZenith(): Promise<ScrapedEvent[]> {
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
      const startDate = parseFrenchDate(dateMatch ? cleanHtml(dateMatch[1]) : "");
      if (!startDate || !isFutureDate(startDate)) continue;
      const stateMatch = block.match(/class="card-show__state">(.*?)<\/div>/s);
      if (stateMatch && cleanHtml(stateMatch[1]).toLowerCase().includes("annul")) continue;
      const dedupKey = `${normalize(name)}|${startDate}`;
      if (seen.has(dedupKey)) continue;
      seen.add(dedupKey);
      const linkMatch = block.match(/href="(\/shows\/[^"]+)"/);
      const imgMatch = block.match(/card-show__img[^>]*>[\s\S]*?<img[^>]+src="([^"]+)"/);
      events.push(makeEvent({
        identifiant: `zenith_${normalize(name).slice(0, 40)}_${startDate}`, source: "day_concert", rubrique: "day",
        nom_de_la_manifestation: name, date_debut: startDate, date_fin: startDate,
        lieu_nom: "ZENITH TOULOUSE METROPOLE", lieu_adresse_2: "11 Avenue Raymond Badiou",
        commune: "Toulouse", code_postal: 31100,
        type_de_manifestation: "Concert", categorie_de_la_manifestation: "Concert",
        manifestation_gratuite: "non",
        reservation_site_internet: linkMatch ? `https://zenith-toulousemetropole.com${decodeURIComponent(linkMatch[1])}` : "",
        photo_url: imgMatch ? imgMatch[1] : "",
      }));
    }
    console.log(`zenith: ${events.length} events`);
    return events;
  } catch (e) { console.error("Zenith error:", e); return []; }
}

// ── Toulouse Tourisme (festivals) ──
async function fetchTTDescription(url: string): Promise<{ short: string; long: string }> {
  try {
    const html = await fetchHtml(url, 12000);
    const descMatch = html.match(/<section[^>]*class=['"]about[^'"]*['"][^>]*>.*?<div[^>]*class="description"[^>]*>(.*?)<\/div>/s);
    if (!descMatch) return { short: "", long: "" };
    const strongMatch = descMatch[1].match(/<strong>(.*?)<\/strong>/s);
    return { short: strongMatch ? cleanHtml(strongMatch[1]) : "", long: cleanHtml(descMatch[1]) };
  } catch { return { short: "", long: "" }; }
}
export async function fetchToulouseTourisme(): Promise<ScrapedEvent[]> {
  try {
    const controller = new AbortController();
    const tid = setTimeout(() => controller.abort(), 20000);
    let responseText: string;
    try {
      const res = await fetch("https://www.toulouse-tourisme.com/wp-json/facetwp/v1/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json", "User-Agent": "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120" },
        body: JSON.stringify({ action: "facetwp_refresh", data: { facets: { categoriesfma: ["8bc78750-3546-4234-8277-bf433e6374cc"] }, http_params: { uri: "sortir-a-toulouse/agenda-sorties-toulouse", lang: "fr" }, template: "agenda", paged: 1, per_page: 100 } }),
        signal: controller.signal,
      });
      responseText = await res.text();
    } finally { clearTimeout(tid); }
    const data = JSON.parse(responseText);
    const html: string = data.template ?? "";
    if (!html) return [];
    interface RawFest { name: string; url: string; location: string; startDate: string; endDate: string; eventId: string; }
    const raw: RawFest[] = [];
    const articles = html.split("<article");
    for (let i = 1; i < articles.length; i++) {
      const article = articles[i].substring(0, 3000);
      const titleMatch = article.match(/<h3[^>]*class="title[^"]*"[^>]*>.*?<a[^>]*>(.*?)<\/a>/s);
      const name = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!name) continue;
      const urlMatch = article.match(/<h3[^>]*>.*?<a[^>]*href="([^"]+)"/s);
      const locMatch = article.match(/<div[^>]*class="location[^"]*"[^>]*>(.*?)<\/div>/s);
      const startDayMatch = article.match(/<div[^>]*class="start"[^>]*>\s*<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s);
      let startDate: string | null = startDayMatch ? frenchDateToIso(`${startDayMatch[1]} ${startDayMatch[2].trim()}`) : null;
      const endDayMatch = article.match(/<div[^>]*class="end"[^>]*>\s*<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s);
      let endDate: string | null = endDayMatch ? frenchDateToIso(`${endDayMatch[1]} ${endDayMatch[2].trim()}`) : null;
      if (!startDate) {
        const untilMatch = article.match(/<div[^>]*class="until"[^>]*>.*?<span[^>]*class="day"[^>]*>(\d{1,2})<\/span>\s*<span[^>]*class="month"[^>]*>([^<]+)<\/span>/s);
        if (untilMatch) { endDate = frenchDateToIso(`${untilMatch[1]} ${untilMatch[2].trim()}`); startDate = todayStr(); }
      }
      if (!startDate) continue;
      if (!endDate) endDate = startDate;
      if (!isFutureDate(startDate) && !isFutureDate(endDate)) continue;
      const eventId = `tltourisme_${normalize(name).slice(0, 40)}_${startDate}`;
      raw.push({ name, url: urlMatch ? urlMatch[1] : "", location: locMatch ? cleanHtml(locMatch[1]) : "", startDate, endDate, eventId });
    }
    const descriptions = new Map<string, { short: string; long: string }>();
    for (let b = 0; b < raw.length; b += 5) {
      const batch = raw.slice(b, b + 5);
      const results = await Promise.all(batch.map(f => f.url ? fetchTTDescription(f.url) : Promise.resolve({ short: "", long: "" })));
      for (let j = 0; j < batch.length; j++) descriptions.set(batch[j].eventId, results[j]);
    }
    const events: ScrapedEvent[] = raw.map(f => {
      const desc = descriptions.get(f.eventId) ?? { short: "", long: "" };
      return makeEvent({
        identifiant: f.eventId, source: "day_festival", rubrique: "day",
        nom_de_la_manifestation: f.name, descriptif_court: desc.short, descriptif_long: desc.long,
        date_debut: f.startDate, date_fin: f.endDate, lieu_nom: f.location, commune: "Toulouse",
        type_de_manifestation: "Festival", categorie_de_la_manifestation: "Festival",
        manifestation_gratuite: "non", reservation_site_internet: f.url,
      });
    });
    console.log(`toulouse-tourisme: ${events.length} festivals`);
    return events;
  } catch (e) { console.error("Toulouse Tourisme error:", e); return []; }
}

// ── Interférence ──
export async function fetchInterference(): Promise<ScrapedEvent[]> {
  try {
    const apiUrl = "https://api.interference-toulouse.fr/events/search";
    const allRaw: any[] = [];
    let page = 1, lastPage = 1;
    while (page <= lastPage) {
      const resp = await fetch(apiUrl, { method: "POST", headers: { "Content-Type": "application/json", "Accept": "application/json" }, body: JSON.stringify({ page, eventCategory: "all", dateFilter: "upcoming", searchFilter: "" }) });
      if (!resp.ok) break;
      const json = await resp.json();
      allRaw.push(...(json.data ?? []));
      lastPage = json.pagination?.lastPage ?? page;
      page++;
    }
    const events: ScrapedEvent[] = [];
    for (const e of allRaw) {
      const rawName = (e.event_name ?? "").trim();
      if (!rawName) continue;
      const complet = /\[complet\]/i.test(rawName);
      const name = rawName.replace(/\[COMPLET\]\s*[-–—]?\s*/gi, "").trim().toUpperCase();
      const startDate = isoToDate(e.event_starting ?? "");
      if (!startDate || !isFutureDate(startDate)) continue;
      const eventType = (e.event_type ?? "").toLowerCase();
      let source = "day_concert", typeName = "Concert";
      if (eventType === "club") { source = "day_djset"; typeName = "DJ Set"; }
      else if (eventType === "show" || eventType === "spectacle") { source = "day_spectacle"; typeName = "Spectacle"; }
      events.push(makeEvent({
        identifiant: `interf_${normalize(name).slice(0, 40)}_${startDate}`, source, rubrique: "day",
        nom_de_la_manifestation: name, descriptif_court: complet ? "COMPLET" : "",
        date_debut: startDate, date_fin: startDate, horaires: isoToTime(e.event_starting ?? ""),
        lieu_nom: "Interference", lieu_adresse_2: "56 Route de Lavaur", commune: "Toulouse", code_postal: 31130,
        type_de_manifestation: typeName, categorie_de_la_manifestation: typeName,
        manifestation_gratuite: "non", reservation_site_internet: e.event_external_ticketing_url ?? "",
        photo_url: e.tile_url ?? "",
      }));
    }
    console.log(`interference: ${events.length} events`);
    return events;
  } catch (e) { console.error("Interference error:", e); return []; }
}

// ── Le Metronum ──
export async function fetchMetronum(): Promise<ScrapedEvent[]> {
  try {
    const resp = await fetch("https://lemetronum.fr/wp-json/tribe/events/v1/events?per_page=50&start_date=now", { headers: { "Accept": "application/json" } });
    if (!resp.ok) return [];
    const rawEvents = (await resp.json()).events ?? [];
    const events: ScrapedEvent[] = [];
    for (const e of rawEvents) {
      const rawTitle = (e.title ?? "").replace(/&#\d+;|&[a-z]+;/gi, " ").replace(/\s+/g, " ").trim();
      if (!rawTitle) continue;
      const startDate = (e.start_date ?? "").substring(0, 10);
      if (!startDate || !isFutureDate(startDate)) continue;
      const cats = (e.categories ?? []).map((c: any) => (c.name ?? "").toLowerCase());
      let source = "day_concert", typeName = "Concert";
      if (cats.some((c: string) => c.includes("club") || c.includes("dj"))) { source = "day_djset"; typeName = "DJ Set"; }
      else if (cats.some((c: string) => c.includes("spectacle"))) { source = "day_spectacle"; typeName = "Spectacle"; }
      if (cats.some((c: string) => c.includes("ateliers")) && !cats.some((c: string) => c.includes("concert"))) continue;
      const description = (e.excerpt ?? e.description ?? "").replace(/<[^>]+>/g, "").trim().substring(0, 300);
      const cost = e.cost ?? "";
      events.push(makeEvent({
        identifiant: `metronum_${normalize(rawTitle).slice(0, 40)}_${startDate}`, source, rubrique: "day",
        nom_de_la_manifestation: rawTitle.toUpperCase(),
        descriptif_court: description.substring(0, 150), descriptif_long: description,
        date_debut: startDate, date_fin: startDate,
        horaires: (e.start_date ?? "").substring(11, 16).replace(":", "h"),
        lieu_nom: "Le Metronum", lieu_adresse_2: "2 Rond-point Madame de Mondonville",
        commune: "Toulouse", code_postal: 31200,
        type_de_manifestation: typeName, categorie_de_la_manifestation: typeName,
        manifestation_gratuite: cost.toLowerCase().includes("gratuit") || cost === "" ? "oui" : "non",
        reservation_site_internet: e.website || e.url || "",
        photo_url: e.image?.url ?? "",
      }));
    }
    console.log(`metronum: ${events.length} events`);
    return events;
  } catch (e) { console.error("Metronum error:", e); return []; }
}

// ── Casino Barrière ──
const STORYBLOK_TOKEN = "zbxp5eNhyKynscv1EpOhsAtt";
export async function fetchCasinoBarriere(): Promise<ScrapedEvent[]> {
  try {
    const allStories: any[] = [];
    for (let page = 1; page <= 5; page++) {
      const res = await fetch(`https://api.storyblok.com/v2/cdn/stories?starts_with=website-casinos/spectacles/&token=${STORYBLOK_TOKEN}&per_page=100&page=${page}`, { redirect: "follow" });
      if (!res.ok) break;
      const stories = (await res.json()).stories || [];
      allStories.push(...stories);
      if (stories.length < 100) break;
    }
    const events: ScrapedEvent[] = [];
    for (const story of allStories) {
      const content = story.content;
      if (!content) continue;
      const title = content.title || content.artist || story.name || "";
      if (!title) continue;
      const subtitle = content.subtitle || "";
      const genre = (content.genre || "").toLowerCase();
      const seoDesc = content.seoDescription || content.previewDescription || "";
      let photoUrl = content.thumbnail?.filename || content.mainVisual?.filename || "";
      const shows = content.shows;
      if (!Array.isArray(shows)) continue;
      for (const show of shows) {
        if (typeof show !== "object" || !show || (show.city || "").toLowerCase() !== "toulouse") continue;
        const schedule = show.schedule;
        if (!Array.isArray(schedule)) continue;
        for (const sched of schedule) {
          const rawDate = sched?.date || "";
          if (!rawDate) continue;
          const dateStr = rawDate.substring(0, 10);
          if (!dateStr || !isFutureDate(dateStr)) continue;
          const timeStr = rawDate.substring(11, 16);
          let source = "day_spectacle", typeName = "Spectacle";
          if (genre === "concert" || genre === "classic") { source = "day_concert"; typeName = "Concert"; }
          const displayName = subtitle ? `${title} - ${subtitle}` : title;
          events.push(makeEvent({
            identifiant: `casino_${normalize(displayName).slice(0, 40)}_${dateStr}`, source, rubrique: "day",
            nom_de_la_manifestation: displayName.toUpperCase(),
            descriptif_court: seoDesc.substring(0, 150), descriptif_long: seoDesc,
            date_debut: dateStr, date_fin: dateStr, horaires: timeStr ? timeStr.replace(":", "h") : "",
            lieu_nom: "Casino Barriere", lieu_adresse_2: "18 Chemin de la Loge",
            commune: "Toulouse", code_postal: 31100,
            type_de_manifestation: typeName, categorie_de_la_manifestation: genre || typeName,
            manifestation_gratuite: "non", tarif_normal: show.price ? `A partir de ${show.price}€` : "",
            reservation_site_internet: `https://www.casinosbarriere.com/toulouse/spectacle/${story.slug || ""}`,
            photo_url: photoUrl,
          }));
        }
      }
    }
    const seen = new Set<string>();
    const deduped = events.filter(e => { if (seen.has(e.identifiant)) return false; seen.add(e.identifiant); return true; });
    console.log(`casino-barriere: ${deduped.length} events`);
    return deduped;
  } catch (e) { console.error("Casino Barriere error:", e); return []; }
}

// ── Poney Club Toulouse 2026 (via Xceed) ──
// Le site poneyclubtoulouse.fr est une SPA React (HTML vide). La billetterie
// passe par Xceed, qui expose un JSON-LD Schema.org Event propre sur chaque
// page detail. On liste depuis xceed.me/fr/toulouse puis on fetche les details.

function isoToParisDateTime(iso: string): { date: string; time: string } {
  if (!iso) return { date: "", time: "" };
  const dt = new Date(iso);
  if (isNaN(dt.getTime())) return { date: "", time: "" };
  const dp = new Intl.DateTimeFormat("en-CA", {
    year: "numeric", month: "2-digit", day: "2-digit", timeZone: "Europe/Paris",
  }).formatToParts(dt);
  const y = dp.find(p => p.type === "year")?.value ?? "";
  const mo = dp.find(p => p.type === "month")?.value ?? "";
  const d = dp.find(p => p.type === "day")?.value ?? "";
  const tp = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit", minute: "2-digit", timeZone: "Europe/Paris", hour12: false,
  }).formatToParts(dt);
  const h = tp.find(p => p.type === "hour")?.value ?? "";
  const mi = tp.find(p => p.type === "minute")?.value ?? "";
  return { date: y && mo && d ? `${y}-${mo}-${d}` : "", time: h && mi ? `${h}h${mi}` : "" };
}

const PONEY_ELECTRONIC_GENRES = ["techno","house","electro","electronic","dnb","drum & bass","trance","hardstyle","tech-house","deep-house","progressive","minimal","big-room","future-house","bass"];

function parsePoneyJsonLd(data: any, eventId: string): ScrapedEvent | null {
  if (!data || !["Event", "MusicEvent"].includes(data["@type"])) return null;
  const name = (data.name ?? "").trim();
  if (!name) return null;
  const { date: startDate, time: horaires } = isoToParisDateTime(data.startDate ?? "");
  if (!startDate || !isFutureDate(startDate)) return null;
  const { date: endDate } = isoToParisDateTime(data.endDate ?? "");

  // Image: picker l'affiche 1:1 (square) de preference, sinon la premiere dispo
  let photoUrl = "";
  const img = data.image;
  if (Array.isArray(img)) {
    const square = img.find((u: unknown) => typeof u === "string" && u.includes("ar=1:1"));
    photoUrl = (typeof square === "string" ? square : (typeof img[0] === "string" ? img[0] : ""));
  } else if (typeof img === "string") {
    photoUrl = img;
  }

  // Classification DJ set vs concert selon les genres
  const performers = Array.isArray(data.performer) ? data.performer : [];
  const genres = performers.map((p: any) => ((p?.genre ?? "") + "").toLowerCase()).join(" ");
  const isElectronic = PONEY_ELECTRONIC_GENRES.some(g => genres.includes(g));
  const source = isElectronic ? "day_djset" : "day_concert";
  const typeName = isElectronic ? "DJ Set" : "Concert";

  const desc = (data.description ?? "").toString().replace(/\s+/g, " ").trim();

  // Venue en dur: Xceed met parfois "Toulouse" comme locality alors que le
  // Poney Club est reellement a Blagnac 31700 (parking aeroport).
  return makeEvent({
    identifiant: `poney_${eventId}_${startDate}`,
    source,
    rubrique: "day",
    nom_de_la_manifestation: name,
    descriptif_court: desc.slice(0, 200),
    descriptif_long: desc,
    date_debut: startDate,
    date_fin: endDate || startDate,
    horaires,
    lieu_nom: "PONEY CLUB",
    lieu_adresse_2: "Parking P3 Aéroport Toulouse-Blagnac",
    commune: "Blagnac",
    code_postal: 31700,
    type_de_manifestation: typeName,
    categorie_de_la_manifestation: typeName,
    manifestation_gratuite: "non",
    reservation_site_internet: data.url ?? "",
    photo_url: photoUrl,
  });
}

export async function fetchPoneyClub(): Promise<ScrapedEvent[]> {
  try {
    const listHtml = await fetchHtml("https://xceed.me/fr/toulouse", 15000);

    // Discover (id -> slug) pour tous les events "*-poney-club-*"
    const refs = new Map<string, string>();
    const reList = /\/fr\/toulouse\/event\/([a-z0-9-]*poney-club[a-z0-9-]*)\/(\d+)/g;
    let m: RegExpExecArray | null;
    while ((m = reList.exec(listHtml)) !== null) {
      const slug = m[1];
      const id = m[2];
      // Skip le "season pass" (SKU bundle, pas d'event date)
      if (/(^|[-])pass$/.test(slug)) continue;
      if (!refs.has(id)) refs.set(id, slug);
    }
    if (refs.size === 0) { console.log("poney-club: aucun event trouve"); return []; }

    const entries = [...refs.entries()];
    const events: ScrapedEvent[] = [];
    const BATCH = 10;
    for (let i = 0; i < entries.length; i += BATCH) {
      const batch = entries.slice(i, i + BATCH);
      const results = await Promise.all(batch.map(async ([id, slug]): Promise<ScrapedEvent | null> => {
        try {
          const html = await fetchHtml(`https://xceed.me/fr/toulouse/event/${slug}/${id}`, 12000);
          const ldRe = /<script type="application\/ld\+json">([\s\S]*?)<\/script>/g;
          let mm: RegExpExecArray | null;
          while ((mm = ldRe.exec(html)) !== null) {
            let data: any;
            try { data = JSON.parse(mm[1]); } catch { continue; }
            if (!data || !["Event", "MusicEvent"].includes(data["@type"])) continue;
            return parsePoneyJsonLd(data, id);
          }
          return null;
        } catch { return null; }
      }));
      for (const ev of results) if (ev) events.push(ev);
    }
    console.log(`poney-club: ${events.length} events`);
    return events;
  } catch (e) { console.error("Poney Club error:", e); return []; }
}

// ── Categorize ODS events ──
export function categorizeEvent(e: ScrapedEvent): string {
  const type = (e.type_de_manifestation || "").toLowerCase();
  const cat = (e.categorie_de_la_manifestation || "").toLowerCase();
  const lieu = (e.lieu_nom || "").toLowerCase();
  const nom = (e.nom_de_la_manifestation || "").toLowerCase();
  if (nom.includes("fête de la musique") || nom.includes("fete de la musique")) return "day_fete_musique";
  if (cat.includes("festival") || type.includes("festival")) return "day_festival";
  if (cat.includes("theatre") || type.includes("theatre") || lieu.includes("theatre")) return "skip";
  if (cat.includes("opera") || type.includes("opera") || type.includes("lyrique")) return "day_opera";
  if (type.includes("dj") || type.includes("electro") || type.includes("techno") || cat.includes("dj")) return "day_djset";
  if (type.includes("showcase") || type.includes("acoustique") || cat.includes("showcase")) return "day_showcase";
  if (cat.includes("concert") || type.includes("musique") || type.includes("concert")) return "day_concert";
  if (cat.includes("spectacle") || type.includes("spectacle") || type.includes("humour") || type.includes("cirque") || type.includes("danse") || type.includes("magie")) return "day_spectacle";
  return "day_other";
}

/** Fetch all Toulouse-specific sources with error logging per source. */
export async function fetchAllToulouseSources(): Promise<ScrapedEvent[]> {
  const w = (source: string, fn: () => Promise<ScrapedEvent[]>) =>
    withErrorLogging("scrape-day", source, "toulouse", fn);

  const [ods, bikini, operaTls, zenith, tfg, tlTourisme, interference, metronum, leRex, bascala, comdt, casinoBarriere, poneyClub, onctPhotos] = await Promise.all([
    w("ods-toulouse", fetchODS),
    w("bikini", fetchBikini),
    w("opera-toulouse", fetchOperaToulouse),
    w("zenith-toulouse", fetchZenith),
    w("timeforgig", fetchTimeForGig),
    w("toulouse-tourisme", fetchToulouseTourisme),
    w("interference", fetchInterference),
    w("metronum", fetchMetronum),
    w("le-rex", fetchLeRex),
    w("bascala", fetchBascala),
    w("comdt", fetchCOMDT),
    w("casino-barriere", fetchCasinoBarriere),
    w("poney-club", fetchPoneyClub),
    fetchONCTPhotos(),  // photo map, not ScrapedEvent[]
  ]);

  // Tag + enrich ODS
  const taggedOds = enrichHallePhotos(
    ods.map(e => { const source = categorizeEvent(e); return source === "skip" ? null : { ...e, source }; }).filter(Boolean) as ScrapedEvent[],
    onctPhotos,
  );

  // Curated first for dedup priority
  return [...zenith, ...poneyClub, ...leRex, ...bascala, ...comdt, ...casinoBarriere, ...tfg, ...operaTls, ...bikini, ...interference, ...metronum, ...tlTourisme, ...taggedOds];
}

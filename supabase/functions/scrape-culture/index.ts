// supabase functions deploy scrape-culture --no-verify-jwt
//
// Scrape tous les theatres + musees + visites guidees + MEETT de Toulouse.
// Porte depuis les 17 scrapers Dart + 3 services culture.

import { type ScrapedEvent, makeEvent, upsertEvents, isFutureDate } from "../_shared/db.ts";
import { cleanHtml, buildIsoDate, frenchDateToIso, currentSeasonYear, fetchHtml, fetchJson, frenchMonths } from "../_shared/html-utils.ts";

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

function todayStr(): string {
  const n = new Date();
  return `${n.getFullYear()}-${String(n.getMonth()+1).padStart(2,"0")}-${String(n.getDate()).padStart(2,"0")}`;
}

function isUpcoming(dateFin: string, dateDebut: string): boolean {
  const ref = dateFin || dateDebut;
  if (!ref) return false;
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const d = new Date(ref);
  return d >= today;
}

// ─────────────────────────────────────────────────────────────
// 1. Theatre Sorano
// ─────────────────────────────────────────────────────────────
async function scrapeSorano(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.theatre-sorano.fr/la-saison/");
    const events: ScrapedEvent[] = [];

    const liRegex = /<li\s+class="lien-spectacle[^"]*">\s*<a\s+href="([^"]*)"[^>]*class="spectacles"[^>]*style="background:\s*url\('([^']*)'\)[^"]*"[^>]*>(.*?)<\/a>\s*<div\s+class="boutons">\s*<a\s+href="([^"]*)"[^>]*>/gs;
    const urlDateRegex = /\/(\d{4}-\d{2}-\d{2})\/?/;
    const datesBlockRegex = /<div\s+class="dates">\s*(.*?)\s*<\/div>/s;
    const dateRangeCrossRegex = /(\d{1,2})\s+(\w+)\.?\s*→\s*(\d{1,2})\s+(\w+)\.?/;
    const dateRangeRegex = /(\d{1,2})\s*→\s*(\d{1,2})\s+(\w+)\.?/;
    const dateSingleRegex = /le\s+(\d{1,2})\s+(\w+)\.?/i;
    const typeRegex = /<p\s+class="type petit">(.*?)<\/p>/s;
    const auteurRegex = /<p\s+class="auteur petit">(.*?)<\/p>/s;
    const titreRegex = /<p\s+class="letitre">(.*?)<\/p>/s;

    let m;
    while ((m = liRegex.exec(html)) !== null) {
      const detailUrl = m[1];
      const cardHtml = m[3];
      const savoirPlusUrl = m[4];

      const titreMatch = titreRegex.exec(cardHtml);
      titreRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const typeMatch = typeRegex.exec(cardHtml);
      typeRegex.lastIndex = 0;
      const type = typeMatch ? cleanHtml(typeMatch[1]) : "Spectacle";

      const auteurMatch = auteurRegex.exec(cardHtml);
      auteurRegex.lastIndex = 0;
      const auteur = auteurMatch ? cleanHtml(auteurMatch[1]) : "";

      const datesBlockMatch = datesBlockRegex.exec(cardHtml);
      datesBlockRegex.lastIndex = 0;
      const datesRaw = datesBlockMatch ? cleanHtml(datesBlockMatch[1]) : "";

      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      const urlDateMatch = urlDateRegex.exec(detailUrl);
      if (urlDateMatch) dateDebut = urlDateMatch[1];

      const year = dateDebut?.substring(0, 4) ?? currentSeasonYear();

      const crossMatch = dateRangeCrossRegex.exec(datesRaw);
      if (crossMatch) {
        dateDebut ??= buildIsoDate(crossMatch[1], crossMatch[2], year);
        dateFin = buildIsoDate(crossMatch[3], crossMatch[4], year);
      } else {
        const rangeMatch = dateRangeRegex.exec(datesRaw);
        if (rangeMatch) {
          dateDebut ??= buildIsoDate(rangeMatch[1], rangeMatch[3], year);
          dateFin = buildIsoDate(rangeMatch[2], rangeMatch[3], year);
        } else {
          const singleMatch = dateSingleRegex.exec(datesRaw);
          if (singleMatch) {
            dateDebut ??= buildIsoDate(singleMatch[1], singleMatch[2], year);
          }
        }
      }

      if (!dateDebut) continue;
      if (!isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      const url = savoirPlusUrl || detailUrl;
      const slug = url.split("/").filter(Boolean).pop() ?? titre.toLowerCase().replace(/\s+/g, "-");
      const id = `sorano_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_sorano", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: auteur ? `${type} · ${auteur}` : type,
        descriptif_long: auteur ? `${titre}\n${type}\n${auteur}` : `${titre}\n${type}`,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        dates_affichage_horaires: datesRaw,
        lieu_nom: "Theatre Sorano", lieu_adresse_2: "35 Allees Jules Guesde",
        commune: "Toulouse", code_postal: 31400,
        type_de_manifestation: type, categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: url,
      }));
    }
    return events;
  } catch (e) { console.error("sorano:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 2. Theatre du Pont Neuf
// ─────────────────────────────────────────────────────────────
async function scrapePontNeuf(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.theatredupontneuf.fr/spectacles25-26/");
    const events: ScrapedEvent[] = [];

    // Parse vc_row sections with spectacle info
    const rowRegex = /<div[^>]*class="[^"]*vc_row[^"]*"[^>]*>(.*?)<\/div>\s*<\/div>\s*<\/div>/gs;
    const titleRegex = /<h[23][^>]*>(.*?)<\/h[23]>/s;
    const dateTextRegex = /(?:du\s+(\d{1,2})\s+au\s+(\d{1,2})\s+(\w+))|(?:les?\s+(\d{1,2})(?:\s+et\s+(\d{1,2}))?\s+(\w+))/gi;
    const linkRegex = /href="(https?:\/\/[^"]*theatredupontneuf[^"]*)"/;

    // Simpler approach: find spectacle blocks by looking for date patterns near titles
    const blockRegex = /<(?:h[23]|strong)[^>]*>(.*?)<\/(?:h[23]|strong)>[\s\S]*?(?:du\s+\d|les?\s+\d|le\s+\d)(.*?)(?=<(?:h[23]|strong)|$)/gi;
    let match;
    while ((match = blockRegex.exec(html)) !== null) {
      const titre = cleanHtml(match[1]);
      if (!titre || titre.length < 3) continue;

      const dateBlock = match[2];
      const year = currentSeasonYear();

      // Try to parse dates
      const dateMatch = /(?:du\s+)?(\d{1,2})(?:\s+(\w+))?\s*(?:au|et|-|→)\s*(\d{1,2})\s+(\w+)/i.exec(match[0]) ??
                         /le\s+(\d{1,2})\s+(\w+)/i.exec(match[0]);
      if (!dateMatch) continue;

      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      if (dateMatch[3] && dateMatch[4]) {
        // Range: "du X au Y mois" or "X-Y mois"
        const monthEnd = dateMatch[4];
        const monthStart = dateMatch[2] || monthEnd;
        dateDebut = buildIsoDate(dateMatch[1], monthStart, year);
        dateFin = buildIsoDate(dateMatch[3], monthEnd, year);
      } else if (dateMatch[2]) {
        // Single: "le X mois"
        dateDebut = buildIsoDate(dateMatch[1], dateMatch[2], year);
        dateFin = dateDebut;
      }

      if (!dateDebut || !isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `pontneuf_${slug}_${dateDebut}`;
      const lnk = linkRegex.exec(match[0]);

      events.push(makeEvent({
        identifiant: id, source: "theatre_pont_neuf", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        lieu_nom: "Theatre du Pont Neuf", lieu_adresse_2: "2 Rue Georges Lardenne",
        commune: "Toulouse", code_postal: 31300,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: lnk?.[1] ?? "https://www.theatredupontneuf.fr/",
      }));
    }
    return events;
  } catch (e) { console.error("pontneuf:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 3. Cave Poesie
// ─────────────────────────────────────────────────────────────
async function scrapeCavePoesie(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.cave-poesie.com/agenda/");
    const events: ScrapedEvent[] = [];

    const eventRegex = /<div\s+class="event\s+all[^"]*">(.*?)<\/div>\s*<\/div>/gs;
    const h2Regex = /<h2[^>]*>(.*?)<\/h2>/s;
    const h4Regex = /<h4[^>]*>(.*?)<\/h4>/s;
    const h5Regex = /<h5[^>]*>(.*?)<\/h5>/gs;
    const linkRegex = /href="([^"]+)"/;

    let m;
    while ((m = eventRegex.exec(html)) !== null) {
      const block = m[1];

      const titreMatch = h2Regex.exec(block);
      h2Regex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const dateMatch = h4Regex.exec(block);
      h4Regex.lastIndex = 0;
      const dateRaw = dateMatch ? cleanHtml(dateMatch[1]) : "";

      // Parse date: "Vendredi 14 mars" or "14 mars"
      const dm = /(\d{1,2})\s+(\w+)/.exec(dateRaw);
      if (!dm) continue;

      const dateDebut = frenchDateToIso(dateRaw);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      // Price & time from h5
      let horaires = "";
      let tarif = "";
      let h5m;
      while ((h5m = h5Regex.exec(block)) !== null) {
        const txt = cleanHtml(h5m[1]);
        if (/\d+h/.test(txt)) horaires = txt;
        if (/\d+\s*[€e]/.test(txt) || /gratuit/i.test(txt)) tarif = txt;
      }
      h5Regex.lastIndex = 0;

      const lnk = linkRegex.exec(block);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `cavepoesie_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "cave_poesie", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateDebut,
        horaires,
        dates_affichage_horaires: dateRaw,
        lieu_nom: "Cave Poesie Rene Gouzenne", lieu_adresse_2: "71 Rue du Taur",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Poesie", categorie_de_la_manifestation: "Theatre",
        tarif_normal: tarif,
        reservation_site_internet: lnk?.[1] ?? "https://www.cave-poesie.com/",
      }));
    }
    return events;
  } catch (e) { console.error("cavepoesie:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 4. Theatre Garonne
// ─────────────────────────────────────────────────────────────
async function scrapeGaronne(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.theatregaronne.com/saison");
    const events: ScrapedEvent[] = [];

    const articleRegex = /<article[^>]*class="[^"]*carte[^"]*carte--spectacle[^"]*"[^>]*>(.*?)<\/article>/gs;
    const titleRegex = /<h[23][^>]*>(.*?)<\/h[23]>/s;
    const timeRegex = /<time[^>]*datetime="([^"]*)"[^>]*>/g;
    const linkRegex = /href="([^"]+)"/;
    const typeRegex = /<span[^>]*class="[^"]*carte__type[^"]*"[^>]*>(.*?)<\/span>/s;

    let m;
    while ((m = articleRegex.exec(html)) !== null) {
      const block = m[1];

      const titreMatch = titleRegex.exec(block);
      titleRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      // Dates from <time datetime=""> elements
      const dates: string[] = [];
      let tm;
      while ((tm = timeRegex.exec(block)) !== null) {
        const d = tm[1].substring(0, 10);
        if (d) dates.push(d);
      }
      timeRegex.lastIndex = 0;

      if (dates.length === 0) continue;
      dates.sort();
      const dateDebut = dates[0];
      const dateFin = dates[dates.length - 1];

      if (!isUpcoming(dateFin, dateDebut)) continue;

      const typeMatch = typeRegex.exec(block);
      typeRegex.lastIndex = 0;
      const type = typeMatch ? cleanHtml(typeMatch[1]) : "Spectacle";

      const lnk = linkRegex.exec(block);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `garonne_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_garonne", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: `${type} · ${titre}`,
        date_debut: dateDebut, date_fin: dateFin,
        lieu_nom: "Theatre Garonne", lieu_adresse_2: "1 Avenue du Chateau d'Eau",
        commune: "Toulouse", code_postal: 31300,
        type_de_manifestation: type, categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: lnk?.[1] ? `https://www.theatregaronne.com${lnk[1]}` : "https://www.theatregaronne.com/",
      }));
    }
    return events;
  } catch (e) { console.error("garonne:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 5. Theatre de la Cite
// ─────────────────────────────────────────────────────────────
async function scrapeCite(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.theatre-cite.com/programmation/");
    const events: ScrapedEvent[] = [];

    // Find spectacle links with dates
    const specRegex = /<a[^>]*href="(https?:\/\/www\.theatre-cite\.com\/spectacle\/[^"]*)"[^>]*title="([^"]*)"[^>]*>[\s\S]*?<\/a>/gi;
    const dateRegex = /(\d{1,2})(?:\s+(\w+))?\s*(?:au|→|-)\s*(\d{1,2})\s+(\w+)\s*(\d{4})?|le\s+(\d{1,2})\s+(\w+)\s*(\d{4})?/gi;

    let m;
    while ((m = specRegex.exec(html)) !== null) {
      const url = m[1];
      const titre = cleanHtml(m[2]);
      if (!titre) continue;

      // Look for dates near this match
      const context = html.substring(m.index, Math.min(m.index + 500, html.length));
      const dm = dateRegex.exec(context);
      dateRegex.lastIndex = 0;
      if (!dm) continue;

      const year = currentSeasonYear();
      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      if (dm[6]) {
        // Single date
        dateDebut = buildIsoDate(dm[6], dm[7], dm[8] || year);
        dateFin = dateDebut;
      } else if (dm[3]) {
        // Range
        const endMonth = dm[4];
        const startMonth = dm[2] || endMonth;
        const y = dm[5] || year;
        dateDebut = buildIsoDate(dm[1], startMonth, y);
        dateFin = buildIsoDate(dm[3], endMonth, y);
      }

      if (!dateDebut || !isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `cite_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_cite", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        lieu_nom: "Theatre de la Cite", lieu_adresse_2: "1 Rue Pierre Baudis",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: url,
      }));
    }
    return events;
  } catch (e) { console.error("cite:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 6. Theatre du Capitole (WordPress REST API)
// ─────────────────────────────────────────────────────────────
async function scrapeCapitole(): Promise<ScrapedEvent[]> {
  try {
    const data = await fetchJson<any[]>(
      "https://opera.toulouse.fr/wp-json/wp/v2/onct-events?per_page=50&_fields=id,title,link,meta"
    );
    const events: ScrapedEvent[] = [];

    for (const item of data) {
      const meta = item.meta ?? {};
      if (meta["onct-event-past"] === true) continue;

      const titre = cleanHtml(item.title?.rendered ?? "");
      if (!titre) continue;

      const day = Number(meta["onct-event-day"]) || 0;
      const month = Number(meta["onct-event-month"]) || 0;
      const year = Number(meta["onct-event-year"]) || 0;
      if (!day || !month || !year) continue;

      const dateDebut = `${year}-${String(month).padStart(2,"0")}-${String(day).padStart(2,"0")}`;

      let dateFin = dateDebut;
      const endTs = Number(meta["onct-event-end-timestamp"]) || 0;
      if (endTs > 0) {
        const endDt = new Date(endTs * 1000);
        dateFin = `${endDt.getFullYear()}-${String(endDt.getMonth()+1).padStart(2,"0")}-${String(endDt.getDate()).padStart(2,"0")}`;
      }

      const hour = meta["onct-event-hour"] != null ? Number(meta["onct-event-hour"]) : null;
      const minute = Number(meta["onct-event-minute"]) || 0;
      const horaires = hour != null ? `${hour}h${String(minute).padStart(2,"0")}` : "";

      const desc = cleanHtml(meta["onct-event-desc"] ?? "");
      const shortDesc = cleanHtml(meta["onct-event-short-desc"] ?? "");
      const regLink = meta["onct-event-registration-link"] ?? "";
      const detailLink = item.link ?? "";
      const freeEntrance = meta["onct-event-free-entrance"] === true;

      const slug = new URL(detailLink || "https://opera.toulouse.fr").pathname.split("/").filter(Boolean).pop() ??
                   titre.toLowerCase().replace(/[^a-z0-9]+/g, "-");
      const id = `capitole_${slug}_${dateDebut}`;

      if (!isUpcoming(dateFin, dateDebut)) continue;

      events.push(makeEvent({
        identifiant: id, source: "theatre_capitole", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: shortDesc || titre,
        descriptif_long: desc || titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        dates_affichage_horaires: horaires ? `${dateDebut} ${horaires}` : dateDebut,
        lieu_nom: "Theatre du Capitole", lieu_adresse_2: "Place du Capitole",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: freeEntrance ? "Gratuit" : "Opera",
        categorie_de_la_manifestation: "Theatre",
        tarif_normal: freeEntrance ? "Gratuit" : "",
        reservation_site_internet: regLink || detailLink,
      }));
    }
    return events;
  } catch (e) { console.error("capitole:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 7. Theatre du Grand Rond
// ─────────────────────────────────────────────────────────────
async function scrapeGrandRond(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.grand-rond.org/programmation");
    const events: ScrapedEvent[] = [];

    const blockRegex = /<div[^>]*class="[^"]*col-md-6\s+bloc_spectacle[^"]*"[^>]*>(.*?)<\/div>\s*<\/div>/gs;
    const titleRegex = /<h[234][^>]*>(.*?)<\/h[234]>/s;
    const dateRegex = /(\d{1,2})(?:\s+(\w+))?\s*(?:au|→|-|et)\s*(\d{1,2})\s+(\w+)|le\s+(\d{1,2})\s+(\w+)/gi;
    const linkRegex = /href="([^"]+)"/;

    let m;
    while ((m = blockRegex.exec(html)) !== null) {
      const block = m[1];
      const titreMatch = titleRegex.exec(block);
      titleRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const dm = dateRegex.exec(block);
      dateRegex.lastIndex = 0;
      if (!dm) continue;

      const year = currentSeasonYear();
      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      if (dm[5]) {
        dateDebut = buildIsoDate(dm[5], dm[6], year);
        dateFin = dateDebut;
      } else if (dm[3]) {
        const endMonth = dm[4];
        const startMonth = dm[2] || endMonth;
        dateDebut = buildIsoDate(dm[1], startMonth, year);
        dateFin = buildIsoDate(dm[3], endMonth, year);
      }

      if (!dateDebut || !isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      const lnk = linkRegex.exec(block);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `grandrond_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_grand_rond", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        lieu_nom: "Theatre du Grand Rond", lieu_adresse_2: "23 Rue des Potiers",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: lnk?.[1] ?? "https://www.grand-rond.org/",
      }));
    }
    return events;
  } catch (e) { console.error("grandrond:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 8. Grenier Theatre
// ─────────────────────────────────────────────────────────────
async function scrapeGrenier(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.greniertheatre.org/la-saison/");
    const events: ScrapedEvent[] = [];

    const blockRegex = /<div[^>]*class="[^"]*pieceContainer[^"]*"[^>]*>(.*?)<\/div>\s*<\/div>/gs;
    const titleRegex = /<h[234][^>]*>(.*?)<\/h[234]>/s;
    const dateSpanRegex = /<span[^>]*class="[^"]*date[^"]*"[^>]*>(.*?)<\/span>/s;
    const priceRegex = /(\d+[\s,.]?\d*\s*[€e])/;
    const linkRegex = /href="([^"]+)"/;

    let m;
    while ((m = blockRegex.exec(html)) !== null) {
      const block = m[1];
      const titreMatch = titleRegex.exec(block);
      titleRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const dateMatch = dateSpanRegex.exec(block);
      dateSpanRegex.lastIndex = 0;
      const dateRaw = dateMatch ? cleanHtml(dateMatch[1]) : "";
      if (!dateRaw) continue;

      const year = currentSeasonYear();
      const dateDebut = frenchDateToIso(dateRaw);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      // Try to find end date
      const rangeMatch = /(\d{1,2})(?:\s+\w+)?\s*(?:au|→|-)\s*(\d{1,2})\s+(\w+)/.exec(dateRaw);
      let dateFin = dateDebut;
      if (rangeMatch) {
        const fin = buildIsoDate(rangeMatch[2], rangeMatch[3], year);
        if (fin) dateFin = fin;
      }

      const priceMatch = priceRegex.exec(block);
      const lnk = linkRegex.exec(block);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `grenier_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "grenier_theatre", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        dates_affichage_horaires: dateRaw,
        lieu_nom: "Grenier Theatre", lieu_adresse_2: "12 Rue Mage",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        tarif_normal: priceMatch?.[1] ?? "",
        reservation_site_internet: lnk?.[1] ?? "https://www.greniertheatre.org/",
      }));
    }
    return events;
  } catch (e) { console.error("grenier:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 9. 3T Cafe Theatre (WordPress REST API + HTML detail)
// ─────────────────────────────────────────────────────────────
async function scrapeThreeT(): Promise<ScrapedEvent[]> {
  try {
    const data = await fetchJson<any[]>(
      "https://3tcafetheatre.com/wp-json/wp/v2/spectacles?per_page=30&_fields=id,title,link"
    );
    const events: ScrapedEvent[] = [];

    // Fetch detail pages in parallel (max 10)
    const pages = await Promise.allSettled(
      data.slice(0, 10).map(async (item: any) => {
        const html = await fetchHtml(item.link);
        return { item, html };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { item, html } = result.value;

      const titre = cleanHtml(item.title?.rendered ?? "");
      if (!titre) continue;

      // Extract dates from detail page
      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s*(\d{4})?/gi;
      const dates: string[] = [];
      let dm;
      while ((dm = dateRegex.exec(html)) !== null) {
        const d = buildIsoDate(dm[1], dm[2], dm[3] || currentSeasonYear());
        if (d && isFutureDate(d)) dates.push(d);
      }

      if (dates.length === 0) continue;
      dates.sort();
      const dateDebut = dates[0];
      const dateFin = dates[dates.length - 1];

      // Extract time
      const timeMatch = /(\d{1,2}h\d{2})/.exec(html);
      const horaires = timeMatch?.[1] ?? "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `3t_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "three_t", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        lieu_nom: "3T Cafe Theatre", lieu_adresse_2: "19 Rue Maran",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: item.link ?? "https://3tcafetheatre.com/",
      }));
    }
    return events;
  } catch (e) { console.error("3t:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 10. Theatre du Pave (Tribe Events REST API)
// ─────────────────────────────────────────────────────────────
async function scrapePave(): Promise<ScrapedEvent[]> {
  try {
    const data = await fetchJson<any>(
      "https://theatredupave.org/wp-json/tribe/events/v1/events?per_page=30&start_date=now"
    );
    const events: ScrapedEvent[] = [];
    const items = data.events ?? [];

    for (const item of items) {
      const titre = cleanHtml(item.title ?? "");
      if (!titre) continue;

      const startDate = (item.start_date ?? "").substring(0, 10);
      const endDate = (item.end_date ?? "").substring(0, 10);
      if (!startDate) continue;
      if (!isUpcoming(endDate || startDate, startDate)) continue;

      const desc = cleanHtml(item.description ?? "");
      const shortDesc = cleanHtml(item.excerpt ?? "");
      const url = item.url ?? "https://theatredupave.org/";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `pave_${slug}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_du_pave", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: shortDesc || titre,
        descriptif_long: desc || titre,
        date_debut: startDate, date_fin: endDate || startDate,
        lieu_nom: "Theatre du Pave", lieu_adresse_2: "34 Rue Maran",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: url,
      }));
    }
    return events;
  } catch (e) { console.error("pave:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 11. Theatre le Fil a Plomb (2 URLs)
// ─────────────────────────────────────────────────────────────
async function scrapeFilAPlomb(): Promise<ScrapedEvent[]> {
  try {
    const urls = [
      "https://www.theatrelefilaplomb.fr/tout-public/",
      "https://www.theatrelefilaplomb.fr/jeune-public/",
    ];
    const events: ScrapedEvent[] = [];

    for (const url of urls) {
      const html = await fetchHtml(url);
      // Find links with show info
      const linkRegex = /<a[^>]*href="(https?:\/\/www\.theatrelefilaplomb\.fr\/[^"]*)"[^>]*>(.*?)<\/a>/gs;
      let m;
      while ((m = linkRegex.exec(html)) !== null) {
        const linkUrl = m[1];
        const text = cleanHtml(m[2]);
        if (!text || text.length < 5) continue;

        // Split by em-dash: "TITRE -- dates"
        const parts = text.split(/\s*[–—-]{2,}\s*/);
        const titre = parts[0]?.trim();
        if (!titre) continue;

        const datesPart = parts[1] ?? "";
        const dateDebut = frenchDateToIso(datesPart);
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        // Try range
        const rangeMatch = /(\d{1,2})(?:\s+\w+)?\s*(?:au|→|-)\s*(\d{1,2})\s+(\w+)/.exec(datesPart);
        let dateFin = dateDebut;
        if (rangeMatch) {
          const year = currentSeasonYear();
          const fin = buildIsoDate(rangeMatch[2], rangeMatch[3], year);
          if (fin) dateFin = fin;
        }

        const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
        const id = `filaplomb_${slug}_${dateDebut}`;

        events.push(makeEvent({
          identifiant: id, source: "fil_a_plomb", rubrique: "culture",
          nom_de_la_manifestation: titre,
          descriptif_court: titre,
          date_debut: dateDebut, date_fin: dateFin,
          lieu_nom: "Theatre le Fil a Plomb", lieu_adresse_2: "2 Rue du Lieutenant Colonel Pelissier",
          commune: "Toulouse", code_postal: 31000,
          type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
          reservation_site_internet: linkUrl,
        }));
      }
    }
    return events;
  } catch (e) { console.error("filaplomb:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 12 & 13. Metropole Toulouse (Mazades + Brique Rouge)
// ─────────────────────────────────────────────────────────────
interface MetropoleConfig {
  extId: string;
  idPrefix: string;
  lieuNom: string;
  lieuAdresse: string;
  codePostal: number;
}

async function scrapeMetropole(config: MetropoleConfig): Promise<ScrapedEvent[]> {
  try {
    const listUrl = `https://www.metropole.toulouse.fr/agenda?ext=${config.extId}`;
    const html = await fetchHtml(listUrl);
    const events: ScrapedEvent[] = [];

    // Find event links
    const linkRegex = /href="(\/agenda\/[^"]+)"/g;
    const urls = new Set<string>();
    let m;
    while ((m = linkRegex.exec(html)) !== null) {
      urls.add(`https://www.metropole.toulouse.fr${m[1]}`);
    }

    // Fetch detail pages (max 15)
    const pages = await Promise.allSettled(
      [...urls].slice(0, 15).map(async (url) => {
        const detailHtml = await fetchHtml(url);
        return { url, html: detailHtml };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { url: pageUrl, html: detailHtml } = result.value;

      // Extract JSON-LD
      const jsonLdMatch = /<script\s+type="application\/ld\+json">(.*?)<\/script>/s.exec(detailHtml);
      if (!jsonLdMatch) continue;

      try {
        const jsonLd = JSON.parse(jsonLdMatch[1]);
        const eventData = Array.isArray(jsonLd) ? jsonLd.find((e: any) => e["@type"] === "Event") : (jsonLd["@type"] === "Event" ? jsonLd : null);
        if (!eventData) continue;

        const name = eventData.name ?? "";
        if (!name) continue;

        const startDate = (eventData.startDate ?? "").substring(0, 10);
        const endDate = (eventData.endDate ?? "").substring(0, 10);
        if (!startDate) continue;
        if (!isUpcoming(endDate || startDate, startDate)) continue;

        const desc = eventData.description ?? "";
        const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
        const id = `${config.idPrefix}_${slug}_${startDate}`;

        events.push(makeEvent({
          identifiant: id, source: config.idPrefix, rubrique: "culture",
          nom_de_la_manifestation: name,
          descriptif_court: desc.length > 120 ? desc.substring(0, 120) + "..." : desc || name,
          descriptif_long: desc || name,
          date_debut: startDate, date_fin: endDate || startDate,
          lieu_nom: config.lieuNom, lieu_adresse_2: config.lieuAdresse,
          commune: "Toulouse", code_postal: config.codePostal,
          type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
          reservation_site_internet: pageUrl,
        }));
      } catch { continue; }
    }
    return events;
  } catch (e) { console.error(`metropole ${config.idPrefix}:`, e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 14. Theatre de la Violette
// ─────────────────────────────────────────────────────────────
async function scrapeViolette(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.theatredelaviolette.com/");
    const events: ScrapedEvent[] = [];

    // Find show links
    const linkRegex = /href="(https?:\/\/www\.theatredelaviolette\.com\/[^"]*spectacle[^"]*)"/gi;
    const urls = new Set<string>();
    let m;
    while ((m = linkRegex.exec(html)) !== null) {
      urls.add(m[1]);
    }

    // Also try a broader pattern for show pages
    const showRegex = /href="(https?:\/\/www\.theatredelaviolette\.com\/[^"]+)"[^>]*>.*?<(?:h[234]|strong)[^>]*>(.*?)<\/(?:h[234]|strong)>/gs;
    while ((m = showRegex.exec(html)) !== null) {
      if (m[1] && !m[1].includes("agenda") && !m[1].includes("contact")) {
        urls.add(m[1]);
      }
    }

    // Fetch detail pages
    const pages = await Promise.allSettled(
      [...urls].slice(0, 15).map(async (url) => {
        const detailHtml = await fetchHtml(url);
        return { url, html: detailHtml };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { url: pageUrl, html: detailHtml } = result.value;

      const titleMatch = /<h1[^>]*>(.*?)<\/h1>/s.exec(detailHtml);
      const titre = titleMatch ? cleanHtml(titleMatch[1]) : "";
      if (!titre || titre.length < 3) continue;

      // Look for session dates in <select class="seances">
      const selectMatch = /<select[^>]*class="[^"]*seances[^"]*"[^>]*>(.*?)<\/select>/s.exec(detailHtml);
      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;

      const dates: string[] = [];
      const searchIn = selectMatch ? selectMatch[1] : detailHtml;
      let dm;
      while ((dm = dateRegex.exec(searchIn)) !== null) {
        const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
        if (d && isFutureDate(d)) dates.push(d);
      }

      if (dates.length === 0) continue;
      dates.sort();

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `violette_${slug}_${dates[0]}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_violette", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dates[0], date_fin: dates[dates.length - 1],
        lieu_nom: "Theatre de la Violette", lieu_adresse_2: "67 Chemin Pujibet",
        commune: "Toulouse", code_postal: 31100,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: pageUrl,
      }));
    }
    return events;
  } catch (e) { console.error("violette:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 15. Theatre de Poche
// ─────────────────────────────────────────────────────────────
async function scrapePoche(): Promise<ScrapedEvent[]> {
  try {
    const mainUrl = "https://www.theatredepochetoulouse.fr/la-programmation-2/";
    const mainHtml = await fetchHtml(mainUrl);
    const events: ScrapedEvent[] = [];

    // Find month sub-page links
    const monthLinkRegex = /href="(https?:\/\/www\.theatredepochetoulouse\.fr\/la-programmation-2\/[^"]+)"/gi;
    const monthUrls = new Set<string>();
    let m;
    while ((m = monthLinkRegex.exec(mainHtml)) !== null) {
      monthUrls.add(m[1]);
    }

    // Fetch each month page
    for (const monthUrl of [...monthUrls].slice(0, 6)) {
      try {
        const html = await fetchHtml(monthUrl);

        // Split by <h3> tags (each show)
        const sections = html.split(/<h3[^>]*>/);
        for (let i = 1; i < sections.length; i++) {
          const section = sections[i];
          const titreMatch = /(.*?)<\/h3>/s.exec(section);
          const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
          if (!titre || titre.length < 3) continue;

          // Find dates
          const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
          const dates: string[] = [];
          let dm;
          while ((dm = dateRegex.exec(section)) !== null) {
            const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
            if (d && isFutureDate(d)) dates.push(d);
          }

          if (dates.length === 0) continue;
          dates.sort();

          // Find time
          const timeMatch = /(\d{1,2}h\d{2})/.exec(section);

          const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
          const id = `poche_${slug}_${dates[0]}`;

          events.push(makeEvent({
            identifiant: id, source: "theatre_de_poche", rubrique: "culture",
            nom_de_la_manifestation: titre,
            descriptif_court: titre,
            date_debut: dates[0], date_fin: dates[dates.length - 1],
            horaires: timeMatch?.[1] ?? "",
            lieu_nom: "Theatre de Poche", lieu_adresse_2: "5 Rue du Taur",
            commune: "Toulouse", code_postal: 31000,
            type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
            reservation_site_internet: monthUrl,
          }));
        }
      } catch { continue; }
    }
    return events;
  } catch (e) { console.error("poche:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 16. Theatre du Chien Blanc (Elementor)
// ─────────────────────────────────────────────────────────────
async function scrapeChienBlanc(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://theatreduchienblanc.fr/programme-en-cours/");
    const events: ScrapedEvent[] = [];

    // Find show links
    const linkRegex = /href="(https?:\/\/theatreduchienblanc\.fr\/[^"]*)"[^>]*>[\s\S]*?<(?:h[234]|strong)[^>]*>(.*?)<\/(?:h[234]|strong)>/gs;
    const shows: { url: string; titre: string }[] = [];
    let m;
    while ((m = linkRegex.exec(html)) !== null) {
      const titre = cleanHtml(m[2]);
      if (titre && titre.length > 3 && !m[1].includes("programme-en-cours")) {
        shows.push({ url: m[1], titre });
      }
    }

    // Fetch detail pages
    const pages = await Promise.allSettled(
      shows.slice(0, 15).map(async (show) => {
        const detailHtml = await fetchHtml(show.url);
        return { ...show, html: detailHtml };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { url, titre, html: detailHtml } = result.value;

      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
      const dates: string[] = [];
      let dm;
      while ((dm = dateRegex.exec(detailHtml)) !== null) {
        const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
        if (d && isFutureDate(d)) dates.push(d);
      }

      if (dates.length === 0) continue;
      dates.sort();

      const timeMatch = /(\d{1,2}h\d{2})/.exec(detailHtml);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `chienblanc_${slug}_${dates[0]}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_chien_blanc", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dates[0], date_fin: dates[dates.length - 1],
        horaires: timeMatch?.[1] ?? "",
        lieu_nom: "Theatre du Chien Blanc", lieu_adresse_2: "18 Rue Belbeze",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: url,
      }));
    }
    return events;
  } catch (e) { console.error("chienblanc:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 17. Theatre Jules Julien (WordPress REST API - same as Capitole)
// ─────────────────────────────────────────────────────────────
async function scrapeJulesJulien(): Promise<ScrapedEvent[]> {
  try {
    const data = await fetchJson<any[]>(
      "https://conservatoire.toulouse.fr/wp-json/wp/v2/onct-events?onct-event-lieu=158&per_page=50&_fields=id,title,link,meta"
    );
    const events: ScrapedEvent[] = [];

    for (const item of data) {
      const meta = item.meta ?? {};
      if (meta["onct-event-past"] === true) continue;

      const titre = cleanHtml(item.title?.rendered ?? "");
      if (!titre) continue;

      const day = Number(meta["onct-event-day"]) || 0;
      const month = Number(meta["onct-event-month"]) || 0;
      const year = Number(meta["onct-event-year"]) || 0;
      if (!day || !month || !year) continue;

      const dateDebut = `${year}-${String(month).padStart(2,"0")}-${String(day).padStart(2,"0")}`;

      let dateFin = dateDebut;
      const endTs = Number(meta["onct-event-end-timestamp"]) || 0;
      if (endTs > 0) {
        const endDt = new Date(endTs * 1000);
        dateFin = `${endDt.getFullYear()}-${String(endDt.getMonth()+1).padStart(2,"0")}-${String(endDt.getDate()).padStart(2,"0")}`;
      }

      if (!isUpcoming(dateFin, dateDebut)) continue;

      const hour = meta["onct-event-hour"] != null ? Number(meta["onct-event-hour"]) : null;
      const minute = Number(meta["onct-event-minute"]) || 0;
      const horaires = hour != null ? `${hour}h${String(minute).padStart(2,"0")}` : "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `julesjulien_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_jules_julien", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        lieu_nom: "Nouveau Theatre Jules Julien", lieu_adresse_2: "2 Rue Dieudonne Costes",
        commune: "Toulouse", code_postal: 31400,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: item.link ?? "https://conservatoire.toulouse.fr/",
      }));
    }
    return events;
  } catch (e) { console.error("julesjulien:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 18. Museum Events (OpenDataSoft API)
// ─────────────────────────────────────────────────────────────
async function scrapeMuseumEvents(): Promise<ScrapedEvent[]> {
  try {
    const today = todayStr();
    const museumKeywords = [
      "augustins", "saint-raymond", "georges labit", "paul dupuy",
      "abattoirs", "bemberg", "aeroscopia", "cite de l'espace",
      "museum", "quai des savoirs", "halle de la machine", "envol des pionniers",
      "aeronautheque", "bazacle", "jacobins", "galerie du chateau",
    ];

    // Simple query: all future events, filter by venue in code
    const where = `date_debut >= "${today}"`;
    const url = `https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records?where=${encodeURIComponent(where)}&limit=100&order_by=date_debut`;

    const data = await fetchJson<any>(url, 20000);
    const events: ScrapedEvent[] = [];

    for (const r of data.results ?? []) {
      const titre = r.nom_de_la_manifestation ?? "";
      if (!titre) continue;

      const lieuNom = (r.lieu_nom ?? "").toLowerCase();
      const isMuseum = museumKeywords.some(k => lieuNom.includes(k));
      if (!isMuseum) continue;

      const dateDebut = (r.date_debut ?? "").substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const id = `museum_${titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40)}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "museum_toulouse", rubrique: "culture",
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
  } catch (e) { console.error("museum:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 19. Guided Tours (OpenDataSoft API)
// ─────────────────────────────────────────────────────────────
async function scrapeGuidedTours(): Promise<ScrapedEvent[]> {
  try {
    const today = todayStr();
    const where = `(search(type_de_manifestation, "Visite") OR search(categorie_de_la_manifestation, "Visite")) AND date_debut >= "${today}"`;
    const url = `https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records?where=${encodeURIComponent(where)}&limit=100&order_by=date_debut`;

    const data = await fetchJson<any>(url);
    const events: ScrapedEvent[] = [];

    for (const r of data.results ?? []) {
      const titre = r.nom_de_la_manifestation ?? "";
      if (!titre) continue;

      const dateDebut = (r.date_debut ?? "").substring(0, 10);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      const id = `guidedtour_${titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40)}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "guided_tours", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: r.descriptif_court ?? "",
        descriptif_long: r.descriptif_long ?? "",
        date_debut: dateDebut,
        date_fin: (r.date_fin ?? "").substring(0, 10) || dateDebut,
        horaires: r.horaires ?? "",
        lieu_nom: r.lieu_nom ?? "",
        lieu_adresse_2: r.lieu_adresse_2 ?? "",
        code_postal: Number(r.code_postal) || 0,
        commune: r.commune ?? "Toulouse",
        type_de_manifestation: r.type_de_manifestation ?? "",
        categorie_de_la_manifestation: r.categorie_de_la_manifestation ?? "",
        manifestation_gratuite: r.manifestation_gratuite ?? "",
        tarif_normal: r.tarif_normal ?? "",
        reservation_site_internet: r.reservation_site_internet ?? "",
        station_metro_tram_a_proximite: r.station_metro_tram_a_proximite ?? "",
      }));
    }
    return events;
  } catch (e) { console.error("guided_tours:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 20. MEETT Exhibitions
// ─────────────────────────────────────────────────────────────
async function scrapeMeett(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.meett.fr/en/exhibitor/");
    const events: ScrapedEvent[] = [];

    // Find exhibition blocks
    const blockRegex = /<article[^>]*>(.*?)<\/article>/gs;
    const titleRegex = /<h[234][^>]*>(.*?)<\/h[234]>/s;
    const dateRegex = /(\d{1,2})(?:\s*[-–]\s*(\d{1,2}))?\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s*(\d{4})?/i;
    const linkRegex = /href="([^"]+)"/;

    let m;
    while ((m = blockRegex.exec(html)) !== null) {
      const block = m[1];
      const titreMatch = titleRegex.exec(block);
      titleRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const dm = dateRegex.exec(block);
      if (!dm) continue;

      const year = dm[4] || currentSeasonYear();
      const dateDebut = buildIsoDate(dm[1], dm[3], year);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      let dateFin = dateDebut;
      if (dm[2]) {
        const fin = buildIsoDate(dm[2], dm[3], year);
        if (fin) dateFin = fin;
      }

      const lnk = linkRegex.exec(block);
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `meett_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "meett", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: `Exposition au MEETT : ${titre}`,
        date_debut: dateDebut, date_fin: dateFin,
        lieu_nom: "MEETT - Parc des Expositions", lieu_adresse_2: "Concorde Avenue",
        commune: "Toulouse", code_postal: 31840,
        type_de_manifestation: "Exposition", categorie_de_la_manifestation: "Exposition",
        reservation_site_internet: lnk?.[1] ?? "https://www.meett.fr/",
      }));
    }
    return events;
  } catch (e) { console.error("meett:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 21. Balma Events (Family)
// ─────────────────────────────────────────────────────────────
async function scrapeBalma(): Promise<ScrapedEvent[]> {
  try {
    const html = await fetchHtml("https://www.mairie-balma.fr/systeme/agenda/");
    const events: ScrapedEvent[] = [];

    const cardRegex = /<a\s[^>]*href="(https?:\/\/www\.mairie-balma\.fr\/agenda\/[^"]+)"[^>]*>(.*?)<\/a>/gs;
    const titleRegex = /<h3[^>]*>(.*?)<\/h3>/s;
    const cardDateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
    const categoryRegex = /(?:Sport|Culture|Environnement|Divers|Solidarit[eé]|Economie|Loisirs|Jeunesse|Sant[eé])/i;

    const cards: { url: string; titre: string; dateStr: string | null; categorie: string }[] = [];
    let m;
    while ((m = cardRegex.exec(html)) !== null) {
      const url = m[1];
      const cardHtml = m[2];

      const titreMatch = titleRegex.exec(cardHtml);
      titleRegex.lastIndex = 0;
      const titre = titreMatch ? cleanHtml(titreMatch[1]) : "";
      if (!titre) continue;

      const dm = cardDateRegex.exec(cardHtml);
      cardDateRegex.lastIndex = 0;
      const dateStr = dm ? `${dm[1]} ${dm[2]}` : null;

      const catMatch = categoryRegex.exec(cardHtml);
      const categorie = catMatch?.[0] ?? "";

      cards.push({ url, titre, dateStr, categorie });
    }

    // Fetch detail pages in parallel (max 15)
    const pages = await Promise.allSettled(
      cards.slice(0, 15).map(async (card) => {
        const detailHtml = await fetchHtml(card.url);
        return { card, html: detailHtml };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { card, html: detailHtml } = result.value;

      // Parse dates from detail page
      const detailDateRegex = /(?:Du\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+au\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4}))|(?:Le\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4}))/i;
      const ddm = detailDateRegex.exec(detailHtml);

      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      if (ddm) {
        if (ddm[1]) {
          dateDebut = buildIsoDate(ddm[1], ddm[2], ddm[3]);
          dateFin = buildIsoDate(ddm[4], ddm[5], ddm[6]);
        } else if (ddm[7]) {
          dateDebut = buildIsoDate(ddm[7], ddm[8], ddm[9]);
          dateFin = dateDebut;
        }
      }

      // Fallback to card date
      dateDebut ??= frenchDateToIso(card.dateStr);
      dateFin ??= dateDebut;

      if (!dateDebut) continue;
      if (!isFutureDate(dateDebut)) continue;

      // Extract time
      const timeMatch = /(\d{1,2}h\d{2})\s*[àa]\s*(\d{1,2}h\d{2})/.exec(detailHtml);
      const horaires = timeMatch ? `${timeMatch[1]} - ${timeMatch[2]}` : "";

      const slug = card.titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `balma_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "balma_events", rubrique: "family",
        nom_de_la_manifestation: `Balma · ${card.titre}`,
        descriptif_court: card.titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        horaires,
        lieu_nom: "Balma", lieu_adresse_2: "",
        commune: "Balma", code_postal: 31130,
        type_de_manifestation: card.categorie || "Evenement municipal",
        categorie_de_la_manifestation: card.categorie || "famille",
        reservation_site_internet: card.url,
      }));
    }
    return events;
  } catch (e) { console.error("balma:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// Main handler
// ─────────────────────────────────────────────────────────────
Deno.serve(async (_req) => {
  try {
    const errors: string[] = [];
    const allEvents: ScrapedEvent[] = [];
    const details: Record<string, number> = {};

    const scrapers = [
      { name: "sorano", fn: scrapeSorano },
      { name: "pont_neuf", fn: scrapePontNeuf },
      { name: "cave_poesie", fn: scrapeCavePoesie },
      { name: "garonne", fn: scrapeGaronne },
      { name: "cite", fn: scrapeCite },
      { name: "capitole", fn: scrapeCapitole },
      { name: "grand_rond", fn: scrapeGrandRond },
      { name: "grenier", fn: scrapeGrenier },
      { name: "three_t", fn: scrapeThreeT },
      { name: "pave", fn: scrapePave },
      { name: "fil_a_plomb", fn: scrapeFilAPlomb },
      { name: "mazades", fn: () => scrapeMetropole({ extId: "2029", idPrefix: "mazades", lieuNom: "Theatre des Mazades", lieuAdresse: "10 avenue des Mazades", codePostal: 31200 }) },
      { name: "briquerouge", fn: () => scrapeMetropole({ extId: "2001", idPrefix: "briquerouge", lieuNom: "La Brique Rouge", lieuAdresse: "15 rue Leon Jouhaux", codePostal: 31500 }) },
      { name: "violette", fn: scrapeViolette },
      { name: "poche", fn: scrapePoche },
      { name: "chien_blanc", fn: scrapeChienBlanc },
      { name: "jules_julien", fn: scrapeJulesJulien },
      { name: "museum", fn: scrapeMuseumEvents },
      { name: "guided_tours", fn: scrapeGuidedTours },
      { name: "meett", fn: scrapeMeett },
      { name: "balma", fn: scrapeBalma },
    ];

    // Run all scrapers in parallel (each handles its own errors)
    const results = await Promise.allSettled(
      scrapers.map(async (s) => {
        console.log(`  scrape-culture: starting ${s.name}`);
        const events = await s.fn();
        console.log(`  scrape-culture: ${s.name} → ${events.length} events`);
        return { name: s.name, events };
      })
    );

    for (const r of results) {
      if (r.status === "fulfilled") {
        details[r.value.name] = r.value.events.length;
        allEvents.push(...r.value.events);
      } else {
        errors.push(`${r.reason}`);
      }
    }

    // Upsert all events
    let count = 0;
    try {
      count = await upsertEvents(allEvents);
    } catch (e) {
      errors.push(`upsert: ${(e as Error).message}`);
    }
    console.log(`scrape-culture: upserted ${count} events total`);

    return new Response(
      JSON.stringify({ count, errors, details }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ count: 0, errors: [`FATAL: ${(e as Error).message}`] }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

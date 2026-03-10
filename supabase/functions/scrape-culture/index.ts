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

      // Image from background-image url in the card
      const imageUrl = m[2] || "";

      events.push(makeEvent({
        identifiant: id, source: "theatre_sorano", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: auteur ? `${type} · ${auteur}` : type,
        descriptif_long: auteur ? `${titre}\n${type}\n${auteur}` : `${titre}\n${type}`,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        dates_affichage_horaires: datesRaw,
        photo_url: imageUrl,
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
    const year = currentSeasonYear();

    // Collect all images near show titles for photo extraction
    const allImgMatches: string[] = [];
    const imgCollectRegex = /<img[^>]*src="([^"]+\.(jpg|jpeg|png|webp))"[^>]*>/gi;
    let imgM;
    while ((imgM = imgCollectRegex.exec(html)) !== null) {
      if (!imgM[1].includes("logo") && !imgM[1].includes("icon") && !imgM[1].includes("favicon")) {
        allImgMatches.push(imgM[1]);
      }
    }

    // Structure: <h2><b>Title</b></h2> then <h3>du X au Y mois</h3> as siblings
    // Strategy: collect all h2/h3 tags in order, pair titles with dates
    const tagRegex = /<(h[23])[^>]*>(.*?)<\/\1>/gs;
    const tags: { tag: string; text: string; index: number }[] = [];
    let m;
    while ((m = tagRegex.exec(html)) !== null) {
      tags.push({ tag: m[1], text: cleanHtml(m[2]), index: m.index });
    }

    for (let i = 0; i < tags.length; i++) {
      const t = tags[i];
      // Title is in h2, not a link/tarif/empty
      if (t.tag !== "h2" || !t.text || t.text.length < 3) continue;
      if (/^tarif|^réserv|^http/i.test(t.text)) continue;

      // Look for date in the next h3
      const next = tags[i + 1];
      if (!next || next.tag !== "h3") continue;

      const dateText = next.text;
      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      // "du mardi 16 au samedi 20 septembre" or "du 16 au 20 septembre"
      const rangeMatch = /(?:du\s+)?(?:\w+\s+)?(\d{1,2})\s*(?:au|et)\s*(?:\w+\s+)?(\d{1,2})\s+(\w+)/i.exec(dateText);
      if (rangeMatch) {
        dateDebut = buildIsoDate(rangeMatch[1], rangeMatch[3], year);
        dateFin = buildIsoDate(rangeMatch[2], rangeMatch[3], year);
      }

      // "les jeudi 18 et vendredi 19 décembre"
      if (!dateDebut) {
        const lesMatch = /les?\s+(?:\w+\s+)?(\d{1,2})(?:\s+et\s+(?:\w+\s+)?(\d{1,2}))?\s+(\w+)/i.exec(dateText);
        if (lesMatch) {
          dateDebut = buildIsoDate(lesMatch[1], lesMatch[3], year);
          dateFin = lesMatch[2] ? buildIsoDate(lesMatch[2], lesMatch[3], year) : dateDebut;
        }
      }

      if (!dateDebut || !isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      // Find closest image before this title position
      const beforeChunk = html.substring(Math.max(0, t.index - 800), t.index);
      const pnImgMatch = /<img[^>]*src="([^"]+\.(jpg|jpeg|png|webp))"[^>]*>/gi;
      let pnPhoto = "";
      let pnM;
      while ((pnM = pnImgMatch.exec(beforeChunk)) !== null) {
        if (!pnM[1].includes("logo") && !pnM[1].includes("icon")) pnPhoto = pnM[1];
      }
      if (pnPhoto && !pnPhoto.startsWith("http")) pnPhoto = `https://www.theatredupontneuf.fr${pnPhoto.startsWith("/") ? "" : "/"}${pnPhoto}`;

      const slug = t.text.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `pontneuf_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_pont_neuf", rubrique: "culture",
        nom_de_la_manifestation: t.text,
        descriptif_court: t.text,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        photo_url: pnPhoto,
        lieu_nom: "Theatre du Pont Neuf", lieu_adresse_2: "2 Rue Georges Lardenne",
        commune: "Toulouse", code_postal: 31300,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: "https://www.theatredupontneuf.fr/",
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

    const eventRegex = /<div\s+class="event\s+all[^"]*">([\s\S]*?)<div\s+class="clear"><\/div>\s*<\/div>/g;
    const h2Regex = /<h2[^>]*>(.*?)<\/h2>/s;
    const h4Regex = /<h4[^>]*>(.*?)<\/h4>/s;
    const h5Regex = /<h5[^>]*>(.*?)<\/h5>/gs;
    const linkRegex = /href="([^"]+)"/;
    const imgRegex = /<img[^>]*src="([^"]+)"[^>]*>/;

    let m;
    while ((m = eventRegex.exec(html)) !== null) {
      // Strip HTML comments (hidden English dates are inside <!-- -->)
      const block = m[1].replace(/<!--[\s\S]*?-->/g, "");

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
      const imgMatch = imgRegex.exec(block);
      imgRegex.lastIndex = 0;
      const photoUrl = imgMatch?.[1] ?? "";
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `cavepoesie_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "cave_poesie", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateDebut,
        horaires,
        dates_affichage_horaires: dateRaw,
        photo_url: photoUrl,
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
      // Extract image from <img> in the article card
      const imgMatch = /<img[^>]*src="([^"]+)"[^>]*>/i.exec(block);
      const photoUrl = imgMatch?.[1] ? (imgMatch[1].startsWith("http") ? imgMatch[1] : `https://www.theatregaronne.com${imgMatch[1]}`) : "";
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
        photo_url: photoUrl,
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
    const html = await fetchHtml("https://theatre-cite.com/programmation/");
    const events: ScrapedEvent[] = [];

    // Each card: <a href="...spectacle/..." title="Titre"> ... <div class="programmation-grid__item__date">DATE</div>
    const cardRegex = /<a\s[^>]*href="(https?:\/\/theatre-cite\.com\/[^"]*spectacle\/[^"]*)"[^>]*title="([^"]*)"[^>]*>[\s\S]*?<\/a>/gi;

    // Date patterns inside date block (nbsp cleaned to spaces):
    // "27 février 2026" | "10 – 18 mars 2026" | "31 mars – 3 avril 2026" | "À partir du 10 janvier 2026"
    const singleDateRe = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s+(\d{4})/i;
    const rangesamemonthRe = /(\d{1,2})\s*[–\-]\s*(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s+(\d{4})/i;
    const rangecrossmonthRe = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s*[–\-]\s*(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s+(\d{4})/i;
    const apartirRe = /partir\s+du\s+(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s+(\d{4})/i;

    let m;
    while ((m = cardRegex.exec(html)) !== null) {
      const url = m[1];
      const titre = cleanHtml(m[2]);
      if (!titre) continue;

      // Extract image near this card (background-image or <img src>)
      const before = html.substring(Math.max(0, m.index - 500), m.index);
      const bgImgMatch = /background-image:\s*url\(["']?([^"')]+)["']?\)/i.exec(before) ||
                          /<img[^>]*src="([^"]+)"[^>]*>/i.exec(before);
      const citePhotoUrl = bgImgMatch?.[1] ?? "";

      // Extract date block near this card
      const after = html.substring(m.index, Math.min(m.index + 1500, html.length));
      const dateBlockMatch = /programmation-grid__item__date">([\s\S]*?)<\/div>/i.exec(after);
      if (!dateBlockMatch) continue;

      const dateText = dateBlockMatch[1].replace(/&nbsp;/g, " ").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
      if (!dateText) continue;

      let dateDebut: string | null = null;
      let dateFin: string | null = null;

      // Try cross-month range first: "31 mars – 3 avril 2026"
      let dm = rangecrossmonthRe.exec(dateText);
      if (dm) {
        dateDebut = buildIsoDate(dm[1], dm[2], dm[5]);
        dateFin = buildIsoDate(dm[3], dm[4], dm[5]);
      }

      // Try same-month range: "10 – 18 mars 2026"
      if (!dateDebut) {
        dm = rangesamemonthRe.exec(dateText);
        if (dm) {
          dateDebut = buildIsoDate(dm[1], dm[3], dm[4]);
          dateFin = buildIsoDate(dm[2], dm[3], dm[4]);
        }
      }

      // Try "À partir du": "À partir du 10 janvier 2026"
      if (!dateDebut) {
        dm = apartirRe.exec(dateText);
        if (dm) {
          dateDebut = buildIsoDate(dm[1], dm[2], dm[3]);
          dateFin = dateDebut;
        }
      }

      // Try single date: "27 février 2026"
      if (!dateDebut) {
        dm = singleDateRe.exec(dateText);
        if (dm) {
          dateDebut = buildIsoDate(dm[1], dm[2], dm[3]);
          dateFin = dateDebut;
        }
      }

      if (!dateDebut || !isUpcoming(dateFin ?? dateDebut, dateDebut)) continue;

      // Extract time if present
      const timeMatch = /(\d{1,2}):(\d{2})/.exec(dateText);
      const horaires = timeMatch ? `${timeMatch[1]}h${timeMatch[2]}` : "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `cite_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_cite", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        horaires,
        lieu_nom: "Theatre de la Cite", lieu_adresse_2: "1 Rue Pierre Baudis",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        photo_url: citePhotoUrl,
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
      "https://opera.toulouse.fr/wp-json/wp/v2/onct-events?per_page=50&_fields=id,title,link,meta,_links&_embed=wp:featuredmedia"
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

      // Featured image from _embedded
      const embedded = item._embedded?.["wp:featuredmedia"]?.[0];
      const capitolePhoto = embedded?.source_url ?? embedded?.media_details?.sizes?.medium?.source_url ?? "";

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
        photo_url: capitolePhoto,
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
      const grImgMatch = /<img[^>]*src="([^"]+)"[^>]*>/i.exec(block);
      const grPhotoUrl = grImgMatch?.[1] ? (grImgMatch[1].startsWith("http") ? grImgMatch[1] : `https://www.grand-rond.org${grImgMatch[1]}`) : "";
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `grandrond_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_grand_rond", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin ?? dateDebut,
        photo_url: grPhotoUrl,
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
      const grenierImgMatch = /<img[^>]*src="([^"]+)"[^>]*>/i.exec(block);
      const grenierPhoto = grenierImgMatch?.[1] ?? "";
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `grenier_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "grenier_theatre", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        dates_affichage_horaires: dateRaw,
        photo_url: grenierPhoto,
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
      "https://new.3tcafetheatre.com/wp-json/wp/v2/spectacle?per_page=30&_fields=id,title,link"
    );
    const events: ScrapedEvent[] = [];

    // Abbreviated French months used on 3T detail pages
    const abbrMonths: Record<string, number> = {
      jan: 1, fév: 2, fev: 2, mar: 3, avr: 4, mai: 5, jun: 6, juin: 6,
      jul: 7, juil: 7, aoû: 8, aou: 8, sep: 9, oct: 10, nov: 11, déc: 12, dec: 12,
      ...frenchMonths,
    };

    // Fetch detail pages in parallel (max 15)
    const pages = await Promise.allSettled(
      data.slice(0, 15).map(async (item: any) => {
        const html = await fetchHtml(item.link);
        return { item, html };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { item, html } = result.value;

      const titre = cleanHtml(item.title?.rendered ?? "");
      if (!titre) continue;

      // Extract dates from <span class="deux">27 Fév</span><span class="trois">20h</span>
      const dateSpanRegex = /<span\s+class="deux">(\d{1,2})\s+(\w+)<\/span>\s*<span\s+class="trois">([^<]*)<\/span>/gi;
      const dates: string[] = [];
      let firstTime = "";
      let dm;
      while ((dm = dateSpanRegex.exec(html)) !== null) {
        const day = parseInt(dm[1], 10);
        const monthStr = dm[2].toLowerCase().replace(".", "");
        const month = abbrMonths[monthStr];
        if (!day || !month) continue;

        // Determine year: use frenchDateToIso logic (current or next year)
        const now = new Date();
        let year = now.getFullYear();
        const candidate = new Date(year, month - 1, day);
        const cutoff = new Date(now);
        cutoff.setDate(cutoff.getDate() - 30);
        if (candidate < cutoff) year++;

        const d = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
        if (isFutureDate(d)) {
          dates.push(d);
          if (!firstTime) firstTime = dm[3].trim();
        }
      }

      if (dates.length === 0) continue;
      dates.sort();
      const dateDebut = dates[0];
      const dateFin = dates[dates.length - 1];

      // Extract tarif from data-taro attribute
      const tarifMatch = /data-taro="[^"]*?(\d+\s*€)[^"]*"/i.exec(html);
      const tarif = tarifMatch ? tarifMatch[1] : "";

      // Format time
      const horaires = firstTime.replace(":", "h").replace(/h$/, "h00");

      // Extract og:image from detail page
      const ogImgMatch = /property="og:image"[^>]*content="([^"]+)"/i.exec(html);
      const ttPhoto = ogImgMatch?.[1] ?? "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `3t_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "three_t", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        tarif_normal: tarif,
        photo_url: ttPhoto,
        lieu_nom: "3T Cafe Theatre", lieu_adresse_2: "19 Rue Maran",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: item.link ?? "https://new.3tcafetheatre.com/",
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
      const pavePhoto = item.image?.url ?? "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `pave_${slug}_${startDate}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_du_pave", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: shortDesc || titre,
        descriptif_long: desc || titre,
        date_debut: startDate, date_fin: endDate || startDate,
        photo_url: pavePhoto,
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
    const html = await fetchHtml("https://theatrelefilaplomb.fr/programmation/");
    const events: ScrapedEvent[] = [];

    // Show info is in image title attributes:
    // « La glaneuse – Du mardi 24 au samedi 28 février 2026 à 15h30 » — Théâtre Le Fil à plomb
    const titleRegex = /src="([^"]*)"[^>]*title="([^"]*(?:janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)[^"]*)"/gi;
    const seen = new Set<string>();

    let m;
    while ((m = titleRegex.exec(html)) !== null) {
      const filImgSrc = m[1] || "";
      let raw = m[2]
        .replace(/&amp;/g, "&").replace(/&#8211;/g, "\u2013").replace(/&#8212;/g, "\u2014")
        .replace(/&laquo;|&raquo;|[«»]/g, "").replace(/\u00ab|\u00bb/g, "")
        .replace(/\s*[—–]\s*Th[ée][aâ]tre Le Fil [àa] [Pp]lomb\s*$/, "")
        .trim();
      if (!raw || raw.length < 10) continue;

      // Split title – date info
      // Pattern: "Title – Du jour DD au jour DD mois YYYY à HHhMM"
      // or:      "Title – Le jour DD mois YYYY à HHhMM"
      const dateMatch = raw.match(/^(.+?)\s*[–—-]\s*(?:Du\s+)?(?:\w+\s+)?(\d{1,2})(?:\s+\w+)?\s*(?:au\s+(?:\w+\s+)?(\d{1,2})\s+)?(\w+)\s+(\d{4})(?:\s+[àa]\s+(\d{1,2}h\d{0,2}))?/);
      if (!dateMatch) continue;

      let titre = dateMatch[1].replace(/^(Exposition|Tout Jeune Public\s*:|Apéro-lecture|Apéro-musical)\s*[–—:]\s*/i, "").trim();
      if (!titre || titre.length < 3) continue;
      if (/programmation|podcast|retrouvez/i.test(titre)) continue;

      const dateDebut = buildIsoDate(dateMatch[2], dateMatch[4], dateMatch[5]);
      if (!dateDebut || !isFutureDate(dateDebut)) continue;

      let dateFin = dateDebut;
      if (dateMatch[3]) {
        const fin = buildIsoDate(dateMatch[3], dateMatch[4], dateMatch[5]);
        if (fin) dateFin = fin;
      }

      const horaires = dateMatch[6] ? dateMatch[6].replace(/h$/, "h00") : "";
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const key = `${slug}_${dateDebut}`;
      if (seen.has(key)) continue;
      seen.add(key);

      const filPhoto = filImgSrc.startsWith("http") ? filImgSrc : (filImgSrc ? `https://theatrelefilaplomb.fr${filImgSrc.startsWith("/") ? "" : "/"}${filImgSrc}` : "");

      events.push(makeEvent({
        identifiant: `filaplomb_${slug}_${dateDebut}`, source: "fil_a_plomb", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        photo_url: filPhoto,
        lieu_nom: "Theatre le Fil a Plomb", lieu_adresse_2: "2 Rue du Lieutenant Colonel Pelissier",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: "https://theatrelefilaplomb.fr/programmation/",
      }));
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
        // Image from JSON-LD or og:image
        const metroPhoto = eventData.image?.url ?? eventData.image ?? "";
        const ogImgMatch = /property="og:image"[^>]*content="([^"]+)"/i.exec(detailHtml);
        const metroPhotoUrl = (typeof metroPhoto === "string" && metroPhoto) ? metroPhoto : (ogImgMatch?.[1] ?? "");
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
          photo_url: metroPhotoUrl,
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
    const baseUrl = "https://www.theatredelaviolette.com";
    const events: ScrapedEvent[] = [];

    // Fetch both petits.html (kids) and grands.html (adults) with longer timeout
    const pages = await Promise.allSettled([
      fetchHtml(`${baseUrl}/petits.html`, 15000),
      fetchHtml(`${baseUrl}/grands.html`, 15000),
    ]);

    // Collect show links matching pattern: name-NNN.html
    const showUrls = new Set<string>();
    for (const p of pages) {
      if (p.status !== "fulfilled") continue;
      const linkRegex = /href="([a-z0-9_]+-\d+\.html)"/gi;
      let m;
      while ((m = linkRegex.exec(p.value)) !== null) {
        showUrls.add(`${baseUrl}/${m[1]}`);
      }
    }

    // Fetch detail pages (max 25) with longer timeout
    const detailPages = await Promise.allSettled(
      [...showUrls].slice(0, 25).map(async (url) => {
        const html = await fetchHtml(url, 12000);
        return { url, html };
      })
    );

    for (const result of detailPages) {
      if (result.status !== "fulfilled") continue;
      const { url: pageUrl, html: detailHtml } = result.value;

      // Title from <p class="titre"> + optional subtitle, or og:title
      let titre = "";
      const pTitreMatch = /<p\s+class="titre">(.*?)<\/p>/s.exec(detailHtml);
      if (pTitreMatch) {
        titre = cleanHtml(pTitreMatch[1]);
        const subMatch = /<p\s+class="sousTitre">(.*?)<\/p>/s.exec(detailHtml);
        if (subMatch) {
          const sub = cleanHtml(subMatch[1]);
          if (sub && sub.length > 2) titre += ` - ${sub}`;
        }
      } else {
        const ogMatch = /property="og:title"[^>]*content="([^"]+)"/s.exec(detailHtml);
        titre = ogMatch ? cleanHtml(ogMatch[1]).replace(/^[«»\s]+|[«»\s]+$/g, "") : "";
      }
      if (!titre || titre.length < 3) continue;

      // Find dates from <span class="date"> or French date patterns
      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
      const dates: string[] = [];
      let dm;
      while ((dm = dateRegex.exec(detailHtml)) !== null) {
        const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
        if (d && isFutureDate(d)) dates.push(d);
      }

      if (dates.length === 0) continue;
      dates.sort();

      // Extract og:image or first <img> from detail page
      const violetteOg = /property="og:image"[^>]*content="([^"]+)"/i.exec(detailHtml);
      const violetteImg = /<img[^>]*src="([^"]+\.(jpg|jpeg|png|webp))"[^>]*>/i.exec(detailHtml);
      let violettePhoto = violetteOg?.[1] ?? violetteImg?.[1] ?? "";
      if (violettePhoto && !violettePhoto.startsWith("http")) violettePhoto = `https://www.theatredelaviolette.com/${violettePhoto.replace(/^\//, "")}`;

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `violette_${slug}_${dates[0]}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_violette", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dates[0], date_fin: dates[dates.length - 1],
        photo_url: violettePhoto,
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
    const mainHtml = await fetchHtml("https://theatredepochetoulouse.fr/la-programmation-2/");
    const events: ScrapedEvent[] = [];

    // Collect individual show URLs (not month category pages)
    const showLinkRegex = /href="(https?:\/\/theatredepochetoulouse\.fr\/la-programmation-2\/\w+\/[a-z0-9-]+\/)"/gi;
    const showUrls = new Set<string>();
    let m;
    while ((m = showLinkRegex.exec(mainHtml)) !== null) {
      // Skip month index pages (e.g., /fevrier/ with no show slug)
      const parts = m[1].replace(/\/$/, "").split("/");
      if (parts.length >= 2) showUrls.add(m[1]);
    }

    // Fetch detail pages in parallel (max 25)
    const pages = await Promise.allSettled(
      [...showUrls].slice(0, 25).map(async (url) => {
        const html = await fetchHtml(url);
        return { url, html };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { url, html } = result.value;

      // Title from og:title or h2
      const ogMatch = /property="og:title"[^>]*content="([^"]+)"/.exec(html);
      const h2Match = /<h2[^>]*class="[^"]*wp-block-post-title[^"]*"[^>]*>(.*?)<\/h2>/s.exec(html);
      const titleRaw = ogMatch ? ogMatch[1] : (h2Match ? h2Match[1] : "");
      const titre = cleanHtml(titleRaw).replace(/&#8217;/g, "\u2019").replace(/&rsquo;/g, "\u2019").replace(/&nbsp;/g, " ");
      if (!titre || titre.length < 3) continue;

      // Find French dates in the page
      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
      const dates: string[] = [];
      let dm;
      while ((dm = dateRegex.exec(html)) !== null) {
        const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
        if (d && isFutureDate(d)) dates.push(d);
      }
      if (dates.length === 0) continue;
      dates.sort();

      // Extract time
      const timeMatch = /(\d{1,2}h\d{0,2})/.exec(html);
      const horaires = timeMatch ? timeMatch[1].replace(/h$/, "h00") : "";

      // Extract og:image from detail page
      const pocheOgMatch = /property="og:image"[^>]*content="([^"]+)"/i.exec(html);
      const pochePhoto = pocheOgMatch?.[1] ?? "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `poche_${slug}_${dates[0]}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_de_poche", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dates[0], date_fin: dates[dates.length - 1],
        horaires,
        photo_url: pochePhoto,
        lieu_nom: "Theatre de Poche", lieu_adresse_2: "5 Rue du Taur",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: url,
      }));
    }
    return events;
  } catch (e) { console.error("poche:", e); return []; }
}

// ─────────────────────────────────────────────────────────────
// 16. Theatre du Chien Blanc (Elementor)
// ─────────────────────────────────────────────────────────────
async function scrapeChienBlanc(): Promise<ScrapedEvent[]> {
  try {
    // Use WP REST API to get spectacle list
    const data = await fetchJson<any[]>(
      "https://theatreduchienblanc.fr/wp-json/wp/v2/spectacle?per_page=15&_fields=id,title,link"
    );
    const events: ScrapedEvent[] = [];

    // Fetch detail pages in parallel
    const pages = await Promise.allSettled(
      data.slice(0, 15).map(async (item: any) => {
        const html = await fetchHtml(item.link);
        return { item, html };
      })
    );

    for (const result of pages) {
      if (result.status !== "fulfilled") continue;
      const { item, html } = result.value;

      const titre = cleanHtml(item.title?.rendered ?? "");
      if (!titre) continue;

      const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/gi;
      const dates: string[] = [];
      let dm;
      while ((dm = dateRegex.exec(html)) !== null) {
        const d = frenchDateToIso(`${dm[1]} ${dm[2]}`);
        if (d && isFutureDate(d)) dates.push(d);
      }

      if (dates.length === 0) continue;
      dates.sort();

      const timeMatch = /(\d{1,2}h\d{2})/.exec(html);
      // Extract og:image from detail page
      const cbOgMatch = /property="og:image"[^>]*content="([^"]+)"/i.exec(html);
      const cbPhoto = cbOgMatch?.[1] ?? "";
      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `chienblanc_${slug}_${dates[0]}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_chien_blanc", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dates[0], date_fin: dates[dates.length - 1],
        horaires: timeMatch?.[1] ?? "",
        photo_url: cbPhoto,
        lieu_nom: "Theatre du Chien Blanc", lieu_adresse_2: "18 Rue Belbeze",
        commune: "Toulouse", code_postal: 31000,
        type_de_manifestation: "Theatre", categorie_de_la_manifestation: "Theatre",
        reservation_site_internet: item.link ?? "https://theatreduchienblanc.fr/",
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
      "https://conservatoire.toulouse.fr/wp-json/wp/v2/onct-events?onct-event-lieu=158&per_page=50&_fields=id,title,link,meta,_links&_embed=wp:featuredmedia"
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

      // Featured image from _embedded
      const jjEmbedded = item._embedded?.["wp:featuredmedia"]?.[0];
      const jjPhoto = jjEmbedded?.source_url ?? jjEmbedded?.media_details?.sizes?.medium?.source_url ?? "";

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `julesjulien_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "theatre_jules_julien", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: titre,
        date_debut: dateDebut, date_fin: dateFin,
        horaires,
        photo_url: jjPhoto,
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

    // Abbreviated uppercase French months used on the page
    const abbrMonths: Record<string, string> = {
      "JANV": "01", "JAN": "01", "JANVIER": "01",
      "FEV": "02", "FEVR": "02", "FÉVRIER": "02", "FEVRIER": "02",
      "MARS": "03", "MAR": "03",
      "AVR": "04", "AVRIL": "04",
      "MAI": "05",
      "JUIN": "06",
      "JUIL": "07", "JUILLET": "07",
      "AOÛT": "08", "AOUT": "08",
      "SEPT": "09", "SEPTEMBRE": "09",
      "OCT": "10", "OCTOBRE": "10",
      "NOV": "11", "NOVEMBRE": "11",
      "DEC": "12", "DÉCEMBRE": "12", "DECEMBRE": "12",
    };

    // 1) Collect ALL jpg/png image src with positions, then filter
    const posterImages: { url: string; pos: number }[] = [];
    const allImgRe = /src="(https?:\/\/meett\.fr\/wp-content\/uploads\/[^"]+)"/gi;
    let pi;
    while ((pi = allImgRe.exec(html)) !== null) {
      const u = pi[1].toLowerCase();
      // Keep only real posters (jpg/png), skip svgs, icons, thumbs
      if (!u.endsWith(".jpg") && !u.endsWith(".jpeg") && !u.endsWith(".png") && !u.endsWith(".webp")) continue;
      if (u.includes("elementor") || u.includes("icon") || u.includes("logo") || u.includes("phone") || u.includes("trolley") || u.includes("element-graphique")) continue;
      posterImages.push({ url: pi[1], pos: pi.index });
    }

    // 2) Parse events
    const pattern = /<div class="elementor-widget-container">\s*(\d{1,2})\s+([A-ZÀ-Ü]+)\s*(?:&#8211;|–|-)?[^<]*<\/div>\s*<\/div>\s*(?:<div[^>]*>)?\s*<div class="elementor-widget-container">\s*(\d{1,2})\s+([A-ZÀ-Ü]+)\s+(\d{4})\s*<\/div>.*?<h2[^>]*>(.*?)<\/h2>/gs;

    const seen = new Set<string>();
    let m;
    while ((m = pattern.exec(html)) !== null) {
      const [, day1, month1, day2, month2, year, titleHtml] = m;

      // Find closest preceding poster image (position-based)
      const matchPos = m.index;
      let bestImg = "";
      for (let i = posterImages.length - 1; i >= 0; i--) {
        if (posterImages[i].pos < matchPos) {
          bestImg = posterImages[i].url;
          break;
        }
      }

      const titre = cleanHtml(titleHtml).replace(/\s*~\s*$/, "").trim();
      if (!titre) continue;

      const m1 = abbrMonths[month1.toUpperCase()] ?? null;
      const m2 = abbrMonths[month2.toUpperCase()] ?? null;
      if (!m1 || !m2) continue;

      const dateDebut = `${year}-${m1}-${day1.padStart(2, "0")}`;
      const dateFin = `${year}-${m2}-${day2.padStart(2, "0")}`;

      if (!isFutureDate(dateFin)) continue;

      const key = `${titre}|${dateDebut}`;
      if (seen.has(key)) continue;
      seen.add(key);

      const slug = titre.toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 40);
      const id = `meett_${slug}_${dateDebut}`;

      events.push(makeEvent({
        identifiant: id, source: "meett", rubrique: "culture",
        nom_de_la_manifestation: titre,
        descriptif_court: `Salon/Exposition au MEETT : ${titre}`,
        date_debut: dateDebut, date_fin: dateFin,
        lieu_nom: "MEETT - Parc des Expositions", lieu_adresse_2: "Concorde Avenue",
        commune: "Toulouse", code_postal: 31840,
        type_de_manifestation: "Exposition", categorie_de_la_manifestation: "Exposition",
        reservation_site_internet: "https://www.meett.fr/agenda/",
        photo_url: bestImg,
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

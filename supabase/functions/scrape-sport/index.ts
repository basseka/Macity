// supabase functions deploy scrape-sport --no-verify-jwt
//
// Scrape :
// 1. Galas de boxe depuis galadeboxetoulouse.com + ffboxe.com
// 2. Matchs basketball Toulouse BC depuis nm1.ffbb.com
// 3. Matchs basketball TMB depuis basketlfb.com
// 4. Matchs rugby Stade Toulousain depuis stadetoulousain.fr
// 5. Matchs rugby Colomiers depuis colomiers-rugby.com
// 6. Matchs handball Fenix Toulouse depuis fenix-toulouse.fr
// Upsert dans la table `matchs`.

import { cleanHtml, frenchDateToIso, fetchHtml } from "../_shared/html-utils.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const headers = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};

interface MatchRow {
  sport: string;
  competition: string;
  equipe_dom: string;
  equipe_ext: string;
  date: string;
  heure: string;
  lieu: string;
  ville: string;
  description: string;
  url: string;
  source: string;
  logo_dom?: string;
  logo_ext?: string;
  photo_url?: string;
}

// ─────────────────────────────────────────────────────
// 1. Gala de Boxe
// ─────────────────────────────────────────────────────
async function scrapeGalaBoxe(): Promise<MatchRow[]> {
    const html = await fetchHtml("https://galadeboxetoulouse.com/services/");
    const results: MatchRow[] = [];

    const titleRegex = /<h2[^>]*>(.*?)<\/h2>/s;
    const titleMatch = titleRegex.exec(html);
    const title = titleMatch ? cleanHtml(titleMatch[1]) : "";

    const dateRegex = /(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)/i;
    const dateMatch = dateRegex.exec(html);
    const dateText = dateMatch ? `${dateMatch[1]} ${dateMatch[2]}` : null;
    const dateFormatted = frenchDateToIso(dateText);

    const timeRegex = /(\d{1,2}h\d{2})/;
    const timeMatch = timeRegex.exec(html);
    const heure = timeMatch?.[1] ?? "";

    const venuePatterns = [
      /Ch[aâ]teau\s+[^<,]{3,40}/i,
      /Salle\s+[^<,]{3,40}/i,
      /Palais\s+des\s+Sports[^<,]{0,40}/i,
      /Z[eé]nith[^<,]{0,40}/i,
      /Gymnase\s+[^<,]{3,40}/i,
      /Halle\s+[^<,]{3,40}/i,
    ];
    let lieu = "";
    for (const p of venuePatterns) {
      const m = p.exec(html);
      if (m) { lieu = cleanHtml(m[0].trim()); break; }
    }

    const billetterieRegex = /href="(https?:\/\/[^"]*)"[^>]*>[^<]*[Bb]illetterie/;
    const billetterieMatch = billetterieRegex.exec(html);
    const billetterie = billetterieMatch?.[1] ?? "";

    const tarifRegex = /(\d+\s*€)/;
    const tarifMatch = tarifRegex.exec(html);
    const tarif = tarifMatch?.[1] ?? "";

    const adresseRegex = /(\d+[^<]*\d{5}[^<]*)/;
    const adresseMatch = adresseRegex.exec(html);
    const adresse = adresseMatch?.[1] ?? "";

    // Photo: first large image in content
    const imgRegex = /<img[^>]*src="(https?:\/\/[^"]+\.(?:jpg|jpeg|png|webp))"[^>]*>/gi;
    let photoUrl = "";
    for (const imgM of html.matchAll(imgRegex)) {
      const src = imgM[1];
      // Skip tiny icons/logos
      if (src.includes("logo") || src.includes("favicon") || src.includes("icon")) continue;
      photoUrl = src;
      break;
    }

    if (title && dateFormatted) {
      const description = [
        "Gala de boxe professionnelle",
        adresse ? `- ${adresse}` : "",
        tarif ? `- A partir de ${tarif}` : "",
      ].filter(Boolean).join(" ");

      results.push({
        sport: "Boxe",
        competition: title,
        equipe_dom: "",
        equipe_ext: "",
        date: dateFormatted,
        heure,
        lieu,
        ville: "Toulouse",
        description,
        url: billetterie,
        source: "galadeboxetoulouse.com",
        photo_url: photoUrl,
      });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// 1b. FFBoxe événements (ffboxe.com)
// ─────────────────────────────────────────────────────
async function scrapeFFBoxe(): Promise<MatchRow[]> {
  const results: MatchRow[] = [];

  // Fetch listing pages to get event URLs
  const eventUrls: string[] = [];
  for (let page = 1; page <= 3; page++) {
    const listUrl = page === 1
      ? "https://www.ffboxe.com/evenements/"
      : `https://www.ffboxe.com/evenements/page/${page}/`;
    const listHtml = await fetchHtml(listUrl, 15000).catch(() => "");
    if (!listHtml) break;
    // Match event URLs (case-insensitive slugs)
    const linkMatches = listHtml.matchAll(/href="(https:\/\/www\.ffboxe\.com\/evenements\/[a-zA-Z0-9_-]+\/)"/gi);
    for (const m of linkMatches) {
      if (!m[1].includes("/page/") && !m[1].endsWith("/feed/") && !eventUrls.includes(m[1])) {
        eventUrls.push(m[1]);
      }
    }
  }

  console.log(`ffboxe: found ${eventUrls.length} event URLs: ${eventUrls.join(", ")}`);

  // Fetch each event page (max 20, sequential to avoid rate limiting)
  const pages: { url: string; html: string }[] = [];
  for (const u of eventUrls.slice(0, 20)) {
    try {
      const html = await fetchHtml(u, 15000);
      pages.push({ url: u, html });
    } catch {
      pages.push({ url: u, html: "" });
    }
  }

  const ffbMonths: Record<string, string> = {
    jan: "01", feb: "02", mar: "03", apr: "04", may: "05", jun: "06",
    jul: "07", aug: "08", sep: "09", oct: "10", nov: "11", dec: "12",
  };

  for (const { url, html } of pages) {
    if (!html) continue;

    // Title — use page-title class to avoid matching mobile menu h1
    const titleMatch = html.match(/<h1[^>]*page-title[^>]*>(?:<span[^>]*>)?\s*(.*?)\s*(?:<\/span>)?<\/h1>/s);
    const title = titleMatch ? cleanHtml(titleMatch[1]) : "";
    if (!title) {
      console.log(`ffboxe: no title found for ${url}`);
      continue;
    }

    // Date: "25 Apr 2026" format
    const dateMatch = html.match(/Date de l[^<]*<span[^>]*>\s*(\d{1,2})\s+(\w{3})\s+(\d{4})/);
    if (!dateMatch) {
      console.log(`ffboxe: no date found for ${url} (title: ${title})`);
      continue;
    }
    const day = dateMatch[1].padStart(2, "0");
    const monthKey = dateMatch[2].toLowerCase();
    const month = ffbMonths[monthKey];
    const year = dateMatch[3];
    if (!month) {
      console.log(`ffboxe: unknown month '${dateMatch[2]}' for ${url}`);
      continue;
    }
    const dateStr = `${year}-${month}-${day}`;

    // Skip past events
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (new Date(dateStr) < today) continue;

    // Location
    const lieuMatch = html.match(/Lieu[^<]*<span[^>]*>\s*(.*?)\s*<\/span>/s);
    const lieu = lieuMatch ? cleanHtml(lieuMatch[1]) : "";

    // Image
    const imgMatch = html.match(/body-event[\s\S]*?<img[^>]*src="([^"]+)"/);
    const photoUrl = imgMatch?.[1] ?? "";

    results.push({
      sport: "Boxe",
      competition: title,
      equipe_dom: "",
      equipe_ext: "",
      date: dateStr,
      heure: "",
      lieu,
      ville: "",
      description: `Événement FFBoxe - ${title}`,
      url,
      source: "ffboxe.com",
      photo_url: photoUrl,
    });
  }

  console.log(`ffboxe: ${results.length} future events`);
  return results;
}

// ─────────────────────────────────────────────────────
// 2. Basketball — Toulouse BC (NM1 FFBB)
// ─────────────────────────────────────────────────────
async function scrapeToulouseBasketball(): Promise<MatchRow[]> {
    const html = await fetchHtml(
      "https://nm1.ffbb.com/equipe/calendrier/1844-toulouse-basketball-club",
      8000,
    );
    const results: MatchRow[] = [];

    // The FFBB page renders match rows in HTML.
    // Each match block contains: date (DD/MM), time (HH:MM), teams, score, venue.
    // Pattern: look for match rows with date + team names.
    //
    // Format attendu dans le HTML :
    //   <span class="date">DD/MM</span> ... <span class="time">HH:MM</span>
    //   equipe_dom ... vs ... equipe_ext
    //
    // On parse toutes les lignes contenant "Toulouse" avec une date.

    // Strategy: extract all match blocks.
    // FFBB uses a pattern like: DD/MM HH:MM EquipeDom Score EquipeExt
    // The HTML structure varies, so we use a broad regex approach.

    // Look for date patterns DD/MM followed by time HH:MM and team names
    const matchRegex = /(\d{2})\/(\d{2})\s+(\d{2}:\d{2})\s+(.*?)\s+(?:\d+\s*-\s*\d+|vs\.?)\s+(.*?)(?:\n|<)/gi;

    let match;
    while ((match = matchRegex.exec(html)) !== null) {
      const [, day, month, time, team1Raw, team2Raw] = match;
      const team1 = cleanHtml(team1Raw).trim();
      const team2 = cleanHtml(team2Raw).trim();

      // Only keep matches involving Toulouse
      if (!team1.toLowerCase().includes("toulouse") && !team2.toLowerCase().includes("toulouse")) continue;

      // Build date — assume current season (sept-aug)
      const now = new Date();
      const m = parseInt(month, 10);
      let year = now.getFullYear();
      // If month is sept-dec and we're in jan-aug, it was last year
      if (m >= 9 && now.getMonth() < 8) year--;
      // If month is jan-aug and we're in sept-dec, it's next year
      if (m <= 8 && now.getMonth() >= 8) year++;

      const dateStr = `${year}-${month}-${day}`;
      const heure = time.replace(":", "h");

      // Determine home/away — first team is home on FFBB
      const isHome = team1.toLowerCase().includes("toulouse");

      results.push({
        sport: "Basketball",
        competition: "NM1",
        equipe_dom: team1,
        equipe_ext: team2,
        date: dateStr,
        heure,
        lieu: isHome ? "Palais des Sports Andre Brouat" : "",
        ville: isHome ? "Toulouse" : "",
        description: `NM1 - ${team1} vs ${team2}`,
        url: "https://toulousebasketballclub.billetterie-club.fr/home",
        source: "nm1.ffbb.com",
      });
    }

    // Alternative parsing: look for structured match data in JSON-LD or embedded data
    // FFBB sometimes embeds match data in script tags
    const jsonRegex = /\{[^{}]*"equipe_dom"[^{}]*"equipe_ext"[^{}]*\}/g;
    let jsonMatch;
    while ((jsonMatch = jsonRegex.exec(html)) !== null) {
      try {
        const data = JSON.parse(jsonMatch[0]);
        if (data.equipe_dom && data.date) {
          const team1 = cleanHtml(data.equipe_dom);
          const team2 = cleanHtml(data.equipe_ext || "");
          if (!team1.toLowerCase().includes("toulouse") && !team2.toLowerCase().includes("toulouse")) continue;

          const isHome = team1.toLowerCase().includes("toulouse");
          results.push({
            sport: "Basketball",
            competition: data.competition || "NM1",
            equipe_dom: team1,
            equipe_ext: team2,
            date: data.date,
            heure: data.heure || "",
            lieu: isHome ? "Palais des Sports Andre Brouat" : (data.lieu || ""),
            ville: isHome ? "Toulouse" : (data.ville || ""),
            description: `NM1 - ${team1} vs ${team2}`,
            url: "https://toulousebasketballclub.billetterie-club.fr/home",
            source: "nm1.ffbb.com",
          });
        }
      } catch { /* ignore invalid JSON */ }
    }

    // Alternative: parse table rows or list items with Toulouse
    // Look for patterns like: "Journée X" ... date ... "Toulouse" ... opponent
    const journeeRegex = /Journ[eé]e\s+(\d+).*?(\d{2})\/(\d{2}).*?(\d{2}:\d{2}).*?(?:(\S[^<\n]+?)\s+(?:\d+-\d+|\s+)\s+(\S[^<\n]+?))\s*(?:<|$)/gis;
    while ((match = journeeRegex.exec(html)) !== null) {
      const [, journee, day, month, time, t1Raw, t2Raw] = match;
      const t1 = cleanHtml(t1Raw).trim();
      const t2 = cleanHtml(t2Raw).trim();
      if (!t1.toLowerCase().includes("toulouse") && !t2.toLowerCase().includes("toulouse")) continue;

      const m = parseInt(month, 10);
      const now = new Date();
      let year = now.getFullYear();
      if (m >= 9 && now.getMonth() < 8) year--;
      if (m <= 8 && now.getMonth() >= 8) year++;

      const dateStr = `${year}-${month}-${day}`;
      const isHome = t1.toLowerCase().includes("toulouse");

      // Avoid duplicates
      if (results.some(r => r.date === dateStr && r.equipe_dom === t1)) continue;

      results.push({
        sport: "Basketball",
        competition: `NM1 - Journee ${journee}`,
        equipe_dom: t1,
        equipe_ext: t2,
        date: dateStr,
        heure: time.replace(":", "h"),
        lieu: isHome ? "Palais des Sports Andre Brouat" : "",
        ville: isHome ? "Toulouse" : "",
        description: `NM1 Journee ${journee} - ${t1} vs ${t2}`,
        url: "https://toulousebasketballclub.billetterie-club.fr/home",
        source: "nm1.ffbb.com",
      });
    }

    // Filter: keep only upcoming matches
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// 3. Basketball — TMB Toulouse Metropole Basket (LFB)
// ─────────────────────────────────────────────────────
async function scrapeTMB(): Promise<MatchRow[]> {
    const html = await fetchHtml(
      "https://basketlfb.com/equipe/calendrier/446-toulouse",
      8000,
    );
    const results: MatchRow[] = [];

    // The LFB page lists matches with dates DD/MM/YYYY, times HH:MM, and team names.
    // Parse match rows: date, time, home team, score, away team
    // Pattern: DD/MM/YYYY HH:MM TeamDom score TeamExt
    const matchRegex = /(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}:\d{2})\s+(.*?)\s+(?:(\d+)\s*-\s*(\d+)|\u2014|—)\s+(.*?)(?:\s*$|\s*<)/gm;

    let match;
    while ((match = matchRegex.exec(html)) !== null) {
      const [, day, month, year, time, t1Raw, score1, score2, t2Raw] = match;
      const t1 = cleanHtml(t1Raw).trim();
      const t2 = cleanHtml(t2Raw).trim();

      if (!t1.toLowerCase().includes("toulouse") && !t2.toLowerCase().includes("toulouse")) continue;

      // Skip matches already played (have a score)
      if (score1 && score2) continue;

      const dateStr = `${year}-${month}-${day}`;
      const isHome = t1.toLowerCase().includes("toulouse");

      results.push({
        sport: "Basketball",
        competition: "LFB - La Boulangere Wonderligue",
        equipe_dom: t1,
        equipe_ext: t2,
        date: dateStr,
        heure: time.replace(":", "h"),
        lieu: isHome ? "Gymnase Compans-Caffarelli" : "",
        ville: isHome ? "Toulouse" : "",
        description: `LFB - ${t1} vs ${t2}`,
        url: "https://www.tmb-basket.com/programmes",
        source: "basketlfb.com",
      });
    }

    // Alternative: broader match parsing
    // Look for lines with Toulouse and a date pattern
    const lines = html.split(/\n/);
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const dateM = line.match(/(\d{2})\/(\d{2})\/(\d{4})/);
      if (!dateM) continue;

      const timeM = line.match(/(\d{2}:\d{2})/);
      const [, day, month, year] = dateM;
      const dateStr = `${year}-${month}-${day}`;

      // Check if this line or nearby lines mention Toulouse
      const context = lines.slice(Math.max(0, i - 2), i + 3).join(" ");
      if (!context.toLowerCase().includes("toulouse")) continue;

      // Skip if already have this date
      if (results.some(r => r.date === dateStr)) continue;

      // Try to extract team names around Toulouse mention
      const teamsM = context.match(/([A-ZÀ-Ü][a-zà-ü'\-\s]+(?:d'[A-Za-z]+)?)\s+(?:\d+-\d+|—|\u2014)\s+([A-ZÀ-Ü][a-zà-ü'\-\s]+(?:d'[A-Za-z]+)?)/);
      if (!teamsM) continue;

      const t1 = cleanHtml(teamsM[1]).trim();
      const t2 = cleanHtml(teamsM[2]).trim();

      // Skip if score present (already played)
      if (context.match(new RegExp(`${t1}.*\\d+\\s*-\\s*\\d+.*${t2}`))) continue;

      const isHome = t1.toLowerCase().includes("toulouse");

      results.push({
        sport: "Basketball",
        competition: "LFB - La Boulangere Wonderligue",
        equipe_dom: t1,
        equipe_ext: t2,
        date: dateStr,
        heure: timeM ? timeM[1].replace(":", "h") : "20h00",
        lieu: isHome ? "Gymnase Compans-Caffarelli" : "",
        ville: isHome ? "Toulouse" : "",
        description: `LFB - ${t1} vs ${t2}`,
        url: "https://www.tmb-basket.com/programmes",
        source: "basketlfb.com",
      });
    }

    // Filter: keep only upcoming matches
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// 4. Rugby — Stade Toulousain (Top 14 + Champions Cup)
// ─────────────────────────────────────────────────────
async function scrapeStadeToulousain(): Promise<MatchRow[]> {
    const html = await fetchHtml(
      "https://www.stadetoulousain.fr/equipe/equipe-pro/calendrier",
      8000,
    );
    const results: MatchRow[] = [];

    // The page embeds match data in structured HTML.
    // Each match has: date, time, home club, away club, competition, venue, ticket link.
    // We look for date patterns and nearby team/competition info.

    // Strategy 1: Look for embedded JSON match data in script tags
    const scriptRegex = /<script[^>]*>([\s\S]*?)<\/script>/gi;
    let scriptMatch;
    while ((scriptMatch = scriptRegex.exec(html)) !== null) {
      const content = scriptMatch[1];
      // Look for match objects with field_date
      const matchObjRegex = /\{[^{}]*"field_date"[^{}]*\}/g;
      let objMatch;
      while ((objMatch = matchObjRegex.exec(content)) !== null) {
        try {
          const data = JSON.parse(objMatch[0]);
          if (!data.field_date) continue;

          const home = cleanHtml(data.field_home_club || "");
          const away = cleanHtml(data.field_away_club || "");
          const competition = cleanHtml(data.field_competition || "");
          const lieu = cleanHtml(data.field_place || "");
          const ticketUrl = data.field_link || "";

          // Parse date from ISO or other format
          const dt = new Date(data.field_date);
          if (isNaN(dt.getTime())) continue;

          const dateStr = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
          const heure = `${String(dt.getHours()).padStart(2, "0")}h${String(dt.getMinutes()).padStart(2, "0")}`;

          const isHome = home.toLowerCase().includes("toulousain") || home.toLowerCase().includes("stade toulousain");

          results.push({
            sport: "Rugby",
            competition,
            equipe_dom: home,
            equipe_ext: away,
            date: dateStr,
            heure,
            lieu: lieu || (isHome ? "Stade Ernest-Wallon" : ""),
            ville: isHome ? "Toulouse" : "",
            description: `${competition} - ${home} vs ${away}`,
            url: ticketUrl || "https://billetterie.stadetoulousain.fr/fr/calendrier",
            source: "stadetoulousain.fr",
          });
        } catch { /* ignore */ }
      }
    }

    // Strategy 2: Parse HTML match blocks
    // Look for date patterns like "22/03/2026" or "2026-03-22" near team names
    const htmlMatchRegex = /(\d{2})\/(\d{2})\/(\d{4})\s*(?:.*?)(\d{2}:\d{2}|\d{2}h\d{2})?/g;
    let hMatch;
    while ((hMatch = htmlMatchRegex.exec(html)) !== null) {
      const [fullMatch, day, month, year, time] = hMatch;
      const dateStr = `${year}-${month}-${day}`;

      // Skip if already found via JSON
      if (results.some(r => r.date === dateStr)) continue;

      // Check surrounding context for team names
      const start = Math.max(0, hMatch.index - 200);
      const end = Math.min(html.length, hMatch.index + 500);
      const context = html.substring(start, end);

      if (!context.toLowerCase().includes("toulousain")) continue;

      // Try to extract teams
      const teamPatterns = [
        /Stade\s+Toulousain/i,
        /Toulouse/i,
      ];
      const hasSTMatch = teamPatterns.some(p => p.test(context));
      if (!hasSTMatch) continue;

      // Extract opponent — look for known Top 14 teams
      const top14Teams = [
        "Racing 92", "Stade Francais", "La Rochelle", "Stade Rochelais",
        "Clermont", "ASM", "Montpellier", "MHR", "Bordeaux", "UBB",
        "Castres", "Toulon", "RC Toulon", "Lyon", "LOU", "Bayonne",
        "Aviron Bayonnais", "Perpignan", "USAP", "Pau", "Section Paloise",
        "Vannes", "RC Vannes", "Bristol", "Leinster", "Northampton",
        "Sharks", "Sale Sharks", "Saracens", "Glasgow", "Bulls",
        "Munster", "La Rochelle", "Leicester",
      ];

      let opponent = "";
      for (const team of top14Teams) {
        if (context.toLowerCase().includes(team.toLowerCase())) {
          opponent = team;
          break;
        }
      }

      if (!opponent) continue;

      const isHome = context.indexOf("Toulousain") < context.indexOf(opponent) ||
                     context.indexOf("Toulouse") < context.indexOf(opponent);

      const heure = time ? time.replace(":", "h") : "";

      results.push({
        sport: "Rugby",
        competition: "Top 14",
        equipe_dom: isHome ? "Stade Toulousain" : opponent,
        equipe_ext: isHome ? opponent : "Stade Toulousain",
        date: dateStr,
        heure,
        lieu: isHome ? "Stade Ernest-Wallon" : "",
        ville: isHome ? "Toulouse" : "",
        description: `Top 14 - ${isHome ? "Stade Toulousain" : opponent} vs ${isHome ? opponent : "Stade Toulousain"}`,
        url: "https://billetterie.stadetoulousain.fr/fr/calendrier",
        source: "stadetoulousain.fr",
      });
    }

    // Filter: keep only upcoming matches
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// 5. Rugby — Colomiers Rugby (Pro D2)
// ─────────────────────────────────────────────────────
async function scrapeColomiers(): Promise<MatchRow[]> {
    const html = await fetchHtml(
      "https://colomiers-rugby.com/calendrier/",
      8000,
    );
    const results: MatchRow[] = [];

    // Month mapping (French + English, full + short forms)
    const monthMap: Record<string, string> = {
      janvier: "01", février: "02", mars: "03", avril: "04",
      mai: "05", juin: "06", juillet: "07", août: "08",
      septembre: "09", octobre: "10", novembre: "11", décembre: "12",
      january: "01", february: "02", march: "03", april: "04",
      may: "05", june: "06", july: "07", august: "08",
      september: "09", october: "10", november: "11", december: "12",
      jan: "01", feb: "02", mar: "03", apr: "04",
      jun: "06", jul: "07", aug: "08", sep: "09",
      oct: "10", nov: "11", dec: "12",
    };

    // Known Pro D2 team names for matching
    const proD2Teams = [
      "Mont-de-Marsan", "Biarritz", "Oyonnax", "Aurillac",
      "Soyaux-Angoulême", "Angoulême", "Agen", "Carcassonne",
      "Vannes", "Béziers", "Beziers", "Provence Rugby", "Provence",
      "Nevers", "Brive", "Grenoble", "Dax", "Valence-Romans",
      "Valence Romans", "Rouen",
    ];

    // Strategy 1: Look for embedded JSON data in script tags
    const scriptRegex = /<script[^>]*>([\s\S]*?)<\/script>/gi;
    let scriptMatch;
    while ((scriptMatch = scriptRegex.exec(html)) !== null) {
      const content = scriptMatch[1];
      // Look for match/event arrays
      const arrayRegex = /\[(\{[^[\]]*"date"[^[\]]*\}(?:,\s*\{[^[\]]*\})*)\]/g;
      let arrMatch;
      while ((arrMatch = arrayRegex.exec(content)) !== null) {
        try {
          const arr = JSON.parse(`[${arrMatch[1]}]`);
          for (const item of arr) {
            if (!item.date) continue;
            const dt = new Date(item.date);
            if (isNaN(dt.getTime())) continue;

            const home = cleanHtml(item.home || item.equipe_dom || item.team_home || "");
            const away = cleanHtml(item.away || item.equipe_ext || item.team_away || "");

            if (!home.toLowerCase().includes("colomiers") &&
                !away.toLowerCase().includes("colomiers")) continue;

            const dateStr = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
            const heure = `${String(dt.getHours()).padStart(2, "0")}h${String(dt.getMinutes()).padStart(2, "0")}`;
            const isHome = home.toLowerCase().includes("colomiers");

            results.push({
              sport: "Rugby",
              competition: "Pro D2",
              equipe_dom: home,
              equipe_ext: away,
              date: dateStr,
              heure,
              lieu: isHome ? "Stade Michel-Bendichou" : (item.venue || item.lieu || ""),
              ville: isHome ? "Colomiers" : "",
              description: `Pro D2 - ${home} vs ${away}`,
              url: "https://billetterie.colomiersrugby.com",
              source: "colomiers-rugby.com",
            });
          }
        } catch { /* ignore invalid JSON */ }
      }
    }

    // Strategy 2: Parse HTML match blocks
    // Pattern: day number + month name, then time, then teams with "vs", then venue
    // The page shows blocks like:
    //   <h3>29</h3> <span>août</span> <span>19:30</span>
    //   Team A vs. Colomiers Rugby
    //   Stade ...
    const blockRegex = /(\d{1,2})\s*(?:<[^>]*>)*\s*(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre|jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b.*?(\d{1,2})[h:](\d{2}).*?((?:Colomiers|[\w\-]+(?:\s+[\w\-]+){0,3})\s+vs\.?\s+(?:Colomiers|[\w\-]+(?:\s+[\w\-]+){0,3})).*?(?:[Ss]tade\s+([\w\-\s'.]+?)(?:<|$|\n))?/gis;

    let bMatch;
    while ((bMatch = blockRegex.exec(html)) !== null) {
      const [, dayStr, monthRaw, hourStr, minStr, teamsRaw, venueRaw] = bMatch;
      const day = dayStr.padStart(2, "0");
      const monthKey = monthRaw.toLowerCase().replace("û", "u").replace("é", "e");
      const month = monthMap[monthKey];
      if (!month) continue;

      // Determine year from season context (Aug-Dec = 2025, Jan-May = 2026)
      const m = parseInt(month, 10);
      const now = new Date();
      let year = now.getFullYear();
      if (m >= 8 && now.getMonth() < 7) year--;
      if (m <= 7 && now.getMonth() >= 7) year++;

      const dateStr = `${year}-${month}-${day}`;
      const heure = `${hourStr.padStart(2, "0")}h${minStr}`;

      // Parse teams from "TeamA vs. TeamB"
      const teams = teamsRaw.split(/\s+vs\.?\s+/i);
      if (teams.length < 2) continue;
      const t1 = cleanHtml(teams[0]).trim();
      const t2 = cleanHtml(teams[1]).trim();

      // Skip if already found
      if (results.some(r => r.date === dateStr)) continue;

      const isHome = t1.toLowerCase().includes("colomiers");
      const venue = venueRaw ? cleanHtml(venueRaw).trim() : "";

      results.push({
        sport: "Rugby",
        competition: "Pro D2",
        equipe_dom: t1,
        equipe_ext: t2,
        date: dateStr,
        heure,
        lieu: venue || (isHome ? "Stade Michel-Bendichou" : ""),
        ville: isHome ? "Colomiers" : "",
        description: `Pro D2 - ${t1} vs ${t2}`,
        url: "https://billetterie.colomiersrugby.com",
        source: "colomiers-rugby.com",
      });
    }

    // Strategy 3: Line-by-line search for Colomiers matches with date patterns
    if (results.length === 0) {
      const dateRegex = /(\d{1,2})\s*(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*/gi;
      let dMatch;
      while ((dMatch = dateRegex.exec(html)) !== null) {
        const day = dMatch[1].padStart(2, "0");
        const monthKey = dMatch[2].toLowerCase().replace("û", "u").replace("é", "e");
        const month = monthMap[monthKey];
        if (!month) continue;

        const m = parseInt(month, 10);
        const now = new Date();
        let year = now.getFullYear();
        if (m >= 8 && now.getMonth() < 7) year--;
        if (m <= 7 && now.getMonth() >= 7) year++;
        const dateStr = `${year}-${month}-${day}`;

        // Check context around this date for Colomiers and opponent
        const start = Math.max(0, dMatch.index - 100);
        const end = Math.min(html.length, dMatch.index + 600);
        const context = html.substring(start, end);

        if (!context.toLowerCase().includes("colomiers")) continue;
        if (results.some(r => r.date === dateStr)) continue;

        // Extract time
        const timeM = context.match(/(\d{1,2})[h:](\d{2})/);
        const heure = timeM ? `${timeM[1].padStart(2, "0")}h${timeM[2]}` : "";

        // Find opponent from known Pro D2 teams
        let opponent = "";
        for (const team of proD2Teams) {
          if (context.toLowerCase().includes(team.toLowerCase())) {
            opponent = team;
            break;
          }
        }
        if (!opponent) continue;

        // Determine home/away
        const colIdx = context.toLowerCase().indexOf("colomiers");
        const oppIdx = context.toLowerCase().indexOf(opponent.toLowerCase());
        const isHome = colIdx < oppIdx;

        results.push({
          sport: "Rugby",
          competition: "Pro D2",
          equipe_dom: isHome ? "Colomiers Rugby" : opponent,
          equipe_ext: isHome ? opponent : "Colomiers Rugby",
          date: dateStr,
          heure,
          lieu: isHome ? "Stade Michel-Bendichou" : "",
          ville: isHome ? "Colomiers" : "",
          description: `Pro D2 - ${isHome ? "Colomiers Rugby" : opponent} vs ${isHome ? opponent : "Colomiers Rugby"}`,
          url: "https://billetterie.colomiersrugby.com",
          source: "colomiers-rugby.com",
        });
      }
    }

    // Filter: keep only upcoming matches
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// 6. Handball — Fenix Toulouse (Liqui Moly StarLigue)
// ─────────────────────────────────────────────────────
async function scrapeFenixToulouse(): Promise<MatchRow[]> {
    const html = await fetchHtml(
      "https://www.fenix-toulouse.fr/equipes/calendrier",
      8000,
    );
    const results: MatchRow[] = [];

    // The page lists matches by month with date DD/MM/YYYY, time HH:MM,
    // team names, scores (or "-- - --" for upcoming), and competition label.
    // Competitions: "Liqui Moly StarLigue", "EHF European League", "Coupe de France"

    // Strategy 1: Look for date patterns DD/MM/YYYY near "Toulouse" with match context
    const dateRegex = /(\d{2})\/(\d{2})\/(\d{4})/g;
    let dMatch;
    while ((dMatch = dateRegex.exec(html)) !== null) {
      const [, day, month, year] = dMatch;
      const dateStr = `${year}-${month}-${day}`;

      // Get surrounding context (before and after)
      const start = Math.max(0, dMatch.index - 500);
      const end = Math.min(html.length, dMatch.index + 500);
      const context = html.substring(start, end);

      // Must involve Toulouse / Fenix
      if (!context.toLowerCase().includes("toulouse") &&
          !context.toLowerCase().includes("fenix")) continue;

      // Skip if already have this date
      if (results.some(r => r.date === dateStr)) continue;

      // Check if match is already played (has a numeric score like "23-29")
      // Upcoming matches show "-- - --" or no score
      const scoreNearDate = context.match(/(\d{1,3})\s*-\s*(\d{1,3})/);
      // If a real score is found very close to the date, it's likely played
      // We'll still include it and let the date filter remove past matches

      // Extract time
      const timeM = context.match(/(\d{2}):(\d{2})/);
      const heure = timeM ? `${timeM[1]}h${timeM[2]}` : "";

      // Detect competition
      let competition = "Liqui Moly StarLigue";
      if (context.toLowerCase().includes("european league") ||
          context.toLowerCase().includes("ehf")) {
        competition = "EHF European League";
      } else if (context.toLowerCase().includes("coupe de france")) {
        competition = "Coupe de France";
      }

      // Known Starligue teams for opponent detection
      const starligueTeams = [
        "Paris Saint-Germain", "PSG", "Montpellier", "Nantes", "HBC Nantes",
        "Aix", "PAUC", "Nîmes", "Nimes", "Chambéry", "Chambery",
        "Dunkerque", "Limoges", "Chartres", "Créteil", "Creteil",
        "Istres", "Cesson-Rennes", "Cesson", "Sélestat", "Selestat",
        "Saint-Raphaël", "Saint-Raphael", "Tremblay",
        "Ivry", "Saran",
      ];

      let opponent = "";
      for (const team of starligueTeams) {
        if (context.toLowerCase().includes(team.toLowerCase())) {
          opponent = team;
          break;
        }
      }

      // For EHF matches, try to find foreign team names
      if (!opponent && competition === "EHF European League") {
        // Look for team names around vs or - patterns
        const vsMatch = context.match(/(?:Toulouse|Fenix)[^<]*?(?:vs\.?|-)\s*([A-ZÀ-Ü][\w\s\-'.]+)/i);
        if (vsMatch) opponent = cleanHtml(vsMatch[1]).trim();
        if (!opponent) {
          const vsMatch2 = context.match(/([A-ZÀ-Ü][\w\s\-'.]+?)\s*(?:vs\.?|-)\s*(?:Toulouse|Fenix)/i);
          if (vsMatch2) opponent = cleanHtml(vsMatch2[1]).trim();
        }
      }

      if (!opponent) continue;

      // Determine home/away based on position of Toulouse vs opponent in context
      const toulouseIdx = Math.min(
        context.toLowerCase().indexOf("toulouse") === -1 ? Infinity : context.toLowerCase().indexOf("toulouse"),
        context.toLowerCase().indexOf("fenix") === -1 ? Infinity : context.toLowerCase().indexOf("fenix"),
      );
      const oppIdx = context.toLowerCase().indexOf(opponent.toLowerCase());
      const isHome = toulouseIdx < oppIdx;

      results.push({
        sport: "Handball",
        competition,
        equipe_dom: isHome ? "Fenix Toulouse" : opponent,
        equipe_ext: isHome ? opponent : "Fenix Toulouse",
        date: dateStr,
        heure,
        lieu: isHome ? "Palais des Sports Andre Brouat" : "",
        ville: isHome ? "Toulouse" : "",
        description: `${competition} - ${isHome ? "Fenix Toulouse" : opponent} vs ${isHome ? opponent : "Fenix Toulouse"}`,
        url: "https://billetterie.fenix-toulouse.fr",
        source: "fenix-toulouse.fr",
      });
    }

    // Strategy 2: Look for "vs" or "vs." patterns with Toulouse
    const vsRegex = /([\w\s\-'À-ü]+?)\s+(?:\d+\s*-\s*\d+|--\s*-\s*--)\s+([\w\s\-'À-ü]+)/g;
    let vsMatch;
    while ((vsMatch = vsRegex.exec(html)) !== null) {
      const t1 = cleanHtml(vsMatch[1]).trim();
      const t2 = cleanHtml(vsMatch[2]).trim();

      if (!t1.toLowerCase().includes("toulouse") &&
          !t2.toLowerCase().includes("toulouse") &&
          !t1.toLowerCase().includes("fenix") &&
          !t2.toLowerCase().includes("fenix")) continue;

      // Find nearest date before this match
      const before = html.substring(Math.max(0, vsMatch.index - 300), vsMatch.index);
      const dateM = before.match(/(\d{2})\/(\d{2})\/(\d{4})/);
      if (!dateM) continue;

      const [, day, month, year] = dateM;
      const dateStr = `${year}-${month}-${day}`;

      if (results.some(r => r.date === dateStr)) continue;

      const timeM = before.match(/(\d{2}):(\d{2})/);
      const heure = timeM ? `${timeM[1]}h${timeM[2]}` : "";

      const isHome = t1.toLowerCase().includes("toulouse") || t1.toLowerCase().includes("fenix");

      results.push({
        sport: "Handball",
        competition: "Liqui Moly StarLigue",
        equipe_dom: t1,
        equipe_ext: t2,
        date: dateStr,
        heure,
        lieu: isHome ? "Palais des Sports Andre Brouat" : "",
        ville: isHome ? "Toulouse" : "",
        description: `Liqui Moly StarLigue - ${t1} vs ${t2}`,
        url: "https://billetterie.fenix-toulouse.fr",
        source: "fenix-toulouse.fr",
      });
    }

    // Filter: keep only upcoming matches
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return results.filter(m => {
      const d = new Date(m.date);
      return !isNaN(d.getTime()) && d >= today;
    });
}

// ─────────────────────────────────────────────────────
// Upsert & serve
// ─────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────
// Resolution d'equipes via la table teams/team_aliases
// Fallback sur l'ancienne table team_logos si resolve echoue
// ─────────────────────────────────────────────────────

interface ResolvedTeam {
  team_id: number;
  team_name: string;
  logo_url: string;
  short_name: string;
}

// Cache pour eviter les appels repetitifs dans un meme run
const _resolveCache = new Map<string, ResolvedTeam | null>();

async function resolveTeam(rawName: string, source: string = ''): Promise<ResolvedTeam | null> {
  const cacheKey = `${rawName.toLowerCase().trim()}|${source}`;
  if (_resolveCache.has(cacheKey)) return _resolveCache.get(cacheKey)!;

  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/resolve_team`,
      {
        method: 'POST',
        headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ p_raw_name: rawName, p_source: source }),
      },
    );
    if (res.ok) {
      const rows: ResolvedTeam[] = await res.json();
      const result = rows.length ? rows[0] : null;
      _resolveCache.set(cacheKey, result);
      return result;
    }
  } catch { /* ignore */ }

  _resolveCache.set(cacheKey, null);
  return null;
}

// Fallback : ancienne table team_logos (substring match)
let _teamLogosCache: { team_key: string; logo_url: string }[] | null = null;

async function getTeamLogos(): Promise<{ team_key: string; logo_url: string }[]> {
  if (_teamLogosCache) return _teamLogosCache;
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/team_logos?select=team_key,logo_url`,
      { headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` } },
    );
    if (res.ok) {
      _teamLogosCache = await res.json();
    } else {
      _teamLogosCache = [];
    }
  } catch {
    _teamLogosCache = [];
  }
  return _teamLogosCache!;
}

function findLogoUrl(teamName: string, logos: { team_key: string; logo_url: string }[]): string {
  const lower = teamName.toLowerCase();
  for (const l of logos) {
    if (lower.includes(l.team_key)) return l.logo_url;
  }
  return '';
}

async function enrichMatchesWithLogos(matches: MatchRow[]): Promise<MatchRow[]> {
  const logos = await getTeamLogos();

  const enriched: MatchRow[] = [];
  for (const m of matches) {
    // 1. Essayer resolve_team (exact match via alias)
    const domResolved = m.equipe_dom ? await resolveTeam(m.equipe_dom, m.source) : null;
    const extResolved = m.equipe_ext ? await resolveTeam(m.equipe_ext, m.source) : null;

    enriched.push({
      ...m,
      // Normaliser le nom si resolve a reussi
      equipe_dom: domResolved?.team_name ?? m.equipe_dom,
      equipe_ext: extResolved?.team_name ?? m.equipe_ext,
      // Logo : resolve > existant > fallback team_logos
      logo_dom: domResolved?.logo_url || m.logo_dom || findLogoUrl(m.equipe_dom, logos),
      logo_ext: extResolved?.logo_url || m.logo_ext || findLogoUrl(m.equipe_ext, logos),
    });
  }
  return enriched;
}

async function upsertMatches(matches: MatchRow[]): Promise<{ count: number; error?: string }> {
  if (matches.length === 0) return { count: 0 };

  const enriched = await enrichMatchesWithLogos(matches);

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/matchs?on_conflict=sport,equipe_dom,equipe_ext,date`,
    {
      method: "POST",
      headers,
      body: JSON.stringify(enriched),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`Upsert matchs failed: ${err}`);
    return { count: 0, error: err };
  }
  return { count: enriched.length };
}

// Helper: run a scraper, propagate internal errors, return debug info
async function runScraper(
  name: string,
  fn: () => Promise<MatchRow[]>,
): Promise<{ name: string; matches: MatchRow[]; error?: string; htmlLen?: number }> {
  try {
    const matches = await fn();
    return { name, matches };
  } catch (e) {
    return { name, matches: [], error: (e as Error).message };
  }
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  // ?only=boxe,rugby-st  — run only specific scrapers
  const onlyParam = url.searchParams.get("only");

  const allScrapers = [
    { name: "boxe", fn: scrapeGalaBoxe },
    { name: "ffboxe", fn: scrapeFFBoxe },
    { name: "basketball-tbc", fn: scrapeToulouseBasketball },
    { name: "basketball-tmb", fn: scrapeTMB },
    { name: "rugby-st", fn: scrapeStadeToulousain },
    { name: "rugby-colomiers", fn: scrapeColomiers },
    { name: "handball-fenix", fn: scrapeFenixToulouse },
  ];

  const scrapers = onlyParam
    ? allScrapers.filter(s => onlyParam.split(",").includes(s.name))
    : allScrapers;

  // Run all scrapers in parallel to avoid timeout
  const results = await Promise.all(
    scrapers.map(({ name, fn }) => runScraper(name, fn)),
  );

  const debug: Record<string, unknown> = {};
  const errors: string[] = [];
  let count = 0;

  for (const result of results) {
    debug[result.name] = {
      found: result.matches.length,
      error: result.error || null,
    };
    if (result.error) {
      errors.push(`${result.name}: ${result.error}`);
    }
    if (result.matches.length > 0) {
      const upsertResult = await upsertMatches(result.matches);
      count += upsertResult.count;
      if (upsertResult.error) {
        (debug[result.name] as Record<string, unknown>).upsertError = upsertResult.error;
        errors.push(`${result.name}_upsert: ${upsertResult.error}`);
      }
    }
  }

  return new Response(
    JSON.stringify({ count, errors, debug }),
    { headers: { "Content-Type": "application/json" } },
  );
});

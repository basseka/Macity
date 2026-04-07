// supabase functions deploy scrape-festival-carcassonne --no-verify-jwt
//
// Scrape la programmation du Festival de Carcassonne depuis
// https://www.festivaldecarcassonne.fr/article-page/toute-la-programmation
// et upsert dans scraped_events (rubrique = culture ou day selon categorie).

import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";
import { upsertEvents, makeEvent, logScraperError } from "../_shared/db.ts";
import type { ScrapedEvent } from "../_shared/db.ts";

const BASE = "https://www.festivaldecarcassonne.fr";
const PROG_URL = `${BASE}/article-page/toute-la-programmation`;

// ── Helpers ──

/** Map categories to rubriques (8 modes de l'app) */
function categoryToRubrique(cat: string, title = ""): string {
  const lower = (cat + " " + title).toLowerCase();

  // Day (Sortir) : concerts, festivals, spectacles musicaux
  if (lower.includes("concert") || lower.includes("musique") || lower.includes("dj")
      || lower.includes("festival") || lower.includes("showcase") || lower.includes("feria")) return "day";

  // Culture : theatre, danse, opera, cinema, exposition, patrimoine
  if (lower.includes("théâtre") || lower.includes("theatre") || lower.includes("danse")
      || lower.includes("opéra") || lower.includes("opera") || lower.includes("cinema")
      || lower.includes("cinéma") || lower.includes("exposition") || lower.includes("patrimoine")
      || lower.includes("musée") || lower.includes("musee") || lower.includes("medieval")
      || lower.includes("médiéval") || lower.includes("chevalerie")) return "culture";

  // Night : soiree, club, bar, nuit
  if (lower.includes("soirée") || lower.includes("soiree") || lower.includes("club")
      || lower.includes("nuit") || lower.includes("night") || lower.includes("bodega")) return "night";

  // Sport : match, course, marathon, rugby, foot
  if (lower.includes("sport") || lower.includes("match") || lower.includes("rugby")
      || lower.includes("football") || lower.includes("course") || lower.includes("marathon")
      || lower.includes("cyclisme") || lower.includes("tournoi")) return "sport";

  // Food : gastronomie, marche, vin, restaurant
  if (lower.includes("gastronomie") || lower.includes("marché") || lower.includes("marche")
      || lower.includes("vin") || lower.includes("degustation") || lower.includes("culinaire")
      || lower.includes("food") || lower.includes("noel")) return "food";

  // Family : enfant, famille, cirque, conte, atelier
  if (lower.includes("enfant") || lower.includes("famille") || lower.includes("cirque")
      || lower.includes("conte") || lower.includes("atelier") || lower.includes("jeune public")) return "family";

  // Tourisme : visite, balade, decouverte
  if (lower.includes("visite") || lower.includes("balade") || lower.includes("decouverte")
      || lower.includes("découverte") || lower.includes("randonnee") || lower.includes("randonnée")) return "tourisme";

  // Default : spectacle → day
  if (lower.includes("spectacle")) return "day";

  return "culture";
}

/** Parse "01/07" to "2026-07-01" (current or next year) */
function parseFestivalDate(dateStr: string): string {
  const match = dateStr.match(/(\d{1,2})\/(\d{1,2})/);
  if (!match) return "";
  const day = parseInt(match[1], 10);
  const month = parseInt(match[2], 10);
  const now = new Date();
  let year = now.getFullYear();
  const candidate = new Date(year, month - 1, day);
  // If date is more than 2 months in the past, use next year
  const cutoff = new Date(now);
  cutoff.setMonth(cutoff.getMonth() - 2);
  if (candidate < cutoff) year++;
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

/** Parse "21h30" to "21h30" */
function parseTime(text: string): string {
  const match = text.match(/(\d{1,2})\s*[hH]\s*(\d{0,2})/);
  if (!match) return "";
  const h = match[1].padStart(2, "0");
  const m = (match[2] || "00").padStart(2, "0");
  return `${h}h${m}`;
}

// ── Scraper ──

async function scrapeProgrammation(): Promise<ScrapedEvent[]> {
  const html = await fetchHtml(PROG_URL, 20000);
  const events: ScrapedEvent[] = [];

  // Match event cards: <a> tags linking to /manifestations/
  // Pattern: <a href="/manifestations/..." ...>...content...</a>
  const cardRegex = /<a\s+[^>]*href="(\/manifestations\/[^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let match;

  while ((match = cardRegex.exec(html)) !== null) {
    const href = match[1].replace("?history_back", "");
    const block = match[2];

    // Extract image
    const imgMatch = block.match(/<img\s+[^>]*src="([^"]+)"[^>]*/);
    let photoUrl = imgMatch ? imgMatch[1] : "";
    if (photoUrl && !photoUrl.startsWith("http")) photoUrl = BASE + photoUrl;
    // Skip embed/invalid URLs
    if (photoUrl.includes("/embed") || photoUrl.includes("secret=")) photoUrl = "";

    // Extract text content (remove HTML tags)
    const textContent = cleanHtml(block);

    // Extract date + time: "01/07 à 21h30" or "01/07 à 18h00"
    const dateTimeMatch = textContent.match(/(\d{1,2}\/\d{1,2})\s*(?:à|a)\s*(\d{1,2}\s*[hH]\s*\d{0,2})/);
    const dateStr = dateTimeMatch ? parseFestivalDate(dateTimeMatch[1]) : "";
    const timeStr = dateTimeMatch ? parseTime(dateTimeMatch[2]) : "";

    if (!dateStr) continue; // Skip if no date found

    // Extract category: Concert, Théâtre, Danse, Opéra, Spectacle, Cirque
    const catMatch = textContent.match(/(Concert|Th[eé][aâ]tre|Danse|Op[eé]ra|Spectacle|Cirque|Musique)/i);
    const category = catMatch ? catMatch[1] : "Spectacle";

    // Extract title: everything before the date pattern, or the main text
    // Title is usually the biggest text — try to find it
    const titleMatch = block.match(/<(?:h[1-6]|strong|b)[^>]*>([\s\S]*?)<\/(?:h[1-6]|strong|b)>/);
    let title = titleMatch ? cleanHtml(titleMatch[1]) : "";

    // Fallback: use text before date
    if (!title) {
      const parts = textContent.split(/\d{1,2}\/\d{1,2}/);
      title = parts.length > 1 ? parts[0].trim() : textContent.substring(0, 60).trim();
    }
    if (!title) continue;

    // Extract venue
    const venuePatterns = [
      "Théâtre Jean-Deschamps",
      "Theatre Jean-Deschamps",
      "Cour d'honneur du Château Comtal",
      "Château Comtal",
      "Eglise Saint-Nazaire",
      "Basilique Saint-Nazaire",
      "Place Carnot",
      "Jardin du Prado",
    ];
    let venue = "Festival de Carcassonne";
    for (const v of venuePatterns) {
      if (textContent.includes(v)) {
        venue = v;
        break;
      }
    }

    // Check if sold out
    const isSoldOut = textContent.toLowerCase().includes("complet");

    const slug = href.split("/").pop() || "";
    const identifiant = `festival_carcassonne_${slug}_${dateStr}`;

    events.push(makeEvent({
      identifiant,
      source: "festival_carcassonne",
      rubrique: categoryToRubrique(category, title),
      nom_de_la_manifestation: title,
      descriptif_court: isSoldOut ? `${category} - COMPLET` : category,
      date_debut: dateStr,
      date_fin: dateStr,
      horaires: timeStr,
      lieu_nom: venue,
      lieu_adresse_2: "Cite de Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: category,
      categorie_de_la_manifestation: category,
      theme_de_la_manifestation: "Festival",
      reservation_site_internet: `${BASE}${href}`,
      photo_url: photoUrl,
      ville: "Carcassonne",
    }));
  }

  return events;
}

// ── Festival du Cinema ──

async function scrapeFestivalCinema(): Promise<ScrapedEvent[]> {
  const CINEMA_URL = "https://festival-cinema-carcassonne.org/";
  const events: ScrapedEvent[] = [];

  try {
    const html = await fetchHtml(CINEMA_URL, 15000);

    // Chercher les projections/événements
    const cardRegex = /<article[^>]*>([\s\S]*?)<\/article>/g;
    let match;

    while ((match = cardRegex.exec(html)) !== null) {
      const block = match[1];

      const titleMatch = block.match(/<h[1-4][^>]*>([\s\S]*?)<\/h[1-4]>/);
      if (!titleMatch) continue;
      const title = cleanHtml(titleMatch[1]);
      if (!title || title.length < 3) continue;

      const imgMatch = block.match(/<img[^>]*src="([^"]+)"/);
      let photoUrl = imgMatch ? imgMatch[1] : "";
      if (photoUrl && !photoUrl.startsWith("http")) photoUrl = CINEMA_URL + photoUrl;

      const linkMatch = block.match(/<a[^>]*href="([^"]+)"/);
      let link = linkMatch ? linkMatch[1] : CINEMA_URL;
      if (link && !link.startsWith("http")) link = CINEMA_URL + link;

      // Date : chercher dans le texte
      const text = cleanHtml(block);
      const dateMatch = text.match(/(\d{1,2})\s+(janvier|fevrier|mars|avril|mai|juin|juillet|aout|septembre|octobre|novembre|decembre|février|août|décembre)/i);

      let dateStr = "";
      if (dateMatch) {
        const months: Record<string, number> = {
          janvier: 1, fevrier: 2, "février": 2, mars: 3, avril: 4, mai: 5, juin: 6,
          juillet: 7, aout: 8, "août": 8, septembre: 9, octobre: 10, novembre: 11,
          decembre: 12, "décembre": 12,
        };
        const day = parseInt(dateMatch[1]);
        const month = months[dateMatch[2].toLowerCase()];
        if (month) {
          const year = new Date().getFullYear();
          dateStr = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
        }
      }

      if (!dateStr) {
        // Utiliser janvier prochain par defaut (festival en janvier)
        const year = new Date().getMonth() >= 6 ? new Date().getFullYear() + 1 : new Date().getFullYear();
        dateStr = `${year}-01-15`;
      }

      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").slice(0, 50);
      events.push(makeEvent({
        identifiant: `cinema_carcassonne_${slug}`,
        source: "cinema_carcassonne",
        rubrique: "culture",
        nom_de_la_manifestation: title,
        descriptif_court: "Festival International du Film Politique",
        date_debut: dateStr,
        date_fin: dateStr,
        lieu_nom: "CGR Le Colisee",
        lieu_adresse_2: "Carcassonne",
        code_postal: 11000,
        commune: "Carcassonne",
        type_de_manifestation: "Cinema",
        categorie_de_la_manifestation: "Cinema",
        theme_de_la_manifestation: "Festival",
        reservation_site_internet: link,
        photo_url: photoUrl,
        ville: "Carcassonne",
      }));
    }
  } catch (e) {
    console.error("Festival Cinema scrape error:", (e as Error).message);
  }

  return events;
}

// ── Temps forts statiques (Feria, etc.) ──

function getTempsForts(): ScrapedEvent[] {
  const year = new Date().getFullYear();
  return [
    makeEvent({
      identifiant: `feria_carcassonne_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "day",
      nom_de_la_manifestation: `Feria de Carcassonne ${year}`,
      descriptif_court: "Fete populaire avec corridas, concerts, bodega, animations de rue",
      date_debut: `${year}-08-15`,
      date_fin: `${year}-08-20`,
      horaires: "Toute la journee",
      lieu_nom: "Centre-ville et arenes",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Festival",
      categorie_de_la_manifestation: "Festival",
      theme_de_la_manifestation: "Feria",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/feria-de-carcassonne",
      photo_url: "",
      ville: "Carcassonne",
    }),
    makeEvent({
      identifiant: `embrasement_cite_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "day",
      nom_de_la_manifestation: `Embrasement de la Cite - 14 juillet ${year}`,
      descriptif_court: "Feu d'artifice spectaculaire sur la Cite medievale, un des plus beaux de France",
      date_debut: `${year}-07-14`,
      date_fin: `${year}-07-14`,
      horaires: "22h30",
      lieu_nom: "Cite medievale de Carcassonne",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Spectacle",
      categorie_de_la_manifestation: "Spectacle",
      theme_de_la_manifestation: "Feu d'artifice",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/",
      photo_url: "",
      ville: "Carcassonne",
    }),
    makeEvent({
      identifiant: `tournois_chevalerie_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "culture",
      nom_de_la_manifestation: `Tournois de Chevalerie ${year}`,
      descriptif_court: "Spectacles medievaux dans la Cite, joutes, combats, animations",
      date_debut: `${year}-08-01`,
      date_fin: `${year}-08-31`,
      horaires: "15h00",
      lieu_nom: "Lices de la Cite",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Spectacle",
      categorie_de_la_manifestation: "Spectacle",
      theme_de_la_manifestation: "Medieval",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/",
      photo_url: "",
      ville: "Carcassonne",
    }),
    makeEvent({
      identifiant: `marche_noel_carcassonne_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "food",
      nom_de_la_manifestation: `Marche de Noel de Carcassonne ${year}`,
      descriptif_court: "Marche de Noel dans la Bastide Saint-Louis, artisanat et gastronomie",
      date_debut: `${year}-11-29`,
      date_fin: `${year}-12-31`,
      horaires: "10h00 - 19h00",
      lieu_nom: "Place Carnot",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Marche",
      categorie_de_la_manifestation: "Marche",
      theme_de_la_manifestation: "Noel",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/",
      photo_url: "",
      ville: "Carcassonne",
    }),
    // Night
    makeEvent({
      identifiant: `bodega_feria_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "night",
      nom_de_la_manifestation: `Bodegas de la Feria ${year}`,
      descriptif_court: "Soirees bodegas dans les rues de Carcassonne pendant la Feria",
      date_debut: `${year}-08-15`,
      date_fin: `${year}-08-20`,
      horaires: "21h00 - 04h00",
      lieu_nom: "Bastide Saint-Louis",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Soiree",
      categorie_de_la_manifestation: "Soiree",
      theme_de_la_manifestation: "Feria",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/feria-de-carcassonne",
      photo_url: "",
      ville: "Carcassonne",
    }),
    // Family
    makeEvent({
      identifiant: `spectacle_jeune_public_cite_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "family",
      nom_de_la_manifestation: `Spectacles jeune public - Cite medievale ${year}`,
      descriptif_court: "Animations pour enfants : contes, ateliers medievaux, spectacles de rue",
      date_debut: `${year}-07-01`,
      date_fin: `${year}-08-31`,
      horaires: "14h00 - 18h00",
      lieu_nom: "Cite medievale de Carcassonne",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Atelier",
      categorie_de_la_manifestation: "Enfant",
      theme_de_la_manifestation: "Medieval",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/",
      photo_url: "",
      ville: "Carcassonne",
    }),
    // Tourisme
    makeEvent({
      identifiant: `visites_guidees_cite_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "tourisme",
      nom_de_la_manifestation: `Visites guidees de la Cite medievale ${year}`,
      descriptif_court: "Decouverte de la Cite avec un guide, remparts, chateau et basilique",
      date_debut: `${year}-01-01`,
      date_fin: `${year}-12-31`,
      horaires: "10h00 - 17h00",
      lieu_nom: "Porte Narbonnaise",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Visite",
      categorie_de_la_manifestation: "Visite",
      theme_de_la_manifestation: "Patrimoine",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/",
      photo_url: "",
      ville: "Carcassonne",
    }),
    // Sport
    makeEvent({
      identifiant: `corrida_feria_${year}`,
      source: "temps_forts_carcassonne",
      rubrique: "sport",
      nom_de_la_manifestation: `Corridas et courses de la Feria ${year}`,
      descriptif_court: "Corridas et courses camarguaises aux arenes de Carcassonne",
      date_debut: `${year}-08-15`,
      date_fin: `${year}-08-20`,
      horaires: "17h00",
      lieu_nom: "Arenes de Carcassonne",
      lieu_adresse_2: "Carcassonne",
      code_postal: 11000,
      commune: "Carcassonne",
      type_de_manifestation: "Sport",
      categorie_de_la_manifestation: "Sport",
      theme_de_la_manifestation: "Tauromachie",
      reservation_site_internet: "https://www.tourisme-carcassonne.fr/temps-forts/feria-de-carcassonne",
      photo_url: "",
      ville: "Carcassonne",
    }),
  ];
}

// ── Handler ──

Deno.serve(async (_req) => {
  try {
    // 1. Festival de Carcassonne (programmation)
    const festivalEvents = await scrapeProgrammation();
    console.log(`Festival Carcassonne: ${festivalEvents.length} events`);

    // 2. Festival du Cinema
    const cinemaEvents = await scrapeFestivalCinema();
    console.log(`Festival Cinema: ${cinemaEvents.length} events`);

    // 3. Temps forts statiques (Feria, 14 juillet, etc.)
    const tempsForts = getTempsForts();
    console.log(`Temps forts: ${tempsForts.length} events`);

    const allEvents = [...festivalEvents, ...cinemaEvents, ...tempsForts];
    const upserted = await upsertEvents(allEvents);

    return new Response(
      JSON.stringify({
        source: "carcassonne_all",
        festival: festivalEvents.length,
        cinema: cinemaEvents.length,
        temps_forts: tempsForts.length,
        total: allEvents.length,
        upserted,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error("scrape-festival-carcassonne FATAL:", err.message);
    await logScraperError({
      scraper: "scrape-festival-carcassonne",
      source: "festivaldecarcassonne.fr",
      ville: "Carcassonne",
      error_type: "fetch",
      message: err.message,
      stack: err.stack,
    });
    return new Response(
      JSON.stringify({
        source: "festival_carcassonne",
        scraped: 0,
        upserted: 0,
        error: err.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

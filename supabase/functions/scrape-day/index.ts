// supabase functions deploy scrape-day --no-verify-jwt
//
// Scrape les événements "day" pour une ville donnée.
// Accepte { ville: "toulouse" } dans le body (défaut: toulouse).
// Sources communes (Ticketmaster, Festik, Songkick, Eventbrite) + sources spécifiques par ville.

import { type ScrapedEvent, upsertEvents, supabaseHeaders, logScraperError, withErrorLogging } from "../_shared/db.ts";
import { CITIES, resolveCityKey, type CityConfig } from "./config/cities.ts";
import { fetchTicketmaster, searchArtistPhoto } from "./sources/ticketmaster.ts";
import { fetchFestik } from "./sources/festik.ts";
import { fetchSongkick } from "./sources/songkick.ts";
import { fetchEventbrite } from "./sources/eventbrite.ts";
import { fetchAllToulouseSources } from "./sources/toulouse.ts";

const TICKETMASTER_API_KEY = Deno.env.get("TICKETMASTER_API_KEY") ?? "";

function normalize(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

/** Normalize event name for dedup: strip feat/ft, parentheses, accents, articles */
function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")       // strip accents
    .replace(/\s*[\(\[].+?[\)\]]\s*/g, "")                  // strip (feat. X), [Live], etc.
    .replace(/\s*(feat\.?|ft\.?|vs\.?|x)\s+.*/i, "")        // strip "feat Artist"
    .replace(/[^a-z0-9]/g, "");                              // keep only alphanum
}

// ── Dedup: keep first occurrence (curated sources should come first) ──
// Uses fuzzy name matching to catch cross-source duplicates
function dedup(events: ScrapedEvent[]): ScrapedEvent[] {
  const seen = new Map<string, string>(); // normalized key → original identifiant
  return events.filter(e => {
    const key = `${normalizeName(e.nom_de_la_manifestation)}|${e.date_debut}`;
    if (seen.has(key)) return false;
    seen.set(key, e.identifiant);

    // Also check with strict normalize for exact matches
    const strictKey = `${normalize(e.nom_de_la_manifestation)}|${e.date_debut}`;
    if (strictKey !== key && seen.has(strictKey)) return false;
    seen.set(strictKey, e.identifiant);

    return true;
  });
}

// ── Re-tag "Fête de la musique" events ──
function tagFeteMusique(events: ScrapedEvent[]): ScrapedEvent[] {
  return events.map(e => {
    const nom = (e.nom_de_la_manifestation || "").toLowerCase();
    if (nom.includes("fête de la musique") || nom.includes("fete de la musique")) {
      return { ...e, source: "day_fete_musique" };
    }
    return e;
  });
}

// ── Enrich no-photo concert events with Ticketmaster artist images ──
// Covers TFG (tfg_) and Songkick (sk_) events that lack photos.
const MANUAL_ARTIST_PHOTOS: Record<string, string> = {
  florentpagny: "https://blog.ticketmaster.fr/wp-content/uploads/2024/12/TKM_800x400.jpg",
};

const ENRICHABLE_PREFIXES = ["tfg_", "sk_"];

async function enrichPhotos(events: ScrapedEvent[]): Promise<ScrapedEvent[]> {
  // Apply manual overrides first
  const withManual = events.map(e => {
    if (e.photo_url || !ENRICHABLE_PREFIXES.some(p => e.identifiant.startsWith(p))) return e;
    const key = normalize(e.nom_de_la_manifestation);
    const manual = MANUAL_ARTIST_PHOTOS[key];
    return manual ? { ...e, photo_url: manual } : e;
  });

  if (!TICKETMASTER_API_KEY) return withManual;

  // Collect unique artist names that still need photos
  const needPhoto = new Map<string, number[]>();
  for (let i = 0; i < withManual.length; i++) {
    const e = withManual[i];
    if (e.photo_url || !ENRICHABLE_PREFIXES.some(p => e.identifiant.startsWith(p))) continue;
    const key = normalize(e.nom_de_la_manifestation);
    if (!needPhoto.has(key)) needPhoto.set(key, []);
    needPhoto.get(key)!.push(i);
  }

  if (needPhoto.size === 0) return withManual;
  console.log(`Photo enrichment: ${needPhoto.size} artists need photos`);

  const enriched = [...withManual];
  let count = 0;
  const artists = [...needPhoto.entries()].slice(0, 20);

  for (const [_, indices] of artists) {
    const name = withManual[indices[0]].nom_de_la_manifestation;
    const photoUrl = await searchArtistPhoto(name);
    if (photoUrl) {
      for (const idx of indices) {
        enriched[idx] = { ...enriched[idx], photo_url: photoUrl };
        count++;
      }
    }
  }
  console.log(`Photo enrichment: found photos for ${count} events`);
  return enriched;
}

// ── Preserve existing photos from DB ──
async function preserveExistingPhotos(events: ScrapedEvent[]): Promise<ScrapedEvent[]> {
  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/scraped_events?select=identifiant,photo_url&photo_url=neq.`,
      { headers: supabaseHeaders },
    );
    if (res.ok) {
      const existing = await res.json() as { identifiant: string; photo_url: string }[];
      const photoMap = new Map(existing.map(e => [e.identifiant, e.photo_url]));
      const result = events.map(e => {
        if (!e.photo_url) {
          const saved = photoMap.get(e.identifiant);
          if (saved) return { ...e, photo_url: saved };
        }
        return e;
      });
      console.log(`Preserved ${photoMap.size} existing photos`);
      return result;
    }
  } catch (e) { console.error("Photo preservation error:", e); }
  return events;
}

// ── Common sources (work for all cities via lat/lng, aliases, or metro IDs) ──
async function fetchCommonSources(city: CityConfig, cityKey: string): Promise<ScrapedEvent[]> {
  const w = (source: string, fn: () => Promise<ScrapedEvent[]>) =>
    withErrorLogging("scrape-day", source, cityKey, fn);

  const [tm, festikConcert, festikFestival, festikSpectacle, songkick, eventbrite] = await Promise.all([
    w("ticketmaster", () => fetchTicketmaster(city)),
    w("festik-concert", () => fetchFestik(city, "Concert")),
    w("festik-festival", () => fetchFestik(city, "Festival")),
    w("festik-spectacle", () => fetchFestik(city, "Spectacle")),
    w("songkick", () => fetchSongkick(city)),
    w("eventbrite", () => fetchEventbrite(city)),
  ]);

  const taggedFestikS = festikSpectacle.filter(e => {
    const t = e.nom_de_la_manifestation.toLowerCase();
    return !t.includes("theatre");
  }).map(e => ({ ...e, source: "day_spectacle" }));

  return [
    // Songkick + Eventbrite first (often have photos)
    ...songkick,
    ...eventbrite,
    ...tm,
    ...festikConcert.map(e => ({ ...e, source: "day_concert" })),
    ...festikFestival.map(e => ({ ...e, source: "day_festival" })),
    ...taggedFestikS,
  ];
}

// ── City-specific sources registry ──
type CitySourceFn = () => Promise<ScrapedEvent[]>;

const CITY_SOURCES: Record<string, CitySourceFn> = {
  toulouse: fetchAllToulouseSources,
  // Futures villes : lyon: fetchAllLyonSources, paris: fetchAllParisSources, ...
};

// ── Main scrape orchestrator ──
async function scrapeCity(cityKey: string): Promise<ScrapedEvent[]> {
  const city = CITIES[cityKey];
  if (!city) throw new Error(`Unknown city: ${cityKey}`);

  console.log(`scrape-day[${city.nom}]: starting...`);

  // Run common + city-specific sources in parallel
  const citySourceFn = CITY_SOURCES[cityKey];
  const [common, specific] = await Promise.all([
    fetchCommonSources(city, cityKey),
    citySourceFn
      ? withErrorLogging("scrape-day", `city-${cityKey}`, cityKey, citySourceFn)
      : Promise.resolve([]),
  ]);

  // City-specific sources first for dedup priority
  const all = tagFeteMusique([...specific, ...common]);
  const deduped = dedup(all);

  // Enrich photos for TFG events
  const enriched = await enrichPhotos(deduped);

  // Tag all events with the city name
  const tagged = enriched.map(e => ({ ...e, ville: city.nom }));

  console.log(`scrape-day[${city.nom}]: ${tagged.length} events after dedup+enrichment`);
  return tagged;
}

// ── Deno.serve handler ──
Deno.serve(async (req) => {
  const errors: string[] = [];

  // Parse city from request body (default: toulouse)
  let cityKey = "toulouse";
  try {
    const body = await req.json();
    if (body.ville) {
      const resolved = resolveCityKey(body.ville);
      if (resolved) cityKey = resolved;
      else errors.push(`Unknown ville: ${body.ville}, falling back to toulouse`);
    }
  } catch { /* no body or invalid JSON → default toulouse */ }

  let allEvents: ScrapedEvent[] = [];
  try {
    allEvents = await scrapeCity(cityKey);
    console.log(`scrape-day[${cityKey}]: found ${allEvents.length} events`);
  } catch (e) {
    const err = e as Error;
    errors.push(`scrapeCity(${cityKey}): ${err.message}`);
    await logScraperError({
      scraper: "scrape-day", source: "orchestrator", ville: cityKey,
      error_type: "fetch", message: err.message, stack: err.stack,
    });
  }

  // Preserve existing photos from DB
  allEvents = await preserveExistingPhotos(allEvents);

  const count = await upsertEvents(allEvents);
  console.log(`scrape-day[${cityKey}]: upserted ${count} events`);

  // Stats by source
  const bySource: Record<string, number> = {};
  for (const e of allEvents) {
    bySource[e.source] = (bySource[e.source] || 0) + 1;
  }

  return new Response(
    JSON.stringify({ ville: cityKey, count, errors, bySource }),
    { headers: { "Content-Type": "application/json" } },
  );
});

// Edge Function: seed-city-venues
// Peuple automatiquement les venues d'une ville via OpenStreetMap (Overpass API).
// Usage: POST /seed-city-venues { "ville": "Lyon" }
//   ou:  POST /seed-city-venues { "ville": "Lyon", "modes": ["night", "culture"] }
//
// Deploy: supabase functions deploy seed-city-venues --no-verify-jwt

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates,return=minimal",
};

// ── Coordonnees des villes ──────────────────────────────────────
const CITY_COORDS: Record<string, { lat: number; lon: number }> = {
  "Toulouse":           { lat: 43.6047, lon: 1.4442 },
  "Paris":              { lat: 48.8566, lon: 2.3522 },
  "Lyon":               { lat: 45.7640, lon: 4.8357 },
  "Marseille":          { lat: 43.2965, lon: 5.3698 },
  "Bordeaux":           { lat: 44.8378, lon: -0.5792 },
  "Lille":              { lat: 50.6292, lon: 3.0573 },
  "Nantes":             { lat: 47.2184, lon: -1.5536 },
  "Strasbourg":         { lat: 48.5734, lon: 7.7521 },
  "Nice":               { lat: 43.7102, lon: 7.2620 },
  "Montpellier":        { lat: 43.6108, lon: 3.8767 },
  "Rennes":             { lat: 48.1173, lon: -1.6778 },
  "Grenoble":           { lat: 45.1885, lon: 5.7245 },
  "Dijon":              { lat: 47.3220, lon: 5.0415 },
  "Angers":             { lat: 47.4784, lon: -0.5632 },
  "Reims":              { lat: 49.2583, lon: 3.5170 },
  "Le Havre":           { lat: 49.4944, lon: 0.1079 },
  "Saint-Etienne":      { lat: 45.4397, lon: 4.3872 },
  "Toulon":             { lat: 43.1242, lon: 5.9280 },
  "Clermont-Ferrand":   { lat: 45.7772, lon: 3.0870 },
  "Le Mans":            { lat: 48.0061, lon: 0.1996 },
  "Aix-en-Provence":    { lat: 43.5297, lon: 5.4474 },
  "Brest":              { lat: 48.3904, lon: -4.4861 },
  "Amiens":             { lat: 49.8941, lon: 2.2958 },
  "Annecy":             { lat: 45.8992, lon: 6.1294 },
  "Besancon":           { lat: 47.2378, lon: 6.0241 },
  "Metz":               { lat: 49.1193, lon: 6.1757 },
  "Rouen":              { lat: 49.4432, lon: 1.0999 },
  "Nancy":              { lat: 48.6921, lon: 6.1844 },
  "Avignon":            { lat: 43.9493, lon: 4.8055 },
  "Colmar":             { lat: 48.0794, lon: 7.3558 },
  "Bayonne":            { lat: 43.4933, lon: -1.4753 },
  "Carcassonne":        { lat: 43.2130, lon: 2.3491 },
  "Blois":              { lat: 47.5861, lon: 1.3359 },
  "Chartres":           { lat: 48.4561, lon: 1.4890 },
  "Nimes":              { lat: 43.8367, lon: 4.3601 },
  "Geneve":             { lat: 46.2044, lon: 6.1432 },
};

// ── Mapping categorie → tags Overpass ────────────────────────────
interface CategoryQuery {
  mode: string;
  category: string;
  overpassTags: string[]; // chaque entree est un filtre Overpass ex: '["amenity"="bar"]'
}

const CATEGORY_QUERIES: CategoryQuery[] = [
  // ── NIGHT ──
  { mode: "night", category: "Bar de nuit",        overpassTags: ['["amenity"="bar"]'] },
  { mode: "night", category: "Bar a cocktails",    overpassTags: ['["amenity"="bar"]["cocktails"="yes"]', '["amenity"="bar"]["name"~"cocktail",i]'] },
  { mode: "night", category: "Pub",                overpassTags: ['["amenity"="pub"]'] },
  { mode: "night", category: "Club Discotheque",   overpassTags: ['["amenity"="nightclub"]'] },
  { mode: "night", category: "Hotel",              overpassTags: ['["tourism"="hotel"]'] },

  // ── CULTURE ──
  { mode: "culture", category: "Theatre",          overpassTags: ['["amenity"="theatre"]'] },
  { mode: "culture", category: "Musee",            overpassTags: ['["tourism"="museum"]'] },
  { mode: "culture", category: "Bibliotheque",     overpassTags: ['["amenity"="library"]'] },
  { mode: "culture", category: "Galerie d'art",    overpassTags: ['["tourism"="gallery"]', '["shop"="art"]'] },

  // ── SPORT ──
  { mode: "sport", category: "Salle de fitness",   overpassTags: ['["leisure"="fitness_centre"]', '["leisure"="sports_centre"]["sport"="fitness"]'] },
  { mode: "sport", category: "Piscine",            overpassTags: ['["leisure"="swimming_pool"]["access"!="private"]', '["amenity"="swimming_pool"]'] },
  { mode: "sport", category: "Terrain de football", overpassTags: ['["leisure"="pitch"]["sport"="soccer"]'] },
  { mode: "sport", category: "Terrain de basketball", overpassTags: ['["leisure"="pitch"]["sport"="basketball"]'] },
  { mode: "sport", category: "Tennis",             overpassTags: ['["leisure"="pitch"]["sport"="tennis"]'] },
  { mode: "sport", category: "Danse",              overpassTags: ['["leisure"="dance"]', '["amenity"="dancing_school"]', '["name"~"danse|dance",i]'] },
  { mode: "sport", category: "Golf",               overpassTags: ['["leisure"="golf_course"]'] },
  { mode: "sport", category: "Salles de boxe",     overpassTags: ['["sport"="boxing"]', '["name"~"boxe|boxing",i]'] },

  // ── FAMILY ──
  { mode: "family", category: "Cinema",            overpassTags: ['["amenity"="cinema"]'] },
  { mode: "family", category: "Bowling",           overpassTags: ['["leisure"="bowling_alley"]'] },
  { mode: "family", category: "Parc d'attractions", overpassTags: ['["tourism"="theme_park"]', '["leisure"="amusement_arcade"]'] },
  { mode: "family", category: "Aire de jeux",      overpassTags: ['["leisure"="playground"]'] },
  { mode: "family", category: "Parc animalier",    overpassTags: ['["tourism"="zoo"]'] },
  { mode: "family", category: "Escape game",       overpassTags: ['["leisure"="escape_game"]', '["name"~"escape",i]'] },
  { mode: "family", category: "Laser game",        overpassTags: ['["leisure"="laser_tag"]', '["name"~"laser",i]'] },

  // ── FOOD ──
  { mode: "food", category: "Restaurant",          overpassTags: ['["amenity"="restaurant"]'] },
  { mode: "food", category: "Salon de the",        overpassTags: ['["amenity"="cafe"]["cuisine"="tea"]', '["name"~"salon de th|thé",i]'] },
  { mode: "food", category: "Brunch",              overpassTags: ['["amenity"="cafe"]["cuisine"~"brunch",i]', '["amenity"="restaurant"]["cuisine"~"brunch",i]'] },

  // ── GAMING ──
  { mode: "gaming", category: "Salle arcade",      overpassTags: ['["leisure"="amusement_arcade"]'] },
  { mode: "gaming", category: "Gaming cafe",       overpassTags: ['["amenity"="cafe"]["name"~"gaming|gamer|esport",i]'] },
  { mode: "gaming", category: "Boutique manga",    overpassTags: ['["shop"="anime"]', '["shop"="books"]["name"~"manga",i]'] },
];

// ── Overpass API ─────────────────────────────────────────────────
const OVERPASS_URL = "https://overpass-api.de/api/interpreter";
const OVERPASS_FALLBACK = "https://overpass.kumi.systems/api/interpreter";

async function queryOverpass(query: string): Promise<OsmElement[]> {
  for (const url of [OVERPASS_URL, OVERPASS_FALLBACK]) {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `data=${encodeURIComponent(query)}`,
      });
      if (!res.ok) continue;
      const json = await res.json();
      return json.elements ?? [];
    } catch {
      continue;
    }
  }
  return [];
}

interface OsmElement {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

function buildOverpassQuery(
  tags: string[],
  lat: number,
  lon: number,
  radius = 8000,
): string {
  const filters = tags
    .flatMap((t) => [
      `node${t}(around:${radius},${lat},${lon});`,
      `way${t}(around:${radius},${lat},${lon});`,
    ])
    .join("\n  ");

  return `[out:json][timeout:30];
(
  ${filters}
);
out center tags;`;
}

// ── Helpers ──────────────────────────────────────────────────────
function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // remove accents
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .substring(0, 80);
}

function buildAddress(tags: Record<string, string>): string {
  const parts: string[] = [];
  const num = tags["addr:housenumber"];
  const street = tags["addr:street"];
  const postcode = tags["addr:postcode"];
  const city = tags["addr:city"];
  if (num && street) parts.push(`${num} ${street}`);
  else if (street) parts.push(street);
  if (postcode && city) parts.push(`${postcode} ${city}`);
  else if (city) parts.push(city);
  return parts.join(", ");
}

function buildMapsLink(name: string, lat: number, lon: number): string {
  return `https://maps.google.com/?q=${encodeURIComponent(name)}&ll=${lat},${lon}`;
}

interface VenueRow {
  slug: string;
  name: string;
  mode: string;
  category: string;
  adresse: string;
  ville: string;
  latitude: number;
  longitude: number;
  lien_maps: string;
  horaires: string;
  telephone: string;
  website_url: string;
  photo: string;
  is_active: boolean;
}

function elementToVenue(
  el: OsmElement,
  ville: string,
  mode: string,
  category: string,
): VenueRow | null {
  const tags = el.tags ?? {};
  const name = tags.name || tags["name:fr"] || "";
  if (!name) return null; // skip unnamed venues

  const lat = el.lat ?? el.center?.lat ?? 0;
  const lon = el.lon ?? el.center?.lon ?? 0;
  if (lat === 0 && lon === 0) return null;

  return {
    slug: slugify(name),
    name,
    mode,
    category,
    adresse: buildAddress(tags) || `${ville}`,
    ville,
    latitude: lat,
    longitude: lon,
    lien_maps: buildMapsLink(name, lat, lon),
    horaires: tags.opening_hours ?? "",
    telephone: tags.phone ?? tags["contact:phone"] ?? "",
    website_url: tags.website ?? tags["contact:website"] ?? "",
    photo: "",
    is_active: true,
  };
}

// ── Upsert vers Supabase ─────────────────────────────────────────
async function upsertVenues(venues: VenueRow[]): Promise<number> {
  if (venues.length === 0) return 0;

  // Batch par 200
  let total = 0;
  for (let i = 0; i < venues.length; i += 200) {
    const batch = venues.slice(i, i + 200);
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/venues?on_conflict=slug,ville`,
      {
        method: "POST",
        headers: supabaseHeaders,
        body: JSON.stringify(batch),
      },
    );
    if (res.ok) {
      total += batch.length;
    } else {
      const err = await res.text();
      console.error(`Upsert batch error: ${err}`);
    }
  }
  return total;
}

// ── Limites par categorie (eviter trop de playgrounds/restaurants) ──
const CATEGORY_LIMITS: Record<string, number> = {
  "Restaurant": 80,
  "Aire de jeux": 30,
  "Terrain de football": 20,
  "Terrain de basketball": 15,
  "Hotel": 40,
};

// ── Main handler ─────────────────────────────────────────────────
Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}));
    const ville: string = body.ville;
    if (!ville) {
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const coords = CITY_COORDS[ville];
    if (!coords) {
      return new Response(
        JSON.stringify({
          error: `Ville '${ville}' inconnue. Villes disponibles: ${Object.keys(CITY_COORDS).join(", ")}`,
        }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Filtrer par modes si specifie
    const requestedModes: string[] | undefined = body.modes;
    const queries = requestedModes
      ? CATEGORY_QUERIES.filter((q) => requestedModes.includes(q.mode))
      : CATEGORY_QUERIES;

    const results: Record<string, number> = {};
    let totalInserted = 0;

    for (const cq of queries) {
      const query = buildOverpassQuery(cq.overpassTags, coords.lat, coords.lon);
      const elements = await queryOverpass(query);

      let venues = elements
        .map((el) => elementToVenue(el, ville, cq.mode, cq.category))
        .filter((v): v is VenueRow => v !== null);

      // Deduplication par slug
      const seen = new Set<string>();
      venues = venues.filter((v) => {
        if (seen.has(v.slug)) return false;
        seen.add(v.slug);
        return true;
      });

      // Limiter certaines categories
      const limit = CATEGORY_LIMITS[cq.category];
      if (limit && venues.length > limit) {
        venues = venues.slice(0, limit);
      }

      const count = await upsertVenues(venues);
      results[`${cq.mode}/${cq.category}`] = count;
      totalInserted += count;

      // Pause entre les requetes pour ne pas surcharger Overpass
      await new Promise((r) => setTimeout(r, 1500));
    }

    return new Response(
      JSON.stringify({
        success: true,
        ville,
        total: totalInserted,
        details: results,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const err = e as Error;
    console.error(`seed-city-venues error: ${err.message}`);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

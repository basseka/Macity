// Shared Supabase helpers for all scraper edge functions.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

export const supabaseHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};

export interface ScrapedEvent {
  identifiant: string;
  source: string;
  rubrique: string;
  nom_de_la_manifestation: string;
  descriptif_court: string;
  descriptif_long: string;
  date_debut: string;
  date_fin: string;
  horaires: string;
  dates_affichage_horaires: string;
  lieu_nom: string;
  lieu_adresse_2: string;
  code_postal: number;
  commune: string;
  type_de_manifestation: string;
  categorie_de_la_manifestation: string;
  theme_de_la_manifestation: string;
  manifestation_gratuite: string;
  tarif_normal: string;
  reservation_site_internet: string;
  reservation_telephone: string;
  station_metro_tram_a_proximite: string;
  photo_url: string;
}

/** Upsert events into scraped_events table (merge on identifiant). */
export async function upsertEvents(events: ScrapedEvent[]): Promise<number> {
  if (events.length === 0) return 0;

  // Deduplicate by identifiant (keep last occurrence)
  const byId = new Map<string, ScrapedEvent>();
  for (const e of events) byId.set(e.identifiant, e);
  const deduped = [...byId.values()];

  // Batch upsert in chunks of 200
  const chunkSize = 200;
  let total = 0;

  for (let i = 0; i < deduped.length; i += chunkSize) {
    const chunk = deduped.slice(i, i + chunkSize);
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/scraped_events?on_conflict=identifiant`,
      {
        method: "POST",
        headers: supabaseHeaders,
        body: JSON.stringify(chunk),
      },
    );

    if (!res.ok) {
      const err = await res.text();
      console.error(`Upsert failed for chunk ${i}: ${res.status} ${err}`);
    } else {
      total += chunk.length;
    }
  }

  return total;
}

/** Build a default ScrapedEvent with empty defaults. */
export function makeEvent(partial: Partial<ScrapedEvent> & Pick<ScrapedEvent, "identifiant" | "source" | "rubrique">): ScrapedEvent {
  return {
    nom_de_la_manifestation: "",
    descriptif_court: "",
    descriptif_long: "",
    date_debut: "",
    date_fin: "",
    horaires: "",
    dates_affichage_horaires: "",
    lieu_nom: "",
    lieu_adresse_2: "",
    code_postal: 0,
    commune: "",
    type_de_manifestation: "",
    categorie_de_la_manifestation: "",
    theme_de_la_manifestation: "",
    manifestation_gratuite: "",
    tarif_normal: "",
    reservation_site_internet: "",
    reservation_telephone: "",
    station_metro_tram_a_proximite: "",
    photo_url: "",
    ...partial,
  };
}

/** Helper to call another edge function. */
export async function callEdgeFunction(name: string): Promise<{ count: number; errors: string[] }> {
  try {
    const res = await fetch(
      `${SUPABASE_URL}/functions/v1/${name}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: "{}",
      },
    );
    if (!res.ok) {
      const err = await res.text();
      return { count: 0, errors: [`${name}: ${err}`] };
    }
    return await res.json();
  } catch (e) {
    return { count: 0, errors: [`${name}: ${(e as Error).message}`] };
  }
}

/** Today's date as YYYY-MM-DD. */
export function todayStr(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
}

/** Check if a date string is in the future (>= today). */
export function isFutureDate(dateStr: string): boolean {
  if (!dateStr) return false;
  return dateStr >= todayStr();
}

/** Check if a date string is not expired (date_fin >= 7 days ago). */
export function isNotExpired(dateFin: string, dateDebut: string): boolean {
  const d = dateFin || dateDebut;
  if (!d) return false;
  const now = new Date();
  now.setDate(now.getDate() - 7);
  const cutoff = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  return d >= cutoff;
}

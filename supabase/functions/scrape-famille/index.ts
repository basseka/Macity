// Edge Function: scrape-famille (multi-ville)
// Scrape events famille/enfants pour toutes les villes.
// Usage: POST /scrape-famille { "ville": "Lyon" }
//
// Sources :
//   1. Eventbrite — famille + enfants
//   2. OpenAgenda — famille, atelier enfants, jeune public, sortie famille
//
// Deploy: supabase functions deploy scrape-famille --no-verify-jwt

import { makeEvent, upsertEvents, withErrorLogging, isFutureDate, type ScrapedEvent } from "../_shared/db.ts";
import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";

const SCRAPER = "scrape-famille";
const OPENAGENDA_KEY = Deno.env.get("OPENAGENDA_API_KEY") || "";

const CITIES: Record<string, string> = {
  "Toulouse": "toulouse", "Paris": "paris", "Lyon": "lyon",
  "Marseille": "marseille", "Bordeaux": "bordeaux", "Lille": "lille",
  "Nantes": "nantes", "Strasbourg": "strasbourg", "Nice": "nice",
  "Montpellier": "montpellier", "Rennes": "rennes", "Grenoble": "grenoble",
  "Dijon": "dijon", "Angers": "angers", "Reims": "reims",
  "Toulon": "toulon", "Saint-Etienne": "saint-etienne",
  "Clermont-Ferrand": "clermont-ferrand", "Le Havre": "le-havre",
  "Aix-en-Provence": "aix-en-provence", "Brest": "brest",
  "Amiens": "amiens", "Annecy": "annecy", "Besancon": "besancon",
  "Metz": "metz", "Rouen": "rouen", "Nancy": "nancy",
  "Avignon": "avignon", "Colmar": "colmar", "Bayonne": "bayonne",
  "Nimes": "nimes", "Geneve": "geneve", "Carcassonne": "carcassonne",
};

// ─── 1. EVENTBRITE ────────────────────────────────────────────
async function scrapeEventbrite(ville: string, slug: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  const keywords = ["famille", "enfants", "jeune-public", "kids"];

  for (const kw of keywords) {
    for (let page = 1; page <= 2; page++) {
      const url = `https://www.eventbrite.fr/d/france--${slug}/${kw}/?page=${page}`;
      let html: string;
      try { html = await fetchHtml(url, 12000); } catch { break; }

      const ldRegex = /<script\s+type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/g;
      let match: RegExpExecArray | null;
      let found = 0;

      while ((match = ldRegex.exec(html)) !== null) {
        try {
          const json = JSON.parse(match[1]);
          const items = json["@type"] === "ItemList" ? (json.itemListElement || []) : [json];

          for (const raw of items) {
            const ev = raw.item || raw;
            if (!ev.name || !ev.startDate) continue;
            if (ev["@type"] !== "Event" && json["@type"] !== "Event" && json["@type"] !== "ItemList") continue;
            found++;

            const dateDebut = ev.startDate.substring(0, 10);
            if (!isFutureDate(dateDebut)) continue;

            let horaires = "";
            if (ev.startDate.includes("T")) {
              const [h, m] = ev.startDate.split("T")[1].split(":");
              horaires = `${h}h${m || "00"}`;
            }

            const evSlug = ev.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
            events.push(makeEvent({
              identifiant: `eb_famille_${evSlug}_${dateDebut}`,
              source: "family_event",
              rubrique: "family",
              nom_de_la_manifestation: cleanHtml(ev.name),
              descriptif_court: cleanHtml((ev.description || "").substring(0, 400)),
              date_debut: dateDebut,
              date_fin: ev.endDate ? ev.endDate.substring(0, 10) : dateDebut,
              horaires,
              lieu_nom: ev.location?.name || "",
              commune: ev.location?.address?.addressLocality || ville,
              ville,
              type_de_manifestation: "Famille",
              categorie_de_la_manifestation: "Famille",
              photo_url: typeof ev.image === "string" ? ev.image : (ev.image?.url || ""),
              reservation_site_internet: ev.url || "",
            }));
          }
        } catch { /* skip */ }
      }
      if (found === 0) break;
    }
  }

  console.log(`[eventbrite-famille/${ville}] ${events.length}`);
  return events;
}

// ─── 2. OPENAGENDA ────────────────────────────────────────────
async function scrapeOpenAgenda(ville: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  if (!OPENAGENDA_KEY) return events;

  const searches = [
    "atelier enfants", "jeune public", "sortie famille",
    "spectacle enfants", "animation enfants", "conte enfants",
    "cirque enfants", "marionnettes",
  ];
  const seen = new Set<string>();

  for (const search of searches) {
    try {
      const params = new URLSearchParams({
        key: OPENAGENDA_KEY, search, city: ville,
        size: "50", sort: "timings.asc",
      });

      const res = await fetch(`https://api.openagenda.com/v2/events?${params.toString()}`, {
        headers: { "User-Agent": "MaCityApp/1.0" },
        signal: AbortSignal.timeout(12000),
      });
      if (!res.ok) continue;

      const data = await res.json();
      for (const e of (data.events || [])) {
        const title = e.title?.fr || e.title?.en || "";
        if (!title) continue;

        const firstTiming = e.firstTiming || (e.timings || [])[0];
        if (!firstTiming) continue;

        const dateDebut = (firstTiming.begin || "").substring(0, 10);
        if (!dateDebut || !isFutureDate(dateDebut)) continue;

        const timeStr = (firstTiming.begin || "").substring(11, 16);
        const horaires = timeStr ? timeStr.replace(":", "h") : "";
        const loc = e.location || {};
        const image = e.image || {};
        const photoUrl = image.base ? `${image.base}${image.filename}` : "";
        const description = e.description?.fr ? cleanHtml(e.description.fr).substring(0, 400) : "";

        const evSlug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        const dedupKey = `${evSlug}_${dateDebut}`;
        if (seen.has(dedupKey)) continue;
        seen.add(dedupKey);

        // Sous-categorie
        const titleLower = title.toLowerCase();
        let categorie = "Famille";
        if (titleLower.includes("atelier")) categorie = "Atelier";
        else if (titleLower.includes("spectacle") || titleLower.includes("theatre")) categorie = "Spectacle enfants";
        else if (titleLower.includes("conte") || titleLower.includes("marionnette")) categorie = "Conte";
        else if (titleLower.includes("cirque")) categorie = "Cirque";

        events.push(makeEvent({
          identifiant: `oa_famille_${evSlug}_${dateDebut}`,
          source: "family_event",
          rubrique: "family",
          nom_de_la_manifestation: title,
          descriptif_court: description,
          date_debut: dateDebut,
          date_fin: (e.lastTiming?.end || firstTiming.begin || "").substring(0, 10),
          horaires,
          lieu_nom: loc.name || "",
          commune: loc.city || ville,
          ville,
          type_de_manifestation: categorie,
          categorie_de_la_manifestation: categorie,
          photo_url: photoUrl,
          reservation_site_internet: e.canonicalUrl || "",
        }));
      }
    } catch { /* skip */ }
  }

  console.log(`[openagenda-famille/${ville}] ${events.length}`);
  return events;
}

// ─── DEDUP ────────────────────────────────────────────────────
function normalizeName(name: string): string {
  return name.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]/g, "");
}

function dedup(events: ScrapedEvent[]): ScrapedEvent[] {
  const seen = new Map<string, ScrapedEvent>();
  for (const e of events) {
    const key = `${normalizeName(e.nom_de_la_manifestation)}_${e.date_debut}`;
    const existing = seen.get(key);
    if (!existing) {
      seen.set(key, e);
    } else {
      if (e.photo_url && !existing.photo_url) existing.photo_url = e.photo_url;
      if (e.horaires && !existing.horaires) existing.horaires = e.horaires;
    }
  }
  return [...seen.values()];
}

// ─── MAIN ────────────────────────────────────────────────────
Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}));
    const ville: string = body.ville || "";

    if (!ville) {
      return new Response(JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const slug = CITIES[ville];
    if (!slug) {
      return new Response(JSON.stringify({ error: `Ville '${ville}' inconnue` }),
        { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const [ebEvents, oaEvents] = await Promise.all([
      withErrorLogging(SCRAPER, "eventbrite", ville, () => scrapeEventbrite(ville, slug)),
      withErrorLogging(SCRAPER, "openagenda", ville, () => scrapeOpenAgenda(ville)),
    ]);

    const allEvents = [...ebEvents, ...oaEvents];
    const deduped = dedup(allEvents);
    const count = await upsertEvents(deduped);

    return new Response(
      JSON.stringify({
        success: true, ville, count,
        sources: { eventbrite: ebEvents.length, openagenda: oaEvents.length, deduped: deduped.length },
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

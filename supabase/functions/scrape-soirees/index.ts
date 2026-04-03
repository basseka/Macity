// Edge Function: scrape-soirees (multi-ville)
// Scrape soirees pour n'importe quelle ville.
// Usage: POST /scrape-soirees { "ville": "Lyon" }
//
// Sources :
//   1. Eventbrite — JSON-LD Event, pagination par ville
//   2. OpenAgenda — API transverse, recherche "soiree"
//
// Deploy: supabase functions deploy scrape-soirees --no-verify-jwt

import { makeEvent, upsertEvents, withErrorLogging, isFutureDate, type ScrapedEvent } from "../_shared/db.ts";
import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";

const SCRAPER = "scrape-soirees";
const OPENAGENDA_KEY = Deno.env.get("OPENAGENDA_API_KEY") || "";

const CITIES: Record<string, { eventbriteSlug: string }> = {
  "Toulouse":         { eventbriteSlug: "toulouse" },
  "Paris":            { eventbriteSlug: "paris" },
  "Lyon":             { eventbriteSlug: "lyon" },
  "Marseille":        { eventbriteSlug: "marseille" },
  "Bordeaux":         { eventbriteSlug: "bordeaux" },
  "Lille":            { eventbriteSlug: "lille" },
  "Nantes":           { eventbriteSlug: "nantes" },
  "Strasbourg":       { eventbriteSlug: "strasbourg" },
  "Nice":             { eventbriteSlug: "nice" },
  "Montpellier":      { eventbriteSlug: "montpellier" },
  "Rennes":           { eventbriteSlug: "rennes" },
  "Grenoble":         { eventbriteSlug: "grenoble" },
  "Dijon":            { eventbriteSlug: "dijon" },
  "Angers":           { eventbriteSlug: "angers" },
  "Reims":            { eventbriteSlug: "reims" },
  "Toulon":           { eventbriteSlug: "toulon" },
  "Saint-Etienne":    { eventbriteSlug: "saint-etienne" },
  "Clermont-Ferrand": { eventbriteSlug: "clermont-ferrand" },
  "Le Havre":         { eventbriteSlug: "le-havre" },
  "Aix-en-Provence":  { eventbriteSlug: "aix-en-provence" },
  "Brest":            { eventbriteSlug: "brest" },
  "Amiens":           { eventbriteSlug: "amiens" },
  "Annecy":           { eventbriteSlug: "annecy" },
  "Besancon":         { eventbriteSlug: "besancon" },
  "Metz":             { eventbriteSlug: "metz" },
  "Rouen":            { eventbriteSlug: "rouen" },
  "Nancy":            { eventbriteSlug: "nancy" },
  "Avignon":          { eventbriteSlug: "avignon" },
  "Colmar":           { eventbriteSlug: "colmar" },
  "Bayonne":          { eventbriteSlug: "bayonne" },
  "Nimes":            { eventbriteSlug: "nimes" },
  "Geneve":           { eventbriteSlug: "geneve" },
};

// ─── 1. EVENTBRITE ────────────────────────────────────────────
async function scrapeEventbrite(ville: string, slug: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  const maxPages = 3;

  for (let page = 1; page <= maxPages; page++) {
    const url = `https://www.eventbrite.fr/d/france--${slug}/soiree/?page=${page}`;
    let html: string;
    try {
      html = await fetchHtml(url, 12000);
    } catch {
      break;
    }

    const ldRegex = /<script\s+type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/g;
    let match: RegExpExecArray | null;
    let found = 0;

    while ((match = ldRegex.exec(html)) !== null) {
      try {
        const json = JSON.parse(match[1]);

        // ItemList
        if (json["@type"] === "ItemList" && Array.isArray(json.itemListElement)) {
          for (const item of json.itemListElement) {
            const ev = item.item || item;
            if (!ev.name || !ev.startDate) continue;
            found++;

            const dateDebut = ev.startDate.substring(0, 10);
            if (!isFutureDate(dateDebut)) continue;

            let horaires = "";
            if (ev.startDate.includes("T")) {
              const [h, m] = ev.startDate.split("T")[1].split(":");
              horaires = `${h}h${m || "00"}`;
            }

            const slug2 = ev.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
            events.push(makeEvent({
              identifiant: `eb_soiree_${slug2}_${dateDebut}`,
              source: "eventbrite_soiree",
              rubrique: "night",
              nom_de_la_manifestation: cleanHtml(ev.name),
              descriptif_court: cleanHtml((ev.description || "").substring(0, 400)),
              date_debut: dateDebut,
              date_fin: ev.endDate ? ev.endDate.substring(0, 10) : dateDebut,
              horaires,
              lieu_nom: ev.location?.name || "",
              commune: ev.location?.address?.addressLocality || ville,
              ville,
              type_de_manifestation: "Soiree",
              categorie_de_la_manifestation: "Soiree",
              photo_url: typeof ev.image === "string" ? ev.image : (ev.image?.url || ""),
              reservation_site_internet: ev.url || "",
            }));
          }
        }

        // Event unique
        if (json["@type"] === "Event") {
          if (!json.name || !json.startDate) continue;
          found++;
          const dateDebut = json.startDate.substring(0, 10);
          if (!isFutureDate(dateDebut)) continue;

          let horaires = "";
          if (json.startDate.includes("T")) {
            const [h, m] = json.startDate.split("T")[1].split(":");
            horaires = `${h}h${m || "00"}`;
          }

          const slug2 = json.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
          events.push(makeEvent({
            identifiant: `eb_soiree_${slug2}_${dateDebut}`,
            source: "eventbrite_soiree",
            rubrique: "night",
            nom_de_la_manifestation: cleanHtml(json.name),
            date_debut: dateDebut,
            date_fin: dateDebut,
            horaires,
            lieu_nom: json.location?.name || "",
            commune: ville,
            ville,
            type_de_manifestation: "Soiree",
            categorie_de_la_manifestation: "Soiree",
            photo_url: typeof json.image === "string" ? json.image : "",
            reservation_site_internet: json.url || "",
          }));
        }
      } catch { /* skip */ }
    }

    if (found === 0) break;
  }

  console.log(`[eventbrite/${ville}] ${events.length} soirees`);
  return events;
}

// ─── 2. OPENAGENDA ────────────────────────────────────────────
async function scrapeOpenAgenda(ville: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  if (!OPENAGENDA_KEY) return events;

  const searches = ["soiree", "soiree dansante", "DJ", "afterwork"];
  const seen = new Set<string>();

  for (const search of searches) {
    try {
      const params = new URLSearchParams({
        key: OPENAGENDA_KEY,
        search,
        city: ville,
        size: "50",
        sort: "timings.asc",
      });

      const res = await fetch(`https://api.openagenda.com/v2/events?${params.toString()}`, {
        headers: { "User-Agent": "MaCityApp/1.0" },
        signal: AbortSignal.timeout(12000),
      });
      if (!res.ok) continue;

      const data = await res.json();
      const records = data.events || [];

      for (const e of records) {
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
        const link = e.canonicalUrl || "";

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        const dedupKey = `${slug}_${dateDebut}`;
        if (seen.has(dedupKey)) continue;
        seen.add(dedupKey);

        events.push(makeEvent({
          identifiant: `oa_soiree_${slug}_${dateDebut}`,
          source: "openagenda_soiree",
          rubrique: "night",
          nom_de_la_manifestation: title,
          descriptif_court: description,
          date_debut: dateDebut,
          date_fin: (e.lastTiming?.end || firstTiming.begin || "").substring(0, 10),
          horaires,
          lieu_nom: loc.name || "",
          commune: loc.city || ville,
          ville,
          type_de_manifestation: "Soiree",
          categorie_de_la_manifestation: "Soiree",
          photo_url: photoUrl,
          reservation_site_internet: link,
        }));
      }
    } catch { /* skip */ }
  }

  console.log(`[openagenda-soiree/${ville}] ${events.length} soirees`);
  return events;
}

// ─── 3. ALLEVENTS.IN ──────────────────────────────────────────
// API JSON multi-villes avec images et horaires
async function scrapeAllEvents(ville: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  const citySlug = ville.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z]+/g, "-");

  for (let page = 1; page <= 3; page++) {
    try {
      const res = await fetch("https://allevents.in/api/events/list", {
        method: "POST",
        headers: {
          "User-Agent": "Mozilla/5.0",
          "Content-Type": "application/json",
          "Referer": `https://allevents.in/${citySlug}/parties`,
        },
        body: JSON.stringify({
          city: citySlug,
          country: "france",
          page,
          rows: 20,
          popular: true,
          venue: [],
          keywords: "",
          type: "",
          ids: [],
          sdate: "",
          edate: "",
        }),
        signal: AbortSignal.timeout(12000),
      });

      if (!res.ok) break;
      const data = await res.json();
      const items = data.data || [];
      if (items.length === 0) break;

      for (const e of items) {
        const title = cleanHtml(e.eventname || "");
        if (!title) continue;

        const ts = parseInt(e.start_time || "0", 10);
        if (!ts) continue;
        const dt = new Date(ts * 1000);
        const dateDebut = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
        if (!isFutureDate(dateDebut)) continue;

        const horaires = `${String(dt.getHours()).padStart(2, "0")}h${String(dt.getMinutes()).padStart(2, "0")}`;
        const photoUrl = e.banner_url || e.thumb_url || "";
        const venueName = e.venue_name || "";
        const link = e.event_url || "";

        const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        events.push(makeEvent({
          identifiant: `allevents_${slug}_${dateDebut}`,
          source: "allevents_soiree",
          rubrique: "night",
          nom_de_la_manifestation: title,
          date_debut: dateDebut,
          date_fin: dateDebut,
          horaires,
          lieu_nom: venueName,
          commune: ville,
          ville,
          type_de_manifestation: "Soiree",
          categorie_de_la_manifestation: "Soiree",
          photo_url: photoUrl,
          reservation_site_internet: link,
        }));
      }
    } catch { break; }
  }

  console.log(`[allevents/${ville}] ${events.length} soirees`);
  return events;
}

// ─── DEDUP ────────────────────────────────────────────────────
function normalizeName(name: string): string {
  return name.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]/g, "");
}

function dedup(events: ScrapedEvent[]): ScrapedEvent[] {
  const seen = new Map<string, ScrapedEvent>();
  const priority: Record<string, number> = { eventbrite_soiree: 3, allevents_soiree: 2, openagenda_soiree: 1 };
  for (const e of events) {
    const key = `${normalizeName(e.nom_de_la_manifestation)}_${e.date_debut}`;
    const existing = seen.get(key);
    if (!existing || (priority[e.source] || 0) > (priority[existing.source] || 0)) {
      if (existing?.photo_url && !e.photo_url) e.photo_url = existing.photo_url;
      if (existing?.horaires && !e.horaires) e.horaires = existing.horaires;
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
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const config = CITIES[ville];
    if (!config) {
      return new Response(
        JSON.stringify({ error: `Ville '${ville}' inconnue. Disponibles: ${Object.keys(CITIES).join(", ")}` }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const [ebEvents, oaEvents, aeEvents] = await Promise.all([
      withErrorLogging(SCRAPER, "eventbrite", ville, () => scrapeEventbrite(ville, config.eventbriteSlug)),
      withErrorLogging(SCRAPER, "openagenda", ville, () => scrapeOpenAgenda(ville)),
      withErrorLogging(SCRAPER, "allevents", ville, () => scrapeAllEvents(ville)),
    ]);

    const allEvents = [...ebEvents, ...oaEvents, ...aeEvents];
    const deduped = dedup(allEvents);
    const count = await upsertEvents(deduped);

    return new Response(
      JSON.stringify({
        success: true,
        ville,
        count,
        sources: { eventbrite: ebEvents.length, openagenda: oaEvents.length, allevents: aeEvents.length, deduped: deduped.length },
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

// Edge Function: scrape-spectacles (multi-ville)
// Scrape spectacles/theatre/humour pour n'importe quelle ville.
// Usage: POST /scrape-spectacles { "ville": "Lyon" }
//
// Sources :
//   1. Eventbrite — JSON-LD Event, pagination par ville
//   2. OpenAgenda — API transverse (spectacle, theatre, humour, opera, danse)
//
// Deploy: supabase functions deploy scrape-spectacles --no-verify-jwt

import { makeEvent, upsertEvents, withErrorLogging, isFutureDate, type ScrapedEvent } from "../_shared/db.ts";
import { cleanHtml, fetchHtml } from "../_shared/html-utils.ts";

const SCRAPER = "scrape-spectacles";
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
  const keywords = ["spectacle", "theatre", "humour", "one-man-show"];

  for (const kw of keywords) {
    for (let page = 1; page <= 2; page++) {
      const url = `https://www.eventbrite.fr/d/france--${slug}/${kw}/?page=${page}`;
      let html: string;
      try {
        html = await fetchHtml(url, 12000);
      } catch { break; }

      const ldRegex = /<script\s+type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/g;
      let match: RegExpExecArray | null;
      let found = 0;

      while ((match = ldRegex.exec(html)) !== null) {
        try {
          const json = JSON.parse(match[1]);

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

              const evSlug = ev.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
              events.push(makeEvent({
                identifiant: `eb_spectacle_${evSlug}_${dateDebut}`,
                source: "day_spectacle",
                rubrique: "day",
                nom_de_la_manifestation: cleanHtml(ev.name),
                descriptif_court: cleanHtml((ev.description || "").substring(0, 400)),
                date_debut: dateDebut,
                date_fin: ev.endDate ? ev.endDate.substring(0, 10) : dateDebut,
                horaires,
                lieu_nom: ev.location?.name || "",
                commune: ev.location?.address?.addressLocality || ville,
                ville,
                type_de_manifestation: "Spectacle",
                categorie_de_la_manifestation: "Spectacle",
                photo_url: typeof ev.image === "string" ? ev.image : (ev.image?.url || ""),
                reservation_site_internet: ev.url || "",
              }));
            }
          }

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

            const evSlug = json.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
            events.push(makeEvent({
              identifiant: `eb_spectacle_${evSlug}_${dateDebut}`,
              source: "day_spectacle",
              rubrique: "day",
              nom_de_la_manifestation: cleanHtml(json.name),
              date_debut: dateDebut,
              date_fin: dateDebut,
              horaires,
              lieu_nom: json.location?.name || "",
              commune: ville,
              ville,
              type_de_manifestation: "Spectacle",
              categorie_de_la_manifestation: "Spectacle",
              photo_url: typeof json.image === "string" ? json.image : "",
              reservation_site_internet: json.url || "",
            }));
          }
        } catch { /* skip */ }
      }

      if (found === 0) break;
    }
  }

  console.log(`[eventbrite-spectacle/${ville}] ${events.length} spectacles`);
  return events;
}

// ─── 2. OPENAGENDA ────────────────────────────────────────────
async function scrapeOpenAgenda(ville: string): Promise<ScrapedEvent[]> {
  const events: ScrapedEvent[] = [];
  if (!OPENAGENDA_KEY) return events;

  const searches = ["spectacle", "theatre", "humour", "opera", "danse", "cirque", "stand up"];
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

        const evSlug = title.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 60);
        const dedupKey = `${evSlug}_${dateDebut}`;
        if (seen.has(dedupKey)) continue;
        seen.add(dedupKey);

        // Determiner la sous-categorie
        const titleLower = title.toLowerCase();
        const keywords = (e.keywords?.fr || []).join(" ").toLowerCase();
        let categorie = "Spectacle";
        if (titleLower.includes("theatre") || titleLower.includes("théâtre") || keywords.includes("theatre")) categorie = "Theatre";
        else if (titleLower.includes("humour") || titleLower.includes("stand up") || keywords.includes("humour")) categorie = "Stand up";
        else if (titleLower.includes("opera") || titleLower.includes("opéra") || keywords.includes("opera")) categorie = "Opera";
        else if (titleLower.includes("danse") || keywords.includes("danse")) categorie = "Spectacle";
        else if (titleLower.includes("cirque") || keywords.includes("cirque")) categorie = "Spectacle";

        events.push(makeEvent({
          identifiant: `oa_spectacle_${evSlug}_${dateDebut}`,
          source: "day_spectacle",
          rubrique: "day",
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
          reservation_site_internet: link,
        }));
      }
    } catch { /* skip */ }
  }

  console.log(`[openagenda-spectacle/${ville}] ${events.length} spectacles`);
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
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const slug = CITIES[ville];
    if (!slug) {
      return new Response(
        JSON.stringify({ error: `Ville '${ville}' inconnue` }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
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
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

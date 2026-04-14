// Edge Function: weekend-picks
// Strategie double execution :
//   - Lundi 8h UTC  : apercu brut sans IA (matchs + events, pas de resume editorial)
//   - Jeudi 17h UTC : selection IA avec resume editorial (ecrase le lundi)
//
// Params: POST { "ville": "Lyon", "no_ai": true, "force": true }
//   - no_ai  : skip Claude, prend les events bruts (lundi)
//   - force  : ignore le cache et regenere (obligatoire pour le jeudi)
//
// Deploy: supabase functions deploy weekend-picks --no-verify-jwt

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") || "";

const supaHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

// ─── Helpers date ────────────────────────────────────────────

function getWeekendDates(): { saturday: string; sunday: string; weekStart: string } {
  const now = new Date();
  const day = now.getDay(); // 0=dim, 6=sam

  // Prochain samedi
  const daysUntilSat = day === 6 ? 0 : day === 0 ? 6 : 6 - day;
  const saturday = new Date(now);
  saturday.setDate(now.getDate() + daysUntilSat);

  const sunday = new Date(saturday);
  sunday.setDate(saturday.getDate() + 1);

  // Lundi de cette semaine (pour le cache key)
  const monday = new Date(now);
  monday.setDate(now.getDate() - ((day + 6) % 7));

  const fmt = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

  return { saturday: fmt(saturday), sunday: fmt(sunday), weekStart: fmt(monday) };
}

// ─── Filtres matchs par ville ────────────────────────────────
// Pour certaines villes, on ne met en avant que les matchs des grands clubs
// (pas les petits championnats / clubs amateurs).
const CITY_TEAM_ALLOWLIST: Record<string, string[]> = {
  toulouse: ["toulouse fc", "tfc", "stade toulousain", "toulousain"],
};

function isAllowedMatch(ville: string, equipeDom: string, equipeExt: string): boolean {
  const allow = CITY_TEAM_ALLOWLIST[ville.toLowerCase()];
  if (!allow) return true; // pas de filtre pour cette ville
  const dom = (equipeDom || "").toLowerCase();
  const ext = (equipeExt || "").toLowerCase();
  return allow.some((t) => dom.includes(t) || ext.includes(t));
}

// ─── Detection categories ────────────────────────────────────
// Les salons/foires/expositions sont des events forts du week-end : on les
// prioritise comme les matchs (juste apres) dans la selection.
function isSalonOrExpo(categorie: string, nom: string): boolean {
  const cat = (categorie || "").toLowerCase();
  const titre = (nom || "").toLowerCase();
  if (/salon|expo|exposition|foire|vernissage/.test(cat)) return true;
  if (/\bsalon\b|\bexpo\b|\bexposition\b|\bfoire\b/.test(titre)) return true;
  return false;
}

function isConcert(categorie: string): boolean {
  return /concert|festival|musique/.test((categorie || "").toLowerCase());
}

function isTheatre(categorie: string): boolean {
  return /th[eé][aâ]tre/.test((categorie || "").toLowerCase());
}

function isSpectacle(categorie: string): boolean {
  // "Theatre" est techniquement un spectacle mais on les separe en 2 slots
  const cat = (categorie || "").toLowerCase();
  if (isTheatre(cat)) return false;
  return /spectacle|stand[ -]?up|humour|cirque|danse|opera/.test(cat);
}

// ─── Fetch events du week-end ────────────────────────────────

interface EventSummary {
  identifiant: string;
  nom: string;
  date: string;
  horaires: string;
  lieu: string;
  categorie: string;
  photo: string;
  rubrique: string;
  isMatch: boolean;
  isSalonExpo: boolean;
}

async function fetchWeekendEvents(ville: string, saturday: string, sunday: string): Promise<EventSummary[]> {
  const select =
    "select=identifiant,nom_de_la_manifestation,date_debut,date_fin,horaires,lieu_nom,categorie_de_la_manifestation,photo_url,rubrique";

  // Scraped events — Samedi (date_debut == samedi)
  const resSat = await fetch(
    `${SUPABASE_URL}/rest/v1/scraped_events?${select}&ville=ilike.${ville}&date_debut=gte.${saturday}&date_debut=lte.${saturday}&photo_url=neq.&order=date_debut.asc&limit=50`,
    { headers: supaHeaders },
  );
  const satEvents: Record<string, string>[] = await resSat.json();

  // Scraped events — Dimanche (date_debut == dimanche)
  const resSun = await fetch(
    `${SUPABASE_URL}/rest/v1/scraped_events?${select}&ville=ilike.${ville}&date_debut=gte.${sunday}&date_debut=lte.${sunday}&photo_url=neq.&order=date_debut.asc&limit=50`,
    { headers: supaHeaders },
  );
  const sunEvents: Record<string, string>[] = await resSun.json();

  // Events multi-jours en cours pendant le week-end
  // (commences avant samedi mais qui s'etalent dessus : foires, salons, expos)
  // Tri DESC pour prioriser ceux qui ont commence recemment (les plus
  // pertinents pour le week-end), pas les pieces de theatre qui tournent
  // depuis 6 semaines.
  const resOngoing = await fetch(
    `${SUPABASE_URL}/rest/v1/scraped_events?${select}&ville=ilike.${ville}&date_debut=lt.${saturday}&date_fin=gte.${saturday}&photo_url=neq.&order=date_debut.desc&limit=50`,
    { headers: supaHeaders },
  );
  const ongoingEvents: Record<string, string>[] = await resOngoing.json();

  // Dedupe par identifiant (au cas ou)
  const seenIds = new Set<string>();
  const allRows = [...satEvents, ...sunEvents, ...ongoingEvents].filter((e) => {
    if (seenIds.has(e.identifiant)) return false;
    seenIds.add(e.identifiant);
    return true;
  });

  const scrapedEvents: EventSummary[] = allRows.map((e) => ({
    identifiant: e.identifiant,
    nom: e.nom_de_la_manifestation,
    date: e.date_debut,
    horaires: e.horaires || "",
    lieu: e.lieu_nom || "",
    categorie: e.categorie_de_la_manifestation || "",
    photo: e.photo_url || "",
    rubrique: e.rubrique || "day",
    isMatch: false,
    isSalonExpo: isSalonOrExpo(
      e.categorie_de_la_manifestation || "",
      e.nom_de_la_manifestation || "",
    ),
  }));

  // Matchs sportifs du week-end (table matchs)
  const resMatchs = await fetch(
    `${SUPABASE_URL}/rest/v1/matchs?select=id,sport,equipe_dom,equipe_ext,competition,lieu,ville,date,heure,photo_url,logo_dom,logo_ext,url&ville=eq.${ville}&and=(date.gte.${saturday},date.lte.${sunday})&order=date.asc,heure.asc`,
    { headers: supaHeaders },
  );
  const allMatchRows: Record<string, string>[] = await resMatchs.json();
  const matchRows = allMatchRows.filter((m) =>
    isAllowedMatch(ville, m.equipe_dom || "", m.equipe_ext || "")
  );
  if (allMatchRows.length !== matchRows.length) {
    console.log(
      `[weekend-picks] ${ville}: filtre matchs ${allMatchRows.length} -> ${matchRows.length} (allowlist club)`,
    );
  }

  const matchEvents: EventSummary[] = matchRows.map((m) => {
    const title = m.equipe_ext
      ? `${m.equipe_dom} vs ${m.equipe_ext}`
      : m.equipe_dom || m.competition || m.sport;
    const photo = m.photo_url || m.logo_dom || m.logo_ext || "";
    return {
      identifiant: `match_${m.id}`,
      nom: title,
      date: m.date,
      horaires: m.heure || "",
      lieu: m.lieu || "",
      categorie: m.sport || "",
      photo,
      rubrique: "sport",
      isMatch: true,
      isSalonExpo: false,
    };
  });

  const salonsCount = scrapedEvents.filter((e) => e.isSalonExpo).length;
  console.log(
    `[weekend-picks] ${ville}: ${scrapedEvents.length} scraped events (${salonsCount} salons/expos) + ${matchEvents.length} matchs`,
  );
  return [...matchEvents, ...scrapedEvents];
}

// ─── Selection sans IA (lundi) ──────────────────────────────

// Composition cible : toujours 5 picks
//   slot 1 : 1 match
//   slot 2 : 1 salon / expo
//   slot 3 : 1 gros concert
//   slot 4 : 1 spectacle
//   slot 5 : 1 theatre
// Si un slot est vide, on comble avec un concert supplementaire (puis n'importe
// quel autre event avec photo).
const TARGET_PICKS = 5;

function selectWithoutAi(events: EventSummary[]): Pick[] {
  const matchPool = events.filter((e) => e.isMatch && e.nom);
  const salonPool = events.filter((e) => !e.isMatch && e.isSalonExpo && e.nom);
  const concertPool = events.filter((e) => !e.isMatch && !e.isSalonExpo && isConcert(e.categorie) && e.nom && e.photo);
  const spectaclePool = events.filter((e) => !e.isMatch && !e.isSalonExpo && isSpectacle(e.categorie) && e.nom && e.photo);
  const theatrePool = events.filter((e) => !e.isMatch && !e.isSalonExpo && isTheatre(e.categorie) && e.nom && e.photo);
  const fallbackPool = events.filter((e) => !e.isMatch && !e.isSalonExpo && e.nom && e.photo);

  const seen = new Set<string>();
  const selected: EventSummary[] = [];

  function takeOne(pool: EventSummary[]): boolean {
    for (const e of pool) {
      if (!seen.has(e.identifiant)) {
        seen.add(e.identifiant);
        selected.push(e);
        return true;
      }
    }
    return false;
  }

  takeOne(matchPool);
  takeOne(salonPool);
  takeOne(concertPool);
  takeOne(spectaclePool);
  takeOne(theatrePool);

  // Combler jusqu'a TARGET_PICKS : concerts en priorite, puis n'importe quoi
  while (selected.length < TARGET_PICKS) {
    if (!takeOne(concertPool) && !takeOne(spectaclePool) && !takeOne(theatrePool) && !takeOne(fallbackPool)) {
      break;
    }
  }

  return selected.map((e) => ({
    identifiant: e.identifiant,
    resume: e.isMatch
      ? `${e.categorie}${e.horaires ? ` — ${e.horaires}` : ""}${e.lieu ? ` — ${e.lieu}` : ""}`
      : `${e.categorie}${e.lieu ? ` a ${e.lieu}` : ""}`,
    isMatch: e.isMatch,
  }));
}

// ─── Selection avec IA (jeudi) ──────────────────────────────

interface Pick {
  identifiant: string;
  resume: string;
  isMatch: boolean;
}

async function askClaude(ville: string, events: EventSummary[]): Promise<Pick[]> {
  if (!ANTHROPIC_API_KEY) {
    console.log("[weekend-picks] pas de cle ANTHROPIC_API_KEY — fallback sans IA");
    return selectWithoutAi(events);
  }

  const eventList = events.map((e, i) => {
    let tag = "EVENT";
    if (e.isMatch) tag = "MATCH";
    else if (e.isSalonExpo) tag = "SALON/EXPO";
    else if (isConcert(e.categorie)) tag = "CONCERT";
    else if (isTheatre(e.categorie)) tag = "THEATRE";
    else if (isSpectacle(e.categorie)) tag = "SPECTACLE";
    return `${i + 1}. [${tag}] "${e.nom}" — ${e.date} ${e.horaires} — ${e.lieu} — ${e.categorie}`;
  }).join("\n");

  const prompt = `Tu es un expert local de ${ville}. Voici les evenements et matchs de ce week-end :

${eventList}

Selectionne EXACTEMENT 5 picks pour ce week-end, en respectant cette composition (1 par slot) :
  1. 1 MATCH sportif (si disponible)
  2. 1 SALON ou EXPO (foire, salon, exposition — si disponible)
  3. 1 GROS CONCERT (le concert le plus marquant / la plus grande salle / l'artiste le plus connu)
  4. 1 SPECTACLE (humour, danse, cirque, opera, stand-up — pas du theatre classique)
  5. 1 THEATRE (piece de theatre)

Si une categorie n'a aucun evenement disponible, REMPLACE par un autre concert (ou a defaut un autre event marquant). Tu DOIS toujours retourner 5 picks.

Pour chacun, ecris un resume editorial accrocheur de 1 a 2 phrases qui donne envie d'y aller.

Reponds UNIQUEMENT avec un JSON valide de 5 elements, sans commentaire :
[
  {"index": 1, "resume": "..."},
  {"index": 2, "resume": "..."},
  {"index": 3, "resume": "..."},
  {"index": 4, "resume": "..."},
  {"index": 5, "resume": "..."}
]

Les index correspondent aux numeros dans la liste ci-dessus.`;

  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }],
      }),
      signal: AbortSignal.timeout(15000),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error(`[weekend-picks] Claude error: ${res.status} ${err.substring(0, 200)}`);
      return selectWithoutAi(events);
    }

    const data = await res.json();
    const text = data.content?.[0]?.text || "[]";

    // Extraire le JSON de la reponse
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      console.error("[weekend-picks] Pas de JSON dans la reponse Claude");
      return selectWithoutAi(events);
    }

    const picks: { index: number; resume: string }[] = JSON.parse(jsonMatch[0]);

    return picks.map((p) => {
      const event = events[p.index - 1];
      if (!event) return null;
      return { identifiant: event.identifiant, resume: p.resume, isMatch: event.isMatch };
    }).filter((p): p is Pick => p !== null);
  } catch (e) {
    console.error(`[weekend-picks] Claude error: ${(e as Error).message}`);
    return selectWithoutAi(events);
  }
}

// ─── Cache ───────────────────────────────────────────────────

async function getCachedPicks(ville: string, weekStart: string): Promise<Record<string, unknown>[] | null> {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/weekend_picks?ville=eq.${ville}&week_start=eq.${weekStart}&select=picks`,
    { headers: supaHeaders },
  );
  const rows: { picks: Record<string, unknown>[] }[] = await res.json();
  if (rows.length > 0 && rows[0].picks.length > 0) {
    return rows[0].picks;
  }
  return null;
}

async function savePicks(ville: string, weekStart: string, picks: Record<string, unknown>[]): Promise<void> {
  await fetch(
    `${SUPABASE_URL}/rest/v1/weekend_picks?on_conflict=ville,week_start`,
    {
      method: "POST",
      headers: { ...supaHeaders, Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({ ville, week_start: weekStart, picks }),
    },
  );
}

// ─── Main ────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}));
    const ville: string = body.ville || "";
    const noAi: boolean = body.no_ai === true;
    const force: boolean = body.force === true;

    if (!ville) {
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { saturday, sunday, weekStart } = getWeekendDates();

    // Verifier le cache (sauf si force=true)
    if (!force) {
      const cached = await getCachedPicks(ville, weekStart);
      if (cached) {
        console.log(`[weekend-picks] ${ville}: cache hit (${cached.length} picks)`);
        return new Response(
          JSON.stringify({ success: true, ville, cached: true, picks: cached }),
          { headers: { "Content-Type": "application/json" } },
        );
      }
    }

    // Fetch events du week-end
    const events = await fetchWeekendEvents(ville, saturday, sunday);
    const matchCount = events.filter((e) => e.isMatch).length;
    console.log(`[weekend-picks] ${ville}: ${events.length} events (${matchCount} matchs) — mode: ${noAi ? "brut" : "IA"} — force: ${force}`);

    if (events.length === 0) {
      return new Response(
        JSON.stringify({ success: true, ville, picks: [], message: "Aucun event ce week-end" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // Selection : sans IA (lundi) ou avec IA (jeudi)
    const rawPicks = noAi
      ? selectWithoutAi(events)
      : await askClaude(ville, events);

    // Enrichir avec les donnees completes de l'event
    const enrichedPicks = rawPicks.map((p) => {
      const event = events.find((e) => e.identifiant === p.identifiant);
      return {
        identifiant: p.identifiant,
        resume: p.resume,
        titre: event?.nom || "",
        photo_url: event?.photo || "",
        date: event?.date || "",
        horaires: event?.horaires || "",
        lieu: event?.lieu || "",
        categorie: event?.categorie || "",
        is_match: event?.isMatch || false,
      };
    });

    // Sauvegarder dans le cache (ecrase le precedent grace a on_conflict)
    await savePicks(ville, weekStart, enrichedPicks);

    return new Response(
      JSON.stringify({
        success: true,
        ville,
        cached: false,
        mode: noAi ? "brut" : "ia",
        matchs: matchCount,
        picks: enrichedPicks,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error(`[weekend-picks] Error: ${(e as Error).message}`);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

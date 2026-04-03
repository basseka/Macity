// Edge Function: weekend-picks
// Utilise Claude pour selectionner les 3 events majeurs du week-end par ville.
// Les resultats sont caches dans la table weekend_picks.
//
// Usage: POST /weekend-picks { "ville": "Lyon" }
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
}

async function fetchWeekendEvents(ville: string, saturday: string, sunday: string): Promise<EventSummary[]> {
  // Samedi
  const resSat = await fetch(
    `${SUPABASE_URL}/rest/v1/scraped_events?select=identifiant,nom_de_la_manifestation,date_debut,horaires,lieu_nom,categorie_de_la_manifestation,photo_url,rubrique&ville=ilike.${ville}&date_debut=gte.${saturday}&date_debut=lte.${saturday}&photo_url=neq.&order=date_debut.asc&limit=50`,
    { headers: supaHeaders },
  );
  const satEvents: Record<string, string>[] = await resSat.json();

  // Dimanche
  const resSun = await fetch(
    `${SUPABASE_URL}/rest/v1/scraped_events?select=identifiant,nom_de_la_manifestation,date_debut,horaires,lieu_nom,categorie_de_la_manifestation,photo_url,rubrique&ville=ilike.${ville}&date_debut=gte.${sunday}&date_debut=lte.${sunday}&photo_url=neq.&order=date_debut.asc&limit=50`,
    { headers: supaHeaders },
  );
  const sunEvents: Record<string, string>[] = await resSun.json();

  const allEvents = [...satEvents, ...sunEvents];

  return allEvents.map((e) => ({
    identifiant: e.identifiant,
    nom: e.nom_de_la_manifestation,
    date: e.date_debut,
    horaires: e.horaires || "",
    lieu: e.lieu_nom || "",
    categorie: e.categorie_de_la_manifestation || "",
    photo: e.photo_url || "",
    rubrique: e.rubrique || "day",
  }));
}

// ─── Appel Claude ────────────────────────────────────────────

interface Pick {
  identifiant: string;
  resume: string;
}

async function askClaude(ville: string, events: EventSummary[]): Promise<Pick[]> {
  if (!ANTHROPIC_API_KEY) {
    console.log("[weekend-picks] pas de cle ANTHROPIC_API_KEY");
    // Fallback : prendre les 3 premiers events avec photo
    return events.slice(0, 3).map((e) => ({
      identifiant: e.identifiant,
      resume: `${e.categorie} a ${e.lieu || ville}`,
    }));
  }

  const eventList = events.map((e, i) =>
    `${i + 1}. "${e.nom}" — ${e.date} ${e.horaires} — ${e.lieu} — ${e.categorie}`
  ).join("\n");

  const prompt = `Tu es un expert local de ${ville}. Voici les evenements de ce week-end :

${eventList}

Choisis les 3 evenements les plus importants, populaires ou incontournables pour ce week-end.
Pour chacun, ecris un resume editorial accrocheur de 1 a 2 phrases qui donne envie d'y aller.

Reponds UNIQUEMENT avec un JSON valide, sans commentaire :
[
  {"index": 1, "resume": "..."},
  {"index": 2, "resume": "..."},
  {"index": 3, "resume": "..."}
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
        max_tokens: 512,
        messages: [{ role: "user", content: prompt }],
      }),
      signal: AbortSignal.timeout(15000),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error(`[weekend-picks] Claude error: ${res.status} ${err.substring(0, 200)}`);
      // Fallback
      return events.slice(0, 3).map((e) => ({
        identifiant: e.identifiant,
        resume: `${e.categorie} a ${e.lieu || ville}`,
      }));
    }

    const data = await res.json();
    const text = data.content?.[0]?.text || "[]";

    // Extraire le JSON de la reponse
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      console.error("[weekend-picks] Pas de JSON dans la reponse Claude");
      return events.slice(0, 3).map((e) => ({
        identifiant: e.identifiant,
        resume: `${e.categorie} a ${e.lieu || ville}`,
      }));
    }

    const picks: { index: number; resume: string }[] = JSON.parse(jsonMatch[0]);

    return picks.map((p) => {
      const event = events[p.index - 1];
      if (!event) return null;
      return { identifiant: event.identifiant, resume: p.resume };
    }).filter((p): p is Pick => p !== null);
  } catch (e) {
    console.error(`[weekend-picks] Claude error: ${(e as Error).message}`);
    return events.slice(0, 3).map((ev) => ({
      identifiant: ev.identifiant,
      resume: `${ev.categorie} a ${ev.lieu || ville}`,
    }));
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

    if (!ville) {
      return new Response(
        JSON.stringify({ error: "Parametre 'ville' requis" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const { saturday, sunday, weekStart } = getWeekendDates();

    // Verifier le cache
    const cached = await getCachedPicks(ville, weekStart);
    if (cached) {
      console.log(`[weekend-picks] ${ville}: cache hit (${cached.length} picks)`);
      return new Response(
        JSON.stringify({ success: true, ville, cached: true, picks: cached }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // Fetch events du week-end
    const events = await fetchWeekendEvents(ville, saturday, sunday);
    console.log(`[weekend-picks] ${ville}: ${events.length} events ce week-end (${saturday} - ${sunday})`);

    if (events.length === 0) {
      return new Response(
        JSON.stringify({ success: true, ville, picks: [], message: "Aucun event ce week-end" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // Demander a Claude
    const aiPicks = await askClaude(ville, events);

    // Enrichir avec les donnees completes de l'event
    const enrichedPicks = aiPicks.map((p) => {
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
      };
    });

    // Sauvegarder dans le cache
    await savePicks(ville, weekStart, enrichedPicks);

    return new Response(
      JSON.stringify({ success: true, ville, cached: false, picks: enrichedPicks }),
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

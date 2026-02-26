// supabase functions deploy run-scrapers --no-verify-jwt
//
// Orchestrateur : appelle les 4 groupes de scrapers sequentiellement.
// Declenche par pg_cron a 04:00 UTC chaque jour.
//
// Secrets requis : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { callEdgeFunction } from "../_shared/db.ts";

Deno.serve(async (_req) => {
  const startTime = Date.now();
  const results: Record<string, { count: number; errors: string[] }> = {};

  // Execute scrapers sequentially to avoid overloading
  for (const fn of ["scrape-culture", "scrape-night", "scrape-day", "scrape-sport"]) {
    console.log(`Starting ${fn}...`);
    results[fn] = await callEdgeFunction(fn);
    console.log(`${fn}: ${results[fn].count} events, ${results[fn].errors.length} errors`);
  }

  const totalCount = Object.values(results).reduce((s, r) => s + r.count, 0);
  const totalErrors = Object.values(results).reduce((s, r) => s + r.errors.length, 0);
  const durationSec = ((Date.now() - startTime) / 1000).toFixed(1);

  console.log(`Done: ${totalCount} events upserted, ${totalErrors} errors, ${durationSec}s`);

  return new Response(
    JSON.stringify({ totalCount, totalErrors, durationSec, results }),
    { headers: { "Content-Type": "application/json" } },
  );
});

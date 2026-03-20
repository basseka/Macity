-- Table de log des erreurs de scraping
-- Permet de monitorer les sources en échec par scraper et par ville.

CREATE TABLE IF NOT EXISTS scraper_errors (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at  timestamptz NOT NULL DEFAULT now(),
  scraper     text NOT NULL,          -- ex: "scrape-day", "scrape-culture", "scrape-sport"
  source      text NOT NULL,          -- ex: "ticketmaster", "songkick", "bikini", "eventbrite"
  ville       text NOT NULL DEFAULT '',-- ex: "toulouse", "lyon"
  error_type  text NOT NULL DEFAULT 'fetch', -- "fetch", "parse", "upsert", "timeout"
  message     text NOT NULL DEFAULT '',
  stack       text DEFAULT '',
  event_count int DEFAULT 0           -- nb events récupérés malgré l'erreur (partiel)
);

-- Index pour requêtes fréquentes
CREATE INDEX idx_scraper_errors_scraper ON scraper_errors (scraper, created_at DESC);
CREATE INDEX idx_scraper_errors_source ON scraper_errors (source, created_at DESC);

-- RLS : lecture anon pour le dashboard, écriture service_role
ALTER TABLE scraper_errors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can read scraper_errors"
  ON scraper_errors FOR SELECT TO anon USING (true);

CREATE POLICY "service_role can insert scraper_errors"
  ON scraper_errors FOR INSERT TO service_role WITH CHECK (true);

-- Auto-cleanup : supprimer les erreurs > 30 jours
SELECT cron.schedule(
  'cleanup-scraper-errors',
  '0 3 * * 0',  -- chaque dimanche à 3h
  $$DELETE FROM scraper_errors WHERE created_at < now() - interval '30 days'$$
);

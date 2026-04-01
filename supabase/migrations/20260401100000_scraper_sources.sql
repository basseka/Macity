-- Table pour gerer les sources de scraping par ville via la DB.
-- Permet d'ajouter/modifier des sources sans redeployer les Edge Functions.

CREATE TABLE IF NOT EXISTS scraper_concert_specific_source (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ville text NOT NULL,                    -- ex: 'Lyon', 'Bordeaux', 'all' (toutes les villes)
  rubrique text NOT NULL DEFAULT 'day',   -- day, night, sport, culture, family, food
  source_name text NOT NULL,              -- identifiant unique de la source ex: 'jds', 'bordeaux-tourisme'
  source_type text NOT NULL DEFAULT 'html_scraper', -- html_scraper, json_ld, api_json, rss
  url_template text NOT NULL,             -- URL avec placeholders: {ville}, {slug}, {page}

  -- Config de parsing (JSON)
  config jsonb NOT NULL DEFAULT '{}',
  -- Exemples de config:
  -- html_scraper:  { "card_selector": ".event-card", "title_field": "h3", "date_field": ".date", "date_format": "fr" }
  -- json_ld:       { "event_type": "MusicEvent", "max_pages": 5 }
  -- api_json:      { "events_path": "results", "title_path": "name", "date_path": "start_date" }
  -- rss:           { "title_tag": "title", "date_tag": "pubDate" }

  category text NOT NULL DEFAULT 'Concert', -- categorie des events crees: Concert, Spectacle, Festival...
  max_pages int NOT NULL DEFAULT 5,         -- nombre max de pages a scraper
  is_active boolean NOT NULL DEFAULT true,
  priority int NOT NULL DEFAULT 0,          -- ordre de priorite (plus haut = prioritaire pour dedup)

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE(ville, source_name)
);

-- Index
CREATE INDEX idx_scraper_concert_specific_source_ville ON scraper_concert_specific_source (ville, is_active);

-- RLS
ALTER TABLE scraper_concert_specific_source ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_scraper_concert_specific_source" ON scraper_concert_specific_source FOR SELECT TO anon USING (true);
CREATE POLICY "service_write_scraper_concert_specific_source" ON scraper_concert_specific_source FOR ALL TO service_role USING (true);

-- ══════════════════════════════════════════════════════════════════
-- SEED : sources existantes
-- ══════════════════════════════════════════════════════════════════

INSERT INTO scraper_concert_specific_source (ville, rubrique, source_name, source_type, url_template, config, category, max_pages, priority) VALUES

-- Sources globales (toutes les villes qui ont un metro area Songkick)
('all', 'day', 'songkick', 'json_ld', 'https://www.songkick.com/metro-areas/{metro_id}-france-{slug}',
 '{"event_type": "MusicEvent", "metro_ids": {"toulouse":28930,"paris":28909,"lyon":28889,"marseille":156979,"bordeaux":28851,"lille":28886,"nice":28903,"nantes":28901,"montpellier":28896,"strasbourg":28928,"rennes":28916}}',
 'Concert', 1, 2),

-- Paris
('Paris', 'day', 'offi', 'html_scraper', 'https://www.offi.fr/concerts/programme.html?npage={page}',
 '{"card_split": "id=\"minifiche_", "title_regex": "<span itemprop=\"name\">([^<]+)</span>", "date_regex": "startDate.*?content=\"(\\d{4}-\\d{2}-\\d{2})", "venue_regex": "event-place[^>]*>\\s*<a[^>]*>\\s*([^<]+)", "image_regex": "itemprop=\"image\"\\s+src=\"([^\"]+)\"", "link_regex": "itemprop=\"url\"[^>]*href=\"([^\"]+)\""}',
 'Concert', 10, 3),

-- Bordeaux
('Bordeaux', 'day', 'bordeaux-tourisme', 'json_ld', 'https://www.bordeaux-tourisme.com/agenda?thematiques=Musique&context=ajax_pager&page={page}',
 '{"event_type": "Event", "two_pass": true, "detail_url_regex": "href=\"(https://www.bordeaux-tourisme.com/evenements/[^\"]+\\.html)\"", "image_fallback_regex": "<img[^>]*src=\"(https://www.bordeaux-tourisme.com/sites/[^\"]+)\""}',
 'Concert', 3, 2),

-- Strasbourg / Colmar (JDS)
('Strasbourg', 'day', 'jds', 'json_ld', 'https://www.jds.fr/strasbourg/concerts',
 '{"event_type": "MusicEvent"}',
 'Concert', 1, 3),
('Colmar', 'day', 'jds', 'json_ld', 'https://www.jds.fr/colmar/concerts',
 '{"event_type": "MusicEvent"}',
 'Concert', 1, 3),

-- Nantes
('Nantes', 'day', 'voyage-nantes', 'html_scraper', 'https://www.levoyageanantes.fr/agenda/?categories=concert',
 '{"card_regex": "<a[^>]*href=\"(https://www.levoyageanantes.fr/activites/[^\"]+)\"[^>]*>([\\s\\S]*?)</a>"}',
 'Concert', 1, 2)

ON CONFLICT (ville, source_name) DO NOTHING;

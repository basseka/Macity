-- ============================================================
-- Migration : tables normalisees sports/leagues/teams/team_aliases
-- Compatible avec l'existant (team_logos + matchs)
-- ============================================================

-- 1. SPORTS (reference)
CREATE TABLE IF NOT EXISTS public.sports (
  id    SERIAL PRIMARY KEY,
  name  TEXT NOT NULL UNIQUE,        -- 'football', 'rugby', 'basketball', 'handball'
  label TEXT NOT NULL,               -- 'Football', 'Rugby', 'Basketball', 'Handball'
  icon  TEXT NOT NULL DEFAULT ''
);

INSERT INTO public.sports (name, label, icon) VALUES
  ('rugby',      'Rugby',      ''),
  ('football',   'Football',   ''),
  ('basketball', 'Basketball', ''),
  ('handball',   'Handball',   ''),
  ('boxe',       'Boxe',       ''),
  ('natation',   'Natation',   '')
ON CONFLICT (name) DO NOTHING;

-- 2. LEAGUES
CREATE TABLE IF NOT EXISTS public.leagues (
  id        SERIAL PRIMARY KEY,
  sport_id  INT NOT NULL REFERENCES sports(id),
  name      TEXT NOT NULL,
  country   TEXT NOT NULL DEFAULT 'FR',
  level     SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(sport_id, name)
);

INSERT INTO public.leagues (sport_id, name, country, level) VALUES
  -- Rugby
  ((SELECT id FROM sports WHERE name='rugby'), 'Top 14',    'FR', 1),
  ((SELECT id FROM sports WHERE name='rugby'), 'Pro D2',    'FR', 2),
  ((SELECT id FROM sports WHERE name='rugby'), 'Champions Cup', 'EU', 1),
  -- Football
  ((SELECT id FROM sports WHERE name='football'), 'Ligue 1',  'FR', 1),
  ((SELECT id FROM sports WHERE name='football'), 'Ligue 2',  'FR', 2),
  ((SELECT id FROM sports WHERE name='football'), 'Ligue Europa', 'EU', 1),
  -- Basketball
  ((SELECT id FROM sports WHERE name='basketball'), 'Betclic Elite', 'FR', 1),
  ((SELECT id FROM sports WHERE name='basketball'), 'NM1',     'FR', 2),
  ((SELECT id FROM sports WHERE name='basketball'), 'LFB',     'FR', 1),
  -- Handball
  ((SELECT id FROM sports WHERE name='handball'), 'Liqui Moly StarLigue', 'FR', 1),
  ((SELECT id FROM sports WHERE name='handball'), 'EHF European League',  'EU', 1),
  ((SELECT id FROM sports WHERE name='handball'), 'Coupe de France',      'FR', 1)
ON CONFLICT (sport_id, name) DO NOTHING;

-- 3. TEAMS
CREATE TABLE IF NOT EXISTS public.teams (
  id         SERIAL PRIMARY KEY,
  sport_id   INT NOT NULL REFERENCES sports(id),
  league_id  INT REFERENCES leagues(id),
  name       TEXT NOT NULL,
  short_name TEXT NOT NULL DEFAULT '',
  logo_url   TEXT NOT NULL DEFAULT '',
  city       TEXT NOT NULL DEFAULT '',
  stadium    TEXT NOT NULL DEFAULT '',
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(sport_id, name)
);

CREATE INDEX IF NOT EXISTS idx_teams_sport   ON teams(sport_id);
CREATE INDEX IF NOT EXISTS idx_teams_league  ON teams(league_id);
CREATE INDEX IF NOT EXISTS idx_teams_city    ON teams(city);

-- 4. TEAM_ALIASES
CREATE TABLE IF NOT EXISTS public.team_aliases (
  id      SERIAL PRIMARY KEY,
  team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  alias   TEXT NOT NULL,
  source  TEXT NOT NULL DEFAULT '',
  UNIQUE(alias, source)
);

CREATE INDEX IF NOT EXISTS idx_team_aliases_lower ON team_aliases (lower(alias));

-- 5. RLS
ALTER TABLE public.sports       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leagues      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_aliases ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='sports' AND policyname='anon_read_sports') THEN
    CREATE POLICY "anon_read_sports" ON public.sports FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='leagues' AND policyname='anon_read_leagues') THEN
    CREATE POLICY "anon_read_leagues" ON public.leagues FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='teams' AND policyname='anon_read_teams') THEN
    CREATE POLICY "anon_read_teams" ON public.teams FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='team_aliases' AND policyname='anon_read_aliases') THEN
    CREATE POLICY "anon_read_aliases" ON public.team_aliases FOR SELECT USING (true);
  END IF;
END $$;

-- 6. Fonction de resolution d'alias
CREATE OR REPLACE FUNCTION resolve_team(
  p_raw_name TEXT,
  p_source   TEXT DEFAULT ''
) RETURNS TABLE(team_id INT, team_name TEXT, logo_url TEXT, short_name TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT t.id, t.name, t.logo_url, t.short_name
  FROM teams t
  JOIN team_aliases ta ON ta.team_id = t.id
  WHERE lower(trim(ta.alias)) = lower(trim(p_raw_name))
    AND (p_source = '' OR ta.source = '' OR ta.source = p_source)
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- 7. Colonnes FK sur matchs (nullable, migration progressive)
ALTER TABLE public.matchs ADD COLUMN IF NOT EXISTS team_dom_id INT REFERENCES teams(id);
ALTER TABLE public.matchs ADD COLUMN IF NOT EXISTS team_ext_id INT REFERENCES teams(id);
ALTER TABLE public.matchs ADD COLUMN IF NOT EXISTS league_id   INT REFERENCES leagues(id);

CREATE INDEX IF NOT EXISTS idx_matchs_team_dom ON matchs(team_dom_id);
CREATE INDEX IF NOT EXISTS idx_matchs_team_ext ON matchs(team_ext_id);
CREATE INDEX IF NOT EXISTS idx_matchs_league   ON matchs(league_id);

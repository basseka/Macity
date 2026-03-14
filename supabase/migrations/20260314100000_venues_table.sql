-- Table unifiée pour tous les lieux/commerces, multi-ville.
-- Remplace les 24 fichiers statiques Dart hardcodés pour Toulouse.

CREATE TABLE IF NOT EXISTS venues (
  id            BIGSERIAL PRIMARY KEY,
  slug          TEXT NOT NULL,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',

  -- Classification
  mode          TEXT NOT NULL,            -- 'sport','culture','night','food','family','gaming','tourisme'
  category      TEXT NOT NULL,            -- 'Salle de fitness','Musee','Bar de nuit','Restaurant'...
  groupe        TEXT NOT NULL DEFAULT '', -- sous-groupe pour les sections
  type          TEXT NOT NULL DEFAULT '', -- classification fine (type de monument, cuisine, etc.)

  -- Localisation
  adresse       TEXT NOT NULL DEFAULT '',
  ville         TEXT NOT NULL DEFAULT 'Toulouse',
  latitude      DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude     DOUBLE PRECISION NOT NULL DEFAULT 0,
  lien_maps     TEXT NOT NULL DEFAULT '',

  -- Contact & infos
  horaires      TEXT NOT NULL DEFAULT '',
  telephone     TEXT NOT NULL DEFAULT '',
  tarif         TEXT NOT NULL DEFAULT '',

  -- Liens
  website_url   TEXT NOT NULL DEFAULT '',
  ticket_url    TEXT NOT NULL DEFAULT '',

  -- Media
  photo         TEXT NOT NULL DEFAULT '',

  -- Champs extras (restaurants, bars, etc.)
  theme         TEXT NOT NULL DEFAULT '',
  quartier      TEXT NOT NULL DEFAULT '',
  style         TEXT NOT NULL DEFAULT '',
  services      TEXT NOT NULL DEFAULT '',

  -- Flags
  has_online_ticket BOOLEAN NOT NULL DEFAULT FALSE,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,

  -- Timestamps
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(slug, ville)
);

-- Index pour les requêtes courantes
CREATE INDEX idx_venues_mode_ville ON venues (mode, ville) WHERE is_active = TRUE;
CREATE INDEX idx_venues_category_ville ON venues (category, ville) WHERE is_active = TRUE;
CREATE INDEX idx_venues_mode_category ON venues (mode, category) WHERE is_active = TRUE;

-- RLS : anon read, service_role write
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_venues" ON venues FOR SELECT TO anon USING (TRUE);
CREATE POLICY "service_write_venues" ON venues FOR ALL TO service_role USING (TRUE);

-- =============================================================================
-- Migration 005 : Table scraped_events pour stocker les resultats des scrapers.
-- Les colonnes correspondent aux @JsonKey du modele Event Flutter.
-- =============================================================================

CREATE TABLE public.scraped_events (
  id                                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  identifiant                       TEXT NOT NULL,
  source                            TEXT NOT NULL,    -- ex: 'theatre_sorano', 'nine_club'
  rubrique                          TEXT NOT NULL,    -- 'culture', 'night', 'day', 'family'

  -- Champs Event (memes noms que @JsonKey)
  nom_de_la_manifestation           TEXT NOT NULL DEFAULT '',
  descriptif_court                  TEXT NOT NULL DEFAULT '',
  descriptif_long                   TEXT NOT NULL DEFAULT '',
  date_debut                        TEXT NOT NULL DEFAULT '',
  date_fin                          TEXT NOT NULL DEFAULT '',
  horaires                          TEXT NOT NULL DEFAULT '',
  dates_affichage_horaires          TEXT NOT NULL DEFAULT '',
  lieu_nom                          TEXT NOT NULL DEFAULT '',
  lieu_adresse_2                    TEXT NOT NULL DEFAULT '',
  code_postal                       INTEGER NOT NULL DEFAULT 0,
  commune                           TEXT NOT NULL DEFAULT '',
  type_de_manifestation             TEXT NOT NULL DEFAULT '',
  categorie_de_la_manifestation     TEXT NOT NULL DEFAULT '',
  theme_de_la_manifestation         TEXT NOT NULL DEFAULT '',
  manifestation_gratuite            TEXT NOT NULL DEFAULT '',
  tarif_normal                      TEXT NOT NULL DEFAULT '',
  reservation_site_internet         TEXT NOT NULL DEFAULT '',
  reservation_telephone             TEXT NOT NULL DEFAULT '',
  station_metro_tram_a_proximite    TEXT NOT NULL DEFAULT '',

  scraped_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (identifiant)
);

-- Index pour les requetes frequentes
CREATE INDEX idx_scraped_rubrique ON public.scraped_events (rubrique);
CREATE INDEX idx_scraped_source ON public.scraped_events (source);
CREATE INDEX idx_scraped_date ON public.scraped_events (date_debut);

-- RLS : lecture anonyme, ecriture service_role uniquement
ALTER TABLE public.scraped_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read" ON public.scraped_events FOR SELECT USING (true);
CREATE POLICY "service_write" ON public.scraped_events FOR ALL USING (auth.role() = 'service_role');

-- Fonction de nettoyage des events expires (> 7 jours apres date_fin)
CREATE OR REPLACE FUNCTION public.cleanup_expired_scraped_events() RETURNS void LANGUAGE sql AS $$
  DELETE FROM public.scraped_events
  WHERE date_fin <> '' AND date_fin < TO_CHAR(NOW() - INTERVAL '7 days', 'YYYY-MM-DD');
$$;

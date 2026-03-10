-- ============================================================
-- Team logos : table de mapping + colonnes logo sur matchs
-- ============================================================

-- 1. Table team_logos : mapping nom d'equipe → URL logo public
CREATE TABLE IF NOT EXISTS public.team_logos (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  team_key    text NOT NULL UNIQUE,   -- clé de recherche (lowercase, partiel)
  logo_url    text NOT NULL,
  sport       text NOT NULL DEFAULT 'basketball'
);

ALTER TABLE public.team_logos ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'team_logos' AND policyname = 'anon_read_logos'
  ) THEN
    CREATE POLICY "anon_read_logos" ON public.team_logos FOR SELECT USING (true);
  END IF;
END $$;

-- Base URL Storage
-- https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/

-- 2. Insérer tous les logos basket
INSERT INTO public.team_logos (team_key, logo_url, sport) VALUES
  ('toulouse basketball', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_toulouse.png', 'basketball'),
  ('tbc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_toulouse.png', 'basketball'),
  ('mulhouse', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_mulhouse.png', 'basketball'),
  ('angers', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_angers.png', 'basketball'),
  ('boulogne', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_boulogne_sur_mer.png', 'basketball'),
  ('fos', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_fos_sur_mer.png', 'basketball'),
  ('sables', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_les_sables_dolone.png', 'basketball'),
  ('lorient', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_lorient.png', 'basketball'),
  ('pole france', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_pole_france.png', 'basketball'),
  ('salon', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_pays_salonais.png', 'basketball'),
  ('vitre', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_vitre.png', 'basketball'),
  ('vitré', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_vitre.png', 'basketball'),
  ('berck', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_berck_rang_du_filier.png', 'basketball'),
  ('charleville', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_charleville_mezieres.png', 'basketball'),
  ('fougeres', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_pays_de_fougeres.png', 'basketball'),
  ('fougères', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_pays_de_fougeres.png', 'basketball'),
  ('levallois', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_levallois.png', 'basketball'),
  ('lyon so', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_lyonso.png', 'basketball'),
  ('orchies', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_orchies.png', 'basketball'),
  ('rennes', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_rennes.png', 'basketball'),
  ('scabb', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_scabb.png', 'basketball'),
  ('tours', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_tours.png', 'basketball'),
  ('besancon', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_besancon.png', 'basketball'),
  ('besançon', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_besancon.png', 'basketball'),
  ('chartres', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_chartres.png', 'basketball'),
  ('le havre', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_lehavre.png', 'basketball'),
  ('metz', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_metz.png', 'basketball'),
  ('poissy', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_poissy.png', 'basketball'),
  ('saint-vallier', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_saint_vallier.png', 'basketball'),
  ('tarbes', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_tarbes_lourdes.png', 'basketball'),
  ('val-de-seine', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_val_de_seine.png', 'basketball'),
  -- Écussons rugby Top 14
  ('stade toulousain', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_toulouse.png', 'rugby'),
  ('montpellier', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_montpellier.png', 'rugby'),
  ('lou', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_lyon.png', 'rugby'),
  ('clermont', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_clermont.png', 'rugby'),
  ('bayonne', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bayonne.png', 'rugby'),
  ('castres', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_castres.png', 'rugby'),
  ('toulon', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_toulon.png', 'rugby'),
  ('racing', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_racing92.png', 'rugby'),
  ('pau', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_pau.png', 'rugby'),
  ('stade français', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_paris.png', 'rugby'),
  ('stade francais', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_paris.png', 'rugby'),
  ('la rochelle', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_larochelle.png', 'rugby'),
  ('montauban', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_montauban.png', 'rugby'),
  ('perpignan', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_perpignan.png', 'rugby'),
  ('bordeaux', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bordeaux.png', 'rugby'),
  ('bristol', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bristol.png', 'rugby'),
  -- Pro D2
  ('colomiers', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_colomiers.png', 'rugby'),
  ('brive', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_brive.png', 'rugby'),
  ('dax', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_dax.png', 'rugby'),
  ('carcassonne', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_carcassonne.png', 'rugby'),
  ('mont-de-marsan', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_montdemarcon.png', 'rugby'),
  ('beziers', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_beziers.png', 'rugby'),
  ('biarritz', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_biarritz.png', 'rugby'),
  ('grenoble', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_grenoble.png', 'rugby'),
  ('oyonnax', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_oyonnax.png', 'rugby'),
  ('provence', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_provence.png', 'rugby'),
  ('vannes', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_vannes.png', 'rugby'),
  ('agen', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_agen.png', 'rugby'),
  ('angouleme', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_angouleme.png', 'rugby'),
  ('aurillac', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_aurillac.png', 'rugby'),
  ('nevers', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_nevers.png', 'rugby'),
  ('valence', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_valence.png', 'rugby'),
  -- Football Ligue 1
  ('toulouse fc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_toulouseFC_foot.png', 'football'),
  ('tfc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_toulouseFC_foot.png', 'football'),
  ('paris saint-germain', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_psg_foot.png', 'football'),
  ('psg', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_psg_foot.png', 'football'),
  ('rc lens', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_lens_foot.png', 'football'),
  ('lens', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_lens_foot.png', 'football'),
  ('olympique lyonnais', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_olympique_lyonnais_foot.png', 'football'),
  ('olympique de marseille', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_marseille_foot.png', 'football'),
  ('marseille', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_marseille_foot.png', 'football'),
  ('losc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_losc_lille_foot.png', 'football'),
  ('lille', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_losc_lille_foot.png', 'football'),
  ('stade rennais', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_stade_rennes_foot.png', 'football'),
  ('as monaco', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_fc_monaco_foot.png', 'football'),
  ('monaco', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_fc_monaco_foot.png', 'football'),
  ('rc strasbourg', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_racing_club_strasbourg_foot.png', 'football'),
  ('strasbourg', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_racing_club_strasbourg_foot.png', 'football'),
  ('stade brestois', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_stade_brestois_foot.png', 'football'),
  ('brest', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_stade_brestois_foot.png', 'football'),
  ('fc lorient foot', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_fc_lorient_foot.png', 'football'),
  ('angers sco', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_angers_foot.png', 'football'),
  ('le havre ac', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_le_havre_foot.png', 'football'),
  ('paris fc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_paris_FC_foot.png', 'football'),
  ('ogc nice', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nice_foot.png', 'football'),
  ('nice', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nice_foot.png', 'football'),
  ('aj auxerre', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_aj_auxerre_foot.png', 'football'),
  ('auxerre', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_aj_auxerre_foot.png', 'football'),
  ('fc nantes', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nantes_foot.png', 'football'),
  ('nantes', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nantes_foot.png', 'football'),
  ('fc metz', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_FC_metz_foot.png', 'football'),
  -- Handball / Natation
  ('fenix', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_fenix.png', 'handball'),
  ('natation', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_natation.png', 'natation'),
  -- TMB basket
  ('tmb', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_toulouseBC.png', 'basketball'),
  ('toulouse metropole', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_toulouseBC.png', 'basketball')
ON CONFLICT (team_key) DO NOTHING;

-- 3. Ajouter colonnes logo_dom et logo_ext sur matchs
ALTER TABLE public.matchs ADD COLUMN IF NOT EXISTS logo_dom text DEFAULT '';
ALTER TABLE public.matchs ADD COLUMN IF NOT EXISTS logo_ext text DEFAULT '';

-- 4. Peupler les logos pour les matchs existants via team_logos
UPDATE public.matchs m
SET logo_dom = tl.logo_url
FROM public.team_logos tl
WHERE m.logo_dom = ''
  AND lower(m.equipe_dom) LIKE '%' || tl.team_key || '%';

UPDATE public.matchs m
SET logo_ext = tl.logo_url
FROM public.team_logos tl
WHERE m.logo_ext = ''
  AND lower(m.equipe_ext) LIKE '%' || tl.team_key || '%';

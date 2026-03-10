-- ============================================================
-- Seed : equipes + alias depuis les donnees team_logos existantes
-- ============================================================

-- ─── RUGBY TOP 14 ───────────────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Stade Toulousain', 'ST', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_toulouse.png', 'Toulouse', 'Stade Ernest-Wallon'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Montpellier Herault Rugby', 'MHR', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_montpellier.png', 'Montpellier', 'GGL Stadium'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'LOU Rugby', 'LOU', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_lyon.png', 'Lyon', 'Matmut Stadium'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'ASM Clermont Auvergne', 'ASM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_clermont.png', 'Clermont-Ferrand', 'Stade Marcel-Michelin'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Aviron Bayonnais', 'AB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bayonne.png', 'Bayonne', 'Stade Jean-Dauger'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Castres Olympique', 'CO', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_castres.png', 'Castres', 'Stade Pierre-Fabre'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'RC Toulon', 'RCT', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_toulon.png', 'Toulon', 'Stade Mayol'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Racing 92', 'R92', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_racing92.png', 'Nanterre', 'Paris La Defense Arena'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Section Paloise', 'SP', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_pau.png', 'Pau', 'Stade du Hameau'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Stade Francais Paris', 'SFP', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_paris.png', 'Paris', 'Stade Jean-Bouin'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Stade Rochelais', 'SR', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_larochelle.png', 'La Rochelle', 'Stade Marcel-Deflandre'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'Union Bordeaux-Begles', 'UBB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bordeaux.png', 'Bordeaux', 'Stade Chaban-Delmas'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'USAP Perpignan', 'USAP', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_perpignan.png', 'Perpignan', 'Stade Aime-Giral'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Top 14'),
   'US Montauban', 'USM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_montauban.png', 'Montauban', 'Stade Sapiac')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ─── RUGBY PRO D2 ──────────────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'Colomiers Rugby', 'USC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_colomiers.png', 'Colomiers', 'Stade Michel-Bendichou'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'CA Brive', 'CAB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_brive.png', 'Brive', 'Stade Amedee-Domenech'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'US Dax', 'USD', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_dax.png', 'Dax', 'Stade Maurice-Boyau'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'US Carcassonne', 'USC-Carc', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_carcassonne.png', 'Carcassonne', 'Stade Albert-Domec'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'Stade Montois', 'SM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_montdemarcon.png', 'Mont-de-Marsan', 'Stade Guy-Boniface'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'AS Beziers', 'ASB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_beziers.png', 'Beziers', 'Stade de la Mediterranee'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'Biarritz Olympique', 'BO', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_biarritz.png', 'Biarritz', 'Parc des Sports Aguilera'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'FC Grenoble', 'FCG', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_grenoble.png', 'Grenoble', 'Stade des Alpes'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'US Oyonnax', 'USO', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_oyonnax.png', 'Oyonnax', 'Stade Charles-Mathon'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'Provence Rugby', 'PR', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_provence.png', 'Aix-en-Provence', 'Stade Maurice-David'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'RC Vannes', 'RCV', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_vannes.png', 'Vannes', 'Stade de la Rabine'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'SU Agen', 'SUA', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_agen.png', 'Agen', 'Stade Armandie'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'SA XV Charente', 'SAXV', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_angouleme.png', 'Angouleme', 'Stade Chanzy'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'SA Aurillac', 'SAA', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_aurillac.png', 'Aurillac', 'Stade Jean-Alric'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'USON Nevers', 'USON', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_nevers.png', 'Nevers', 'Stade du Pre-Fleuri'),
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Pro D2'),
   'Valence Romans Drome Rugby', 'VRDR', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_valence.png', 'Valence', 'Stade Pompidou')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ─── RUGBY CHAMPIONS CUP ───────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='rugby'), (SELECT id FROM leagues WHERE name='Champions Cup'),
   'Bristol Bears', 'BB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecussion_bristol.png', 'Bristol', 'Ashton Gate')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ─── FOOTBALL LIGUE 1 ──────────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Toulouse FC', 'TFC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_toulouseFC_foot.png', 'Toulouse', 'Stadium de Toulouse'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Paris Saint-Germain', 'PSG', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_psg_foot.png', 'Paris', 'Parc des Princes'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Olympique de Marseille', 'OM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_marseille_foot.png', 'Marseille', 'Stade Velodrome'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Olympique Lyonnais', 'OL', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_olympique_lyonnais_foot.png', 'Lyon', 'Groupama Stadium'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'LOSC Lille', 'LOSC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_losc_lille_foot.png', 'Lille', 'Stade Pierre-Mauroy'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'AS Monaco', 'ASM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_fc_monaco_foot.png', 'Monaco', 'Stade Louis-II'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'RC Lens', 'RCL', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_lens_foot.png', 'Lens', 'Stade Bollaert-Delelis'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Stade Rennais', 'SRFC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_stade_rennes_foot.png', 'Rennes', 'Roazhon Park'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'RC Strasbourg', 'RCSA', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_racing_club_strasbourg_foot.png', 'Strasbourg', 'Stade de la Meinau'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Stade Brestois', 'SB29', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_stade_brestois_foot.png', 'Brest', 'Stade Francis-Le Ble'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'OGC Nice', 'OGCN', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nice_foot.png', 'Nice', 'Allianz Riviera'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'AJ Auxerre', 'AJA', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_aj_auxerre_foot.png', 'Auxerre', 'Stade Abbe-Deschamps'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Angers SCO', 'SCO', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_angers_foot.png', 'Angers', 'Stade Raymond-Kopa'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Le Havre AC', 'HAC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_le_havre_foot.png', 'Le Havre', 'Stade Oceane'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'FC Nantes', 'FCN', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_nantes_foot.png', 'Nantes', 'Stade de la Beaujoire'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'Paris FC', 'PFC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_paris_FC_foot.png', 'Paris', 'Stade Charléty'),
  ((SELECT id FROM sports WHERE name='football'), (SELECT id FROM leagues WHERE name='Ligue 1'),
   'FC Metz', 'FCM', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/football/logo_FC_metz_foot.png', 'Metz', 'Stade Saint-Symphorien')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ─── BASKETBALL ─────────────────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='basketball'), (SELECT id FROM leagues WHERE name='NM1'),
   'Toulouse Basketball Club', 'TBC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_toulouse.png', 'Toulouse', 'Palais des Sports Andre Brouat'),
  ((SELECT id FROM sports WHERE name='basketball'), (SELECT id FROM leagues WHERE name='LFB'),
   'Toulouse Metropole Basket', 'TMB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_toulouseBC.png', 'Toulouse', 'Gymnase Compans-Caffarelli'),
  ((SELECT id FROM sports WHERE name='basketball'), (SELECT id FROM leagues WHERE name='NM1'),
   'Mulhouse Basket Agglomeration', 'MBA', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_mulhouse.png', 'Mulhouse', ''),
  ((SELECT id FROM sports WHERE name='basketball'), (SELECT id FROM leagues WHERE name='NM1'),
   'Angers BC', 'ABC', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_angers.png', 'Angers', ''),
  ((SELECT id FROM sports WHERE name='basketball'), (SELECT id FROM leagues WHERE name='NM1'),
   'Le Havre STB', 'STB', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/basket/logo_lehavre.png', 'Le Havre', '')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ─── HANDBALL ───────────────────────────────────────────────

INSERT INTO public.teams (sport_id, league_id, name, short_name, logo_url, city, stadium) VALUES
  ((SELECT id FROM sports WHERE name='handball'), (SELECT id FROM leagues WHERE name='Liqui Moly StarLigue'),
   'Fenix Toulouse', 'FTH', 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/team-logos/ecussons/ecu_fenix.png', 'Toulouse', 'Palais des Sports Andre Brouat')
ON CONFLICT (sport_id, name) DO NOTHING;

-- ============================================================
-- ALIASES — chaque variante connue des scrapers
-- ============================================================

-- Rugby Top 14
INSERT INTO team_aliases (team_id, alias, source) VALUES
  ((SELECT id FROM teams WHERE name='Stade Toulousain' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Stade Toulousain', ''),
  ((SELECT id FROM teams WHERE name='Stade Toulousain' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Stade Toulousain Rugby', ''),
  ((SELECT id FROM teams WHERE name='LOU Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'LOU Rugby', ''),
  ((SELECT id FROM teams WHERE name='LOU Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'LOU', ''),
  ((SELECT id FROM teams WHERE name='LOU Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Lyon', 'espn'),
  ((SELECT id FROM teams WHERE name='Montpellier Herault Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Montpellier', ''),
  ((SELECT id FROM teams WHERE name='Montpellier Herault Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'MHR', ''),
  ((SELECT id FROM teams WHERE name='ASM Clermont Auvergne' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Clermont', ''),
  ((SELECT id FROM teams WHERE name='ASM Clermont Auvergne' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'ASM', ''),
  ((SELECT id FROM teams WHERE name='Aviron Bayonnais' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Bayonne', ''),
  ((SELECT id FROM teams WHERE name='Aviron Bayonnais' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Aviron Bayonnais', ''),
  ((SELECT id FROM teams WHERE name='Castres Olympique' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Castres', ''),
  ((SELECT id FROM teams WHERE name='RC Toulon' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Toulon', ''),
  ((SELECT id FROM teams WHERE name='RC Toulon' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'RC Toulon', ''),
  ((SELECT id FROM teams WHERE name='Racing 92' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Racing 92', ''),
  ((SELECT id FROM teams WHERE name='Racing 92' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Racing', ''),
  ((SELECT id FROM teams WHERE name='Section Paloise' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Pau', ''),
  ((SELECT id FROM teams WHERE name='Section Paloise' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Section Paloise', ''),
  ((SELECT id FROM teams WHERE name='Stade Francais Paris' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Stade Francais', ''),
  ((SELECT id FROM teams WHERE name='Stade Rochelais' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'La Rochelle', ''),
  ((SELECT id FROM teams WHERE name='Stade Rochelais' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Stade Rochelais', ''),
  ((SELECT id FROM teams WHERE name='Union Bordeaux-Begles' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Bordeaux', ''),
  ((SELECT id FROM teams WHERE name='Union Bordeaux-Begles' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'UBB', ''),
  ((SELECT id FROM teams WHERE name='USAP Perpignan' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Perpignan', ''),
  ((SELECT id FROM teams WHERE name='USAP Perpignan' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'USAP', ''),
  ((SELECT id FROM teams WHERE name='US Montauban' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Montauban', ''),
  -- Pro D2
  ((SELECT id FROM teams WHERE name='Colomiers Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Colomiers Rugby', ''),
  ((SELECT id FROM teams WHERE name='Colomiers Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Colomiers', ''),
  ((SELECT id FROM teams WHERE name='CA Brive' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Brive', ''),
  ((SELECT id FROM teams WHERE name='US Dax' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Dax', ''),
  ((SELECT id FROM teams WHERE name='US Carcassonne' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Carcassonne', ''),
  ((SELECT id FROM teams WHERE name='Stade Montois' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Mont-de-Marsan', ''),
  ((SELECT id FROM teams WHERE name='AS Beziers' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Beziers', ''),
  ((SELECT id FROM teams WHERE name='AS Beziers' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Béziers', ''),
  ((SELECT id FROM teams WHERE name='Biarritz Olympique' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Biarritz', ''),
  ((SELECT id FROM teams WHERE name='FC Grenoble' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Grenoble', ''),
  ((SELECT id FROM teams WHERE name='US Oyonnax' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Oyonnax', ''),
  ((SELECT id FROM teams WHERE name='Provence Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Provence', ''),
  ((SELECT id FROM teams WHERE name='Provence Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Provence Rugby', ''),
  ((SELECT id FROM teams WHERE name='RC Vannes' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Vannes', ''),
  ((SELECT id FROM teams WHERE name='SU Agen' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Agen', ''),
  ((SELECT id FROM teams WHERE name='SA XV Charente' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Angouleme', ''),
  ((SELECT id FROM teams WHERE name='SA XV Charente' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Soyaux-Angoulême', 'colomiers-rugby.com'),
  ((SELECT id FROM teams WHERE name='SA Aurillac' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Aurillac', ''),
  ((SELECT id FROM teams WHERE name='USON Nevers' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Nevers', ''),
  ((SELECT id FROM teams WHERE name='Valence Romans Drome Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Valence', ''),
  ((SELECT id FROM teams WHERE name='Valence Romans Drome Rugby' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Valence-Romans', 'colomiers-rugby.com'),
  ((SELECT id FROM teams WHERE name='Bristol Bears' AND sport_id=(SELECT id FROM sports WHERE name='rugby')), 'Bristol', ''),
  -- Football
  ((SELECT id FROM teams WHERE name='Toulouse FC' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Toulouse FC', ''),
  ((SELECT id FROM teams WHERE name='Toulouse FC' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'TFC', ''),
  ((SELECT id FROM teams WHERE name='Paris Saint-Germain' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Paris Saint-Germain', ''),
  ((SELECT id FROM teams WHERE name='Paris Saint-Germain' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'PSG', ''),
  ((SELECT id FROM teams WHERE name='Paris Saint-Germain' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Paris SG', ''),
  ((SELECT id FROM teams WHERE name='Olympique de Marseille' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Olympique de Marseille', ''),
  ((SELECT id FROM teams WHERE name='Olympique de Marseille' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Marseille', ''),
  ((SELECT id FROM teams WHERE name='Olympique de Marseille' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'OM', ''),
  ((SELECT id FROM teams WHERE name='Olympique Lyonnais' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Olympique Lyonnais', ''),
  ((SELECT id FROM teams WHERE name='Olympique Lyonnais' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'OL', ''),
  ((SELECT id FROM teams WHERE name='LOSC Lille' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'LOSC', ''),
  ((SELECT id FROM teams WHERE name='LOSC Lille' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Lille', ''),
  ((SELECT id FROM teams WHERE name='AS Monaco' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'AS Monaco', ''),
  ((SELECT id FROM teams WHERE name='AS Monaco' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Monaco', ''),
  ((SELECT id FROM teams WHERE name='RC Lens' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'RC Lens', ''),
  ((SELECT id FROM teams WHERE name='RC Lens' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Lens', ''),
  ((SELECT id FROM teams WHERE name='Stade Rennais' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Stade Rennais', ''),
  ((SELECT id FROM teams WHERE name='Stade Rennais' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Rennes', ''),
  ((SELECT id FROM teams WHERE name='RC Strasbourg' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'RC Strasbourg', ''),
  ((SELECT id FROM teams WHERE name='RC Strasbourg' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Strasbourg', ''),
  ((SELECT id FROM teams WHERE name='Stade Brestois' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Stade Brestois', ''),
  ((SELECT id FROM teams WHERE name='Stade Brestois' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Brest', ''),
  ((SELECT id FROM teams WHERE name='OGC Nice' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'OGC Nice', ''),
  ((SELECT id FROM teams WHERE name='OGC Nice' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Nice', ''),
  ((SELECT id FROM teams WHERE name='AJ Auxerre' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'AJ Auxerre', ''),
  ((SELECT id FROM teams WHERE name='AJ Auxerre' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Auxerre', ''),
  ((SELECT id FROM teams WHERE name='Angers SCO' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Angers SCO', ''),
  ((SELECT id FROM teams WHERE name='Le Havre AC' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Le Havre AC', ''),
  ((SELECT id FROM teams WHERE name='FC Nantes' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'FC Nantes', ''),
  ((SELECT id FROM teams WHERE name='FC Nantes' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Nantes', ''),
  ((SELECT id FROM teams WHERE name='Paris FC' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'Paris FC', ''),
  ((SELECT id FROM teams WHERE name='FC Metz' AND sport_id=(SELECT id FROM sports WHERE name='football')), 'FC Metz', ''),
  -- Basketball
  ((SELECT id FROM teams WHERE name='Toulouse Basketball Club' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Toulouse Basketball Club', 'ffbb'),
  ((SELECT id FROM teams WHERE name='Toulouse Basketball Club' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Toulouse BC', ''),
  ((SELECT id FROM teams WHERE name='Toulouse Basketball Club' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'TBC', ''),
  ((SELECT id FROM teams WHERE name='Toulouse Metropole Basket' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Toulouse Metropole Basket', 'lfb'),
  ((SELECT id FROM teams WHERE name='Toulouse Metropole Basket' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'TMB', ''),
  ((SELECT id FROM teams WHERE name='Mulhouse Basket Agglomeration' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Mulhouse', 'ffbb'),
  ((SELECT id FROM teams WHERE name='Angers BC' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Angers', 'ffbb'),
  ((SELECT id FROM teams WHERE name='Le Havre STB' AND sport_id=(SELECT id FROM sports WHERE name='basketball')), 'Le Havre', 'ffbb'),
  -- Handball
  ((SELECT id FROM teams WHERE name='Fenix Toulouse' AND sport_id=(SELECT id FROM sports WHERE name='handball')), 'Fenix Toulouse', ''),
  ((SELECT id FROM teams WHERE name='Fenix Toulouse' AND sport_id=(SELECT id FROM sports WHERE name='handball')), 'Fenix', ''),
  ((SELECT id FROM teams WHERE name='Fenix Toulouse' AND sport_id=(SELECT id FROM sports WHERE name='handball')), 'Toulouse', 'fenix-toulouse.fr')
ON CONFLICT (alias, source) DO NOTHING;

-- ============================================================
-- Enrichir les matchs existants avec les nouveaux team IDs
-- ============================================================
UPDATE matchs m
SET team_dom_id = t.id
FROM team_aliases ta
JOIN teams t ON t.id = ta.team_id
WHERE lower(trim(m.equipe_dom)) = lower(trim(ta.alias))
  AND m.team_dom_id IS NULL;

UPDATE matchs m
SET team_ext_id = t.id
FROM team_aliases ta
JOIN teams t ON t.id = ta.team_id
WHERE lower(trim(m.equipe_ext)) = lower(trim(ta.alias))
  AND m.team_ext_id IS NULL;

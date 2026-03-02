-- =============================================================================
-- Migration : Table sport_venues pour stocker les salles/clubs de sport.
-- Remplace les fichiers statiques Dart (fitness, boxe, golf, raquette).
-- =============================================================================

CREATE TABLE public.sport_venues (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom         TEXT NOT NULL,
  categorie   TEXT NOT NULL DEFAULT '',
  sport_type  TEXT NOT NULL,   -- fitness, boxe, golf, tennis, padel, squash, ping-pong, badminton
  adresse     TEXT NOT NULL DEFAULT '',
  site_web    TEXT NOT NULL DEFAULT '',
  lien_maps   TEXT NOT NULL DEFAULT '',
  photo       TEXT NOT NULL DEFAULT 'assets/images/pochette_autre.png',
  latitude    DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude   DOUBLE PRECISION NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour les requetes frequentes
CREATE INDEX idx_sport_venues_type ON public.sport_venues (sport_type);
CREATE INDEX idx_sport_venues_active ON public.sport_venues (is_active);

-- RLS : lecture anonyme, ecriture service_role uniquement
ALTER TABLE public.sport_venues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read" ON public.sport_venues FOR SELECT USING (true);
CREATE POLICY "service_write" ON public.sport_venues FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- INSERT : Fitness venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- Basic-Fit
('Basic-Fit Jean Jaures', '💪 Basic-Fit', 'fitness', '58 Allee Jean Jaures, 31000 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+58+Allee+Jean+Jaures+Toulouse', 'assets/images/pochette_autre.png', 43.6047, 1.4500),
('Basic-Fit Compans Caffarelli', '💪 Basic-Fit', 'fitness', '3 Esplanade Compans Caffarelli, 31000 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Compans+Caffarelli+Toulouse', 'assets/images/pochette_autre.png', 43.6115, 1.4330),
('Basic-Fit Faubourg Bonnefoy', '💪 Basic-Fit', 'fitness', '14 Rue du Faubourg Bonnefoy, 31500 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Faubourg+Bonnefoy+Toulouse', 'assets/images/pochette_autre.png', 43.6080, 1.4600),
('Basic-Fit Sesquieres', '💪 Basic-Fit', 'fitness', '2 Rue de l''Egalite, 31200 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Sesquieres+Toulouse', 'assets/images/pochette_autre.png', 43.6380, 1.4370),
('Basic-Fit Avenue des Etats-Unis', '💪 Basic-Fit', 'fitness', 'Avenue des Etats-Unis, 31200 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Avenue+des+Etats+Unis+Toulouse', 'assets/images/pochette_autre.png', 43.6290, 1.4460),
('Basic-Fit Bd de Geneve', '💪 Basic-Fit', 'fitness', '27 Boulevard de Geneve, 31200 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Boulevard+de+Geneve+Toulouse', 'assets/images/pochette_autre.png', 43.6340, 1.4490),
('Basic-Fit Route d''Espagne', '💪 Basic-Fit', 'fitness', '39 Route d''Espagne, 31100 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Route+d+Espagne+Toulouse', 'assets/images/pochette_autre.png', 43.5730, 1.4230),
('Basic-Fit Avenue de Larrieu', '💪 Basic-Fit', 'fitness', '10 Avenue de Larrieu, 31100 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Avenue+de+Larrieu+Toulouse', 'assets/images/pochette_autre.png', 43.5780, 1.4090),
('Basic-Fit Marcel Dassault', '💪 Basic-Fit', 'fitness', '29 bis Av. Marcel Dassault, 31500 Toulouse', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Marcel+Dassault+Toulouse', 'assets/images/pochette_autre.png', 43.5860, 1.4880),
('Basic-Fit Balma', '💪 Basic-Fit', 'fitness', '27 Avenue des Arenes, 31130 Balma', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Balma+Avenue+des+Arenes', 'assets/images/pochette_autre.png', 43.6100, 1.4980),
('Basic-Fit Colomiers', '💪 Basic-Fit', 'fitness', '3 Rue Yves Brunaud, 31770 Colomiers', 'https://www.basic-fit.com/fr-fr/salles-de-sport/toulouse', 'https://www.google.com/maps/search/Basic-Fit+Colomiers+Rue+Yves+Brunaud', 'assets/images/pochette_autre.png', 43.6110, 1.3350),
-- Fitness Park
('Fitness Park Bayard', '🏋️ Fitness Park', 'fitness', '11 Rue de Bayard, 31000 Toulouse', 'https://www.fitnesspark.fr/club/toulouse-bayard/', 'https://www.google.com/maps/search/Fitness+Park+Toulouse+Bayard', 'assets/images/pochette_autre.png', 43.6110, 1.4540),
('Fitness Park La Cartoucherie', '🏋️ Fitness Park', 'fitness', '1 Allee Georges Charpak, 31300 Toulouse', 'https://www.fitnesspark.fr/club/toulouse-la-cartoucherie/', 'https://www.google.com/maps/search/Fitness+Park+Cartoucherie+Toulouse', 'assets/images/pochette_autre.png', 43.6000, 1.4010),
('Fitness Park Montaudran', '🏋️ Fitness Park', 'fitness', 'Place Marcel Bouilloux-Lafont, 31400 Toulouse', 'https://www.fitnesspark.fr/club/toulouse-montaudran/', 'https://www.google.com/maps/search/Fitness+Park+Montaudran+Toulouse', 'assets/images/pochette_autre.png', 43.5720, 1.4870),
('Fitness Park Blagnac', '🏋️ Fitness Park', 'fitness', '2 Impasse Emile Zola, 31700 Blagnac', 'https://www.fitnesspark.fr/club/blagnac/', 'https://www.google.com/maps/search/Fitness+Park+Blagnac', 'assets/images/pochette_autre.png', 43.6370, 1.3780),
('Fitness Park Colomiers', '🏋️ Fitness Park', 'fitness', 'ZAC du Perget, 31770 Colomiers', 'https://www.fitnesspark.fr/club/colomiers/', 'https://www.google.com/maps/search/Fitness+Park+Colomiers', 'assets/images/pochette_autre.png', 43.6020, 1.3260),
('Fitness Park Saint-Orens', '🏋️ Fitness Park', 'fitness', '5 Allee des Champs Pinsons, 31650 Saint-Orens', 'https://www.fitnesspark.fr/club/saint-orens-de-gameville/', 'https://www.google.com/maps/search/Fitness+Park+Saint+Orens', 'assets/images/pochette_autre.png', 43.5510, 1.5310),
-- Interval
('Interval Jean Jaures', '🔥 Interval', 'fitness', '17 Allee Jean Jaures, 31000 Toulouse', 'https://www.interval.fr/salles-de-sport/toulouse-centre/', 'https://www.google.com/maps/search/Interval+Jean+Jaures+Toulouse', 'assets/images/pochette_autre.png', 43.6040, 1.4510),
('Interval Carnot Challenge', '🔥 Interval', 'fitness', '2 Rue Castellane, 31000 Toulouse', 'https://www.interval.fr/salles-de-sport/toulouse-carnot-challenge/', 'https://www.google.com/maps/search/Interval+Carnot+Challenge+Toulouse', 'assets/images/pochette_autre.png', 43.6050, 1.4530),
('Interval Balma', '🔥 Interval', 'fitness', '175 Avenue Jean Chaubet, 31500 Toulouse', 'https://www.interval.fr/salles-de-sport/balma/', 'https://www.google.com/maps/search/Interval+Balma+Jean+Chaubet', 'assets/images/pochette_autre.png', 43.6090, 1.4770),
('Interval Blagnac', '🔥 Interval', 'fitness', '8 Rue Raymond Grimaud, 31700 Blagnac', 'https://www.interval.fr/salles-de-sport/', 'https://www.google.com/maps/search/Interval+Blagnac', 'assets/images/pochette_autre.png', 43.6380, 1.3830),
('Interval Labege', '🔥 Interval', 'fitness', '137 Rue Garance, 31670 Labege', 'https://www.interval.fr/salles-de-sport/', 'https://www.google.com/maps/search/Interval+Labege', 'assets/images/pochette_autre.png', 43.5380, 1.5060),
('Interval L''Union', '🔥 Interval', 'fitness', '9 Avenue de Toulouse, 31240 L''Union', 'https://www.interval.fr/salles-de-sport/', 'https://www.google.com/maps/search/Interval+L+Union', 'assets/images/pochette_autre.png', 43.6480, 1.4750),
-- Keepcool
('Keepcool Capitole', '😎 Keepcool', 'fitness', '6 Impasse Baour Lormian, 31000 Toulouse', 'https://www.keepcool.fr/s/salle-de-sport-toulouse-capitole', 'https://www.google.com/maps/search/Keepcool+Capitole+Toulouse', 'assets/images/pochette_autre.png', 43.6040, 1.4410),
('Keepcool Matabiau', '😎 Keepcool', 'fitness', '46 Boulevard Matabiau, 31000 Toulouse', 'https://www.keepcool.fr/s/salle-de-sport-toulouse-matabiau', 'https://www.google.com/maps/search/Keepcool+Matabiau+Toulouse', 'assets/images/pochette_autre.png', 43.6130, 1.4570),
('Keepcool Atlanta', '😎 Keepcool', 'fitness', '2 Rue Maurice Caunes, 31200 Toulouse', 'https://www.keepcool.fr/s/salle-de-sport-toulouse-atlanta', 'https://www.google.com/maps/search/Keepcool+Atlanta+Toulouse', 'assets/images/pochette_autre.png', 43.6360, 1.4660),
('Keepcool Labege', '😎 Keepcool', 'fitness', '60 Rue Pierre et Marie Curie, 31670 Labege', 'https://www.keepcool.fr/v/salle-de-sport-toulouse', 'https://www.google.com/maps/search/Keepcool+Labege', 'assets/images/pochette_autre.png', 43.5410, 1.5120),
-- L'Orange Bleue
('L''Orange Bleue Toulouse', '🍊 L''Orange Bleue', 'fitness', '7 Rue Marc Miguet, 31200 Toulouse', 'https://www.lorangebleue.fr/ville/toulouse/', 'https://www.google.com/maps/search/L+Orange+Bleue+Toulouse', 'assets/images/pochette_autre.png', 43.6340, 1.4540),
('L''Orange Bleue Balma', '🍊 L''Orange Bleue', 'fitness', '26 Avenue Galilee, 31130 Balma', 'https://wellness.lorangebleue.fr/balma/', 'https://www.google.com/maps/search/L+Orange+Bleue+Balma', 'assets/images/pochette_autre.png', 43.6090, 1.4960),
-- Independantes
('Sun Form L''Union', '⭐ Salles independantes', 'fitness', 'ZA 18 bis, Rue d''Ariane, 31240 L''Union', 'https://sun-form.fr/', 'https://www.google.com/maps/search/Sun+Form+Rue+d+Ariane+L+Union', 'assets/images/pochette_autre.png', 43.6530, 1.4780),
('Sun Form Roques-sur-Garonne', '⭐ Salles independantes', 'fitness', '6 Avenue des Muriers, 31120 Roques-sur-Garonne', 'https://sun-form.fr/salle-de-sport/toulouse-roques/', 'https://www.google.com/maps/search/Sun+Form+6+Avenue+des+Muriers+Roques+sur+Garonne', 'assets/images/pochette_autre.png', 43.5080, 1.3870),
('Gymnasia Rouffiac-Tolosan', '⭐ Salles independantes', 'fitness', '40 Route d''Albi, 31180 Rouffiac-Tolosan', 'https://www.gymnasia.fr/', 'https://www.google.com/maps/search/Gymnasia+40+Route+d+Albi+Rouffiac+Tolosan', 'assets/images/pochette_autre.png', 43.6670, 1.5090),
('Gymnasia Tournefeuille', '⭐ Salles independantes', 'fitness', '1 Bd Jean Gay, 31170 Tournefeuille', 'https://www.gymnasia.fr/', 'https://www.google.com/maps/search/Gymnasia+1+Bd+Jean+Gay+Tournefeuille', 'assets/images/pochette_autre.png', 43.5830, 1.3470),
('Clark Powell Balma', '⭐ Salles independantes', 'fitness', '21 Chemin de Gabardie, 31200 Toulouse', 'https://clarkpowell.fr/en/club/balma/', 'https://www.google.com/maps/search/Clark+Powell+Balma+21+Chemin+de+Gabardie+Toulouse', 'assets/images/pochette_autre.png', 43.6280, 1.4720),
('Clark Powell Montaudran', '⭐ Salles independantes', 'fitness', '9 Avenue de la Marcaissonne, 31400 Toulouse', 'https://clarkpowell.fr/en/club/montaudran/', 'https://www.google.com/maps/search/Clark+Powell+Montaudran+9+Avenue+Marcaissonne+Toulouse', 'assets/images/pochette_autre.png', 43.5780, 1.4780),
-- CrossFit
('CrossFit Grand Rond', '🏅 CrossFit', 'fitness', '8 Rue des Potiers, 31000 Toulouse', 'https://crossfitgrandrond.fr/', 'https://www.google.com/maps/search/CrossFit+Grand+Rond+Toulouse', 'assets/images/pochette_autre.png', 43.5990, 1.4540),
('CrossFit Minimes', '🏅 CrossFit', 'fitness', '7 Rue Marc Miguet, 31200 Toulouse', 'https://www.crossfitminimes.com/', 'https://www.google.com/maps/search/CrossFit+Minimes+Toulouse', 'assets/images/pochette_autre.png', 43.6340, 1.4540),
('CrossFit 272', '🏅 CrossFit', 'fitness', '272 Route de Launaguet, 31200 Toulouse', 'https://www.crossfit272.com/', 'https://www.google.com/maps/search/CrossFit+272+Toulouse', 'assets/images/pochette_autre.png', 43.6530, 1.4530),
('CrossFit Saint-Simon', '🏅 CrossFit', 'fitness', '31 bis Route de Seysses, 31100 Toulouse', 'https://www.crossfitsaintsimon.com/', 'https://www.google.com/maps/search/CrossFit+Saint+Simon+Toulouse', 'assets/images/pochette_autre.png', 43.5680, 1.3930),
('Be Unit CrossFit Montaudran', '🏅 CrossFit', 'fitness', '164 Route de Revel, 31400 Toulouse', 'https://www.beunitcrossfit.com/', 'https://www.google.com/maps/search/Be+Unit+CrossFit+Montaudran+Toulouse', 'assets/images/pochette_autre.png', 43.5700, 1.4890),
('CrossFit Blagnac', '🏅 CrossFit', 'fitness', '19 Rue Raymond Grimaud, 31700 Blagnac', 'https://crossfitblagnac.fr/', 'https://www.google.com/maps/search/CrossFit+Blagnac', 'assets/images/pochette_autre.png', 43.6380, 1.3830),
-- Independantes (suite)
('Sporting Form', '⭐ Salles independantes', 'fitness', '272 Route de Launaguet, 31200 Toulouse', 'https://www.sporting-form.fr/', 'https://www.google.com/maps/search/Sporting+Form+Toulouse', 'assets/images/pochette_autre.png', 43.6530, 1.4530),
('Movida Gambetta', '⭐ Salles independantes', 'fitness', '25 Rue Leon Gambetta, 31000 Toulouse', 'https://www.movidaclub.fr/gambetta/', 'https://www.google.com/maps/search/Movida+Club+Gambetta+Toulouse', 'assets/images/pochette_autre.png', 43.6060, 1.4450),
('Movida Arcole', '⭐ Salles independantes', 'fitness', '8 Boulevard d''Arcole, 31000 Toulouse', 'https://www.movidaclub.fr/arcole/', 'https://www.google.com/maps/search/Movida+8+Boulevard+d+Arcole+Toulouse', 'assets/images/pochette_autre.png', 43.6120, 1.4530),
('Movida Gramont', '⭐ Salles independantes', 'fitness', '101 Route d''Agde, 31500 Toulouse', 'https://www.movidaclub.fr/', 'https://www.google.com/maps/search/Movida+101+Route+d+Agde+Toulouse', 'assets/images/pochette_autre.png', 43.6250, 1.4830),
('Movida Castanet', '⭐ Salles independantes', 'fitness', '69 Avenue de Toulouse, 31320 Castanet-Tolosan', 'https://www.movidaclub.fr/', 'https://www.google.com/maps/search/Movida+69+Avenue+de+Toulouse+Castanet+Tolosan', 'assets/images/pochette_autre.png', 43.5160, 1.4990),
('Movida Blagnac', '⭐ Salles independantes', 'fitness', '1 Impasse Emile Zola, 31700 Blagnac', 'https://www.movidaclub.fr/', 'https://www.google.com/maps/search/Movida+1+Impasse+Emile+Zola+Blagnac', 'assets/images/pochette_autre.png', 43.6370, 1.3780),
('Movida Portet-sur-Garonne', '⭐ Salles independantes', 'fitness', '10 Allee Pablo Picasso, 31120 Portet-sur-Garonne', 'https://www.movidaclub.fr/', 'https://www.google.com/maps/search/Movida+10+Allee+Pablo+Picasso+Portet+sur+Garonne', 'assets/images/pochette_autre.png', 43.5200, 1.4050),
('Le 10 Boulevard', '⭐ Salles independantes', 'fitness', '10 Boulevard de la Gare, 31500 Toulouse', 'https://www.10boulevard.com/', 'https://www.google.com/maps/search/Le+10+Boulevard+Toulouse', 'assets/images/pochette_autre.png', 43.5950, 1.4560),
('L''Atelier Sport', '⭐ Salles independantes', 'fitness', '34 Rue des Paradoux, 31000 Toulouse', 'https://www.latelier-sport.fr/', 'https://www.google.com/maps/search/L+Atelier+Sport+Toulouse', 'assets/images/pochette_autre.png', 43.5990, 1.4380),
('UCPA La Cartoucherie', '⭐ Salles independantes', 'fitness', '10 Place de la Charte des Libertes, 31300 Toulouse', 'https://www.ucpa.com/centres-sportifs/cartoucherie-toulouse', 'https://www.google.com/maps/search/UCPA+Cartoucherie+Toulouse', 'assets/images/pochette_autre.png', 43.6000, 1.4010),
-- Studios & cours collectifs
('Happyness Studio', '🧘 Studios & cours collectifs', 'fitness', '13 Rue Sainte-Ursule, 31000 Toulouse', 'https://happyness-studios.com/', 'https://www.google.com/maps/search/Happyness+Studio+Toulouse', 'assets/images/pochette_autre.png', 43.6020, 1.4440),
('Body Pilates', '🧘 Studios & cours collectifs', 'fitness', '5 Boulevard Lazare Carnot, 31000 Toulouse', 'https://www.body-pilates.com/', 'https://www.google.com/maps/search/Body+Pilates+Toulouse', 'assets/images/pochette_autre.png', 43.6030, 1.4530),
('Sanskriti Yoga Studio', '🧘 Studios & cours collectifs', 'fitness', '105 Rue Bonnat, 31400 Toulouse', 'https://www.sanskriti31.com/', 'https://www.google.com/maps/search/Sanskriti+Yoga+Toulouse', 'assets/images/pochette_autre.png', 43.5810, 1.4620),
('Encore Pilates Le Studio', '🧘 Studios & cours collectifs', 'fitness', '9 Rue Viguerie, 31300 Toulouse', 'https://www.lestudioencorepilates.com/', 'https://www.google.com/maps/search/Encore+Pilates+Le+Studio+Toulouse', 'assets/images/pochette_autre.png', 43.5980, 1.4310),
('The Roof Toulouse', '🧘 Studios & cours collectifs', 'fitness', '10 Place de la Charte des Libertes, 31300 Toulouse', 'https://toulouse.theroof.fr/', 'https://www.google.com/maps/search/The+Roof+Toulouse+Cartoucherie', 'assets/images/pochette_autre.png', 43.6000, 1.4010);

-- =============================================================================
-- INSERT : Boxing venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- Boxe anglaise & sports de combat
('Toulouse Fight Club Montaudran', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Montaudran, 31400 Toulouse', '', 'https://www.google.com/maps/search/Toulouse+Fight+Club+Montaudran', 'assets/images/pochette_boxe.png', 43.5770, 1.4830),
('Boxing Center Toulouse Minimes', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Quartier des Minimes, 31200 Toulouse', 'https://www.boxingcenter.fr/', 'https://www.google.com/maps/search/Boxing+Center+Toulouse+Minimes', 'assets/images/pochette_boxe.png', 43.6280, 1.4350),
('Boxing Center Toulouse St Cyprien', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Saint-Cyprien, 31300 Toulouse', 'https://www.boxingcenter.fr/', 'https://www.google.com/maps/search/Boxing+Center+Toulouse+Saint+Cyprien', 'assets/images/pochette_boxe.png', 43.5990, 1.4310),
('Boxing Center Balma Gramont', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Balma Gramont, 31130 Balma', 'https://www.boxingcenter.fr/', 'https://www.google.com/maps/search/Boxing+Center+Balma+Gramont', 'assets/images/pochette_boxe.png', 43.6200, 1.4970),
('BOXOUM', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/BOXOUM+Toulouse', 'assets/images/pochette_boxe.png', 43.6047, 1.4442),
('Ladjal Boxing Club Toulouse', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/Ladjal+Boxing+Club+Toulouse', 'assets/images/pochette_boxe.png', 43.6100, 1.4380),
('Royal Boxing Toulouse', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/Royal+Boxing+Toulouse', 'assets/images/pochette_boxe.png', 43.6020, 1.4500),
('As Boxing', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/As+Boxing+Toulouse', 'assets/images/pochette_boxe.png', 43.5950, 1.4420),
('Boxing Club Toulousain', '🥊 Boxe anglaise & sports de combat', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/Boxing+Club+Toulousain', 'assets/images/pochette_boxe.png', 43.6080, 1.4460),
-- Multi-boxe & boxe francaise
('Toulouse Centre Boxe Francaise Savate', '🥋 Multi-boxe & boxe francaise', 'boxe', 'Toulouse', '', 'https://www.google.com/maps/search/Toulouse+Centre+Boxe+Francaise+Savate', 'assets/images/pochette_boxe.png', 43.6030, 1.4480),
('Toulouse Multi Boxing La Faourette', '🥋 Multi-boxe & boxe francaise', 'boxe', 'La Faourette, 31100 Toulouse', '', 'https://www.google.com/maps/search/Toulouse+Multi+Boxing+La+Faourette', 'assets/images/pochette_boxe.png', 43.5850, 1.4200),
('Toulouse Multi Boxing Rangueil', '🥋 Multi-boxe & boxe francaise', 'boxe', 'Rangueil, 31400 Toulouse', '', 'https://www.google.com/maps/search/Toulouse+Multi+Boxing+Rangueil', 'assets/images/pochette_boxe.png', 43.5700, 1.4600),
-- Proche de Toulouse
('Blagnac Boxing Club', '🏙️ Proche de Toulouse', 'boxe', 'Blagnac', '', 'https://www.google.com/maps/search/Blagnac+Boxing+Club', 'assets/images/pochette_boxe.png', 43.6370, 1.3940);

-- =============================================================================
-- INSERT : Golf venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('Golf Club de Toulouse', '⛳ Golfs', 'golf', '2 Chemin de la Planho, 31320 Vieille-Toulouse', 'https://www.golfclubdetoulouse.fr/', 'https://www.google.com/maps/search/Golf+Club+de+Toulouse+Vieille+Toulouse', 'assets/images/pochette_autre.png', 43.5564, 1.4580),
('UGOLF Toulouse Seilh', '⛳ Golfs', 'golf', '2 Route de Grenade, 31840 Seilh', 'https://jouer.golf/golf/ugolf-toulouse-seilh/', 'https://www.google.com/maps/search/UGOLF+Toulouse+Seilh+Route+de+Grenade', 'assets/images/pochette_autre.png', 43.6694, 1.3547),
('UGOLF Toulouse La Ramee', '⛳ Golfs', 'golf', 'Avenue du General Eisenhower, 31170 Tournefeuille', 'https://www.golfdelaramee.fr/', 'https://www.google.com/maps/search/UGOLF+Toulouse+La+Ramee+Tournefeuille', 'assets/images/pochette_autre.png', 43.5813, 1.3460),
('UGOLF Toulouse Teoula', '⛳ Golfs', 'golf', '71 Avenue des Landes, 31830 Plaisance-du-Touch', 'https://jouer.golf/golf/ugolf-toulouse-teoula/', 'https://www.google.com/maps/search/UGOLF+Toulouse+Teoula+Plaisance+du+Touch', 'assets/images/pochette_autre.png', 43.5282, 1.2607),
('Golf de Palmola', '⛳ Golfs', 'golf', 'Route d''Albi, 31660 Buzet-sur-Tarn', 'https://www.golfdepalmola.com/', 'https://www.google.com/maps/search/Golf+de+Palmola+Buzet+sur+Tarn', 'assets/images/pochette_autre.png', 43.7768, 1.6310),
('Estolosa Golf & Country Club', '⛳ Golfs', 'golf', '4 Chemin de Borde-Haute, 31280 Dremil-Lafage', 'https://www.estolosa.fr/', 'https://www.google.com/maps/search/Estolosa+Golf+Dremil+Lafage', 'assets/images/pochette_autre.png', 43.5868, 1.5824),
('Golf Saint Gabriel', '⛳ Golfs', 'golf', 'Castie, 31850 Montrabe', 'https://golfsaintgabriel.com/', 'https://www.google.com/maps/search/Golf+Saint+Gabriel+Montrabe', 'assets/images/pochette_autre.png', 43.6515, 1.5335),
('Golf de Garonne', '🏌️ Practices & initiations', 'golf', '5 Allee Charles Gandia, 31200 Toulouse', 'https://www.golfdegaronne.fr/', 'https://www.google.com/maps/search/Golf+de+Garonne+Toulouse+Sept+Deniers', 'assets/images/pochette_autre.png', 43.6266, 1.4153),
('Here We Golf', '🏌️ Practices & initiations', 'golf', '1 Rue Delacroix, 31000 Toulouse', 'https://en.herewegolf.fr/', 'https://www.google.com/maps/search/Here+We+Golf+Toulouse+Rue+Delacroix', 'assets/images/pochette_autre.png', 43.6058, 1.4540);

-- =============================================================================
-- INSERT : Tennis venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('Stade Toulousain Tennis Club', '🎾 Tennis', 'tennis', '116 Rue des Troenes, 31200 Toulouse', 'https://stadetoulousain-tennis-padel.com/', 'https://www.google.com/maps/search/Stade+Toulousain+Tennis+Club+116+Rue+des+Troenes+Toulouse', 'assets/images/pochette_autre.png', 43.6350, 1.4280),
('Olympe Tennis Club', '🎾 Tennis', 'tennis', '200 Route de Blagnac, 31200 Toulouse', 'https://club.fft.fr/olympe.tennis', 'https://www.google.com/maps/search/Olympe+Tennis+Club+200+Route+de+Blagnac+Toulouse', 'assets/images/pochette_autre.png', 43.6320, 1.4180),
('TAC Tennis Club Toulouse', '🎾 Tennis', 'tennis', 'Toulouse', 'https://www.tactennis.fr/', 'https://www.google.com/maps/search/TAC+Tennis+Club+Toulouse', 'assets/images/pochette_autre.png', 43.6047, 1.4442),
('ASPTT Toulouse Tennis', '🎾 Tennis', 'tennis', '47 Rue de Soupetard, 31500 Toulouse', 'https://toulouse.asptt.com/activity/tennis/', 'https://www.google.com/maps/search/ASPTT+Toulouse+47+Rue+Soupetard', 'assets/images/pochette_autre.png', 43.5920, 1.4680),
('Arnaune Tennis Club Toulouse', '🎾 Tennis', 'tennis', 'Toulouse', 'https://arnaunetennisclub.fr/', 'https://www.google.com/maps/search/Arnaune+Tennis+Club+Toulouse', 'assets/images/pochette_autre.png', 43.6150, 1.4350),
('Club de l''Hers', '🎾 Tennis', 'tennis', '23 Avenue de la Marqueille, 31650 Saint-Orens-de-Gameville', 'https://www.clubdelhers.fr/', 'https://www.google.com/maps/search/Club+de+l+Hers+Saint+Orens+de+Gameville', 'assets/images/pochette_autre.png', 43.5500, 1.5310),
('Blagnac Tennis Club', '🎾 Tennis', 'tennis', '11 Avenue des Tilleuls, 31700 Blagnac', 'https://blagnactennisclub.fr/', 'https://www.google.com/maps/search/Blagnac+Tennis+Club+11+Avenue+des+Tilleuls', 'assets/images/pochette_autre.png', 43.6380, 1.3920),
('US Colomiers Tennis', '🎾 Tennis', 'tennis', '2 bis Allee des Alpilles, 31770 Colomiers', 'https://uscolomierstennis.com/', 'https://www.google.com/maps/search/US+Colomiers+Tennis+Allee+des+Alpilles', 'assets/images/pochette_autre.png', 43.6100, 1.3400);

-- =============================================================================
-- INSERT : Padel venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('Toulouse Padel Club', '🎾 Padel', 'padel', '11 Rue Marie-Louise Dissard, 31300 Toulouse', 'https://www.toulousepadelclub.com/', 'https://www.google.com/maps/search/Toulouse+Padel+Club+11+Rue+Marie-Louise+Dissard', 'assets/images/pochette_autre.png', 43.5960, 1.4150),
('Padel Tolosa', '🎾 Padel', 'padel', '55 Avenue Louis Breguet, 31400 Toulouse', 'https://www.padeltolosa.fr/', 'https://www.google.com/maps/search/Padel+Tolosa+55+Avenue+Louis+Breguet+Toulouse', 'assets/images/pochette_autre.png', 43.5700, 1.4820),
('Stade Toulousain Tennis Padel', '🎾 Padel', 'padel', '116 Rue des Troenes, 31200 Toulouse', 'https://stadetoulousain-tennis-padel.com/', 'https://www.google.com/maps/search/Stade+Toulousain+Tennis+Padel+116+Rue+des+Troenes', 'assets/images/pochette_autre.png', 43.6350, 1.4280),
('Club de l''Hers - Padel', '🎾 Padel', 'padel', '23 Avenue de la Marqueille, 31650 Saint-Orens-de-Gameville', 'https://www.clubdelhers.fr/', 'https://www.google.com/maps/search/Club+de+l+Hers+Padel+Saint+Orens', 'assets/images/pochette_autre.png', 43.5500, 1.5310);

-- =============================================================================
-- INSERT : Squash venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('Toulouse Padel Club - Squash', '🎾 Squash', 'squash', '11 Rue Marie-Louise Dissard, 31300 Toulouse', 'https://www.toulousepadelclub.com/squash/', 'https://www.google.com/maps/search/Toulouse+Padel+Club+Squash+31300', 'assets/images/pochette_autre.png', 43.5960, 1.4150),
('TOAC Squash', '🎾 Squash', 'squash', 'Stade Ernest Wallon, Toulouse', 'https://www.toacsquash.com/', 'https://www.google.com/maps/search/TOAC+Squash+Toulouse', 'assets/images/pochette_autre.png', 43.6180, 1.4020),
('UCPA La Cartoucherie - Squash', '🎾 Squash', 'squash', '1 Allee Charles de Fitte, 31300 Toulouse', 'https://www.ucpa.com/centres-sportifs/cartoucherie-toulouse/squash', 'https://www.google.com/maps/search/UCPA+La+Cartoucherie+Toulouse+Squash', 'assets/images/pochette_autre.png', 43.5990, 1.4230);

-- =============================================================================
-- INSERT : Ping-pong venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('TOAC Tennis de Table', '🏓 Ping-pong', 'ping-pong', '20 Chemin de Garric, 31000 Toulouse', '', 'https://www.google.com/maps/search/TOAC+Tennis+de+Table+20+Chemin+de+Garric+Toulouse', 'assets/images/pochette_autre.png', 43.6180, 1.4020),
('ASPTT Toulouse Tennis de Table', '🏓 Ping-pong', 'ping-pong', '47 Rue de Soupetard, 31500 Toulouse', '', 'https://www.google.com/maps/search/ASPTT+Toulouse+Tennis+de+Table+47+Rue+Soupetard', 'assets/images/pochette_autre.png', 43.5920, 1.4680),
('Toulouse Patte d''Oie Tennis de Table', '🏓 Ping-pong', 'ping-pong', 'Gymnase Christine Rumeau, Rue des Turres, 31300 Toulouse', 'https://toulouse-pattedoie-tt.fr/', 'https://www.google.com/maps/search/Toulouse+Patte+d+Oie+Tennis+de+Table+Rue+des+Turres', 'assets/images/pochette_autre.png', 43.5950, 1.4250),
('TT Blagnacais', '🏓 Ping-pong', 'ping-pong', 'Blagnac', 'https://ttblagnacais.fr/', 'https://www.google.com/maps/search/TT+Blagnacais+Tennis+de+Table', 'assets/images/pochette_autre.png', 43.6370, 1.3940);

-- =============================================================================
-- INSERT : Badminton venues
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
('Volant Club Toulousain (VCT)', '🏸 Badminton', 'badminton', 'Toulouse', 'https://www.vctbad.fr/', 'https://www.google.com/maps/search/Volant+Club+Toulousain+Badminton+Toulouse', 'assets/images/pochette_autre.png', 43.6047, 1.4442),
('TUC Badminton', '🏸 Badminton', 'badminton', '11 Allee du Professeur Camille Soula, 31000 Toulouse', 'https://www.tucbad.org/', 'https://www.google.com/maps/search/TUC+Badminton+11+Allee+Camille+Soula+Toulouse', 'assets/images/pochette_autre.png', 43.5800, 1.4630),
('Olympe Badminton Club (OBC)', '🏸 Badminton', 'badminton', 'Toulouse', 'https://www.badminton-obc.fr/', 'https://www.google.com/maps/search/Olympe+Badminton+Club+Toulouse', 'assets/images/pochette_autre.png', 43.6320, 1.4180),
('TOAC Badminton', '🏸 Badminton', 'badminton', 'Toulouse', 'https://www.site.toacbadminton.fr/', 'https://www.google.com/maps/search/TOAC+Badminton+Toulouse', 'assets/images/pochette_autre.png', 43.6180, 1.4020),
('ASTMB - Toulouse Mirail Badminton', '🏸 Badminton', 'badminton', 'Quartier du Mirail, Toulouse', 'https://www.astmb.fr/', 'https://www.google.com/maps/search/ASTMB+Badminton+Mirail+Toulouse', 'assets/images/pochette_autre.png', 43.5820, 1.3950),
('Club de l''Hers - Badminton', '🏸 Badminton', 'badminton', '23 Avenue de la Marqueille, 31650 Saint-Orens-de-Gameville', 'https://www.clubdelhers.fr/', 'https://www.google.com/maps/search/Club+de+l+Hers+Badminton+Saint+Orens', 'assets/images/pochette_autre.png', 43.5500, 1.5310);

-- =============================================================================
-- INSERT : Football venues (terrains)
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- Stades
('Stadium de Toulouse (TFC)', '⚽ Stades', 'terrain-football', '1 Allee Gabriel Bienes, 31028 Toulouse', 'https://www.stadiumdetoulouse.fr/', 'https://www.google.com/maps/search/Stadium+de+Toulouse+1+Allee+Gabriel+Bienes', 'assets/images/shell_sport_football.png', 43.5833, 1.4340),
-- Foot en salle / Five
('UrbanSoccer Toulouse', '⚽ Foot en salle / Five', 'terrain-football', '50 Chemin de la Salade Ponsan, 31400 Toulouse', 'https://www.urbansoccer.fr/centres/toulouse/', 'https://www.google.com/maps/search/UrbanSoccer+Toulouse+Chemin+Salade+Ponsan', 'assets/images/shell_sport_football.png', 43.5690, 1.4690),
('Le Five Toulouse', '⚽ Foot en salle / Five', 'terrain-football', '15 Impasse de Lisbonne, 31200 Toulouse', 'https://www.lefive.fr/toulouse', 'https://www.google.com/maps/search/Le+Five+Toulouse+Impasse+de+Lisbonne', 'assets/images/shell_sport_football.png', 43.6360, 1.4170),
('Le Five Colomiers', '⚽ Foot en salle / Five', 'terrain-football', '5 Rue Louis Breguet, 31770 Colomiers', 'https://www.lefive.fr/colomiers', 'https://www.google.com/maps/search/Le+Five+Colomiers+Rue+Louis+Breguet', 'assets/images/shell_sport_football.png', 43.6190, 1.3270),
('So Foot Five Sesquieres', '⚽ Foot en salle / Five', 'terrain-football', 'Chemin de Sesquieres, 31200 Toulouse', '', 'https://www.google.com/maps/search/So+Foot+Five+Sesquieres+Toulouse', 'assets/images/shell_sport_football.png', 43.6440, 1.4270),
-- Terrains municipaux
('Complexe Sportif de Sesquieres', '⚽ Terrains municipaux', 'terrain-football', 'Allee des Foulques, 31200 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Complexe+Sportif+Sesquieres+Toulouse', 'assets/images/shell_sport_football.png', 43.6460, 1.4260),
('Stade de la Juncasse', '⚽ Terrains municipaux', 'terrain-football', 'Chemin de la Juncasse, 31200 Toulouse', '', 'https://www.google.com/maps/search/Stade+Juncasse+Toulouse', 'assets/images/shell_sport_football.png', 43.6350, 1.4600),
('Stade Arnaune', '⚽ Terrains municipaux', 'terrain-football', '23 Chemin Arnaune, 31200 Toulouse', '', 'https://www.google.com/maps/search/Stade+Arnaune+Toulouse', 'assets/images/shell_sport_football.png', 43.6310, 1.4380),
('Stade Municipal de Lalande', '⚽ Terrains municipaux', 'terrain-football', '2 Impasse de Lalande, 31200 Toulouse', '', 'https://www.google.com/maps/search/Stade+Municipal+Lalande+Toulouse', 'assets/images/shell_sport_football.png', 43.6500, 1.4340),
('Stade Raphael Pujazon', '⚽ Terrains municipaux', 'terrain-football', 'Chemin de Naudet, 31100 Toulouse', '', 'https://www.google.com/maps/search/Stade+Raphael+Pujazon+Toulouse', 'assets/images/shell_sport_football.png', 43.5730, 1.4100),
('Stade Municipal de Balma', '⚽ Terrains municipaux', 'terrain-football', 'Avenue des Platanes, 31130 Balma', '', 'https://www.google.com/maps/search/Stade+Municipal+Balma+Avenue+des+Platanes', 'assets/images/shell_sport_football.png', 43.6110, 1.4950),
('Complexe Sportif Andromede Blagnac', '⚽ Terrains municipaux', 'terrain-football', 'Rue de Jupiter, 31700 Blagnac', '', 'https://www.google.com/maps/search/Complexe+Sportif+Andromede+Blagnac', 'assets/images/shell_sport_football.png', 43.6530, 1.3760),
('Stade Municipal de Colomiers', '⚽ Terrains municipaux', 'terrain-football', 'Place Alex Raymond, 31770 Colomiers', '', 'https://www.google.com/maps/search/Stade+Municipal+Colomiers+Place+Alex+Raymond', 'assets/images/shell_sport_football.png', 43.6080, 1.3370),
('Stade de la Ramee', '⚽ Terrains municipaux', 'terrain-football', 'Avenue du General Eisenhower, 31170 Tournefeuille', '', 'https://www.google.com/maps/search/Stade+de+la+Ramee+Tournefeuille', 'assets/images/shell_sport_football.png', 43.5850, 1.3490),
('Stade de Croix-Daurade', '⚽ Terrains municipaux', 'terrain-football', 'Chemin Virebent, 31200 Toulouse', '', 'https://www.google.com/maps/search/Stade+Croix+Daurade+Chemin+Virebent+Toulouse', 'assets/images/shell_sport_football.png', 43.6420, 1.4630);

-- =============================================================================
-- INSERT : Basketball venues (terrains & gymnases)
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- Gymnases
('Palais des Sports Andre Brouat', '🏀 Gymnases', 'terrain-basketball', '2 Allee Gabriel Bienes, 31400 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Palais+des+Sports+Andre+Brouat+Toulouse', 'assets/images/shell_sport_basketball.png', 43.5860, 1.4620),
('Gymnase Compans Caffarelli', '🏀 Gymnases', 'terrain-basketball', 'Esplanade Compans Caffarelli, 31000 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Gymnase+Compans+Caffarelli+Toulouse', 'assets/images/shell_sport_basketball.png', 43.6115, 1.4320),
('Gymnase de la Croix de Pierre', '🏀 Gymnases', 'terrain-basketball', '2 Rue Jacques Babinet, 31300 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Gymnase+Croix+de+Pierre+Toulouse', 'assets/images/shell_sport_basketball.png', 43.5927, 1.4210),
('Gymnase Pont des Demoiselles', '🏀 Gymnases', 'terrain-basketball', '10 Rue du Pont des Demoiselles, 31400 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Gymnase+Pont+des+Demoiselles+Toulouse', 'assets/images/shell_sport_basketball.png', 43.5930, 1.4630),
('Gymnase des Argoulets', '🏀 Gymnases', 'terrain-basketball', '75 Boulevard des Cretes, 31500 Toulouse', 'https://www.toulouse.fr/web/sports/les-equipements-sportifs', 'https://www.google.com/maps/search/Gymnase+des+Argoulets+Toulouse', 'assets/images/shell_sport_basketball.png', 43.6110, 1.4800),
-- Terrains exterieurs
('City Stade Prairie des Filtres', '🏀 Terrains exterieurs', 'terrain-basketball', 'Allee Charles de Fitte, 31000 Toulouse', '', 'https://www.google.com/maps/search/City+Stade+Prairie+des+Filtres+Toulouse', 'assets/images/shell_sport_basketball.png', 43.5976, 1.4350),
('Terrain de Basket Ile du Ramier', '🏀 Terrains exterieurs', 'terrain-basketball', 'Ile du Ramier, 31400 Toulouse', '', 'https://www.google.com/maps/search/terrain+basketball+Ile+du+Ramier+Toulouse', 'assets/images/shell_sport_basketball.png', 43.5830, 1.4370),
('City Stade Sesquieres', '🏀 Terrains exterieurs', 'terrain-basketball', 'Allee des Foulques, 31200 Toulouse', '', 'https://www.google.com/maps/search/City+Stade+Sesquieres+Toulouse', 'assets/images/shell_sport_basketball.png', 43.6420, 1.4280),
('Terrain de Basket Parc de la Maourine', '🏀 Terrains exterieurs', 'terrain-basketball', 'Chemin de la Maourine, 31200 Toulouse', '', 'https://www.google.com/maps/search/terrain+basket+Parc+Maourine+Toulouse', 'assets/images/shell_sport_basketball.png', 43.6440, 1.4520),
-- Clubs
('Toulouse Basket Club (TBC)', '🏀 Clubs', 'terrain-basketball', 'Chemin de Mange-Pommes, 31100 Toulouse', 'https://www.toulousebasketclub.fr/', 'https://www.google.com/maps/search/Toulouse+Basket+Club+Lafourguette', 'assets/images/shell_sport_basketball.png', 43.5700, 1.4050),
-- Proche de Toulouse
('Gymnase Leo Lagrange Blagnac', '🏀 Proche de Toulouse', 'terrain-basketball', 'Chemin du Ferradou, 31700 Blagnac', 'https://www.mairie-blagnac.fr/', 'https://www.google.com/maps/search/Gymnase+Leo+Lagrange+Blagnac', 'assets/images/shell_sport_basketball.png', 43.6350, 1.3870),
('Gymnase Didier Vaillant Colomiers', '🏀 Proche de Toulouse', 'terrain-basketball', 'Avenue du General de Gaulle, 31770 Colomiers', 'https://www.ville-colomiers.fr/', 'https://www.google.com/maps/search/Gymnase+Didier+Vaillant+Colomiers', 'assets/images/shell_sport_basketball.png', 43.6110, 1.3400),
('Gymnase Municipal de Balma', '🏀 Proche de Toulouse', 'terrain-basketball', 'Avenue de la Marqueille, 31130 Balma', 'https://www.mairie-balma.fr/', 'https://www.google.com/maps/search/Gymnase+Municipal+Balma', 'assets/images/shell_sport_basketball.png', 43.6110, 1.4980),
('Gymnase de Tournefeuille', '🏀 Proche de Toulouse', 'terrain-basketball', '1 Place de la Mairie, 31170 Tournefeuille', 'https://www.mairie-tournefeuille.fr/', 'https://www.google.com/maps/search/Gymnase+Municipal+Tournefeuille', 'assets/images/shell_sport_basketball.png', 43.5860, 1.3470);

-- =============================================================================
-- INSERT : Swimming venues (piscines)
-- =============================================================================
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- Piscines municipales
('Piscine Nakache', '🏊 Piscines municipales', 'piscine', '12 Boulevard des Minimes, 31200 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Nakache+Toulouse', 'assets/images/pochette_natation.png', 43.6130, 1.4560),
('Piscine Leo Lagrange', '🏊 Piscines municipales', 'piscine', '2 Rue de la Colombette, 31000 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Leo+Lagrange+Toulouse', 'assets/images/pochette_natation.png', 43.6040, 1.4530),
('Piscine Alex Jany', '🏊 Piscines municipales', 'piscine', '31 Chemin de la Cepiere, 31100 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Alex+Jany+Toulouse', 'assets/images/pochette_natation.png', 43.5830, 1.4080),
('Piscine Chapou', '🏊 Piscines municipales', 'piscine', '2 Quai de Tounis, 31000 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Chapou+Toulouse', 'assets/images/pochette_natation.png', 43.5990, 1.4410),
('Piscine Bellevue', '🏊 Piscines municipales', 'piscine', '2 Rue Louis Vitet, 31100 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Bellevue+Toulouse', 'assets/images/pochette_natation.png', 43.5890, 1.4110),
('Piscine Castex', '🏊 Piscines municipales', 'piscine', '15 Rue de la Mairie, 31500 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Castex+Toulouse', 'assets/images/pochette_natation.png', 43.6080, 1.4770),
('Piscine Jacqueline Auriol', '🏊 Piscines municipales', 'piscine', '13 Allee Henri Sellier, 31400 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Jacqueline+Auriol+Toulouse', 'assets/images/pochette_natation.png', 43.5780, 1.4540),
('Piscine de Lardenne', '🏊 Piscines municipales', 'piscine', '60 Route de Lardenne, 31100 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Lardenne+Toulouse', 'assets/images/pochette_natation.png', 43.5970, 1.3900),
('Piscine Henri Pailles', '🏊 Piscines municipales', 'piscine', '16 Avenue Jean Moulin, 31400 Toulouse', 'https://www.toulouse.fr/web/sports/piscines', 'https://www.google.com/maps/search/Piscine+Henri+Pailles+Toulouse+Rangueil', 'assets/images/pochette_natation.png', 43.5740, 1.4560),
-- Toulouse Metropole
('Centre Aquatique de Blagnac', '🏊 Toulouse Metropole', 'piscine', '4 Rue Bernard Maris, 31700 Blagnac', 'https://www.blagnac.fr', 'https://www.google.com/maps/search/Centre+Aquatique+Blagnac', 'assets/images/pochette_natation.png', 43.6380, 1.3880),
('Piscine de Colomiers', '🏊 Toulouse Metropole', 'piscine', '11 Allee du Rouergue, 31770 Colomiers', 'https://www.ville-colomiers.fr', 'https://www.google.com/maps/search/Piscine+Colomiers+31770', 'assets/images/pochette_natation.png', 43.6120, 1.3360),
('Piscine de Balma', '🏊 Toulouse Metropole', 'piscine', '1 Rue des Sports, 31130 Balma', 'https://www.mairie-balma.fr', 'https://www.google.com/maps/search/Piscine+Balma+31130', 'assets/images/pochette_natation.png', 43.6100, 1.4990),
('Piscine de Tournefeuille', '🏊 Toulouse Metropole', 'piscine', '7 Place de la Mairie, 31170 Tournefeuille', 'https://www.mairie-tournefeuille.fr', 'https://www.google.com/maps/search/Piscine+Tournefeuille+31170', 'assets/images/pochette_natation.png', 43.5850, 1.3460),
('Centre Aquatique de Ramonville', '🏊 Toulouse Metropole', 'piscine', 'Chemin de Florian, 31520 Ramonville-Saint-Agne', 'https://www.mairie-ramonville.fr', 'https://www.google.com/maps/search/Piscine+Ramonville+Saint+Agne', 'assets/images/pochette_natation.png', 43.5530, 1.4740),
('Piscine de Castanet-Tolosan', '🏊 Toulouse Metropole', 'piscine', '2 Rue du Stade, 31320 Castanet-Tolosan', 'https://www.ville-castanet-tolosan.fr', 'https://www.google.com/maps/search/Piscine+Castanet+Tolosan', 'assets/images/pochette_natation.png', 43.5160, 1.4970),
('Centre Aquatique Spadium L''Union', '🏊 Toulouse Metropole', 'piscine', '5 Chemin de Borderouge, 31240 L''Union', 'https://www.spadium.fr', 'https://www.google.com/maps/search/Spadium+L+Union+Toulouse', 'assets/images/pochette_natation.png', 43.6530, 1.4740),
('Piscine de Cugnaux', '🏊 Toulouse Metropole', 'piscine', 'Place de l''Eglise, 31270 Cugnaux', 'https://www.mairie-cugnaux.fr', 'https://www.google.com/maps/search/Piscine+Cugnaux+31270', 'assets/images/pochette_natation.png', 43.5370, 1.3450);

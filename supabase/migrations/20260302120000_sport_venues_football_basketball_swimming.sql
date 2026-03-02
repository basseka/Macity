-- =============================================================================
-- Migration : Ajout des venues football, basketball et piscine.
-- =============================================================================

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

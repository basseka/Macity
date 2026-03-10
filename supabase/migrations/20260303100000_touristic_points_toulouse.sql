-- =============================================================================
-- Migration : Table touristic_points_toulouse
-- Sites historiques et lieux importants a visiter dans Toulouse.
-- =============================================================================

CREATE TABLE public.touristic_points_toulouse (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom         TEXT NOT NULL,
  categorie   TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  adresse     TEXT NOT NULL DEFAULT '',
  site_web    TEXT NOT NULL DEFAULT '',
  lien_maps   TEXT NOT NULL DEFAULT '',
  photo       TEXT NOT NULL DEFAULT 'assets/images/pochette_visite.png',
  latitude    DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude   DOUBLE PRECISION NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour les requetes frequentes
CREATE INDEX idx_touristic_points_categorie ON public.touristic_points_toulouse (categorie);
CREATE INDEX idx_touristic_points_active ON public.touristic_points_toulouse (is_active);

-- RLS : lecture anonyme, ecriture service_role uniquement
ALTER TABLE public.touristic_points_toulouse ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read" ON public.touristic_points_toulouse FOR SELECT USING (true);
CREATE POLICY "service_write" ON public.touristic_points_toulouse FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- INSERT : Monuments & patrimoine
-- =============================================================================
INSERT INTO public.touristic_points_toulouse (nom, categorie, description, adresse, site_web, lien_maps, latitude, longitude) VALUES
('Capitole de Toulouse', 'Monument', 'Hotel de ville et theatre du Capitole, symbole de Toulouse depuis le XIIe siecle. Facade neoclassique de 128 metres.', 'Place du Capitole, 31000 Toulouse', 'https://www.toulouse.fr/capitole', 'https://www.google.com/maps/search/Capitole+Toulouse', 43.6045, 1.4440),
('Basilique Saint-Sernin', 'Monument', 'Plus grande eglise romane d''Europe, classee UNESCO. Construite entre le XIe et le XIIIe siecle sur le tombeau de saint Saturnin.', '13 Place Saint-Sernin, 31000 Toulouse', 'https://www.basilique-saint-sernin.fr', 'https://www.google.com/maps/search/Basilique+Saint-Sernin+Toulouse', 43.6084, 1.4419),
('Couvent des Jacobins', 'Monument', 'Chef-d''oeuvre de l''art gothique meridional, celebre pour son palmier a 22 nervures. Abrite les reliques de saint Thomas d''Aquin.', 'Rue Lakanal, 31000 Toulouse', 'https://www.jacobins.toulouse.fr', 'https://www.google.com/maps/search/Couvent+des+Jacobins+Toulouse', 43.6040, 1.4395),
('Cathedrale Saint-Etienne', 'Monument', 'Cathedrale atypique melant gothique meridional et gothique du nord, construite du XIe au XVIIe siecle.', 'Place Saint-Etienne, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Cathedrale+Saint-Etienne+Toulouse', 43.5998, 1.4498),
('Eglise Notre-Dame du Taur', 'Monument', 'Eglise du XIVe siecle avec un clocher-mur typique du style toulousain, sur le trajet du martyre de saint Saturnin.', '12 Rue du Taur, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Eglise+Notre-Dame+du+Taur+Toulouse', 43.6065, 1.4435),
('Eglise Notre-Dame de la Dalbade', 'Monument', 'Eglise gothique meridionale du XVe siecle, celebre pour son portail Renaissance et son tympan en ceramique.', 'Rue de la Dalbade, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Eglise+Notre-Dame+de+la+Dalbade+Toulouse', 43.5998, 1.4420),
('Pont Neuf', 'Monument', 'Plus ancien pont de Toulouse (XVIe siecle), relie la rive droite a Saint-Cyprien. Vue panoramique sur la Garonne.', 'Pont Neuf, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Pont+Neuf+Toulouse', 43.5996, 1.4385),
('Chateau d''eau (galerie photographique)', 'Monument', 'Ancien chateau d''eau du XIXe siecle transforme en galerie de photographie, l''une des plus anciennes d''Europe.', '1 Place Laganne, 31300 Toulouse', 'https://www.galeriduchateau.deau.toulouse.fr', 'https://www.google.com/maps/search/Chateau+d+eau+galerie+Toulouse', 43.5990, 1.4330),
('Donjon du Capitole', 'Monument', 'Tour medievale du XVIe siecle, ancien beffroi de la ville. Abrite aujourd''hui l''office de tourisme.', 'Rue du Donjon, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Donjon+du+Capitole+Toulouse', 43.6042, 1.4455),
('Hotel d''Assezat', 'Monument', 'Plus bel hotel particulier Renaissance de Toulouse (XVIe siecle), abrite la Fondation Bemberg.', 'Place d''Assezat, 31000 Toulouse', 'https://www.fondation-bemberg.fr', 'https://www.google.com/maps/search/Hotel+d+Assezat+Toulouse', 43.6010, 1.4410),

-- =============================================================================
-- INSERT : Musees
-- =============================================================================
('Cite de l''espace', 'Musee', 'Parc a theme dedie a l''espace et a la conquete spatiale. Replique de la fusee Ariane 5, planetarium geant et station Mir.', 'Avenue Jean Gonord, 31500 Toulouse', 'https://www.cite-espace.com', 'https://www.google.com/maps/search/Cite+de+l+espace+Toulouse', 43.5863, 1.4932),
('Musee des Augustins', 'Musee', 'Musee des beaux-arts dans un ancien couvent augustin. Collections de peintures et sculptures du Moyen Age au XXe siecle.', '21 Rue de Metz, 31000 Toulouse', 'https://www.augustins.org', 'https://www.google.com/maps/search/Musee+des+Augustins+Toulouse', 43.6010, 1.4470),
('Museum de Toulouse', 'Musee', 'Museum d''histoire naturelle, l''un des plus grands de France. Collections de paleontologie, mineralogie et ethnographie.', '35 Allee Jules Guesde, 31000 Toulouse', 'https://www.museum.toulouse.fr', 'https://www.google.com/maps/search/Museum+de+Toulouse', 43.5940, 1.4490),
('Fondation Bemberg', 'Musee', 'Collection privee exceptionnelle : peintures Renaissance, bronzes, livres anciens, dans l''Hotel d''Assezat.', 'Place d''Assezat, 31000 Toulouse', 'https://www.fondation-bemberg.fr', 'https://www.google.com/maps/search/Fondation+Bemberg+Toulouse', 43.6010, 1.4410),
('Les Abattoirs - Musee d''art moderne', 'Musee', 'Musee d''art moderne et contemporain installe dans les anciens abattoirs. Le Rideau de scene de Picasso y est expose.', '76 Allee Charles de Fitte, 31300 Toulouse', 'https://www.lesabattoirs.org', 'https://www.google.com/maps/search/Les+Abattoirs+Musee+Toulouse', 43.5990, 1.4290),
('Aeroscopia', 'Musee', 'Musee aeronautique avec des avions mythiques : Concorde, Airbus A300B, Super Guppy, Caravelle.', '1 Allee Andre Turcat, 31700 Blagnac', 'https://www.musee-aeroscopia.fr', 'https://www.google.com/maps/search/Aeroscopia+Blagnac', 43.6580, 1.3680),
('Musee Saint-Raymond', 'Musee', 'Musee d''archeologie, collections antiques et paleochretiennes. Installe dans un ancien college universitaire du XVIe siecle.', '1 ter Place Saint-Sernin, 31000 Toulouse', 'https://www.saintraymond.toulouse.fr', 'https://www.google.com/maps/search/Musee+Saint-Raymond+Toulouse', 43.6088, 1.4410),
('Musee Georges Labit', 'Musee', 'Collections d''arts asiatiques et egyptiens dans une villa mauresque du XIXe siecle au bord du Canal du Midi.', '17 Rue du Japon, 31400 Toulouse', 'https://www.museegeorgeslabit.toulouse.fr', 'https://www.google.com/maps/search/Musee+Georges+Labit+Toulouse', 43.5930, 1.4560),

-- =============================================================================
-- INSERT : Sites emblematiques & places
-- =============================================================================
('Place du Capitole', 'Place', 'Coeur de Toulouse, place emblematique de 12 000 m2. Marche, terrasses, croix occitane au sol par Raymond Moretti.', 'Place du Capitole, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Place+du+Capitole+Toulouse', 43.6047, 1.4442),
('Place Wilson', 'Place', 'Elegante place en arc de cercle avec ses arcades, fontaine et jardin. Nommee en hommage au president americain.', 'Place Wilson, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Place+Wilson+Toulouse', 43.6068, 1.4488),
('Place Saint-Pierre', 'Place', 'Place animee au bord de la Garonne, haut lieu de la vie nocturne toulousaine avec ses bars et restaurants.', 'Place Saint-Pierre, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Place+Saint-Pierre+Toulouse', 43.6040, 1.4370),
('Place Saint-Georges', 'Place', 'Place pietoniere du centre historique, entouree de cafes et restaurants. Point de rencontre populaire.', 'Place Saint-Georges, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Place+Saint-Georges+Toulouse', 43.6025, 1.4490),

-- =============================================================================
-- INSERT : Canal du Midi & Garonne
-- =============================================================================
('Canal du Midi', 'Site naturel', 'Oeuvre de Pierre-Paul Riquet (XVIIe siecle), classe UNESCO. 240 km de Toulouse a l''etang de Thau. Promenades, croisiere, velo.', 'Allee de Brienne / Port Saint-Sauveur, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Canal+du+Midi+Toulouse', 43.5990, 1.4530),
('Quais de la Garonne', 'Site naturel', 'Promenade amenagee le long de la Garonne, du Bazacle au Pont Saint-Michel. Vue sur les facades de briques roses.', 'Quai de la Daurade, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Quais+de+la+Garonne+Toulouse', 43.6020, 1.4380),
('Prairie des Filtres', 'Site naturel', 'Grand parc au bord de la Garonne, face au centre historique. Lieu de pique-nique, festivals et promenades.', 'Cours Dillon, 31300 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Prairie+des+Filtres+Toulouse', 43.5970, 1.4350),
('Jardin des Plantes', 'Site naturel', 'Plus ancien jardin public de Toulouse (XVIIIe siecle). Jardin botanique, carrousel, kiosque a musique.', '31 Allee Jules Guesde, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Jardin+des+Plantes+Toulouse', 43.5930, 1.4500),
('Jardin Japonais', 'Site naturel', 'Jardin zen de 7000 m2 au sein du parc Compans-Caffarelli. Pavillon de the, pont rouge, jardin sec, cascade.', 'Boulevard Lascrosses, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Jardin+Japonais+Toulouse', 43.6130, 1.4310),
('Le Bazacle', 'Site naturel', 'Ancien moulin-barrage sur la Garonne (XIIe siecle). Espace d''exposition EDF et passe a poissons.', '11 Quai Saint-Pierre, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Le+Bazacle+Toulouse', 43.6070, 1.4340),

-- =============================================================================
-- INSERT : Quartiers historiques
-- =============================================================================
('Quartier Saint-Cyprien', 'Quartier', 'Rive gauche de la Garonne, quartier boheme et artistique. Galeries, restaurants, Les Abattoirs.', 'Saint-Cyprien, 31300 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Saint-Cyprien+Toulouse', 43.5980, 1.4310),
('Quartier des Carmes', 'Quartier', 'Quartier medieval pittoresque avec ruelles etroites, marche couvert des Carmes et boutiques artisanales.', 'Quartier des Carmes, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Quartier+des+Carmes+Toulouse', 43.5995, 1.4460),
('Rue du Taur', 'Quartier', 'Rue historique reliant la place du Capitole a la basilique Saint-Sernin. Librairies, commerces et vie etudiante.', 'Rue du Taur, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Rue+du+Taur+Toulouse', 43.6060, 1.4430),
('Rue Saint-Rome', 'Quartier', 'Principale rue pietonne du centre historique, axe commercial depuis le Moyen Age.', 'Rue Saint-Rome, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Rue+Saint-Rome+Toulouse', 43.6020, 1.4450),

-- =============================================================================
-- INSERT : Lieux incontournables
-- =============================================================================
('Halle de la Machine', 'Lieu culturel', 'Compagnie La Machine : le Minotaure geant et l''Araignee mecanique. Spectacles de rue et machines extraordinaires.', '3 Avenue de l''Aerodrome de Montaudran, 31400 Toulouse', 'https://www.halledelamachine.fr', 'https://www.google.com/maps/search/Halle+de+la+Machine+Toulouse', 43.5700, 1.4900),
('Envol des Pionniers', 'Lieu culturel', 'Musee interactif sur l''histoire de l''Aeropostale et de l''aviation postale. Sur les traces de Saint-Exupery et Mermoz.', '6 Rue Jacqueline Auriol, 31400 Toulouse', 'https://www.lenvol-des-pionniers.com', 'https://www.google.com/maps/search/Envol+des+Pionniers+Toulouse', 43.5710, 1.4890),
('Marche Victor Hugo', 'Lieu culturel', 'Marche couvert emblematique de Toulouse. Produits frais, specialites locales et restaurants a l''etage.', 'Place Victor Hugo, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/Marche+Victor+Hugo+Toulouse', 43.6050, 1.4470),
('Cloitre des Jacobins', 'Lieu culturel', 'Cloitre gothique du XIIIe siecle, havre de paix au coeur de la ville. Colonnes de marbre et jardin interieur.', 'Rue Lakanal, 31000 Toulouse', 'https://www.jacobins.toulouse.fr', 'https://www.google.com/maps/search/Cloitre+des+Jacobins+Toulouse', 43.6038, 1.4393),
('Daurade (port et basilique)', 'Lieu culturel', 'Quartier historique au bord de la Garonne. La basilique Notre-Dame de la Daurade et le port fluvial.', 'Quai de la Daurade, 31000 Toulouse', 'https://www.toulouse-tourisme.com', 'https://www.google.com/maps/search/La+Daurade+Toulouse', 43.6030, 1.4380),

-- =============================================================================
-- INSERT : Stations de metro — Ligne A (Basso Cambo → Balma-Gramont)
-- =============================================================================
('Basso Cambo', 'Metro A', 'Station de metro Ligne A — terminus ouest. Correspondance bus et parking relais.', 'Basso Cambo, 31100 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Basso+Cambo+Toulouse', 43.5693, 1.3917),
('Bellefontaine', 'Metro A', 'Station de metro Ligne A.', 'Bellefontaine, 31100 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Bellefontaine+Toulouse', 43.5727, 1.3983),
('Reynerie', 'Metro A', 'Station de metro Ligne A.', 'Reynerie, 31100 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Reynerie+Toulouse', 43.5757, 1.4023),
('Mirail-Universite', 'Metro A', 'Station de metro Ligne A. Acces Universite Toulouse Jean Jaures.', 'Mirail, 31100 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Mirail+Universite+Toulouse', 43.5786, 1.4048),
('Bagatelle', 'Metro A', 'Station de metro Ligne A.', 'Bagatelle, 31100 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Bagatelle+Toulouse', 43.5817, 1.4088),
('Mermoz', 'Metro A', 'Station de metro Ligne A.', 'Mermoz, 31300 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Mermoz+Toulouse', 43.5856, 1.4130),
('Fontaine Lestang', 'Metro A', 'Station de metro Ligne A.', 'Fontaine Lestang, 31300 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Fontaine+Lestang+Toulouse', 43.5888, 1.4200),
('Arenes', 'Metro A', 'Station de metro Ligne A. Correspondance tramway T1 et T2.', 'Allee de Barcelone, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Arenes+Toulouse', 43.5912, 1.4250),
('Patte d''Oie', 'Metro A', 'Station de metro Ligne A.', 'Place Patte d''Oie, 31300 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Patte+d+Oie+Toulouse', 43.5943, 1.4290),
('St-Cyprien-Republique', 'Metro A', 'Station de metro Ligne A. Quartier Saint-Cyprien, rive gauche.', 'Place de la Republique, 31300 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+St+Cyprien+Republique+Toulouse', 43.5978, 1.4340),
('Esquirol', 'Metro A', 'Station de metro Ligne A. Centre historique, rue de Metz.', 'Place Esquirol, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Esquirol+Toulouse', 43.6003, 1.4448),
('Capitole', 'Metro A', 'Station de metro Ligne A. Place du Capitole, coeur de Toulouse.', 'Place du Capitole, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Capitole+Toulouse', 43.6044, 1.4440),
('Jean Jaures', 'Metro A', 'Station de metro Ligne A. Correspondance Ligne B.', 'Place Jean Jaures, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Jean+Jaures+Toulouse', 43.6060, 1.4490),
('Marengo-SNCF', 'Metro A', 'Station de metro Ligne A. Acces gare Matabiau.', 'Gare Matabiau, 31500 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Marengo+SNCF+Toulouse', 43.6113, 1.4538),
('Jolimont', 'Metro A', 'Station de metro Ligne A. Acces Stadium et Cite de l''espace.', 'Jolimont, 31500 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Jolimont+Toulouse', 43.6128, 1.4612),
('Roseraie', 'Metro A', 'Station de metro Ligne A.', 'Roseraie, 31500 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Roseraie+Toulouse', 43.6112, 1.4685),
('Argoulets', 'Metro A', 'Station de metro Ligne A. Parking relais.', 'Argoulets, 31500 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Argoulets+Toulouse', 43.6120, 1.4750),
('Balma-Gramont', 'Metro A', 'Station de metro Ligne A — terminus est. Parking relais, correspondance bus.', 'Balma-Gramont, 31130 Balma', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Balma+Gramont+Toulouse', 43.6133, 1.4833),

-- =============================================================================
-- INSERT : Stations de metro — Ligne B (Borderouge → Ramonville)
-- =============================================================================
('Borderouge', 'Metro B', 'Station de metro Ligne B — terminus nord. Parking relais.', 'Borderouge, 31200 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Borderouge+Toulouse', 43.6382, 1.4533),
('Trois Cocus', 'Metro B', 'Station de metro Ligne B.', 'Trois Cocus, 31200 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Trois+Cocus+Toulouse', 43.6332, 1.4507),
('La Vache', 'Metro B', 'Station de metro Ligne B.', 'La Vache, 31200 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+La+Vache+Toulouse', 43.6278, 1.4483),
('Barriere de Paris', 'Metro B', 'Station de metro Ligne B.', 'Barriere de Paris, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Barriere+de+Paris+Toulouse', 43.6230, 1.4467),
('Minimes-Claude Nougaro', 'Metro B', 'Station de metro Ligne B. Hommage au chanteur toulousain Claude Nougaro.', 'Les Minimes, 31200 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Minimes+Claude+Nougaro+Toulouse', 43.6172, 1.4448),
('Canal du Midi (metro)', 'Metro B', 'Station de metro Ligne B. A proximite du Canal du Midi.', 'Canal du Midi, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Canal+du+Midi+Toulouse', 43.6122, 1.4433),
('Compans-Caffarelli', 'Metro B', 'Station de metro Ligne B. Acces Jardin Japonais et parc Compans-Caffarelli.', 'Compans-Caffarelli, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Compans+Caffarelli+Toulouse', 43.6108, 1.4392),
('Jeanne d''Arc', 'Metro B', 'Station de metro Ligne B.', 'Place Jeanne d''Arc, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Jeanne+d+Arc+Toulouse', 43.6078, 1.4458),
('Francois Verdier', 'Metro B', 'Station de metro Ligne B. Acces Grand Rond et Jardin des Plantes.', 'Place Francois Verdier, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Francois+Verdier+Toulouse', 43.6018, 1.4530),
('Carmes', 'Metro B', 'Station de metro Ligne B. Acces marche des Carmes.', 'Place des Carmes, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Carmes+Toulouse', 43.5993, 1.4443),
('Palais de Justice', 'Metro B', 'Station de metro Ligne B. Rive gauche, acces quartier Saint-Michel.', 'Palais de Justice, 31000 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Palais+de+Justice+Toulouse', 43.5960, 1.4403),
('Saint-Michel-Marcel Langer', 'Metro B', 'Station de metro Ligne B.', 'Saint-Michel, 31400 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Saint+Michel+Marcel+Langer+Toulouse', 43.5882, 1.4448),
('Empalot', 'Metro B', 'Station de metro Ligne B.', 'Empalot, 31400 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Empalot+Toulouse', 43.5778, 1.4443),
('Saint-Agne-SNCF', 'Metro B', 'Station de metro Ligne B. Correspondance gare SNCF Saint-Agne.', 'Saint-Agne, 31400 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Saint+Agne+SNCF+Toulouse', 43.5723, 1.4438),
('Faculte de Pharmacie', 'Metro B', 'Station de metro Ligne B. Acces campus sante.', 'Faculte de Pharmacie, 31400 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Faculte+de+Pharmacie+Toulouse', 43.5622, 1.4493),
('Universite Paul Sabatier', 'Metro B', 'Station de metro Ligne B. Acces campus scientifique.', 'Universite Paul Sabatier, 31400 Toulouse', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Universite+Paul+Sabatier+Toulouse', 43.5588, 1.4578),
('Ramonville', 'Metro B', 'Station de metro Ligne B — terminus sud. Parking relais.', 'Ramonville-Saint-Agne, 31520 Ramonville', 'https://www.tisseo.fr', 'https://www.google.com/maps/search/Metro+Ramonville+Toulouse', 43.5492, 1.4680);

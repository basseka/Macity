-- =============================================================================
-- Migration : Salles de danse dans sport_venues
-- =============================================================================

INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude) VALUES
-- ── Ecoles / Studios de danse ──
('Encas-Danses Studio', 'Ecole de danse', 'danse', '18 Rue Bayard, 31000 Toulouse', 'https://www.encas-danses.com/', 'https://www.google.com/maps/search/Encas-Danses+Studio+Toulouse', 'assets/images/pochette_autre.png', 43.6100, 1.4540),
('Le 144 Dance Avenue', 'Ecole de danse', 'danse', '144 Avenue des Etats-Unis, 31200 Toulouse', '', 'https://www.google.com/maps/search/Le+144+Dance+Avenue+Toulouse', 'assets/images/pochette_autre.png', 43.6270, 1.4460),
('Studio9 Toulouse - School De Danse', 'Ecole de danse', 'danse', '9 Rue de la Colombette, 31000 Toulouse', '', 'https://www.google.com/maps/search/Studio9+School+De+Danse+Toulouse', 'assets/images/pochette_autre.png', 43.6070, 1.4560),
('La Salle', 'Ecole de danse', 'danse', '4 Rue Gabriel Peri, 31000 Toulouse', '', 'https://www.google.com/maps/search/La+Salle+danse+Toulouse', 'assets/images/pochette_autre.png', 43.6050, 1.4480),
('La Maison De La Danse', 'Ecole de danse', 'danse', '4 Rue Pharaon, 31000 Toulouse', '', 'https://www.google.com/maps/search/La+Maison+De+La+Danse+Toulouse', 'assets/images/pochette_autre.png', 43.5980, 1.4430),
('Choreographic Centre De Toulouse', 'Centre choregraphique', 'danse', '5 Avenue Etienne Billieres, 31300 Toulouse', '', 'https://www.google.com/maps/search/Choreographic+Centre+Toulouse', 'assets/images/pochette_autre.png', 43.5990, 1.4270),
('Atelier Danse', 'Ecole de danse', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Atelier+Danse+Toulouse', 'assets/images/pochette_autre.png', 43.6040, 1.4440),
('La Place De La Danse CDCN Toulouse Occitanie', 'Centre choregraphique', 'danse', '8 Quai Saint-Pierre, 31000 Toulouse', 'https://www.laplacedeladanse.com/', 'https://www.google.com/maps/search/La+Place+De+La+Danse+CDCN+Toulouse', 'assets/images/pochette_autre.png', 43.5960, 1.4400),

-- ── Salles specialisees / thematiques ──
('Danc''in La Roseraie Dance School Toulouse', 'Ecole de danse', 'danse', 'Quartier La Roseraie, 31500 Toulouse', '', 'https://www.google.com/maps/search/Danc+in+La+Roseraie+Dance+School+Toulouse', 'assets/images/pochette_autre.png', 43.5940, 1.4850),
('Cecile - Cours De Danse & Accompagnement Sport Sante Bien-Etre', 'Danse bien-etre', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Cecile+Cours+De+Danse+Bien+Etre+Toulouse', 'assets/images/pochette_autre.png', 43.6040, 1.4440),
('Art Dance International', 'Ecole de danse', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Art+Dance+International+Toulouse', 'assets/images/pochette_autre.png', 43.6050, 1.4450),
('Three Time Dense', 'Ecole de danse', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Three+Time+Dense+Toulouse', 'assets/images/pochette_autre.png', 43.6030, 1.4460),
('Ecole de danse Francoise RAZES / Studio Gilles JACINTO', 'Ecole de danse', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Ecole+danse+Francoise+Razes+Gilles+Jacinto+Toulouse', 'assets/images/pochette_autre.png', 43.6060, 1.4430),
('Puntatalon Academy - School Dances Latines', 'Danse latine', 'danse', 'Toulouse', 'https://www.puntatalon.com/', 'https://www.google.com/maps/search/Puntatalon+Academy+Danse+Latine+Toulouse', 'assets/images/pochette_autre.png', 43.6020, 1.4470),
('Laliana Danse Orientale Et Armenienne', 'Danse orientale', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Laliana+Danse+Orientale+Armenienne+Toulouse', 'assets/images/pochette_autre.png', 43.6010, 1.4450),
('Dance Studio', 'Ecole de danse', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Dance+Studio+Toulouse', 'assets/images/pochette_autre.png', 43.6040, 1.4440),

-- ── Associations / groupes de danse ──
('Ballet School Harold & Alexandra Paturet', 'Ballet / Classique', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Ballet+School+Harold+Alexandra+Paturet+Toulouse', 'assets/images/pochette_autre.png', 43.6050, 1.4430),
('Brigade Fantome - Equipe De Danse Hip Hop Et Breakdance', 'Hip-hop / Breakdance', 'danse', 'Toulouse', '', 'https://www.google.com/maps/search/Brigade+Fantome+Hip+Hop+Breakdance+Toulouse', 'assets/images/pochette_autre.png', 43.6030, 1.4460),

-- ── Espaces avec location de salles ──
('La Residence Des Arts', 'Location de salle', 'danse', 'Toulouse', 'https://www.laresidencedesarts.fr/', 'https://www.google.com/maps/search/La+Residence+Des+Arts+Toulouse', 'assets/images/pochette_autre.png', 43.6000, 1.4420);

-- Table des catégories dynamiques par mode et ville.
-- Remplace tous les fichiers *_category_data.dart hardcodés.

CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mode text NOT NULL,              -- day, night, sport, culture, family, food, gaming, tourisme
  groupe text NOT NULL DEFAULT '',  -- nom du groupe (ex: 'Bars & vie nocturne')
  groupe_emoji text NOT NULL DEFAULT '',
  groupe_ordre int NOT NULL DEFAULT 0,
  label text NOT NULL,             -- nom affiché (ex: 'Bar de nuit')
  search_tag text NOT NULL,        -- clé de navigation/filtre (ex: 'Bar de nuit')
  emoji text NOT NULL DEFAULT '',
  image_url text NOT NULL DEFAULT '',  -- chemin asset ou URL CDN
  ordre int NOT NULL DEFAULT 0,    -- tri dans le groupe
  ville text,                      -- NULL = toutes les villes
  display_type text NOT NULL DEFAULT 'venues',  -- events, venues, map, matches, sub_grid, fullscreen_map
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb,                  -- config extra (venue_keywords, sport_type, children, etc.)
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index pour les requêtes courantes
CREATE INDEX idx_categories_mode_ville ON categories (mode, ville);
CREATE INDEX idx_categories_mode_groupe ON categories (mode, groupe_ordre, ordre);

-- RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_categories" ON categories FOR SELECT TO anon USING (true);
CREATE POLICY "service_write_categories" ON categories FOR ALL TO service_role USING (true);

-- ══════════════════════════════════════════════════════════════════
-- SEED DATA : toutes les catégories actuellement hardcodées
-- ══════════════════════════════════════════════════════════════════

-- ── DAY ──────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('day', '', '', 0, 'Fête de la musique', 'Fete musique', '', 'assets/images/pochette_fetedelamusique.png', 0, 'fullscreen_map'),
('day', '', '', 0, 'Concert', 'Concert', '', 'assets/images/pochette_concert.png', 1, 'venue_grid'),
('day', '', '', 0, 'Spectacle', 'Spectacle', '', 'assets/images/pochette_spectacle.png', 2, 'venue_grid'),
('day', '', '', 0, 'Festival', 'Festival', '', 'assets/images/pochette_festival.png', 3, 'events'),
('day', '', '', 0, 'Opera', 'Opera', '', 'assets/images/pochette_opera.jpg', 4, 'events'),
('day', '', '', 0, 'Stand Up', 'Stand up', '', 'assets/images/pochette_standup.png', 5, 'events'),
('day', '', '', 0, 'DJ Set', 'DJ set', '', 'assets/images/pochette_discotheque.png', 6, 'venue_grid'),
('day', '', '', 0, 'Showcase', 'Showcase', '', 'assets/images/pochette_showcase.png', 7, 'events'),
('day', '', '', 0, 'Autres', 'Autres', '', 'assets/images/pochette_autre.jpg', 8, 'events');

-- Day concert venues (Toulouse-specific)
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, ville, display_type, metadata) VALUES
('day', 'Concert', '', 1, 'Zenith', 'zenith', '', 'assets/images/salle_zenith.jpg', 0, 'Toulouse', 'events', '{"venue_keyword": "zenith"}'),
('day', 'Concert', '', 1, 'Halle aux Grains', 'halle aux grains', '', 'assets/images/salle_halleauxgrains.jpg', 1, 'Toulouse', 'events', '{"venue_keyword": "halle aux grains"}'),
('day', 'Concert', '', 1, 'Le Bikini', 'bikini', '', 'assets/images/salle_bikini.png', 2, 'Toulouse', 'events', '{"venue_keyword": "bikini"}'),
('day', 'Concert', '', 1, 'Auditorium', 'auditorium', '', 'assets/images/salle_auditorium.jpg', 3, 'Toulouse', 'events', '{"venue_keyword": "auditorium"}'),
('day', 'Concert', '', 1, 'Interference', 'interference', '', 'assets/images/salle_interference.jpg', 4, 'Toulouse', 'events', '{"venue_keyword": "interference"}'),
('day', 'Concert', '', 1, 'Casino Barriere', 'casino barriere', '', 'assets/images/pochette_concert.png', 5, 'Toulouse', 'events', '{"venue_keyword": "casino barriere"}'),
('day', 'Concert', '', 1, 'Le Metronum', 'metronum', '', 'assets/images/pochette_metronum.jpg', 6, 'Toulouse', 'events', '{"venue_keyword": "metronum"}'),
('day', 'Concert', '', 1, 'Le Rex', 'rex', '', 'assets/images/pochette_rex.jpg', 7, 'Toulouse', 'events', '{"venue_keyword": "rex"}'),
('day', 'Concert', '', 1, 'La Dynamo', 'dynamo', '', 'assets/images/pochette_concert.png', 8, 'Toulouse', 'events', '{"venue_keyword": "dynamo"}'),
('day', 'Concert', '', 1, 'Bascala', 'bascala', '', 'assets/images/pochette_concert.png', 9, 'Toulouse', 'events', '{"venue_keyword": "bascala"}'),
('day', 'Concert', '', 1, 'COMDT', 'comdt', '', 'assets/images/pochette_concert.png', 10, 'Toulouse', 'events', '{"venue_keyword": "comdt"}'),
('day', 'Concert', '', 1, 'Hall 8', 'hall 8', '', 'assets/images/pochette_concert.png', 11, 'Toulouse', 'events', '{"venue_keyword": "hall 8"}'),
('day', 'Concert', '', 1, 'Senechal', 'senechal', '', 'assets/images/pochette_concert.png', 12, 'Toulouse', 'events', '{"venue_keyword": "senechal"}');

-- Day DJ Set venues (Toulouse)
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, ville, display_type, metadata) VALUES
('day', 'DJ set', '', 2, 'Interference', 'interference', '', 'assets/images/salle_interference.jpg', 0, 'Toulouse', 'events', '{"venue_keyword": "interference"}'),
('day', 'DJ set', '', 2, 'Le Bikini', 'bikini', '', 'assets/images/salle_bikini.png', 1, 'Toulouse', 'events', '{"venue_keyword": "bikini"}'),
('day', 'DJ set', '', 2, 'Le Rex', 'rex', '', 'assets/images/pochette_rex.jpg', 2, 'Toulouse', 'events', '{"venue_keyword": "rex"}');

-- Day Spectacle venues (Toulouse)
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, ville, display_type, metadata) VALUES
('day', 'Spectacle', '', 3, 'Interference', 'interference', '', 'assets/images/salle_interference.jpg', 0, 'Toulouse', 'events', '{"venue_keyword": "interference"}'),
('day', 'Spectacle', '', 3, 'Le Bikini', 'bikini', '', 'assets/images/salle_bikini.png', 1, 'Toulouse', 'events', '{"venue_keyword": "bikini"}'),
('day', 'Spectacle', '', 3, 'Zenith', 'zenith', '', 'assets/images/salle_zenith.jpg', 2, 'Toulouse', 'events', '{"venue_keyword": "zenith"}'),
('day', 'Spectacle', '', 3, 'Halle aux Grains', 'halle aux grains', '', 'assets/images/salle_halleauxgrains.jpg', 3, 'Toulouse', 'events', '{"venue_keyword": "halle aux grains"}'),
('day', 'Spectacle', '', 3, 'Bascala', 'bascala', '', 'assets/images/pochette_concert.png', 4, 'Toulouse', 'events', '{"venue_keyword": "bascala"}'),
('day', 'Spectacle', '', 3, 'Casino Barriere', 'casino barriere', '', 'assets/images/pochette_concert.png', 5, 'Toulouse', 'events', '{"venue_keyword": "casino barriere"}');

-- ── NIGHT ─────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('night', 'A venir', '', 0, 'Agenda', 'A venir', '', 'assets/images/pochette_default.jpg', 0, 'events'),
('night', 'Bars & vie nocturne', '', 1, 'Bar de nuit', 'Bar de nuit', '', 'assets/images/pochette_pub.png', 0, 'venues'),
('night', 'Bars & vie nocturne', '', 1, 'Club / Discotheque', 'Club Discotheque', '', 'assets/images/pochette_discotheque.png', 1, 'venues'),
('night', 'Bars & vie nocturne', '', 1, 'Bar a cocktails', 'Bar a cocktails', '', 'assets/images/pochette_pub.png', 2, 'venues'),
('night', 'Bars & vie nocturne', '', 1, 'Bar a chicha', 'Bar a chicha', '', 'assets/images/pochette_chicha.png', 3, 'venues'),
('night', 'Bars & vie nocturne', '', 1, 'Pub', 'Pub', '', 'assets/images/pochette_pub.png', 4, 'venues'),
('night', 'Commerces ouverts la nuit', '', 2, 'Epicerie de nuit', 'Epicerie de nuit', '', 'assets/images/pochette_tabac.png', 0, 'venues'),
('night', 'Commerces ouverts la nuit', '', 2, 'SOS Apero', 'SOS Apero', '', 'assets/images/pochette_default.jpg', 1, 'venues'),
('night', 'Commerces ouverts la nuit', '', 2, 'Tabac de nuit', 'Tabac de nuit', '', 'assets/images/pochette_tabac.png', 2, 'venues'),
('night', 'Hebergement', '', 3, 'Hotel', 'Hotel', '', 'assets/images/pochette_hotel.png', 0, 'venues');

-- ── SPORT ─────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type, metadata) VALUES
('sport', 'Matchs', '', 0, 'Rugby', 'Rugby', '', 'assets/images/shell_sport_rugby.png', 0, 'matches', '{"sport_type": "rugby"}'),
('sport', 'Matchs', '', 0, 'Football', 'Football', '', 'assets/images/shell_sport_football.png', 1, 'matches', '{"sport_type": "football"}'),
('sport', 'Matchs', '', 0, 'Basketball', 'Basketball', '', 'assets/images/shell_sport_basketball.png', 2, 'matches', '{"sport_type": "basketball"}'),
('sport', 'Matchs', '', 0, 'Handball', 'Handball', '', 'assets/images/shell_sport_handball.png', 3, 'matches', '{"sport_type": "handball"}'),
('sport', 'Evenements', '', 1, 'Boxe', 'Boxe', '', 'assets/images/pochette_boxe.png', 0, 'events', NULL),
('sport', 'Evenements', '', 1, 'Natation', 'Natation', '', 'assets/images/pochette_natation.jpg', 1, 'events', NULL),
('sport', 'Evenements', '', 1, 'Course a pied', 'Courses a pied', '', 'assets/images/pochette_course.png', 2, 'events', NULL),
('sport', 'Evenements', '', 1, 'Golf', 'Golf', '', 'assets/images/pochette_Golf.jpg', 3, 'events', NULL),
('sport', 'Evenements', '', 1, 'Stage de danse', 'Stage de danse', '', 'assets/images/pochette_stagedanse.png', 4, 'events', NULL),
('sport', 'Ou pratiquer', '', 2, 'Salle de Fitness', 'Salle de fitness', '', 'assets/images/shell_sport_fitness.png', 0, 'venues', '{"sport_type": "fitness"}'),
('sport', 'Ou pratiquer', '', 2, 'Salle de danse', 'Danse', '', 'assets/images/pochette_animation.png', 1, 'venues', '{"sport_type": "danse"}'),
('sport', 'Ou pratiquer', '', 2, 'Salles de boxe', 'Salles de boxe', '', 'assets/images/pochette_boxe.png', 2, 'venues', '{"sport_type": "boxe"}'),
('sport', 'Ou pratiquer', '', 2, 'Terrain de football', 'Terrain de football', '', 'assets/images/shell_sport_football.png', 3, 'venues', '{"sport_type": "football"}'),
('sport', 'Ou pratiquer', '', 2, 'Terrain de basketball', 'Terrain de basketball', '', 'assets/images/shell_sport_basketball.png', 4, 'venues', '{"sport_type": "basketball"}'),
('sport', 'Ou pratiquer', '', 2, 'Piscine', 'Piscine', '', 'assets/images/pochette_natation.jpg', 5, 'venues', '{"sport_type": "piscine"}'),
('sport', 'Ou pratiquer', '', 2, 'Golf', 'Golf carte', '', 'assets/images/pochette_Golf.jpg', 6, 'map', '{"sport_type": "golf"}'),
('sport', 'Ou pratiquer', '', 2, 'Raquette', 'Raquette', '', 'assets/images/pochette_autre.jpg', 7, 'sub_grid', NULL);

-- Sport raquette sub-categories
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type, metadata) VALUES
('sport', 'Raquette', '', 3, 'Tennis', 'Tennis', '', 'assets/images/pochette_autre.jpg', 0, 'venues', '{"sport_type": "tennis"}'),
('sport', 'Raquette', '', 3, 'Padel', 'Padel', '', 'assets/images/pochette_autre.jpg', 1, 'venues', '{"sport_type": "padel"}'),
('sport', 'Raquette', '', 3, 'Squash', 'Squash', '', 'assets/images/pochette_autre.jpg', 2, 'venues', '{"sport_type": "squash"}'),
('sport', 'Raquette', '', 3, 'Ping-pong', 'Ping-pong', '', 'assets/images/pochette_autre.jpg', 3, 'venues', '{"sport_type": "ping-pong"}'),
('sport', 'Raquette', '', 3, 'Badminton', 'Badminton', '', 'assets/images/pochette_autre.jpg', 4, 'venues', '{"sport_type": "badminton"}');

-- ── CULTURE ───────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('culture', 'Arts vivants', '', 0, 'Theatre', 'Theatre', '', 'assets/images/pochette_theatre.png', 0, 'venues'),
('culture', 'Musees & expositions', '', 1, 'Musee', 'Musee', '', 'assets/images/pochette_musee.png', 0, 'venues'),
('culture', 'Musees & expositions', '', 1, 'Exposition', 'Exposition', '', 'assets/images/pochette_exposition.png', 1, 'events'),
('culture', 'Patrimoine & monuments', '', 2, 'Monument historique', 'Monument historique', '', 'assets/images/pochette_monument.jpg', 0, 'venues'),
('culture', 'Patrimoine & monuments', '', 2, 'Bibliotheque', 'Bibliotheque', '', 'assets/images/pochette_bibliotheque.jpg', 1, 'venues'),
('culture', 'Visites & animations', '', 3, 'Visites guidees', 'Visites guidees', '', 'assets/images/pochette_visite.png', 0, 'events'),
('culture', 'Art', '', 4, 'Galerie d''art', 'Galerie d''art', '', 'assets/images/pochette_culture_art.png', 0, 'venues');

-- ── FAMILY ────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('family', 'A venir', '', 0, 'Calendrier', 'A venir', '', 'assets/images/pochette_default.jpg', 0, 'events'),
('family', 'Parcs & jeux', '', 1, 'Parc d''attractions', 'Parc d''attractions', '', 'assets/images/pochette_parc_attraction.png', 0, 'venues'),
('family', 'Parcs & jeux', '', 1, 'Aire de jeux', 'Aire de jeux', '', 'assets/images/pochette_enfamille.jpg', 1, 'venues'),
('family', 'Parcs & jeux', '', 1, 'Parc animalier', 'Parc animalier', '', 'assets/images/pochette_parc_animalier.png', 2, 'venues'),
('family', 'Parcs & jeux', '', 1, 'Ferme pedagogique', 'Ferme pedagogique', '', 'assets/images/pochette_enfamille.jpg', 3, 'venues'),
('family', 'Loisirs', '', 2, 'Cinema', 'Cinema', '', 'assets/images/pochette_spectacle.png', 0, 'venues'),
('family', 'Loisirs', '', 2, 'Bowling', 'Bowling', '', 'assets/images/pochette_enfamille.jpg', 1, 'venues'),
('family', 'Loisirs', '', 2, 'Laser game', 'Laser game', '', 'assets/images/pochette_enfamille.jpg', 2, 'venues'),
('family', 'Loisirs', '', 2, 'Escape game', 'Escape game', '', 'assets/images/pochette_gaming.jpg', 3, 'venues'),
('family', 'Loisirs', '', 2, 'Patinoire', 'Patinoire', '', 'assets/images/pochette_enfamille.jpg', 4, 'venues'),
('family', 'Culture', '', 3, 'Aquarium', 'Aquarium', '', 'assets/images/pochette_parc_animalier.png', 0, 'venues'),
('family', 'Restauration', '', 4, 'Restaurant familial', 'Restaurant familial', '', 'assets/images/pochette_restaurant.jpg', 0, 'venues');

-- ── FOOD ──────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('food', 'A venir', '', 0, 'Calendrier', 'A venir', '', 'assets/images/pochette_cettesemaine.jpg', 0, 'events'),
('food', 'Restaurants', '', 1, 'Restaurant', 'Restaurant', '', 'assets/images/pochette_restaurant.jpg', 0, 'venues'),
('food', 'Restaurants', '', 1, 'Guinguette', 'Guinguette', '', 'assets/images/pochette_restaurant.jpg', 1, 'venues'),
('food', 'Restaurants', '', 1, 'Buffets', 'Buffets', '', 'assets/images/pochette_restaurant.jpg', 2, 'venues'),
('food', 'Cafes & brunchs', '', 2, 'Salon de the', 'Salon de the', '', 'assets/images/pochette_salondethe.jpg', 0, 'venues'),
('food', 'Cafes & brunchs', '', 2, 'Brunch', 'Brunch', '', 'assets/images/pochette_brunch.jpg', 1, 'venues'),
('food', 'Bien-etre & lifestyle', '', 3, 'Spa & hammam', 'Spa hammam', '', 'assets/images/pochette_spa&hammam.png', 0, 'venues'),
('food', 'Bien-etre & lifestyle', '', 3, 'Massage', 'Massage', '', 'assets/images/pochette_spa&hammam.png', 1, 'venues'),
('food', 'Bien-etre & lifestyle', '', 3, 'Yoga & meditation', 'Yoga meditation', '', 'assets/images/pochette_yoga.jpg', 2, 'venues');

-- ── GAMING ─────────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('gaming', 'A venir', '', 0, 'Agenda', 'A venir', '', 'assets/images/pochette_cettesemaine.jpg', 0, 'events'),
('gaming', 'Jeux video', '', 1, 'Salle d''arcade', 'Salle arcade', '', 'assets/images/pochette_sallearcade.png', 0, 'venues'),
('gaming', 'Jeux video', '', 1, 'Gaming cafe', 'Gaming cafe', '', 'assets/images/pochette_gamingcafe.jpg', 1, 'venues'),
('gaming', 'Jeux video', '', 1, 'VR & realite virtuelle', 'Realite virtuelle VR', '', 'assets/images/pochette_VR.png', 2, 'venues'),
('gaming', 'Jeux de societe & cartes', '', 2, 'Bar a jeux', 'Bar a jeux', '', 'assets/images/pochette_barajeux.png', 0, 'venues'),
('gaming', 'Jeux de societe & cartes', '', 2, 'Boutique jeux', 'Boutique jeux', '', 'assets/images/pochette_gaming.jpg', 1, 'venues'),
('gaming', 'Jeux de societe & cartes', '', 2, 'Escape game', 'Escape game', '', 'assets/images/pochette_escapegame.jpg', 2, 'venues'),
('gaming', 'Manga, comics & BD', '', 3, 'Boutique manga', 'Boutique manga', '', 'assets/images/pochette_boutiquemanga.jpg', 0, 'venues'),
('gaming', 'Manga, comics & BD', '', 3, 'Comics & BD', 'Comics BD', '', 'assets/images/pochette_default.jpg', 1, 'venues'),
('gaming', 'Manga, comics & BD', '', 3, 'Figurines & goodies', 'Figurines goodies', '', 'assets/images/pochette_default.jpg', 2, 'venues'),
('gaming', 'Evenements & conventions', '', 4, 'Convention & salon', 'Convention salon geek', '', 'assets/images/pochette_default.jpg', 0, 'events'),
('gaming', 'Evenements & conventions', '', 4, 'Tournoi e-sport', 'Tournoi esport', '', 'assets/images/pochette_gaming.jpg', 1, 'events'),
('gaming', 'Evenements & conventions', '', 4, 'Cosplay', 'Cosplay', '', 'assets/images/pochette_cosplay.jpg', 2, 'events');

-- ── TOURISME ──────────────────────────────────────────────────────
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('tourisme', 'Se deplacer', '', 0, 'Se deplacer', 'Se deplacer', '', 'assets/images/carte_se_deplacer.png', 0, 'fullscreen_map'),
('tourisme', 'Plan touristique', '', 1, 'Plan touristique', 'Plan touristique', '', 'assets/images/carte_plan_touristique.png', 0, 'fullscreen_map'),
('tourisme', 'Activites', '', 2, 'Activites', 'Activites', '', 'assets/images/pochette_tourisme_toulouse.png', 0, 'venues'),
('tourisme', 'Visiter', '', 3, 'Visiter', 'Visiter', '', 'assets/images/pochette_tourisme_toulouse.png', 0, 'sub_grid');

-- Tourisme Visiter children (Toulouse-specific)
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, ville, display_type) VALUES
('tourisme', 'Visiter', '', 4, 'City tour', 'City tour', '', 'assets/images/pochette_tourisme_toulouse.png', 0, 'Toulouse', 'venues'),
('tourisme', 'Visiter', '', 4, 'Tuk-tuk', 'Tuk-tuk', '', 'assets/images/pochette_tourisme_toulouse.png', 1, 'Toulouse', 'venues'),
('tourisme', 'Visiter', '', 4, 'Petit Train', 'Petit Train', '', 'assets/images/pochette_tourisme_toulouse.png', 2, 'Toulouse', 'venues'),
('tourisme', 'Visiter', '', 4, 'La maison de la violette', 'La maison de la violette', '', 'assets/images/pochette_tourisme_toulouse.png', 3, 'Toulouse', 'venues'),
('tourisme', 'Visiter', '', 4, 'Le Canal', 'Le Canal', '', 'assets/images/pochette_tourisme_toulouse.png', 4, 'Toulouse', 'venues');

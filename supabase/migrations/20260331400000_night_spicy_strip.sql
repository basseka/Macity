-- Sous-categorie Strip sous Spicy
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('night', 'Spicy', '', 7, 'Strip', 'Strip', '', 'assets/images/pochette_strip.png', 1, 'venues');

-- Seed venues Strip pour Paris
INSERT INTO venues (slug, name, mode, category, adresse, ville, horaires, website_url, lien_maps, latitude, longitude, photo, is_active) VALUES
  ('secret-square', 'Secret Square Strip Club', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'http://www.secretsquare.fr/', 'https://maps.google.com/?q=Secret+Square+Strip+Club+Paris', 48.8690, 2.3310, '', true),
  ('pink-paradise', 'Pink Paradise', 'night', 'Strip', '49 Rue de Ponthieu, 75008 Paris', 'Paris', '22h00 - 06h00', 'https://pinkparadise.fr/', 'https://maps.google.com/?q=Pink+Paradise+49+Rue+Ponthieu+Paris', 48.8730, 2.3070, '', true),
  ('whisper-club', 'Whisper Club', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'http://www.whisper-club-paris.com/', 'https://maps.google.com/?q=Whisper+Club+Paris', 48.8660, 2.3390, '', true),
  ('club-azur-strip', 'Club Azur', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.clubazur.fr/', 'https://maps.google.com/?q=Club+Azur+Strip+Paris', 48.8640, 2.3420, '', true),
  ('g-spot-club', 'G-Spot Club', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.gspot-club.com/', 'https://maps.google.com/?q=G-Spot+Club+Paris', 48.8610, 2.3450, '', true),
  ('la-marquise-strip', 'La Marquise Club', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'http://www.lamarquise.club/', 'https://maps.google.com/?q=La+Marquise+Club+Strip+Paris', 48.8580, 2.3480, '', true),
  ('secret-strip', 'Secret', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'http://club-secret.fr/', 'https://maps.google.com/?q=Club+Secret+Strip+Paris', 48.8620, 2.3360, '', true),
  ('home-striptease', 'Home Striptease', 'night', 'Strip', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.home-striptease.fr/', 'https://maps.google.com/?q=Home+Striptease+Paris', 48.8650, 2.3340, '', true);

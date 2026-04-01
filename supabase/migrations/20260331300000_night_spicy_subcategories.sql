-- Transformer Spicy en sub_grid pour accueillir des sous-categories
UPDATE categories SET display_type = 'sub_grid' WHERE mode = 'night' AND search_tag = 'Spicy';

-- Sous-categorie Coquin
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type) VALUES
('night', 'Spicy', '', 7, 'Coquin', 'Coquin', '', 'assets/images/pochette_coquin.png', 0, 'venues');

-- Seed venues Coquin pour Paris
INSERT INTO venues (slug, name, mode, category, adresse, ville, horaires, website_url, lien_maps, latitude, longitude, photo, is_active) VALUES
  ('les-chandelles', 'Les Chandelles', 'night', 'Coquin', '1 Rue Therese, 75001 Paris', 'Paris', '22h00 - 06h00', 'https://www.leschandelles.com', 'https://maps.google.com/?q=Les+Chandelles+1+Rue+Therese+Paris', 48.8650, 2.3350, '', true),
  ('2plus2-club', '2plus2 Club', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.2plus2.fr', 'https://maps.google.com/?q=2plus2+Club+Paris', 48.8620, 2.3400, '', true),
  ('cupidon-club', 'Cupidon Club', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.cupidon-club.net', 'https://maps.google.com/?q=Cupidon+Club+Paris', 48.8590, 2.3450, '', true),
  ('overside', 'Overside', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.overside.fr', 'https://maps.google.com/?q=Overside+Club+Paris', 48.8570, 2.3500, '', true),
  ('la-marquise', 'La Marquise', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://www.lamarquise.club', 'https://maps.google.com/?q=La+Marquise+Club+Paris', 48.8600, 2.3380, '', true),
  ('the-dream-studio', 'The Dream Studio', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://annuaire-libertin.fr/club-libertin-paris.html', 'https://maps.google.com/?q=The+Dream+Studio+Paris', 48.8640, 2.3420, '', true),
  ('we-club', 'WE Club', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://annuaire-libertin.fr/club-libertin-paris.html', 'https://maps.google.com/?q=WE+Club+Paris', 48.8610, 2.3460, '', true),
  ('divine-alcove', 'Divine Alcove', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://annuaire-libertin.fr/club-libertin-paris.html', 'https://maps.google.com/?q=Divine+Alcove+Paris', 48.8580, 2.3490, '', true),
  ('eleven-club-prive', 'Eleven Club Prive', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', 'https://annuaire-libertin.fr/club-libertin-paris.html', 'https://maps.google.com/?q=Eleven+Club+Prive+Paris', 48.8630, 2.3370, '', true),
  ('le-mask', 'Le Mask', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', '', 'https://maps.google.com/?q=Le+Mask+club+libertin+Paris', 48.8560, 2.3520, '', true),
  ('le-taken-club', 'Le Taken Club', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', '', 'https://maps.google.com/?q=Taken+Club+Paris', 48.8650, 2.3440, '', true),
  ('le-secret-club', 'Le Secret Club', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', '', 'https://maps.google.com/?q=Secret+club+libertin+Paris', 48.8600, 2.3530, '', true),
  ('l-escarpin', 'L''Escarpin', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', '', 'https://maps.google.com/?q=Escarpin+club+Paris', 48.8570, 2.3480, '', true),
  ('cris-et-chuchotements', 'Cris et Chuchotements', 'night', 'Coquin', 'Paris, 75000', 'Paris', '22h00 - 06h00', '', 'https://maps.google.com/?q=Cris+et+Chuchotements+Paris', 48.8540, 2.3550, '', true);

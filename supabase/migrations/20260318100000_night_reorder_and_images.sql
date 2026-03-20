-- Reorder night categories and update images

-- Bars & vie nocturne: Club/Discotheque avant Bar de nuit
UPDATE categories SET ordre = 0 WHERE mode = 'night' AND search_tag = 'Club Discotheque';
UPDATE categories SET ordre = 1 WHERE mode = 'night' AND search_tag = 'Bar de nuit';

-- Commerces ouverts la nuit: SOS Apero avant Epicerie de nuit
UPDATE categories SET ordre = 0, image_url = 'assets/images/pochette_sosapero.png' WHERE mode = 'night' AND search_tag = 'SOS Apero';
UPDATE categories SET ordre = 1, image_url = 'assets/images/pochette_epicerie.png' WHERE mode = 'night' AND search_tag = 'Epicerie de nuit';

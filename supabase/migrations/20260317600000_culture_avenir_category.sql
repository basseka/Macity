-- Ajouter la categorie "A venir" pour le mode culture
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type, is_active)
VALUES ('culture', 'A venir', '', -1, 'Agenda', 'A venir', '', 'assets/images/pochette_cettesemaine.jpg', 0, 'events', true)
ON CONFLICT DO NOTHING;

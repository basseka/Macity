-- Ajouter la carte "A venir" dans le hub Day/Concert.
INSERT INTO categories (mode, groupe, groupe_emoji, groupe_ordre, label, search_tag, emoji, image_url, ordre, display_type, is_active)
VALUES ('day', 'A venir', '', -1, 'Agenda', 'A venir', '', 'assets/images/pochette_cettesemaine.png', 0, 'events', true)
ON CONFLICT DO NOTHING;

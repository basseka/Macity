-- Match Basketball Toulouse BC - Mars 2026
INSERT INTO matchs (sport, competition, equipe_dom, equipe_ext, date, heure, lieu, ville, description, url, source)
VALUES
  ('Basketball', 'NM1', 'Toulouse Basketball Club', 'Mulhouse', '2026-03-06', '20h00', 'Palais des Sports Andre Brouat', 'Toulouse', 'NM1 - Toulouse Basketball Club vs Mulhouse', 'https://toulousebasketballclub.billetterie-club.fr/home', 'nm1.ffbb.com')
ON CONFLICT (sport, equipe_dom, equipe_ext, date) DO NOTHING;

-- =============================================================================
-- Migration : Ajout colonne groupe + remplissage pour les salles de danse
-- =============================================================================

-- 1. Ajouter la colonne groupe
ALTER TABLE public.sport_venues ADD COLUMN groupe TEXT NOT NULL DEFAULT '';

-- 2. Mettre a jour les salles specialisees (mapping categorie → groupe)
UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom = 'Ballet School Harold & Alexandra Paturet' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Hip-Hop / Street / Breakdance'
  WHERE nom = 'Brigade Fantome - Equipe De Danse Hip Hop Et Breakdance' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Latines (Salsa, Bachata, Rock...)'
  WHERE nom = 'Puntatalon Academy - School Dances Latines' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Du Monde / Orientales / Afro'
  WHERE nom = 'Laliana Danse Orientale Et Armenienne' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Bien-Etre / Expression corporelle'
  WHERE nom = 'Cecile - Cours De Danse & Accompagnement Sport Sante Bien-Etre' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Contemporaine'
  WHERE nom = 'Choreographic Centre De Toulouse' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Contemporaine'
  WHERE nom = 'La Place De La Danse CDCN Toulouse Occitanie' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Studios polyvalents / Location de salles'
  WHERE nom = 'La Residence Des Arts' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Studios polyvalents / Location de salles'
  WHERE nom = 'Atelier Danse' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Studios polyvalents / Location de salles'
  WHERE nom = 'Dance Studio' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Bien-Etre / Expression corporelle'
  WHERE nom LIKE 'Danc%in La Roseraie%' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Latines (Salsa, Bachata, Rock...)'
  WHERE nom = 'Art Dance International' AND sport_type = 'danse';

-- 3. Ecoles generales : groupe principal
UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom = 'Encas-Danses Studio' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom = 'La Salle' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom = 'La Maison De La Danse' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom = 'Studio9 Toulouse - School De Danse' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Classique / Ballet'
  WHERE nom LIKE 'Ecole de danse Francoise RAZES%' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Hip-Hop / Street / Breakdance'
  WHERE nom = 'Le 144 Dance Avenue' AND sport_type = 'danse';

UPDATE public.sport_venues SET groupe = 'Contemporaine'
  WHERE nom = 'Three Time Dense' AND sport_type = 'danse';

-- 4. Entrees supplementaires pour ecoles multi-groupes
--    (duplique la ligne existante avec un groupe different)

-- Encas-Danses Studio : aussi dans Contemporaine, Du Monde/Afro, Jazz
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, groupe)
SELECT nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, v.g
FROM public.sport_venues,
     (VALUES ('Contemporaine'), ('Du Monde / Orientales / Afro'), ('Jazz / Modern Jazz')) AS v(g)
WHERE nom = 'Encas-Danses Studio' AND sport_type = 'danse' AND groupe = 'Classique / Ballet';

-- La Salle : aussi dans Contemporaine, Hip-Hop, Jazz
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, groupe)
SELECT nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, v.g
FROM public.sport_venues,
     (VALUES ('Contemporaine'), ('Hip-Hop / Street / Breakdance'), ('Jazz / Modern Jazz')) AS v(g)
WHERE nom = 'La Salle' AND sport_type = 'danse' AND groupe = 'Classique / Ballet';

-- Studio9 : aussi dans Hip-Hop, Jazz
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, groupe)
SELECT nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, v.g
FROM public.sport_venues,
     (VALUES ('Hip-Hop / Street / Breakdance'), ('Jazz / Modern Jazz')) AS v(g)
WHERE nom = 'Studio9 Toulouse - School De Danse' AND sport_type = 'danse' AND groupe = 'Classique / Ballet';

-- Le 144 Dance Avenue : aussi dans Latines, Jazz
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, groupe)
SELECT nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, v.g
FROM public.sport_venues,
     (VALUES ('Latines (Salsa, Bachata, Rock...)'), ('Jazz / Modern Jazz')) AS v(g)
WHERE nom = 'Le 144 Dance Avenue' AND sport_type = 'danse' AND groupe = 'Hip-Hop / Street / Breakdance';

-- Three Time Dense : aussi dans Jazz
INSERT INTO public.sport_venues (nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, groupe)
SELECT nom, categorie, sport_type, adresse, site_web, lien_maps, photo, latitude, longitude, 'Jazz / Modern Jazz'
FROM public.sport_venues
WHERE nom = 'Three Time Dense' AND sport_type = 'danse' AND groupe = 'Contemporaine';

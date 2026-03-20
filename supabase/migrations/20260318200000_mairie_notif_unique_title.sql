-- Supprimer les doublons existants avant d'ajouter la contrainte unique.
-- On garde l'entree avec le plus petit id pour chaque (ville, title).
DELETE FROM public.mairie_notifications
WHERE id NOT IN (
  SELECT MIN(id)
  FROM public.mairie_notifications
  GROUP BY ville, title
);

-- Contrainte unique pour eviter les doublons lors du scraping mairie.
ALTER TABLE public.mairie_notifications
  ADD CONSTRAINT uq_mairie_notif_ville_title UNIQUE (ville, title);

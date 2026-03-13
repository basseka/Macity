-- Supprime automatiquement les notifications mairie de plus de 90 jours.
-- pg_cron execute la tache chaque jour a 3h du matin.

SELECT cron.schedule(
  'cleanup-old-mairie-notifications',
  '0 3 * * *',
  $$DELETE FROM mairie_notifications WHERE created_at < now() - interval '90 days'$$
);

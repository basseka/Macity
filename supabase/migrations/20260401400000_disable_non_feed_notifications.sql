-- Desactiver les notifications non liees au feed.
-- Garder uniquement send-daily-digest (base sur les events du feed).

-- Supprimer le cron des promos si existant
SELECT cron.unschedule('send-promo-notifications') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'send-promo-notifications'
);

-- Supprimer le cron mairie notifications si existant
SELECT cron.unschedule('send-mairie-notifications') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'send-mairie-notifications'
);

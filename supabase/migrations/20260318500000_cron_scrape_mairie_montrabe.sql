-- Cron job : scrape l'agenda de la mairie de Montrabé chaque jour à 7h30 UTC (9h30 CET)
SELECT cron.schedule(
  'scrape-mairie-montrabe-daily',
  '30 7 * * *',
  $$
  SELECT net.http_post(
    url    := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-montrabe',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDI5OTExOCwiZXhwIjoyMDg1ODc1MTE4fQ.7-Tv6VPoYYY2Kt07hMe1vPFz0iCE9V6SjMIgX1IQVVw',
      'Content-Type',  'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

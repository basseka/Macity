-- Cron job : scrape les actualités + agenda de Plaisance-du-Touch chaque jour à 8h15 UTC (10h15 CET)
SELECT cron.schedule(
  'scrape-mairie-plaisance-daily',
  '15 8 * * *',
  $$
  SELECT net.http_post(
    url    := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-plaisance',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDI5OTExOCwiZXhwIjoyMDg1ODc1MTE4fQ.7-Tv6VPoYYY2Kt07hMe1vPFz0iCE9V6SjMIgX1IQVVw',
      'Content-Type',  'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

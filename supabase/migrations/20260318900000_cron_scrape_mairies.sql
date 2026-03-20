-- Cron job : scrape toutes les mairies chaque jour à 6h UTC (8h CET)
-- Avant les scrapers individuels (7h-8h30) pour éviter les chevauchements.
SELECT cron.schedule(
  'scrape-all-mairies-daily',
  '0 6 * * *',
  $$
  SELECT net.http_post(
    url    := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairies',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDI5OTExOCwiZXhwIjoyMDg1ODc1MTE4fQ.7-Tv6VPoYYY2Kt07hMe1vPFz0iCE9V6SjMIgX1IQVVw',
      'Content-Type',  'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

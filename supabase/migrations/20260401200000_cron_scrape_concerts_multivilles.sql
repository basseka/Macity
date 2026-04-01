-- Cron jobs pour scrape-concerts multi-villes
-- Chaque ville est scrapee individuellement pour eviter les timeouts.
-- Reparties entre 2h00 et 3h30 UTC pour ne pas surcharger.

-- Grandes villes (plus de sources) : 2h00 - 2h30
SELECT cron.schedule(
  'scrape-concerts-paris',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Paris"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-lyon',
  '5 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Lyon"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-bordeaux',
  '10 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Bordeaux"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-geneve',
  '15 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Geneve"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-strasbourg',
  '20 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Strasbourg"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-nantes',
  '25 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"Nantes"}'::jsonb
  );
  $$
);

-- Villes Songkick (scrape-concerts-toulouse les gere deja via run-scrapers)
-- On ajoute un cron unique qui appelle le scraper toulouse pour les autres villes
-- Le scraper toulouse/songkick couvre : Marseille, Lille, Nice, Montpellier, Rennes

SELECT cron.schedule(
  'scrape-concerts-songkick-batch1',
  '30 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"marseille"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-songkick-batch2',
  '35 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"lille"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-songkick-batch3',
  '40 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"nice"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-songkick-batch4',
  '45 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"montpellier"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-songkick-batch5',
  '50 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"rennes"}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'scrape-concerts-songkick-batch6',
  '55 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-concerts-toulouse',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{"ville":"bordeaux"}'::jsonb
  );
  $$
);

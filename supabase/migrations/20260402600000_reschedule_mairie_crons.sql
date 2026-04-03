-- Replanifier les scrapers mairie entre 17h00 et 17h15 UTC

SELECT cron.unschedule('scrape-all-mairies-daily');
SELECT cron.unschedule('scrape-mairie-toulouse-daily');
SELECT cron.unschedule('scrape-mairie-beaupuy-daily');
SELECT cron.unschedule('scrape-mairie-balma-daily');
SELECT cron.unschedule('scrape-mairie-montrabe-daily');
SELECT cron.unschedule('scrape-mairie-lunion-daily');
SELECT cron.unschedule('scrape-mairie-colomiers-daily');
SELECT cron.unschedule('scrape-mairie-plaisance-daily');

SELECT cron.schedule('scrape-all-mairies-daily', '0 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairies',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-toulouse-daily', '2 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-toulouse',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-beaupuy-daily', '4 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-beaupuy',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-balma-daily', '6 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-balma',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-montrabe-daily', '8 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-montrabe',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-lunion-daily', '10 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-lunion',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-colomiers-daily', '12 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-colomiers',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);
SELECT cron.schedule('scrape-mairie-plaisance-daily', '15 17 * * *', $$SELECT net.http_post(url:='https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/scrape-mairie-plaisance',headers:=jsonb_build_object('Authorization','Bearer '||current_setting('app.settings.service_role_key',true),'Content-Type','application/json'),body:='{}'::jsonb);$$);

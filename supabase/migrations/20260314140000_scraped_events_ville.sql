-- Add ville column to scraped_events for multi-city filtering
ALTER TABLE public.scraped_events
  ADD COLUMN IF NOT EXISTS ville TEXT NOT NULL DEFAULT 'Toulouse';

CREATE INDEX IF NOT EXISTS idx_scraped_ville ON public.scraped_events (ville);

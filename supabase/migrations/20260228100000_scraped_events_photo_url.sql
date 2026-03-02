-- Add photo_url column to scraped_events for event images/posters.
ALTER TABLE public.scraped_events
  ADD COLUMN IF NOT EXISTS photo_url TEXT NOT NULL DEFAULT '';

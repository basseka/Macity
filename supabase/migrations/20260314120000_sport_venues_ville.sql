-- Add ville column to sport_venues and set existing data to Toulouse
ALTER TABLE public.sport_venues
  ADD COLUMN IF NOT EXISTS ville TEXT NOT NULL DEFAULT 'Toulouse';

CREATE INDEX IF NOT EXISTS idx_sport_venues_ville ON public.sport_venues (ville);

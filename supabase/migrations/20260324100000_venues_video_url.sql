-- Ajouter video_url aux tables venues et sport_venues
ALTER TABLE venues ADD COLUMN IF NOT EXISTS video_url TEXT NOT NULL DEFAULT '';
ALTER TABLE sport_venues ADD COLUMN IF NOT EXISTS video_url TEXT NOT NULL DEFAULT '';

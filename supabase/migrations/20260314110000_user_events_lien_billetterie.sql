-- Add lien_billetterie column to user_events table
ALTER TABLE user_events
  ADD COLUMN IF NOT EXISTS lien_billetterie TEXT NOT NULL DEFAULT '';

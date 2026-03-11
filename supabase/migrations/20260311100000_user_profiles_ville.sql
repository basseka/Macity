-- Add ville column to user_profiles for city-specific Mairie notifications
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS ville TEXT NOT NULL DEFAULT '';

-- User profiles: email, phone, activity preferences
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id     TEXT PRIMARY KEY,
  email       TEXT NOT NULL DEFAULT '',
  telephone   TEXT NOT NULL DEFAULT '',
  prenom      TEXT NOT NULL DEFAULT '',
  preferences TEXT[] NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_own_profile"
  ON public.user_profiles FOR SELECT
  USING (true);

CREATE POLICY "users_write_own_profile"
  ON public.user_profiles FOR INSERT
  WITH CHECK (true);

CREATE POLICY "users_update_own_profile"
  ON public.user_profiles FOR UPDATE
  USING (true);

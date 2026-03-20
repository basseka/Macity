-- ============================================================
-- Table : shared_events
-- Permet a un utilisateur de partager un event avec un autre.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.shared_events (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id    TEXT    NOT NULL REFERENCES public.user_events(id) ON DELETE CASCADE,
  from_user_id TEXT   NOT NULL,
  to_user_id   TEXT   NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (event_id, to_user_id)
);

CREATE INDEX idx_shared_events_to ON public.shared_events(to_user_id);
CREATE INDEX idx_shared_events_from ON public.shared_events(from_user_id);

ALTER TABLE public.shared_events ENABLE ROW LEVEL SECURITY;

-- Lecture : un user voit les partages qui le concernent
CREATE POLICY "shared_events_read" ON public.shared_events
  FOR SELECT USING (true);

-- Ecriture : n'importe qui peut partager (anon key)
CREATE POLICY "shared_events_insert" ON public.shared_events
  FOR INSERT WITH CHECK (true);

-- Suppression : l'expéditeur peut annuler le partage
CREATE POLICY "shared_events_delete" ON public.shared_events
  FOR DELETE USING (true);

-- ============================================================
-- RPC : find_users_by_phones
-- Recoit un tableau de numeros normalises, retourne les users
-- qui matchent (user_id, prenom, telephone).
-- ============================================================

CREATE OR REPLACE FUNCTION public.find_users_by_phones(phones TEXT[])
RETURNS TABLE(user_id TEXT, prenom TEXT, telephone TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT up.user_id, up.prenom, up.telephone
  FROM public.user_profiles up
  WHERE up.telephone = ANY(phones)
    AND up.telephone <> '';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

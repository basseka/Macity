-- Creer le bucket public 'venues' pour stocker les photos des etablissements.
INSERT INTO storage.buckets (id, name, public)
VALUES ('venues', 'venues', true)
ON CONFLICT (id) DO NOTHING;

-- Autoriser la lecture publique (anon)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Public read venues' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "Public read venues"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'venues');
  END IF;
END $$;

-- Cache des picks du week-end generes par l'IA Claude.
-- Regenere chaque vendredi par le cron weekend-picks.

CREATE TABLE IF NOT EXISTS weekend_picks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ville text NOT NULL,
  week_start date NOT NULL,
  picks jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(ville, week_start)
);

-- RLS
ALTER TABLE weekend_picks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_weekend_picks" ON weekend_picks FOR SELECT TO anon USING (true);
CREATE POLICY "service_write_weekend_picks" ON weekend_picks FOR ALL TO service_role USING (true);

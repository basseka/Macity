-- ============================================================
-- HYBRID PRESENCE SYSTEM
-- Affiche un "nombre de personnes presentes" par lieu.
-- Formule : display = real_count + (fake_count * weight)
-- Le weight diminue automatiquement quand le trafic reel augmente.
-- ============================================================

-- 1. Colonne display_count directement sur venues (evite les joins)
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS display_count INT NOT NULL DEFAULT 0;

-- ============================================================
-- 2. Table des presences reelles (check-ins)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.venue_presence (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venue_id      BIGINT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  user_id       TEXT   NOT NULL,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '2 hours'),
  UNIQUE(venue_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_vp_venue_active
  ON public.venue_presence(venue_id, expires_at);

ALTER TABLE public.venue_presence ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_insert_presence" ON public.venue_presence
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_read_own_presence" ON public.venue_presence
  FOR SELECT TO anon USING (true);
CREATE POLICY "service_manage_presence" ON public.venue_presence
  FOR ALL TO service_role USING (true);

-- ============================================================
-- 3. Table de configuration par lieu
-- ============================================================
CREATE TABLE IF NOT EXISTS public.venue_presence_config (
  venue_id              BIGINT PRIMARY KEY REFERENCES public.venues(id) ON DELETE CASCADE,
  base_popularity       INT NOT NULL DEFAULT 15,
  fake_weight           NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  consecutive_real_cycles INT NOT NULL DEFAULT 0,
  last_real_count       INT NOT NULL DEFAULT 0,
  last_display_count    INT NOT NULL DEFAULT 0,
  transition_status     TEXT NOT NULL DEFAULT 'fake',
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.venue_presence_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_vpc" ON public.venue_presence_config
  FOR SELECT TO anon USING (true);
CREATE POLICY "service_manage_vpc" ON public.venue_presence_config
  FOR ALL TO service_role USING (true);

-- Seed config pour tous les lieux existants
INSERT INTO public.venue_presence_config (venue_id, base_popularity)
SELECT id,
  CASE
    WHEN category ILIKE '%discotheque%' OR category ILIKE '%club%' THEN 40
    WHEN category ILIKE '%bar%'        THEN 25
    WHEN category ILIKE '%restaurant%' OR category ILIKE '%brasserie%' THEN 20
    WHEN category ILIKE '%musee%'      THEN 30
    WHEN category ILIKE '%theatre%'    THEN 35
    WHEN category ILIKE '%monument%'   THEN 20
    WHEN category ILIKE '%bibliotheque%' THEN 10
    WHEN category ILIKE '%cinema%'     THEN 30
    WHEN category ILIKE '%fitness%' OR category ILIKE '%sport%' THEN 18
    ELSE 15
  END
FROM public.venues
WHERE is_active = TRUE
ON CONFLICT DO NOTHING;

-- Trigger : auto-creer la config quand un nouveau lieu est insere
CREATE OR REPLACE FUNCTION public.auto_presence_config()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.venue_presence_config (venue_id, base_popularity)
  VALUES (NEW.id, 15)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_presence_config
  AFTER INSERT ON public.venues
  FOR EACH ROW EXECUTE FUNCTION public.auto_presence_config();

-- ============================================================
-- 4. Generateur de fake count realiste
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_fake_count(
  p_mode TEXT,
  p_category TEXT,
  p_base_popularity INT
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
  h   INT := EXTRACT(HOUR FROM NOW() AT TIME ZONE 'Europe/Paris')::INT;
  dow INT := EXTRACT(ISODOW FROM NOW() AT TIME ZONE 'Europe/Paris')::INT;
  hour_curve    NUMERIC := 0.3;
  weekend_boost NUMERIC := 1.0;
  jitter        NUMERIC;
  result        INT;
BEGIN
  -- Courbes par mode/categorie
  IF p_mode = 'night' OR p_category ILIKE '%discotheque%' OR p_category ILIKE '%club%' THEN
    hour_curve := CASE
      WHEN h BETWEEN 22 AND 23 THEN 0.9
      WHEN h BETWEEN 0 AND 2   THEN 1.0
      WHEN h BETWEEN 18 AND 21 THEN 0.5
      WHEN h BETWEEN 3 AND 5   THEN 0.3
      ELSE 0.05
    END;
    weekend_boost := CASE WHEN dow >= 5 THEN 1.4 ELSE 1.0 END;

  ELSIF p_category ILIKE '%bar%' OR p_category ILIKE '%pub%' THEN
    hour_curve := CASE
      WHEN h BETWEEN 18 AND 20 THEN 0.7
      WHEN h BETWEEN 21 AND 23 THEN 1.0
      WHEN h BETWEEN 0 AND 1   THEN 0.6
      WHEN h BETWEEN 14 AND 17 THEN 0.2
      ELSE 0.05
    END;
    weekend_boost := CASE WHEN dow >= 4 THEN 1.3 ELSE 1.0 END;

  ELSIF p_mode = 'food' OR p_category ILIKE '%restaurant%' OR p_category ILIKE '%brasserie%' THEN
    hour_curve := CASE
      WHEN h BETWEEN 12 AND 13 THEN 0.9
      WHEN h BETWEEN 19 AND 21 THEN 1.0
      WHEN h = 11              THEN 0.5
      WHEN h BETWEEN 14 AND 18 THEN 0.15
      ELSE 0.05
    END;
    weekend_boost := CASE WHEN dow >= 6 THEN 1.2 ELSE 1.0 END;

  ELSIF p_mode = 'culture' OR p_category ILIKE '%musee%' OR p_category ILIKE '%theatre%'
        OR p_category ILIKE '%bibliotheque%' OR p_category ILIKE '%monument%' THEN
    hour_curve := CASE
      WHEN h BETWEEN 10 AND 12 THEN 0.7
      WHEN h BETWEEN 13 AND 16 THEN 1.0
      WHEN h BETWEEN 17 AND 18 THEN 0.5
      WHEN h = 9               THEN 0.3
      ELSE 0.05
    END;
    weekend_boost := CASE WHEN dow >= 6 THEN 1.5 ELSE 1.0 END;

  ELSIF p_mode = 'sport' THEN
    hour_curve := CASE
      WHEN h BETWEEN 8 AND 11  THEN 0.6
      WHEN h BETWEEN 17 AND 20 THEN 1.0
      WHEN h BETWEEN 12 AND 16 THEN 0.4
      ELSE 0.1
    END;
    weekend_boost := CASE WHEN dow >= 6 THEN 1.3 ELSE 1.0 END;

  ELSIF p_mode = 'family' THEN
    hour_curve := CASE
      WHEN h BETWEEN 10 AND 12 THEN 0.8
      WHEN h BETWEEN 14 AND 17 THEN 1.0
      WHEN h BETWEEN 13 AND 13 THEN 0.5
      ELSE 0.1
    END;
    weekend_boost := CASE WHEN dow >= 6 THEN 1.6 ELSE 1.0 END;

  ELSE
    hour_curve := CASE
      WHEN h BETWEEN 10 AND 18 THEN 0.6
      ELSE 0.15
    END;
  END IF;

  -- Jitter aleatoire +-20%
  jitter := 0.8 + (random() * 0.4);

  result := GREATEST(2, ROUND(p_base_popularity * hour_curve * weekend_boost * jitter)::INT);
  RETURN result;
END;
$$;

-- ============================================================
-- 5. Calcul hybride du display_count pour un lieu
-- ============================================================
CREATE OR REPLACE FUNCTION public.compute_display_count(
  p_venue_id BIGINT
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
  v_real_count  INT;
  v_fake_count  INT;
  v_weight      NUMERIC;
  v_last_display INT;
  v_raw_display INT;
  v_final       INT;
  v_mode        TEXT;
  v_category    TEXT;
  v_base_pop    INT;
  v_max_change  NUMERIC := 0.20;
BEGIN
  SELECT v.mode, v.category INTO v_mode, v_category
  FROM public.venues v WHERE v.id = p_venue_id;

  SELECT vpc.fake_weight, vpc.base_popularity, vpc.last_display_count
  INTO v_weight, v_base_pop, v_last_display
  FROM public.venue_presence_config vpc
  WHERE vpc.venue_id = p_venue_id;

  IF v_weight IS NULL THEN v_weight := 1.0; END IF;
  IF v_base_pop IS NULL THEN v_base_pop := 15; END IF;
  IF v_last_display IS NULL THEN v_last_display := 0; END IF;

  -- Compter les presences reelles actives
  SELECT COUNT(*) INTO v_real_count
  FROM public.venue_presence vp
  WHERE vp.venue_id = p_venue_id AND vp.expires_at > NOW();

  -- Generer le fake count
  v_fake_count := public.generate_fake_count(v_mode, v_category, v_base_pop);

  -- Formule hybride
  v_raw_display := v_real_count + ROUND(v_fake_count * v_weight)::INT;

  -- Lissage : variation max +-20% par cycle
  IF v_last_display > 0 THEN
    v_final := LEAST(
      GREATEST(v_raw_display, ROUND(v_last_display * (1.0 - v_max_change))::INT),
      ROUND(v_last_display * (1.0 + v_max_change))::INT
    );
  ELSE
    v_final := v_raw_display;
  END IF;

  -- Plancher : jamais < 2
  v_final := GREATEST(2, v_final);

  RETURN v_final;
END;
$$;

-- ============================================================
-- 6. Refresh global (appele par pg_cron toutes les 7 min)
-- ============================================================
CREATE OR REPLACE FUNCTION public.refresh_all_display_counts()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  rec RECORD;
  v_display    INT;
  v_real_count INT;
BEGIN
  FOR rec IN
    SELECT vpc.venue_id, vpc.fake_weight, vpc.consecutive_real_cycles
    FROM public.venue_presence_config vpc
    JOIN public.venues v ON v.id = vpc.venue_id
    WHERE v.is_active = TRUE
  LOOP
    -- Calculer le display_count
    v_display := public.compute_display_count(rec.venue_id);

    -- Compter les presences reelles
    SELECT COUNT(*) INTO v_real_count
    FROM public.venue_presence
    WHERE venue_id = rec.venue_id AND expires_at > NOW();

    -- Mettre a jour la config + transition du weight (ratchet)
    UPDATE public.venue_presence_config SET
      last_display_count = v_display,
      last_real_count = v_real_count,
      consecutive_real_cycles = CASE
        WHEN v_real_count > 3 THEN consecutive_real_cycles + 1
        ELSE 0
      END,
      fake_weight = CASE
        WHEN v_real_count > 30 AND consecutive_real_cycles >= 3 THEN 0.00
        WHEN v_real_count > 20 AND consecutive_real_cycles >= 3 THEN LEAST(fake_weight, 0.20)
        WHEN v_real_count > 10 AND consecutive_real_cycles >= 3 THEN LEAST(fake_weight, 0.50)
        WHEN v_real_count > 3  AND consecutive_real_cycles >= 3 THEN LEAST(fake_weight, 0.80)
        ELSE fake_weight
      END,
      transition_status = CASE
        WHEN v_real_count > 30 AND consecutive_real_cycles >= 3 THEN 'real'
        WHEN fake_weight < 1.0 THEN 'blending'
        ELSE 'fake'
      END,
      updated_at = NOW()
    WHERE venue_id = rec.venue_id;

    -- Ecrire le display_count directement dans venues
    UPDATE public.venues SET display_count = v_display WHERE id = rec.venue_id;
  END LOOP;

  -- Nettoyer les presences expirees depuis +24h
  DELETE FROM public.venue_presence WHERE expires_at < NOW() - INTERVAL '24 hours';
END;
$$;

-- ============================================================
-- 7. pg_cron : refresh toutes les 7 minutes
-- ============================================================
SELECT cron.schedule(
  'refresh-venue-display-counts',
  '*/7 * * * *',
  $$SELECT public.refresh_all_display_counts()$$
);

-- ============================================================
-- 8. Vues monitoring
-- ============================================================
CREATE OR REPLACE VIEW public.v_presence_monitoring AS
SELECT
  transition_status,
  COUNT(*) AS nb_venues,
  AVG(fake_weight)::NUMERIC(3,2) AS avg_weight,
  AVG(last_real_count)::INT AS avg_real_count,
  AVG(last_display_count)::INT AS avg_display_count
FROM public.venue_presence_config
GROUP BY transition_status;

CREATE OR REPLACE VIEW public.v_presence_anomalies AS
SELECT
  vpc.venue_id,
  v.name,
  v.mode,
  v.category,
  vpc.last_display_count,
  vpc.last_real_count,
  vpc.fake_weight,
  vpc.transition_status
FROM public.venue_presence_config vpc
JOIN public.venues v ON v.id = vpc.venue_id
WHERE vpc.last_display_count > 100
   OR (vpc.last_real_count > 50 AND vpc.fake_weight > 0.5)
ORDER BY vpc.last_display_count DESC;

-- ============================================================
-- 9. Seed initial : remplir display_count pour tous les lieux
-- ============================================================
SELECT public.refresh_all_display_counts();

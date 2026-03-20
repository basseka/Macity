-- Improved dedup: catches cross-source duplicates where names differ
-- (e.g., "MESSMER - 13HZ" vs "Messmer" for the same date).
-- Uses substring containment instead of exact normalized name match.

-- Replace the existing dedup function with an improved version.
CREATE OR REPLACE FUNCTION dedup_scraped_events() RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  deleted_count INT := 0;
  batch_deleted INT;
BEGIN
  -- Pass 1: exact normalized name + date_debut (fast, catches most dupes)
  WITH normalized AS (
    SELECT
      id,
      identifiant,
      source,
      regexp_replace(lower(nom_de_la_manifestation), '[^a-z0-9]', '', 'g') AS norm_name,
      date_debut,
      source_priority(source, identifiant) AS priority,
      (CASE WHEN descriptif_court IS NOT NULL AND descriptif_court != '' THEN 1 ELSE 0 END
       + CASE WHEN photo_url IS NOT NULL AND photo_url != '' THEN 1 ELSE 0 END
       + CASE WHEN lieu_nom IS NOT NULL AND lieu_nom != '' THEN 1 ELSE 0 END
       + CASE WHEN reservation_site_internet IS NOT NULL AND reservation_site_internet != '' THEN 1 ELSE 0 END
      ) AS completeness
    FROM scraped_events
    WHERE date_debut >= to_char(CURRENT_DATE, 'YYYY-MM-DD')
  ),
  ranked AS (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY norm_name, date_debut
        ORDER BY priority ASC, completeness DESC, id ASC
      ) AS rn
    FROM normalized
    WHERE norm_name != '' AND length(norm_name) >= 3
  ),
  to_delete AS (
    SELECT id FROM ranked WHERE rn > 1
  )
  DELETE FROM scraped_events WHERE id IN (SELECT id FROM to_delete);
  GET DIAGNOSTICS batch_deleted = ROW_COUNT;
  deleted_count := deleted_count + batch_deleted;

  -- Pass 2: substring containment — if a shorter name is fully contained
  -- in a longer name for the same date, they're likely the same event.
  -- Example: "messmer" is contained in "messmer13hz" for same date.
  WITH normalized AS (
    SELECT
      id,
      identifiant,
      source,
      regexp_replace(lower(nom_de_la_manifestation), '[^a-z0-9]', '', 'g') AS norm_name,
      date_debut,
      source_priority(source, identifiant) AS priority,
      (CASE WHEN descriptif_court IS NOT NULL AND descriptif_court != '' THEN 1 ELSE 0 END
       + CASE WHEN photo_url IS NOT NULL AND photo_url != '' THEN 1 ELSE 0 END
       + CASE WHEN lieu_nom IS NOT NULL AND lieu_nom != '' THEN 1 ELSE 0 END
       + CASE WHEN reservation_site_internet IS NOT NULL AND reservation_site_internet != '' THEN 1 ELSE 0 END
      ) AS completeness
    FROM scraped_events
    WHERE date_debut >= to_char(CURRENT_DATE, 'YYYY-MM-DD')
      AND regexp_replace(lower(nom_de_la_manifestation), '[^a-z0-9]', '', 'g') != ''
      AND length(regexp_replace(lower(nom_de_la_manifestation), '[^a-z0-9]', '', 'g')) >= 4
  ),
  pairs AS (
    -- Find pairs where shorter name is contained in longer name, same date
    SELECT
      a.id AS id_a, a.norm_name AS name_a, a.priority AS pri_a, a.completeness AS comp_a,
      b.id AS id_b, b.norm_name AS name_b, b.priority AS pri_b, b.completeness AS comp_b
    FROM normalized a
    JOIN normalized b
      ON a.date_debut = b.date_debut
      AND a.id < b.id
      AND a.norm_name != b.norm_name
      AND (
        -- shorter is contained in longer (min 4 chars to avoid false positives)
        (length(a.norm_name) >= 4 AND position(a.norm_name IN b.norm_name) > 0)
        OR
        (length(b.norm_name) >= 4 AND position(b.norm_name IN a.norm_name) > 0)
      )
  ),
  losers AS (
    -- For each pair, pick the one to delete (higher priority number = less important)
    SELECT CASE
      WHEN pri_a < pri_b THEN id_b  -- a has better source priority
      WHEN pri_b < pri_a THEN id_a  -- b has better source priority
      WHEN comp_a >= comp_b THEN id_b  -- same priority, a more complete
      ELSE id_a
    END AS loser_id
    FROM pairs
  )
  DELETE FROM scraped_events WHERE id IN (SELECT loser_id FROM losers);
  GET DIAGNOSTICS batch_deleted = ROW_COUNT;
  deleted_count := deleted_count + batch_deleted;

  RETURN deleted_count;
END;
$$;

-- Schedule dedup to run daily at 04:45 UTC (after scrapers finish at ~04:30)
SELECT cron.schedule(
  'dedup-scraped-events',
  '45 4 * * *',
  $$SELECT public.dedup_scraped_events()$$
);

-- Run now to clean existing duplicates
SELECT dedup_scraped_events();

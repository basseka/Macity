-- Fonction de dedup des scraped_events.
-- Quand deux events ont le meme nom normalise + meme date_debut,
-- on garde celui dont la source est un lieu d'accueil (theatre_*, bikini_*, etc.)
-- et on supprime les doublons generiques (day_concert, day_opera, day_other...).

-- Source priority: plus le score est bas, plus on garde.
CREATE OR REPLACE FUNCTION source_priority(src TEXT, ident TEXT) RETURNS INT
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    -- Lieu d'accueil direct = priorite max
    WHEN ident LIKE 'theatre_%'    THEN 0
    WHEN ident LIKE 'bikini_%'     THEN 0
    WHEN ident LIKE 'zenith_%'     THEN 0
    WHEN ident LIKE 'casino_%'     THEN 0
    WHEN ident LIKE 'rex_%'        THEN 0
    WHEN ident LIKE 'bascala_%'    THEN 0
    WHEN ident LIKE 'metronum_%'   THEN 0
    WHEN ident LIKE 'comdt_%'      THEN 0
    WHEN ident LIKE 'opera_tls_%'  THEN 0
    WHEN ident LIKE 'meett_%'      THEN 0
    WHEN ident LIKE 'cave_poesie_%' THEN 0
    WHEN ident LIKE 'filaplomb_%'  THEN 0
    WHEN src LIKE 'theatre_%'      THEN 0
    WHEN src LIKE 'guided_tours'   THEN 0
    -- Billetterie / aggregateur = second
    WHEN ident LIKE 'festik_%'     THEN 1
    WHEN ident LIKE 'sk_%'         THEN 1
    WHEN ident LIKE 'tm_%'         THEN 1
    WHEN ident LIKE 'eb_%'         THEN 1
    -- Source generique = dernier
    ELSE 2
  END
$$;

-- Fonction de nettoyage appelable manuellement ou via pg_cron
CREATE OR REPLACE FUNCTION dedup_scraped_events() RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  deleted_count INT;
BEGIN
  WITH normalized AS (
    SELECT
      id,
      identifiant,
      source,
      regexp_replace(lower(nom_de_la_manifestation), '[^a-z0-9]', '', 'g') AS norm_name,
      date_debut,
      source_priority(source, identifiant) AS priority,
      -- Prefer: more info (longer description, has photo, has lieu)
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
    WHERE norm_name != ''
  ),
  to_delete AS (
    SELECT id FROM ranked WHERE rn > 1
  )
  DELETE FROM scraped_events WHERE id IN (SELECT id FROM to_delete);

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- Executer le nettoyage initial
SELECT dedup_scraped_events();

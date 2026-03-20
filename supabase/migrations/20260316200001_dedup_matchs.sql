-- Dedup matchs: quand deux matchs ont les memes equipes (fuzzy) + meme date,
-- on garde celui avec la meilleure source.
-- Priorite: espn/lnr > manual > scraper

CREATE OR REPLACE FUNCTION dedup_matchs() RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  deleted_count INT;
BEGIN
  WITH normalized AS (
    SELECT
      id,
      sport,
      regexp_replace(lower(equipe_dom), '[^a-z0-9]', '', 'g') AS norm_dom,
      regexp_replace(lower(equipe_ext), '[^a-z0-9]', '', 'g') AS norm_ext,
      date,
      source,
      (CASE
        WHEN source IN ('espn-top14', 'lnr-prod2') THEN 0
        WHEN source = 'manual' THEN 1
        ELSE 2
      END) AS priority,
      (CASE WHEN logo_dom IS NOT NULL AND logo_dom != '' THEN 1 ELSE 0 END
       + CASE WHEN logo_ext IS NOT NULL AND logo_ext != '' THEN 1 ELSE 0 END
       + CASE WHEN lieu IS NOT NULL AND lieu != '' THEN 1 ELSE 0 END
       + CASE WHEN ville IS NOT NULL AND ville != '' THEN 1 ELSE 0 END
      ) AS completeness
    FROM matchs
    WHERE date >= to_char(CURRENT_DATE, 'YYYY-MM-DD')
  ),
  ranked AS (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY sport, norm_dom, norm_ext, date
        ORDER BY priority ASC, completeness DESC, id ASC
      ) AS rn
    FROM normalized
  ),
  to_delete AS (
    SELECT id FROM ranked WHERE rn > 1
  )
  DELETE FROM matchs WHERE id IN (SELECT id FROM to_delete);

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- Executer le nettoyage initial
SELECT dedup_matchs();

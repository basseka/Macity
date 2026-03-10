-- Fonction qui detecte le quartier a partir de l'adresse
CREATE OR REPLACE FUNCTION public.detect_quartier(addr TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  a TEXT := lower(addr);
BEGIN
  -- Centre-ville
  IF a ~ '(place du capitole|rue du taur|rue saint-rome|rue alsace|rue de metz|rue lafayette|rue bayard|allees jean jaures)'
    OR a LIKE '%capitole%' THEN RETURN 'Capitole';
  END IF;

  IF a ~ '(place saint-georges|rue des blanchers|rue pargaminières|rue saint-pierre|place saint-pierre)'
    OR a LIKE '%saint-georges%' OR a LIKE '%saint georges%' THEN RETURN 'Saint-Georges';
  END IF;

  IF a ~ '(place esquirol|rue de la pomme|rue des filatiers|rue jules chalande|rue des changes)'
    OR a LIKE '%esquirol%' THEN RETURN 'Esquirol';
  END IF;

  IF a ~ '(rue saint-etienne|place saint-etienne|rue fermat|rue ozenne|rue des arts)'
    OR a LIKE '%saint-etienne%' OR a LIKE '%saint etienne%' THEN RETURN 'Saint-Etienne';
  END IF;

  IF a ~ '(place des carmes|rue des filatiers|rue mage|rue du may|rue maurice fonvieille|rue de la garonnette|rue pharaon|rue des marchands)'
    OR a LIKE '%carmes%' THEN RETURN 'Carmes';
  END IF;

  -- Quartiers autour du centre
  IF a ~ '(saint-cyprien|place roguet|rue de la republique|avenue etienne billieres|rue du pont saint-pierre)'
    OR a LIKE '%saint-cyprien%' OR a LIKE '%saint cyprien%' THEN RETURN 'Saint-Cyprien';
  END IF;

  IF a ~ '(compans|caffarelli|boulevard lascrosses|rue bayard|allee de barcelone)'
    OR a LIKE '%compans%' OR a LIKE '%caffarelli%' THEN RETURN 'Compans-Caffarelli';
  END IF;

  IF a ~ '(francois.verdier|boulevard carnot|allees forain francois verdier)'
    OR a LIKE '%francois-verdier%' OR a LIKE '%francois verdier%' THEN RETURN 'Francois-Verdier';
  END IF;

  IF a ~ '(gare matabiau|boulevard de la gare|rue de bayard|pierre semard)'
    OR a LIKE '%matabiau%' THEN RETURN 'Matabiau';
  END IF;

  -- Quartiers residentiels
  IF a LIKE '%cote pavee%' OR a LIKE '%côte pavée%' OR a ~ '(chemin des cotes de pech david)'
    THEN RETURN 'Cote Pavee';
  END IF;

  IF a LIKE '%lardenne%' THEN RETURN 'Lardenne'; END IF;

  IF a LIKE '%rangueil%' OR a LIKE '%route de narbonne%' THEN RETURN 'Rangueil'; END IF;

  IF a LIKE '%minimes%' OR a LIKE '%avenue des minimes%' THEN RETURN 'Minimes'; END IF;

  -- Quartiers peripheriques
  IF a LIKE '%empalot%' THEN RETURN 'Empalot'; END IF;
  IF a LIKE '%bagatelle%' THEN RETURN 'Bagatelle'; END IF;
  IF a LIKE '%mirail%' OR a LIKE '%reynerie%' THEN RETURN 'Mirail'; END IF;

  -- Par defaut : vide (a remplir manuellement)
  RETURN '';
END;
$$;

-- Trigger qui auto-detecte le quartier a l'insertion/update si quartier est vide
CREATE OR REPLACE FUNCTION public.auto_quartier_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.quartier = '' AND NEW.adresse <> '' AND NEW.rubrique = 'food' THEN
    NEW.quartier := detect_quartier(NEW.adresse);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_quartier ON public.etablissements;
CREATE TRIGGER trg_auto_quartier
  BEFORE INSERT OR UPDATE ON public.etablissements
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_quartier_trigger();

-- Mettre a jour les restaurants existants qui n'ont pas de quartier
UPDATE public.etablissements
SET quartier = detect_quartier(adresse)
WHERE rubrique = 'food' AND quartier = '' AND adresse <> '';

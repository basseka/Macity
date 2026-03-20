-- Desactiver les sous-categories de "Visiter" dans tourisme
-- (City tour, Tuk-tuk, Petit Train, La maison de la violette, Le Canal)
UPDATE categories
SET is_active = false
WHERE mode = 'tourisme'
  AND groupe = 'Visiter'
  AND groupe_ordre = 4;

-- Ajouter une colonne ville a la table groups pour filtrer par ville
ALTER TABLE groups ADD COLUMN IF NOT EXISTS ville TEXT NOT NULL DEFAULT 'Toulouse';

-- Index pour filtrer par ville
CREATE INDEX IF NOT EXISTS idx_groups_ville ON groups (ville) WHERE is_visible = TRUE;

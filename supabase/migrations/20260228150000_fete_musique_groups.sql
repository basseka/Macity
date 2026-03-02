-- ============================================================
-- Fête de la Musique 2026 — Toulouse
-- 200 groupes fictifs répartis dans 20 quartiers (10 styles)
-- 15 premiers visibles (is_visible = TRUE)
-- ============================================================

CREATE TABLE IF NOT EXISTS groups (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name       TEXT NOT NULL,
  music_style TEXT NOT NULL,
  address    TEXT NOT NULL,
  latitude   DOUBLE PRECISION NOT NULL,
  longitude  DOUBLE PRECISION NOT NULL,
  is_visible BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index partiel pour les groupes visibles
CREATE INDEX idx_groups_visible ON groups (id) WHERE is_visible = TRUE;

-- RLS : lecture seule pour anon
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access"
  ON groups
  FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- INSERT 200 groupes
-- Quartiers 1-15 : premier groupe visible (is_visible = TRUE)
-- Quartiers 16-20 : tous cachés
-- Styles distribués : chaque quartier a 10 groupes, 1 par style
-- ============================================================

INSERT INTO groups (name, music_style, address, latitude, longitude, is_visible) VALUES
-- ── Quartier 1 : Capitole ──
('Les Volcans',              'Rock',               'Place du Capitole',            43.6045, 1.4440, TRUE),
('Velours Bleu',             'Jazz',               'Rue Saint-Rome 12',            43.6038, 1.4435, FALSE),
('Synthwave 31',             'Electro',            'Rue du Taur 8',                43.6060, 1.4438, FALSE),
('MC Garonne',               'Hip-Hop',            'Rue Peyrolières 22',           43.6042, 1.4420, FALSE),
('Ensemble Garonne',         'Classique',          'Rue Gambetta 5',               43.6050, 1.4445, FALSE),
('Positive Vibration',       'Reggae',             'Rue de la Pomme 18',           43.6048, 1.4455, FALSE),
('Les Troubadours Modernes', 'Chanson Française',  'Rue d''Alsace-Lorraine 30',    43.6035, 1.4442, FALSE),
('Tolosa Mundo',             'World Music',        'Rue des Changes 6',            43.6040, 1.4430, FALSE),
('Forge Noire',              'Metal',              'Rue Lafayette 14',             43.6055, 1.4450, FALSE),
('Mississippi Occitan',      'Blues',              'Rue Bayard 9',                 43.6052, 1.4460, FALSE),

-- ── Quartier 2 : Saint-Cyprien ──
('Fracture',                 'Rock',               'Allée Charles de Fitte 15',    43.5995, 1.4325, FALSE),
('Trio Indigo',              'Jazz',               'Avenue Étienne Billières 42',  43.5988, 1.4310, TRUE),
('Pixel Noir',               'Electro',            'Rue de la République 7',       43.5992, 1.4335, FALSE),
('Rimeur du Sud',            'Hip-Hop',            'Rue du Pont Saint-Pierre 3',   43.5998, 1.4340, FALSE),
('Quatuor Occitan',          'Classique',          'Rue Réclusane 11',             43.5985, 1.4315, FALSE),
('Roots Occitan',            'Reggae',             'Place Intérieure Saint-Cyprien', 43.5990, 1.4320, FALSE),
('Mélodie Urbaine',          'Chanson Française',  'Rue de Cugnaux 28',            43.5982, 1.4305, FALSE),
('Garonne World',            'World Music',        'Avenue de Muret 55',            43.5978, 1.4300, FALSE),
('Acier Occitan',            'Metal',              'Rue Paul Vidal 16',             43.5996, 1.4330, FALSE),
('Les Lamenteurs',           'Blues',              'Rue du Férétra 4',              43.5984, 1.4318, FALSE),

-- ── Quartier 3 : Les Carmes ──
('Gravier Noir',             'Rock',               'Rue des Filatiers 20',         43.5998, 1.4428, FALSE),
('Café Crème Quartet',       'Jazz',               'Place des Carmes 3',           43.5992, 1.4435, FALSE),
('Fréquence Rose',           'Electro',            'Rue des Polinaires 8',         43.5995, 1.4425, TRUE),
('Flowmatic',                'Hip-Hop',            'Rue Pharaon 15',               43.6000, 1.4440, FALSE),
('Cordes Sensibles',         'Classique',          'Rue Ozenne 12',                43.5988, 1.4438, FALSE),
('Soleil Vert',              'Reggae',             'Rue des Couteliers 6',         43.5996, 1.4442, FALSE),
('Chanson d''Ici',           'Chanson Française',  'Rue Merlane 9',                43.5990, 1.4420, FALSE),
('Les Nomades Sonores',      'World Music',        'Rue du Languedoc 22',          43.5985, 1.4432, FALSE),
('Marteau Sombre',           'Metal',              'Rue Perchepinte 11',           43.5994, 1.4445, FALSE),
('Guitare Rouillée',         'Blues',              'Rue des Gestes 7',             43.5999, 1.4418, FALSE),

-- ── Quartier 4 : Saint-Étienne ──
('Ciel d''Orage',            'Rock',               'Place Saint-Étienne 1',        43.5960, 1.4500, FALSE),
('Les Noctambules',          'Jazz',               'Rue Croix-Baragnon 18',        43.5965, 1.4495, FALSE),
('Nébuleuse',                'Electro',            'Rue Fermat 10',                43.5958, 1.4505, FALSE),
('Les Chroniqueurs',         'Hip-Hop',            'Rue des Arts 25',              43.5962, 1.4510, TRUE),
('Les Harmonistes',          'Classique',          'Rue Ninau 8',                  43.5955, 1.4498, FALSE),
('One Drop Toulouse',        'Reggae',             'Rue de la Dalbade 14',         43.5968, 1.4488, FALSE),
('Les Balladins',            'Chanson Française',  'Rue Mage 6',                   43.5952, 1.4502, FALSE),
('Fusion Méditerranée',      'World Music',        'Rue du Vieux Raisin 11',       43.5970, 1.4492, FALSE),
('Les Titans',               'Metal',              'Rue Tolosane 3',               43.5956, 1.4508, FALSE),
('Café Blues',                'Blues',              'Rue Boulbonne 19',             43.5963, 1.4485, FALSE),

-- ── Quartier 5 : Arnaud-Bernard ──
('Les Insoumis',             'Rock',               'Rue du Périgord 30',           43.6092, 1.4425, FALSE),
('Swing Occitan',            'Jazz',               'Place Arnaud-Bernard 2',       43.6088, 1.4435, FALSE),
('Circuit Fermé',            'Electro',            'Rue des Trois Renards 5',      43.6095, 1.4428, FALSE),
('Bitume Rose',              'Hip-Hop',            'Boulevard d''Arcole 18',       43.6085, 1.4440, FALSE),
('Orchestre de Poche',       'Classique',          'Rue Gatien Arnoult 9',         43.6090, 1.4420, TRUE),
('Bass Culture',             'Reggae',             'Rue Bellegarde 14',            43.6098, 1.4432, FALSE),
('Plume et Voix',            'Chanson Française',  'Rue Valade 7',                 43.6082, 1.4438, FALSE),
('Rythmes du Monde',         'World Music',        'Rue des Lois 21',              43.6094, 1.4445, FALSE),
('Grondement',               'Metal',              'Rue du Coq d''Inde 4',         43.6087, 1.4415, FALSE),
('Bourbon Street Toulouse',  'Blues',              'Rue Gramat 12',                43.6096, 1.4442, FALSE),

-- ── Quartier 6 : Compans-Caffarelli ──
('Béton Armé',               'Rock',               'Boulevard Compans-Caffarelli 8', 43.6125, 1.4348, FALSE),
('Brise du Soir',            'Jazz',               'Boulevard Lascrosses 22',      43.6118, 1.4355, FALSE),
('Modulaire',                'Electro',            'Rue Roquelaine 15',            43.6122, 1.4340, FALSE),
('Prose Urbaine',            'Hip-Hop',            'Rue de Belfort 6',             43.6115, 1.4360, FALSE),
('Solistes du Capitole',     'Classique',          'Rue du Rempart Villeneuve 10', 43.6128, 1.4345, FALSE),
('Dubwise 31',               'Reggae',             'Rue d''Aubuisson 19',          43.6120, 1.4338, TRUE),
('Rue des Mots',             'Chanson Française',  'Rue Rivals 4',                 43.6112, 1.4352, FALSE),
('Carrefour Musical',        'World Music',        'Allée de Barcelone 12',        43.6130, 1.4365, FALSE),
('Tornade Noire',            'Metal',              'Rue Matabiau 28',              43.6116, 1.4358, FALSE),
('Blues du Midi',             'Blues',              'Canal du Midi Écluse 5',       43.6124, 1.4342, FALSE),

-- ── Quartier 7 : Jean-Jaurès ──
('Onde de Choc',             'Rock',               'Place Jean-Jaurès 1',          43.6048, 1.4508, FALSE),
('Doux Reflet',              'Jazz',               'Allée Jean Jaurès 35',         43.6052, 1.4515, FALSE),
('808 Toulouse',             'Electro',            'Rue de Metz 14',               43.6045, 1.4502, FALSE),
('Micro Ouvert',             'Hip-Hop',            'Rue de Rémusat 8',             43.6055, 1.4520, FALSE),
('Trio Bel Canto',           'Classique',          'Boulevard Lazare Carnot 20',   43.6042, 1.4512, FALSE),
('Lion du Sud',              'Reggae',             'Rue Héliot 6',                 43.6058, 1.4505, FALSE),
('Café Chanson',             'Chanson Française',  'Rue des Marchands 11',         43.6050, 1.4498, TRUE),
('Babel Son',                'World Music',        'Square Charles de Gaulle 3',   43.6038, 1.4518, FALSE),
('Abîme',                    'Metal',              'Rue du Rempart Saint-Étienne 9', 43.6040, 1.4525, FALSE),
('Les Mélancoliques',        'Blues',              'Boulevard Lazare Carnot 40',   43.6046, 1.4495, FALSE),

-- ── Quartier 8 : Matabiau ──
('Les Météores',             'Rock',               'Boulevard de Bonrepos 15',     43.6112, 1.4538, FALSE),
('Les Éclairés',             'Jazz',               'Rue de Tivoli 8',              43.6108, 1.4545, FALSE),
('Digital Sunset',           'Electro',            'Avenue de Lyon 22',            43.6115, 1.4550, FALSE),
('Les Architectes du Son',   'Hip-Hop',            'Rue du Faubourg Bonnefoy 30',  43.6105, 1.4535, FALSE),
('Les Virtuoses',            'Classique',          'Place Jeanne d''Arc 2',        43.6118, 1.4542, FALSE),
('Reggae Pastel',            'Reggae',             'Allée de Barcelone 25',        43.6102, 1.4548, FALSE),
('Voix du Midi',             'Chanson Française',  'Rue de la Colombette 18',      43.6110, 1.4530, FALSE),
('Les Voyageurs',            'World Music',        'Boulevard de Bonrepos 40',     43.6120, 1.4555, TRUE),
('Fer Brûlant',              'Metal',              'Rue Matabiau 45',              43.6106, 1.4540, FALSE),
('Corde Usée',               'Blues',              'Canal du Midi Quai 8',         43.6114, 1.4558, FALSE),

-- ── Quartier 9 : Minimes ──
('Acier Trempé',             'Rock',               'Avenue des Minimes 20',        43.6192, 1.4508, FALSE),
('Nuance',                   'Jazz',               'Rue des Fontaines 12',         43.6188, 1.4515, FALSE),
('Ondes Parallèles',         'Electro',            'Place du Marché aux Cochons 4', 43.6195, 1.4505, FALSE),
('Phrasé Libre',             'Hip-Hop',            'Rue Léon Jouhaux 8',           43.6185, 1.4520, FALSE),
('Camerata Rosa',            'Classique',          'Boulevard de la Marquette 15', 43.6198, 1.4512, FALSE),
('Irie Vibes',               'Reggae',             'Avenue Honoré Serres 30',      43.6182, 1.4498, FALSE),
('Les Rimeurs',              'Chanson Française',  'Rue Paul Mériel 6',            43.6190, 1.4525, FALSE),
('Terra Musica',             'World Music',        'Rue des Fontaines 35',         43.6186, 1.4502, FALSE),
('Les Forgerons',            'Metal',              'Route de Launaguet 12',        43.6200, 1.4518, TRUE),
('Plainte du Sud',           'Blues',              'Chemin de la Flambère 5',      43.6194, 1.4528, FALSE),

-- ── Quartier 10 : Rangueil ──
('Lame de Fond',             'Rock',               'Avenue de Rangueil 55',        43.5702, 1.4598, FALSE),
('Satin Doré',               'Jazz',               'Route de Narbonne 120',        43.5695, 1.4605, FALSE),
('VoltFace',                 'Electro',            'Allée Émile Monso 8',          43.5708, 1.4592, FALSE),
('Verbe Haut',               'Hip-Hop',            'Chemin des Étroits 3',         43.5698, 1.4610, FALSE),
('Ensemble Corelli',         'Classique',          'Rue des 36 Ponts 18',          43.5710, 1.4588, FALSE),
('Kingston-sur-Garonne',     'Reggae',             'Avenue Jules Julien 40',       43.5692, 1.4602, FALSE),
('Les Chansonniers',         'Chanson Française',  'Chemin du Vallon 7',           43.5705, 1.4615, FALSE),
('Couleurs du Monde',        'World Music',        'Avenue de la Gloire 12',       43.5688, 1.4595, FALSE),
('Enclume',                  'Metal',              'Route de Narbonne 150',        43.5712, 1.4608, FALSE),
('Vieux Blues',               'Blues',              'Impasse de la Lune 2',         43.5700, 1.4618, TRUE),

-- ── Quartier 11 : Saint-Michel ──
('Les Incandescents',        'Rock',               'Grande Rue Saint-Michel 45',   43.5902, 1.4458, TRUE),
('Quatuor Garonne',          'Jazz',               'Allée Jules Guesde 20',        43.5898, 1.4465, FALSE),
('Pulsation',                'Electro',            'Rue du Japon 8',               43.5905, 1.4452, FALSE),
('Capitale Occitane Crew',   'Hip-Hop',            'Place Saint-Michel 1',         43.5895, 1.4470, FALSE),
('Quatuor Pastel',           'Classique',          'Port Saint-Sauveur 6',         43.5908, 1.4448, FALSE),
('Jah Toulouse',             'Reggae',             'Rue Deville 14',               43.5892, 1.4462, FALSE),
('Guitare et Plume',         'Chanson Française',  'Boulevard Déodat de Séverac 8', 43.5910, 1.4475, FALSE),
('Ailleurs Ici',             'World Music',        'Rue Raymond IV 22',            43.5888, 1.4455, FALSE),
('Ombre d''Acier',           'Metal',              'Chemin de la Loge 5',          43.5904, 1.4442, FALSE),
('Harmonica Rose',           'Blues',              'Grande Rue Saint-Michel 78',   43.5896, 1.4468, FALSE),

-- ── Quartier 12 : Saint-Aubin ──
('Éclair Noir',              'Rock',               'Place Saint-Aubin 3',          43.6012, 1.4548, FALSE),
('L''Heure Bleue',           'Jazz',               'Rue de la Colombette 30',      43.6008, 1.4555, TRUE),
('Laser Violet',             'Electro',            'Rue Riquet 15',                43.6015, 1.4542, FALSE),
('MC Briques',               'Hip-Hop',            'Rue des Potiers 8',            43.6005, 1.4560, FALSE),
('Sonate Occitane',          'Classique',          'Rue Caffarelli 12',            43.6018, 1.4538, FALSE),
('Roots Garden',             'Reggae',             'Rue Montaudran 6',             43.6002, 1.4552, FALSE),
('Mots Chantés',             'Chanson Française',  'Place Dupuy 4',                43.6010, 1.4565, FALSE),
('Métissage',                'World Music',        'Rue de la Colombette 55',      43.6020, 1.4545, FALSE),
('Fonte Noire',              'Metal',              'Rue Saint-Aubin 20',           43.6006, 1.4558, FALSE),
('Blues Garonne',             'Blues',              'Rue Riquet 32',                43.6014, 1.4535, FALSE),

-- ── Quartier 13 : Patte-d'Oie ──
('Tonnerre',                 'Rock',               'Place de la Patte d''Oie 1',   43.5952, 1.4228, FALSE),
('Éclipse Jazz',             'Jazz',               'Route de Saint-Simon 15',      43.5948, 1.4235, FALSE),
('Bitstream',                'Electro',            'Avenue de Lombez 22',          43.5955, 1.4222, TRUE),
('Flow Pastelier',           'Hip-Hop',            'Rue de la Passerelle 8',       43.5945, 1.4240, FALSE),
('Les Mélodistes',           'Classique',          'Boulevard Déodat de Séverac 30', 43.5958, 1.4218, FALSE),
('Basse Fréquence',          'Reggae',             'Rue du Férétra 18',            43.5942, 1.4232, FALSE),
('Poésie Sonore',            'Chanson Française',  'Avenue de Lombez 45',          43.5960, 1.4245, FALSE),
('Globe Trotter Band',       'World Music',        'Rue de Cugnaux 60',            43.5938, 1.4225, FALSE),
('Tempête Sombre',           'Metal',              'Route de Saint-Simon 40',      43.5950, 1.4215, FALSE),
('Slide Guitar Quartet',     'Blues',              'Place de la Patte d''Oie 6',   43.5946, 1.4238, FALSE),

-- ── Quartier 14 : Purpan ──
('Les Rebelles',             'Rock',               'Avenue de Grande-Bretagne 20', 43.6052, 1.4098, FALSE),
('Nocturne',                 'Jazz',               'Rue de Purpan 12',             43.6048, 1.4105, FALSE),
('Électron Libre',           'Electro',            'Chemin de Nicol 8',            43.6055, 1.4092, FALSE),
('Rime Occitane',            'Hip-Hop',            'Avenue de Casselardit 15',     43.6045, 1.4110, TRUE),
('Arco Vivo',                'Classique',          'Place de l''Ormeau 3',         43.6058, 1.4088, FALSE),
('Vibration Solaire',        'Reggae',             'Rue de Purpan 30',             43.6042, 1.4102, FALSE),
('La Complainte',            'Chanson Française',  'Chemin de la Terrasse 6',      43.6060, 1.4115, FALSE),
('Passeport Musical',        'World Music',        'Avenue de Grande-Bretagne 45', 43.6038, 1.4095, FALSE),
('Rouille',                  'Metal',              'Impasse des Arènes 2',         43.6050, 1.4082, FALSE),
('Whiskey Blues',             'Blues',              'Chemin de Nicol 22',           43.6056, 1.4108, FALSE),

-- ── Quartier 15 : Bonnefoy ──
('Roche Mère',               'Rock',               'Rue du Faubourg Bonnefoy 55',  43.6152, 1.4598, FALSE),
('Jazz Pastel',              'Jazz',               'Rue de Périole 18',            43.6148, 1.4605, FALSE),
('Signal Faible',            'Electro',            'Rue Achille Viadieu 10',       43.6155, 1.4592, FALSE),
('Mots de Passe',            'Hip-Hop',            'Place Dupuy 8',                43.6145, 1.4610, FALSE),
('Allegro Toulouse',         'Classique',          'Rue du Faubourg Bonnefoy 80',  43.6158, 1.4588, TRUE),
('Riddim Occitan',           'Reggae',             'Rue Bonnefoy 12',              43.6142, 1.4602, FALSE),
('Ballade Occitane',         'Chanson Française',  'Rue de Périole 35',            43.6160, 1.4615, FALSE),
('Écho du Monde',            'World Music',        'Avenue de Lyon 50',            43.6138, 1.4595, FALSE),
('Mâchoire d''Acier',        'Metal',              'Rue Bonnefoy 28',              43.6150, 1.4608, FALSE),
('Cri du Cœur',              'Blues',              'Rue Achille Viadieu 25',       43.6156, 1.4585, FALSE),

-- ── Quartier 16 : Croix-Daurade (tous cachés) ──
('Les Intempéries',          'Rock',               'Route d''Albi 25',             43.6302, 1.4548, FALSE),
('Quatuor Lunaire',          'Jazz',               'Chemin de Croix-Daurade 10',   43.6298, 1.4555, FALSE),
('Synthé Urbain',            'Electro',            'Rue de Borderouge 18',         43.6305, 1.4542, FALSE),
('Les Versificateurs',       'Hip-Hop',            'Route d''Albi 50',             43.6295, 1.4560, FALSE),
('Classique en Ville',       'Classique',          'Impasse des Music 3',          43.6308, 1.4538, FALSE),
('Reggae Rouge',             'Reggae',             'Chemin de Croix-Daurade 30',   43.6292, 1.4552, FALSE),
('Les Diseurs',              'Chanson Française',  'Rue du Barry 8',               43.6310, 1.4565, FALSE),
('Saveurs Sonores',          'World Music',        'Route d''Albi 75',             43.6288, 1.4545, FALSE),
('Les Colossaux',            'Metal',              'Chemin de Lanusse 5',          43.6304, 1.4558, FALSE),
('Les Désenchantés',         'Blues',              'Rue de Borderouge 35',         43.6296, 1.4535, FALSE),

-- ── Quartier 17 : Les Chalets (tous cachés) ──
('Granit',                   'Rock',               'Rue des Chalets 15',           43.6102, 1.4468, FALSE),
('Coulée Douce',             'Jazz',               'Rue de Belfort 20',            43.6098, 1.4475, FALSE),
('Boucle Infinie',           'Electro',            'Rue du Rempart Saint-Étienne 25', 43.6105, 1.4462, FALSE),
('MC Tolosa',                'Hip-Hop',            'Rue des Chalets 35',           43.6095, 1.4480, FALSE),
('Les Romantiques',          'Classique',          'Rue Rivals 18',                43.6108, 1.4458, FALSE),
('Zion Garden',              'Reggae',             'Rue de Belfort 40',            43.6092, 1.4472, FALSE),
('Chanson Rose',             'Chanson Française',  'Rue d''Aubuisson 25',          43.6110, 1.4485, FALSE),
('Continents',               'World Music',        'Rue des Chalets 55',           43.6088, 1.4465, FALSE),
('Les Brutaux',              'Metal',              'Rue du Rempart Villeneuve 20', 43.6104, 1.4452, FALSE),
('Les Bluesmen du Sud',      'Blues',              'Rue Rivals 30',                43.6096, 1.4478, FALSE),

-- ── Quartier 18 : Côte Pavée (tous cachés) ──
('Séisme',                   'Rock',               'Avenue de la Côte Pavée 20',   43.5902, 1.4698, FALSE),
('Les Harmoniques',          'Jazz',               'Rue Louis Plana 12',           43.5898, 1.4705, FALSE),
('Néon Bleu',                'Electro',            'Chemin des Côtes de Pech David 8', 43.5905, 1.4692, FALSE),
('Parole Donnée',            'Hip-Hop',            'Rue Deodat de Séverac 15',     43.5895, 1.4710, FALSE),
('Orchestre Miniature',      'Classique',          'Avenue de la Côte Pavée 45',   43.5908, 1.4688, FALSE),
('Soleil Levant',            'Reggae',             'Rue Louis Plana 30',           43.5892, 1.4702, FALSE),
('Prose et Musique',         'Chanson Française',  'Chemin de la Terrase 10',      43.5910, 1.4715, FALSE),
('Monde Sonore',             'World Music',        'Avenue de la Côte Pavée 70',   43.5888, 1.4695, FALSE),
('Éclat Noir',               'Metal',              'Rue des Music 5',              43.5904, 1.4682, FALSE),
('Soul du Midi',             'Blues',              'Chemin des Côtes de Pech David 20', 43.5896, 1.4708, FALSE),

-- ── Quartier 19 : Lardenne (tous cachés) ──
('Les Éruptifs',             'Rock',               'Route de Lardenne 15',         43.6002, 1.3948, FALSE),
('Brume Jazz',               'Jazz',               'Chemin de Lardenne 8',         43.5998, 1.3955, FALSE),
('Fréquence 31',             'Electro',            'Rue de Lardenne 22',           43.6005, 1.3942, FALSE),
('Les Rimailleur',           'Hip-Hop',            'Route de Saint-Simon 55',      43.5995, 1.3960, FALSE),
('Tutti Quanti',             'Classique',          'Chemin de la Pradette 10',     43.6008, 1.3938, FALSE),
('Bass Pillar',              'Reggae',             'Route de Lardenne 40',         43.5992, 1.3952, FALSE),
('Les Mélomanes',            'Chanson Française',  'Rue du Village 6',             43.6010, 1.3965, FALSE),
('Diaspora Sound',           'World Music',        'Chemin de Lardenne 25',        43.5988, 1.3945, FALSE),
('Marteau Pilon',            'Metal',              'Route de Lardenne 60',         43.6004, 1.3932, FALSE),
('Delta Garonne',            'Blues',              'Chemin de la Pradette 20',     43.5996, 1.3958, FALSE),

-- ── Quartier 20 : Borderouge (tous cachés) ──
('Magma Rouge',              'Rock',               'Avenue de Borderouge 10',      43.6402, 1.4498, FALSE),
('L''Instant Jazz',          'Jazz',               'Place de Borderouge 2',        43.6398, 1.4505, FALSE),
('Oscillation',              'Electro',            'Rue Henri Desbals 15',         43.6405, 1.4492, FALSE),
('Flow Continu',             'Hip-Hop',            'Avenue de Borderouge 30',      43.6395, 1.4510, FALSE),
('Cantabile',                'Classique',          'Place de Borderouge 5',        43.6408, 1.4488, FALSE),
('One Love TLS',             'Reggae',             'Rue des Music 12',             43.6392, 1.4502, FALSE),
('Les Poètes du Pont Neuf',  'Chanson Française',  'Avenue de Borderouge 50',      43.6410, 1.4515, FALSE),
('Écho Lointain',            'World Music',        'Rue Henri Desbals 30',         43.6388, 1.4495, FALSE),
('Brasier',                  'Metal',              'Avenue de Borderouge 70',      43.6404, 1.4482, FALSE),
('Twelve Bar Toulouse',      'Blues',              'Place de Borderouge 8',        43.6396, 1.4508, FALSE);

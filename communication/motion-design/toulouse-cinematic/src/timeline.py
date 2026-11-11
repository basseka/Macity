"""Timeline du reel MaCity Toulouse, calée sur « Sexy Chick » (David Guetta feat. Akon).

Tempo : 130 BPM -> 1 temps = 0,4615 s, 1 mesure (4 temps) = 1,846 s.
La vidéo démarre sur le premier temps du refrain d'Akon et dure 22 mesures
(88 temps, 40,6 s). Toutes les positions ci-dessous sont en TEMPS (beats).

Structure :
  0-12   FOOD      (refrain : cuts tous les 1-2 temps)
  12-24  NIGHT     (cuts à chaque temps, flashs, stroboscope)
  24-32  FAMILLE   (ralentis, lumière chaude)
  32-44  CULTURE   (symétries, architecture)
  44-56  SPORT     (cuts secs, zooms d'impact)
  56-68  ÉVASION   (respiration : plans longs, fondus)
  68-76  FINAL     (montée : cuts qui accélèrent, lasers, convergence)
  76     EXPLOSION (onde de choc + logo)
  76-88  REVEAL    (logo, accroche, appel à télécharger)
"""
BPM = 130.0
BEAT = 60.0 / BPM
FPS = 30
TOTAL_BEATS = 88
W, H = 1080, 1920

# Couleurs par univers (charte MaCity, rubriques)
COL = {
    'food': (251, 146, 60), 'night': (168, 85, 247), 'famille': (255, 120, 150),
    'culture': (34, 211, 238), 'sport': (34, 197, 94), 'evasion': (255, 190, 90),
    'final': (255, 30, 142),
}

M = 'media/'
# Plans : (début, fin, univers, type, fichier, options)
# type img : zoom = (échelle début, échelle fin), pan = (dx, dy) en fraction de marge
# type vid : start (s dans la source), speed, layout 'full' ou 'window'
SHOTS = [
    # ---------- FOOD ----------
    (0, 4, 'food', 'vid', M + 'food/banner_food_ALL.mp4', dict(start=2.0, speed=0.8, layout='window')),
    (4, 6, 'food', 'img', M + 'food/food_avitar_2.jpg', dict(zoom=(1.18, 1.0))),
    (6, 7, 'food', 'img', M + 'food/food_kiyoshi_2.jpg', dict(zoom=(1.0, 1.1))),
    (7, 8, 'food', 'img', M + 'food/food_boniface-coquillages_1.jpg', dict(zoom=(1.12, 1.0))),
    (8, 9, 'food', 'img', M + 'food/food_susanoo_4.jpg', dict(zoom=(1.0, 1.12))),
    (9, 10, 'food', 'img', M + 'food/food_joshore-road_1.jpg', dict(zoom=(1.15, 1.02))),
    (10, 12, 'food', 'img', M + 'food/food_bouillon-labege_2.jpg', dict(zoom=(1.0, 1.25))),
    # ---------- NIGHT ----------
    (12, 14, 'night', 'vid', M + 'night/story_17a47a04_0.mp4', dict(start=0.5, speed=1.0)),
    (14, 15, 'night', 'img', M + 'night/nuit_hiboo-club_4.jpg', dict(zoom=(1.15, 1.0))),
    (15, 16, 'night', 'img', M + 'night/nuit_hiboo-club_1.jpg', dict(zoom=(1.0, 1.12))),
    (16, 18, 'night', 'vid', M + 'night/story_65fca498_0.mp4', dict(start=0.2, speed=1.0)),
    (18, 19, 'night', 'img', M + 'night/nuit_o-club-by-charleston_4.jpg', dict(zoom=(1.15, 1.0))),
    (19, 20, 'night', 'img', M + 'night/nuit_hiboo-club_3.jpg', dict(zoom=(1.0, 1.1))),
    (20, 21, 'night', 'vid', M + 'night/fake_2.mp4', dict(start=0.6, speed=1.0)),
    (21, 22, 'night', 'img', M + 'night/nuit_via-brazil_0.jpg', dict(zoom=(1.15, 1.0))),
    (22, 24, 'night', 'vid', M + 'night/story_8dd64470_0.mp4', dict(start=4.0, speed=1.0)),
    # ---------- FAMILLE ----------
    (24, 27, 'famille', 'vid', M + 'famille/banner_family.mp4', dict(start=0.8, speed=0.6, layout='window')),
    (27, 28.5, 'famille', 'vid', M + 'famille/story_8d557835_1.mp4', dict(start=1.5, speed=0.8)),
    (28.5, 30, 'famille', 'img', M + 'famille/famille_african-safari-zoo-de-plaisanc_0.jpg', dict(zoom=(1.0, 1.12), pan=(0.3, 0))),
    (30, 32, 'famille', 'vid', M + 'famille/story_ccd1af2b_0.mp4', dict(start=3.0, speed=0.8)),
    # ---------- CULTURE ----------
    (32, 34, 'culture', 'img', M + 'culture/capitole_nuit_3.jpg', dict(zoom=(1.0, 1.2))),
    (34, 35, 'culture', 'img', M + 'culture/jacobins_4.jpg', dict(zoom=(1.15, 1.0))),
    (35, 36, 'culture', 'vid', M + 'culture/banner_culture.mp4', dict(start=1.0, speed=1.0, layout='window')),
    (36, 37, 'culture', 'img', M + 'culture/cult_theatre_du_capit_0.jpg', dict(zoom=(1.0, 1.12))),
    (37, 38, 'culture', 'img', M + 'culture/jacobins_5.jpg', dict(zoom=(1.15, 1.0))),
    (38, 40, 'culture', 'img', M + 'culture/pontneuf_2.jpg', dict(zoom=(1.0, 1.1), pan=(-0.4, 0))),
    (40, 42, 'culture', 'img', M + 'culture/capitole_nuit_4.jpg', dict(zoom=(1.2, 1.0))),
    (42, 44, 'culture', 'img', M + 'culture/sernin_1.jpg', dict(zoom=(1.0, 1.3))),
    # ---------- SPORT ----------
    (44, 46, 'sport', 'img', M + 'sport/rugby_st_0.jpg', dict(zoom=(1.25, 1.05))),
    (46, 47, 'sport', 'img', M + 'sport/sport_clark_6.jpg', dict(zoom=(1.0, 1.12))),
    (47, 48, 'sport', 'img', M + 'sport/rugby_st_1.jpg', dict(zoom=(1.15, 1.0))),
    (48, 49, 'sport', 'img', M + 'sport/sport_clark_10.jpg', dict(zoom=(1.0, 1.12))),
    (49, 50, 'sport', 'vid', M + 'sport/banner_sport_ALL.mp4', dict(start=2.6, speed=1.0, layout='window')),
    (50, 51, 'sport', 'img', M + 'sport/sport_clark_8.jpg', dict(zoom=(1.15, 1.0))),
    (51, 52, 'sport', 'img', M + 'sport/wallon_4.jpg', dict(zoom=(1.0, 1.15))),
    (52, 53, 'sport', 'img', M + 'sport/sport_clark_13.jpg', dict(zoom=(1.15, 1.0))),
    (53, 54, 'sport', 'vid', M + 'sport/banner_sport.mp4', dict(start=19.0, speed=1.0)),
    (54, 56, 'sport', 'img', M + 'sport/stadium_tls_5.jpg', dict(zoom=(1.0, 1.2))),
    # ---------- ÉVASION ----------
    (56, 60, 'evasion', 'vid', M + 'evasion/banner_evasion.mp4', dict(start=0.0, speed=0.9)),
    (60, 62, 'evasion', 'img', M + 'evasion/gavarnie_1.jpg', dict(zoom=(1.0, 1.12), pan=(0.3, 0))),
    (62, 64, 'evasion', 'img', M + 'evasion/lac_oo_0.jpg', dict(zoom=(1.12, 1.0))),
    (64, 66, 'evasion', 'img', M + 'evasion/carcassonne_4.jpg', dict(zoom=(1.0, 1.1), pan=(-0.3, 0))),
    (66, 68, 'evasion', 'img', M + 'evasion/evasion_domaine-du-belvedere_1.jpg', dict(zoom=(1.0, 1.18))),
    # ---------- FINAL (montée) ----------
    (68, 70, 'final', 'vid', M + 'final/story_a955672a_0.mp4', dict(start=3.0, speed=1.0)),
    (70, 71, 'final', 'img', M + 'final/nuit_l-etoile-club_3.jpg', dict(zoom=(1.15, 1.0))),
    (71, 72, 'final', 'vid', M + 'final/story_5b71054a_0.mp4', dict(start=12.0, speed=1.0)),
    (72, 72.5, 'final', 'img', M + 'final/nuit_l-etoile-club_2.jpg', dict(zoom=(1.2, 1.1))),
    (72.5, 73, 'final', 'img', M + 'final/nuit_o-club-by-charleston_5.jpg', dict(zoom=(1.2, 1.1))),
    (73, 73.5, 'final', 'img', M + 'final/nuit_l-etoile-club_1.jpg', dict(zoom=(1.2, 1.1))),
    (73.5, 74, 'final', 'img', M + 'final/nuit_o-club-by-charleston_0.jpg', dict(zoom=(1.2, 1.1))),
    (74, 74.5, 'final', 'vid', M + 'final/story_47d98913_0.mp4', dict(start=6.0, speed=1.0)),
    (74.5, 75, 'final', 'img', M + 'final/nuit_l-etoile-club_5.jpg', dict(zoom=(1.3, 1.15))),
    (75, 75.25, 'final', 'img', M + 'final/nuit_l-etoile-club_6.jpg', dict(zoom=(1.4, 1.3))),
    (75.25, 75.5, 'final', 'img', M + 'final/nuit_l-etoile-club_0.jpg', dict(zoom=(1.5, 1.4))),
    (75.5, 76, 'final', 'img', M + 'final/nuit_l-etoile-club_3.jpg', dict(zoom=(1.6, 2.4))),
]

# Transitions à l'entrée de chaque univers (temps de la frontière -> type)
TRANS = {
    12: 'zoomthru',   # le cocktail nous aspire dans la nuit
    24: 'flash',      # flash blanc sur le temps, bascule Famille
    32: 'whip',       # quelqu'un traverse le cadre -> Culture
    44: 'spin',       # la nef de Saint-Sernin tourne -> Sport
    56: 'shock',      # impact -> le paysage s'ouvre
    68: 'leak',       # le coucher de soleil devient lumière de scène
    76: 'explode',    # onde de choc finale
}

# Libellés d'univers : (temps d'apparition, temps de fin, texte, index)
LABELS = [
    (4, 11.5, 'FOOD', 1), (12.5, 23.5, 'NIGHT', 2), (24.5, 31.5, 'FAMILLE', 3),
    (32.5, 43.5, 'CULTURE', 4), (44.25, 55.5, 'SPORT', 5), (57, 67.5, 'ÉVASION', 6),
]

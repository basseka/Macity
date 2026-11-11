# Reel MaCity Toulouse (cinématique)

Vidéo 1080x1920, 30 i/s, H.264, 40,6 s, **sans son** : elle est calée sur le tempo de
« Sexy Chick » (David Guetta feat. Akon), 130 BPM, à partir du refrain d'Akon.
La musique s'ajoute dans Instagram / TikTok (bibliothèque musicale), départ = 1er temps du refrain.

- `MACITY_Toulouse_Cinematic_Reel.mp4` : la vidéo à publier.
- `MACITY_Toulouse_apercu_metronome_130bpm.mp4` : même vidéo avec un clic sur chaque temps
  (aigu = début de mesure), pour vérifier le calage. Ne pas publier.

## Structure (en temps, 1 temps = 0,4615 s)
FOOD 0-12, NIGHT 12-24, FAMILLE 24-32, CULTURE 32-44, SPORT 44-56, ÉVASION 56-68,
montée finale 68-76, explosion + logo 76, accroche et bouton jusqu'à 88.

## Modifier
- `src/timeline.py` : plans (fichier, durée, zoom), transitions, libellés.
- `src/render.py` : effets, textes, final.
- Chaîne : `python src/prep.py` (extrait les vidéos), `python src/render.py` (images dans out/frames ;
  `python src/render.py 12 33.5` pour tester quelques instants), `python src/encode.py` (MP4).
  Dépendances : numpy, opencv-python-headless, pillow, ffmpeg. Effacer out/frames avant un rendu complet.

## Médias
`media/<univers>/` : photos des partenaires MaCity, vidéos des stories et bandeaux de l'app,
photos Wikimedia Commons (crédits obligatoires : voir CREDITS.txt), logo officiel dans `brand/`.

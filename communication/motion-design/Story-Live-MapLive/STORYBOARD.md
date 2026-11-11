# Reel « Story Live + Map Live » : convaincre les établissements

Fichier à publier : `MACITY_Story_Live_Map_Live_Reel.mp4` (1080 x 1920, 30 i/s, 26 s, H.264 + AAC, son 100 % synthétisé donc libre de droits).

Cible : gérants de bars, restos, clubs, lieux culturels. Message : les stories LIVE de leurs clients apparaissent en direct sur la Map Live, les jeunes du coin les voient et viennent.

## Direction artistique

- Palette de l'affiche Black Friday / charte MaCity : bleu nuit `#06041A`, magenta `#FF1E8E`, violet `#7C3AED`, blanc.
- Couleurs réelles de l'app reprises à l'identique : pin partenaire avec story `#C2185B`, badge LIVE `#FF2244`, pins catégories néon (`#F472B6`, `#FBBF24`, `#C77DFF`, `#22D3EE`, `#A855F7`), partenaires Premium/Gold vert `#16A34A`, Classique orange `#F97316`, fond carte `#F1EEE9`, bouton Publier dégradé `#7C3AED` vers `#EC4899`, snackbar `#7B2D8E`.
- Libellés réels de l'app : « Soirée », « Lieu », « GPS OK », « Publier », « Signalé ! L'affiche se prépare... », « LIVE », « Y aller », « Discuter », « Signalé par ».
- Typo Poppins ExtraBold inclinée, mots clés sur ruban magenta (comme l'affiche).

## Storyboard

| Temps | Plan | Contenu |
|---|---|---|
| 0 à 3 s | Accroche | « TON LIEU / EST-IL VISIBLE / CE SOIR ? » en 3 claques sur la carte de nuit |
| 3 à 5,4 s | Étape 1 | Téléphone violet : un client filme la soirée (appui long, anneau rouge, REC) |
| 5,5 à 7,1 s | Étape 1 | Écran de publication : catégorie « Soirée », Lieu, GPS OK, tap sur « Publier », snackbar, badge LIVE |
| 7,1 à 12 s | Étape 2 | Le téléphone plonge dans la carte et devient le pin rose « TON ÉTABLISSEMENT », la vraie story LIVE en aperçu au-dessus ; les autres vraies stories de la ville surgissent au-dessus de leurs pins |
| 12 à 15,7 s | Étape 3 | Les jeunes du coin apparaissent, chacun « voit » la story (œil), compteur de vues qui grimpe |
| 15,8 à 20 s | Étape 4 | Fiche story, tap sur « Y aller », tous convergent par les rues vers le lieu, « +1 » à chaque arrivée |
| 20,3 à 22,4 s | Rappel offre | Partenaires Premium ou Gold en vert sur la carte même sans story |
| 22,6 à 26 s | Fin | Logo, « Plus de stories = plus de visibilité = plus de clients », ruban « DEVIENS PARTENAIRE MACITY », renvoi vers l'Espace professionnel de l'app |

Zones sûres Instagram respectées : rien d'important dans les 400 px du bas.

## Vraies stories utilisées (2026-11-07)

- Source : bucket Storage `user-events` (fichiers `*_report.mp4` / `*_report.jpg`), 279 vidéos de stories réelles d'avril à novembre 2026.
- Écran du téléphone, aperçu LIVE au-dessus du lieu et fiche « Y aller » : vidéo `1790387277959_report.mp4` (concert, lumières violettes), extraite dans `src/assets/stories/hero/`.
- Mosaïque de l'accroche et aperçus au-dessus des autres pins : 24 vignettes réelles (club, concerts, bars, terrasses, restos, guinguette) dans `src/assets/stories/covers/`. Les images de manifestation et les visages en gros plan ont été écartés.
- Fidélité à l'app : la vraie Map Live n'affiche pas de photo dans ses pins, donc les photos apparaissent en aperçu au-dessus des pins, pas dedans.
- Version précédente (illustrations dessinées) : `src/live_v1_illustre.html`.

## Points d'honnêteté

- Le compteur « 1 284 vues », les avatars et « Signalé par Léa » sont illustratifs ; les images et la vidéo sont de vraies stories.
- Dans l'app, une story est rattachée à un partenaire si elle est publiée à moins de 80 m de lui (pas de lien manuel) : le champ « Lieu » rempli « Ton établissement » est une mise en scène.
- La durée de vie d'une story n'est pas affichée (valeur côté serveur non vérifiée).

## Modifier et refaire le rendu

```bash
cd communication/motion-design/Story-Live-MapLive
python3 src/audio_live.py                        # bande-son -> src/live_audio.wav
export PW=~/.npm/_npx/e41f203b7505f1fb/node_modules/playwright
WORKERS=3 node src/render.js /tmp/live_frames    # 780 images
node src/render.js /tmp/live_test 4.4 13.2 18.6  # tester quelques instants
ffmpeg -y -framerate 30 -i /tmp/live_frames/f%04d.jpg -i src/live_audio.wav \
  -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -c:a aac -b:a 256k \
  -shortest -movflags +faststart MACITY_Story_Live_Map_Live_Reel.mp4
```

- Timing : objet `T` en haut du script de `src/live.html` (le son est calé sur les mêmes valeurs dans `src/audio_live.py`).
- Effacer le dossier d'images avant un rendu complet (les images déjà présentes sont sautées).

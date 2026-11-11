# Pub « Ta ville bouge » (format 9:16, 28 s)

Vidéo : `MACITY_Pub_Ta_Ville_Bouge_9x16.mp4` (1080x1920, 30 i/s, H.264 + AAC).
Musique et bruitages 100 % synthétisés (`src/audio_pub.py`), donc libres de droits pour la pub.
Images : vidéos des stories et bandeaux de l'app, captures de l'app, logo officiel.

Tout le texte est à l'écran en sous-titres animés : la pub se comprend sans le son
(la plupart des vues Meta se font en muet).

| Temps | Scène | À l'écran |
|---|---|---|
| 0 - 2 s | Accroche | Capitole en noir et blanc, terne. « Tu crois qu'il ne se passe RIEN dans ta ville ce week-end ? » |
| 2 - 3,4 s | Suspense | Écran noir. « Eh bien… », montée sonore |
| 3,4 - 4,6 s | Drop | Flash, foule de concert. « tu risques d'être SURPRIS ! » |
| 4,6 - 8,2 s | Montage | 6 coupes sur le temps : CONCERTS, SPECTACLES, SOIRÉES, FESTIVALS, EXPOS, GRATUIT |
| 8,2 - 10,6 s | Abondance | Mosaïque de 6 vidéos, compteur jusqu'à « 99+ sorties ce week-end ». « Il se passe beaucoup plus de choses que tu ne l'imagines ! » |
| 10,6 - 13 s | Problème | 10 onglets de navigateur s'empilent, « ? », « 10 onglets ouverts… ». « Mais encore faut-il savoir où les trouver ! » |
| 13 - 17,6 s | Solution | Les onglets sont aspirés, le téléphone arrive avec l'app (accueil, Nuit, Food). Pin de géolocalisation et ondes radar. « Avec MaCity, découvre les événements autour de toi » |
| 17,6 - 19,9 s | Bénéfice | « 10 SITES » barré, icône MaCity « 1 seule appli ». « Plus besoin de chercher sur dix sites différents ! » |
| 19,9 - 22,4 s | Émotion | Fête de rue de nuit, pins MaCity qui tombent partout. « TOUTE TA VILLE BOUGE. Ne passe plus à côté ! » |
| 22,4 - 28 s | Appel à l'action | Logo, « Tous les événements. Une seule application. », bouton « Télécharge MaCity » qui pulse, doigt qui tape |

## Modifier
- Textes, timings, animations : `src/pub.html` (tableau `CUES` pour les sous-titres, `MONT` pour le montage).
- Musique : `src/audio_pub.py` puis `python3 audio_pub.py`.
- Rendu : `PW=<chemin playwright> node render_node.js pub.html frames 30`, puis ffmpeg (voir la commande dans l'historique ou ci-dessous).

```
ffmpeg -framerate 30 -i frames/f%04d.jpg -i pub_audio.wav -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart ../MACITY_Pub_Ta_Ville_Bouge_9x16.mp4
```

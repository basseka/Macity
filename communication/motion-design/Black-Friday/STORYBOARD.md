# Reel Black Friday MaCity : « Le compte à rebours explosif »

Fichier à publier : `MACITY_BlackFriday_iPhone_Reel.mp4` (1080 x 1920, 30 i/s, 15 s, H.264 + AAC, son inclus).

## Direction artistique

- **Idée maîtresse** : reprend l'affiche `1000062818.jpg` (*pour moins payer, c'est Black Friday ; pour l'iPhone gratuit, c'est MaCity*), mêmes couleurs que l'affiche depuis le 2026-11-06.
- **Palette (alignée sur l'affiche)** : bleu nuit `#06041A`, indigo `#160B3D` / `#2C1466`, violet `#7A1FD1` / `#9B5CFF`, magenta MaCity `#FF1E8E` (rubans, aura, braises, volet), blanc et lavande pour le métal. Disques magenta en coin sur le plan final, comme sur l'affiche.
- **Version rouge d'origine** : `MACITY_BlackFriday_iPhone_Reel_rouge_original.mp4` + `src/bf_rouge_original.html`.
- **Typo** : Anton (condensée, massive) avec un dégradé chromé (argent en haut, ligne d'horizon nette, reflet rouge en bas), un liseré clair et un halo rouge. Poppins ExtraBold pour les rubans.
- **Matière** : grain film léger, vignettage, braises rouges qui montent en permanence, faisceaux lumineux tournants, sol en grille rouge en perspective (lecture « tech »).
- **iPhone 18 Pro** : modélisé en vraie 3D (18 couches d'épaisseur), finition violet profond comme sur l'affiche, plateau photo pleine largeur (3 objectifs à gauche, flash + LiDAR à droite), Dynamic Island réduite, bordures d'écran fines, fond d'écran vagues magenta/violet maison. Sans logo Apple ni fond d'écran Apple.

## Storyboard

| Temps | Plan | Animation / caméra | Effets | Son |
|---|---|---|---|---|
| 0,00 à 0,95 | **« 3 »** géant | Tombe du haut de l'écran, étiré par le flou de mouvement, s'écrase (squash 0,82 puis rebond), légère poussée avant puis il traverse la caméra (zoom x5 + flou) | Gerbe d'étincelles au sol, onde de choc elliptique, flash rouge, aberration chromatique, tremblement caméra | Whoosh descendant, **bass impact** + choc métallique, drone qui monte |
| 1,00 à 1,95 | **« 2 »** | Même mécanique, cadence d'une seconde | Idem | Idem, choc métallique un ton plus haut |
| 2,00 à 2,95 | **« 1 »** | Idem | Idem | Idem, la montée s'intensifie |
| 3,00 à 3,40 | **« 0 » : l'explosion** | Le zéro tombe et explose | Flash blanc plein écran, 580 étincelles, deux ondes de choc, fond qui vire au rouge incandescent, tremblement fort | **Explosion** (sub + craquement) |
| 3,40 à 4,70 | **Plongée dans le zéro** | La caméra fonce dans le trou du 0 (zoom x35), effet tunnel | Lignes de vitesse radiales, fond rouge qui pulse | Long whoosh montant + riser |
| 4,75 à 6,00 | **Apparition de l'iPhone** | Surgit du centre, minuscule à plein cadre en 0,9 s, en tournant sur lui-même (3,5 tours qui décélèrent) | Flash, onde de choc, aura rouge, 3 faisceaux tournants, sol en grille | Hit grave + **scintillement** cristallin |
| 6,00 à 9,75 | **La star : rotation lente** | Rotation continue (environ 86°/s) : face, tranche, dos avec bloc photo, retour face ; léger flottement | Reflets qui glissent sur l'écran et le dos selon l'angle | Beat électronique 128 BPM + basse |
| 6,35 | **« BLACK FRIDAY »** | Arrive de la caméra (x3,2), s'écrase, rebond | Glitch en 7 bandes qui se décalent puis se recollent, éclats triangulaires, flash | Impact + choc métallique + zap |
| 7,90 | **« UN iPHONE 18 À GAGNER ! »** | Ruban rouge incliné à -4°, arrive en zoom puis respire | Étincelles horizontales | Impact + scintillement |
| 9,80 à 10,25 | **Transition** | Tout s'envole (téléphone vers le bas, textes en zoom avant), volet rouge diagonal qui balaie l'écran | Flash rouge | Whoosh + riser |
| 10,30 / 10,60 | **« TENTE TA » / « CHANCE ! »** | Deux claques successives, ligne par ligne | Fond noir traversé d'une grande diagonale rouge, éclats | Deux bass impacts |
| 11,30 à 12,45 | **« PARTICIPE AU CONCOURS »** | Ruban blanc, texte rouge, incliné à -3° | Étincelles | Impact + nappe tendue (temps de lecture) |
| 12,55 à 15,00 | **Plan final** | Les textes remontent et se resserrent, l'iPhone remonte face caméra (vue 3/4 qui pivote doucement), logo MaCity en haut | Explosion rose et rouge, aura rose, faisceaux, éclat lumineux qui balaie l'écran à 13,8 s, mention « INFOS ET RÈGLEMENT EN BIO » | **Coup final** massif + accord grave + queue métallique |

## Textes à l'écran

1. `3` / `2` / `1` / `0`
2. `BLACK FRIDAY`
3. `UN iPHONE 18 À GAGNER !`
4. `TENTE TA CHANCE !`
5. `PARTICIPE AU CONCOURS`
6. `INFOS ET RÈGLEMENT EN BIO` + logo MaCity

Zones sûres Instagram respectées : aucun texte dans les 400 px du bas (légende, boutons) ni collé au bord droit.

## Avant de publier

- **Règlement du jeu concours** obligatoire en France (modalités, dates, tirage, dotation). Mettre le lien en bio, d'où la mention à l'écran.
- Dans la légende Instagram : préciser que le concours n'est ni organisé ni parrainé par Instagram / Meta, ni par Apple.
- Modifier la mention ou la date affichée sur l'écran du téléphone (« vendredi 27 novembre ») dans `src/bf.html` si besoin.

## Modifier et refaire le rendu

```bash
cd communication/motion-design/Black-Friday
python3 src/audio_bf.py                         # bande-son -> src/bf_audio.wav
export PW=~/.npm/_npx/e41f203b7505f1fb/node_modules/playwright
WORKERS=6 node src/render.js /tmp/bf_frames     # 450 images (~1 min 30)
node src/render.js /tmp/bf_test 3.2 6.5 13      # tester quelques instants
ffmpeg -y -framerate 30 -i /tmp/bf_frames/f%04d.jpg -i src/bf_audio.wav \
  -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -c:a aac -b:a 256k \
  -shortest -movflags +faststart MACITY_BlackFriday_iPhone_Reel.mp4
```

- Timing : constantes `IMP`, `TZ`, `TP`, `TBF`, `TG`, `TA`, `TB`, `TPART`, `THERO` en haut des scripts de `src/bf.html` (le son est calé sur les mêmes valeurs dans `src/audio_bf.py`).
- Effacer le dossier d'images avant un rendu complet (les images déjà présentes sont sautées).

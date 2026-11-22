# Pub MaCity « 3 messages » (9:16, 22,5 s)

Vidéos :
- `MACITY_Pub_Radio_3_Messages_9x16.mp4` : voix off IA française (edge-tts, voix Henri) + musique synthétisée, libre de droits.
- `MACITY_Pub_Radio_3_Messages_9x16_sans_voix.mp4` : musique seule, pour poser la voix de l'animateur radio.

Direction artistique conforme à la charte (`communication/charte-graphique/`) :
- logo officiel couleur fond sombre, sans ombre ni effet ;
- Poppins pour les titres et textes, Geist Mono pour les petites mentions en capitales (pas d'Anton) ;
- base Nuit MaCity, rose #FF1E8E en accent, Magenta #E91E63 pour les boutons, dégradé principal pour l'écran « Publié », pastilles néon #F4247C, touches cyan ;
- couleurs de rubrique officielles : Culture cyan, Night violet, Food orange, Famille pastel.

Versions précédentes : `src/pub_v1.html`, `src/pub_v2.html`.

| Temps | Scène | À l'écran |
|---|---|---|
| 0 - 2,4 s | Accroche | Rue animée de Toulouse la nuit, étiquette « TOULOUSE », « CE WEEK-END, TU FAIS QUOI ? » |
| 2,4 - 9,6 s | 1. Trouve ton plan | Téléphone avec l'accueil de l'app, bulles Concerts / Soirées / Restos / En famille, pin MaCity et ondes radar |
| 9,6 - 13,8 s | 2. Publie ton event | Formulaire « Publier un événement » qui se remplit, doigt sur « Publier », « Publié ! » et confettis |
| 13,8 - 18,4 s | 3. Mets en avant ton établissement | Carte « ★ PARTENAIRE » dans un cadre néon rose, étiquettes « À la une », « Sur la carte », « + de visibilité » |
| 18,4 - 22,5 s | Fin | Logo MaCity, « Toute ta ville, dans une seule appli », boutons App Store / Google Play, « Gratuit · macity.app » |

## Modifier
- Animations et sous-titres : `src/pub.html` (tableau `CUES`).
- Voix : `src/voix/lines.txt`, puis edge-tts ; musique et mixage : `src/audio.py`.
- Rendu : `PW=<playwright> node render_node.js pub.html frames 30`, puis ffmpeg (`-c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac`).

# Spécifications vidéo pour bannière MaCity

## Format technique

| Critère | Recommandation |
|---|---|
| **Format** | MP4 (conteneur) |
| **Codec vidéo** | H.264 (le plus compatible mobile) |
| **Résolution** | 360p (640x360) — suffisant pour la bannière de 120px de haut |
| **Ratio** | 16:9 (paysage) |
| **Durée** | 6 à 15 secondes max |
| **Boucle** | La vidéo tourne en boucle, donc prévoir un raccord fluide début/fin |
| **Audio** | Aucun (le son est coupé dans l'app), ne pas inclure de piste audio pour réduire le poids |
| **Poids** | < 500 Ko idéalement (réseau mobile) |
| **FPS** | 24 ou 30 fps |

## Points importants

- **Pas de texte trop petit** : la vidéo s'affiche dans un bandeau de 120px de haut, le texte incrusté doit être gros et centré
- **Pas de son** : la vidéo est muette, le message doit passer uniquement par l'image
- **Ambiance plutôt que message** : les vidéos actuelles sont des plans d'ambiance (foule, mouvement, action), pas des pubs classiques — ça fonctionne mieux dans ce format court en boucle
- **360p suffit** : inutile d'envoyer du 1080p, ça alourdirait le chargement pour rien vu la taille d'affichage

## En résumé

Un MP4 H.264 de 10 secondes en 640x360, sans son, en boucle fluide, moins de 500 Ko.

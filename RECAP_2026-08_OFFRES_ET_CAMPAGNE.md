# Récapitulatif : offres, attribution des installations et campagne Meta

**Période :** 3 au 5 août 2026
**Branche :** `feat/partner-tiers-rotation`
**Commits :** `10ffdd8`, `6947cc9`, `2aa15bb`, `5c70dec`, `50b2f8c`

Document destiné à l'équipe. Il couvre trois chantiers menés ensemble : les
offres partenaires dans l'application, la mesure des installations, et la
campagne publicitaire d'août.

---

## 1. Les offres partenaires

### Le problème de départ

Une offre créée dans l'admin naissait **sans visuel**. La colonne
`offers.image_url` existait pourtant en base et l'application l'affichait déjà,
mais la fonction d'écriture `admin_upsert_client_offer` ignorait purement cette
clé.

Second manque : **rien ne reliait une offre à un commerce**. La colonne
`offers.client_id` pointe vers `partner_clients`, l'entité facturée, et le lien
vers un établissement réel ne vivait que dans `venue_subscriptions`, table
réservée à l'admin. L'application, qui lit `offers` en anonyme, ne pouvait donc
pas savoir quelle fiche mettre en avant.

### Ce qui a été fait

**Dans l'admin**, le formulaire d'offre accepte désormais une photo (glisser
déposer, Ctrl+V, ou parcourir) et une pochette à mettre en avant, choisie par
recherche libre sur toutes les fiches.

⚠️ Point important : la recherche porte sur **toutes** les fiches, pas seulement
sur les établissements abonnés du client. C'était une demande explicite : une
offre ne doit pas dépendre d'un abonnement saisi. Contrepartie assumée, on peut
donc mettre en avant un commerce qui ne paie rien.

**Dans l'application**, une offre rattachée produit deux choses : une pastille
🏷️ sur la pochette du commerce dans les listes, et un encart sous le badge
« Restaurant partenaire » dans sa fiche, qui ouvre la réclamation au clic.

Le rattachement utilise le couple `(source_table, source_id)`, déjà la clé de
jointure canonique du projet, celle qu'utilisent les métriques partenaires, les
avis et les cartes Inspirations.

### Un piège à connaître

`CommerceModel.sourceTable` n'a **jamais été uniformisé** : selon le service qui
l'alimente, il vaut le singulier (`etablissement`, `venue`, `family_venue`, pour
les avis et les revendications) ou le pluriel (`etablissements`, `venues`,
`sport_venues`, pour les partenaires du jour). Une comparaison directe raterait
donc silencieusement la moitié des pochettes. D'où `Offer.venueKeyFor()`, qui
normalise avant de comparer. Ne pas court-circuiter cette fonction.

---

## 2. Le QR code des offres

### Ce qui existait

Le bouton « J'en profite » ouvrait un écran d'abonnement, et le code présenté au
commerçant était **tiré au hasard sur le téléphone**, six chiffres jamais
enregistrés nulle part. Le commerçant n'avait donc aucun moyen de distinguer un
vrai code d'un code inventé, et rien n'empêchait la même personne de consommer
l'offre dix fois.

Second défaut : `claimSpot` lisait `claimed_spots` puis réécrivait `valeur + 1`.
Deux personnes qui cliquaient en même temps ne consommaient qu'une seule place.

### Ce qui a été fait

Une table `offer_claims` enregistre chaque réclamation avec un code unique de 8
caractères. La fonction `claim_offer` **verrouille la ligne d'offre** avant
d'incrémenter, ce qui règle la course. Elle est idempotente par appareil :
rouvrir la fenêtre réaffiche le même code sans consommer de place, et un index
unique interdit à un même téléphone de réclamer deux fois la même offre.

Le code s'affiche en QR sur fond blanc, avec le code en clair dessous pour la
saisie manuelle quand la caméra refuse de coopérer. L'alphabet exclut 0 et O,
1, I et L, parce que ce code sera lu à voix haute et recopié à la main.

### ⚠️ Ce qui manque encore

**Aucun écran ne permet au commerçant de valider un QR.** La fonction
`redeem_offer_claim` existe, elle est réservée aux comptes authentifiés, mais
elle n'est appelée nulle part. En l'état, un client montre son QR et le
restaurant ne peut ni le vérifier ni le marquer comme utilisé : le même code
reste valable indéfiniment.

Décision en attente : saisie du code à la main dans l'espace pro (aucune
dépendance nouvelle) ou scan par la caméra (ajout de `mobile_scanner`, donc
permissions caméra et nouvelle version à publier).

---

## 3. Correctifs de la recherche

Deux défauts corrigés au passage, sans rapport avec les offres.

`_searchSportVenues` ne sélectionnait ni `photos` ni `video_url`, alors que la
table `sport_venues` porte ces colonnes. Toute salle de sport ouverte depuis la
recherche affichait donc les médias par défaut au lieu des siens.

Surtout, les **douze URLs de photos par défaut n'avaient jamais été uploadées**
dans le bucket : elles répondaient toutes 404. Résultat, une fiche sans galerie
montrait une vraie photo suivie de cinq vignettes cassées. Ces listes ont été
supprimées. Le repli visuel de ces rubriques reste la vidéo générique, qui
existe bien en storage, elle.

Ne pas réintroduire de photos par défaut sans avoir d'abord vérifié que les
fichiers répondent 200.

---

## 4. Base de données

Trois migrations, **toutes appliquées en production** au 5 août 2026. Elles
vivent dans `appli/supabase/migrations/`, qui n'est pas un dépôt git.

| Fichier | Contenu |
|---|---|
| `20260803140000_offer_photo_and_venue_link.sql` | Colonnes `image_url`, `source_table`, `source_id` sur `offers`. Fonctions de lecture et d'écriture mises à jour. |
| `20260803160000_offer_claims_qr.sql` | Table `offer_claims`, réclamation atomique, validation commerçant. |
| `20260804100000_admin_story_contributors.sql` | Vue des contributeurs stories pour l'admin. |

Rappel de méthode : les migrations se **collent dans Studio SQL**, jamais par
`db push`. L'historique du CLI est désynchronisé de longue date.

Détail utile : `offers.pro_profile_id` était `NOT NULL` alors que l'admin ne le
renseigne pas, et le code Dart le castait en type non nullable. Une seule offre
créée depuis l'admin aurait fait planter le chargement de **toute** la rubrique
Offres. La contrainte a été levée et le modèle rendu tolérant.

---

## 5. Mesure des installations

### Pourquoi c'était nécessaire

La campagne de juillet a coûté 89 € pour 31 198 affichages et 813 clics, soit un
taux de clic de 2,6 %, bien au-dessus de la moyenne Instagram. Mais **personne ne
savait combien de ces clics avaient produit une installation** : les
installations de la Play Console formaient un tas indistinct, mélangeant
publicité, bouche à oreille et recherche spontanée.

Meta ne peut pas combler ce trou tout seul : optimiser ou mesurer des
installations exige que l'application lui soit connectée par son SDK, qui n'est
pas dans le projet. À noter que l'ajouter supposerait de remettre la permission
`AD_ID`, retirée en 1.0.152.

### Comment ça marche maintenant

Google Play sait attribuer une installation grâce au paramètre `referrer` de
l'URL du store. La publicité amène sur `macity.app` avec des paramètres UTM, et
un script recopie ces paramètres dans le `referrer` au moment où le visiteur
clique sur le bouton d'installation.

Le script vit dans **`index.html`** et dans **`download.html`**. Cette seconde
page était indispensable : elle redirige automatiquement sur mobile, donc sans
elle tout se perdait dès qu'un utilisateur passait par la barre « Télécharger ».

Deux contraintes de format à respecter si on y touche. Google Play attend **un
seul paramètre `referrer`, lui-même encodé** : le découper en paramètres séparés
casse l'attribution. Et dans Meta, le champ « Paramètres d'URL » doit rester
**vide**, sinon Meta ajoute ses propres paramètres et casse l'encodage.

### Les liens de campagne

```
https://macity.app/?utm_source=facebook&utm_medium=cpc&utm_campaign=install_aout2026&utm_content=bouscule
https://macity.app/?utm_source=facebook&utm_medium=cpc&utm_campaign=install_aout2026&utm_content=sandwich
https://macity.app/?utm_source=facebook&utm_medium=cpc&utm_campaign=install_aout2026&utm_content=voiture
```

Seul `utm_content` change, il identifie la vidéo.

### Où lire les résultats

**Play Console**, section Acquisition d'utilisateurs : les installations s'y
répartissent par source et par campagne, décomposables par `utm_content`.
Compter 24 à 48 heures de décalage.

Le coût par clic se lit dans Meta, les installations dans Play. C'est le rapport
entre les deux qui donne le coût par installation, le seul chiffre qui compte.

### ⚠️ Deux angles morts

**iOS n'est pas attribué.** Apple utilise ses propres paramètres, `pt` pour le
jeton fournisseur et `ct` pour la campagne, et **ignore `ct` sans `pt`**. Le code
est en place mais désactivé : une variable `PT` vide attend le jeton, à récupérer
dans App Store Connect via App Analytics puis Acquisition puis Campagnes.
L'application est bien publiée sur l'App Store depuis le 27 juillet 2026, donc
ce trou est réel.

**Rien ne mesure la landing elle-même.** Ni pixel Meta, ni Google Analytics sur
`macity.app`. On sait donc combien de clics sont facturés et combien
d'installations sont attribuées, mais pas combien de personnes arrivent
réellement sur la page ni combien repartent sans cliquer.

---

## 6. La campagne Meta, et pourquoi ces réglages

| Réglage | Choix | Raison |
|---|---|---|
| Objectif | **Trafic** | « Promotion d'application » exige le SDK Meta, absent. « Notoriété » paie de l'affichage, ce qui a déjà donné 31 000 impressions inexploitables. |
| Configuration | **Manuelle** | Advantage+ automatise l'audience et les placements, et rend opaques le ciblage et la comparaison entre vidéos. |
| Catégorie spéciale | **Aucune** | La cocher interdit le ciblage par âge et élargit de force la zone géographique, ce qui rendrait le ciblage Toulouse inutilisable. |
| Budget | **5 € par jour**, au niveau campagne | La répétition de juillet était à 1,15 et 1,45, donc l'audience est loin d'être saturée. Le budget au niveau campagne laisse Meta arbitrer entre les vidéos. |
| Destination | **Site web** | La landing vend le produit avant l'installation, et le script y récupère l'attribution. |
| Optimisation | **Clics sur un lien** | « Vues de page de destination » exige un pixel, absent. |
| Audience | Toulouse plus 30 km, 18 à 40 ans, un **seul** ensemble | À ce budget, découper l'audience empêche l'algorithme de sortir de sa phase d'apprentissage. |
| Placements | **Advantage+** | Les vidéos sont verticales, elles iront en Reels et Stories. Meta arbitre mieux que nous à ce niveau de dépense. |
| Appel à l'action | **Installer** | |

Après publication, **ne rien modifier pendant 48 heures** : chaque changement
relance la phase d'apprentissage.

---

## 7. Le traitement des vidéos

Les rushes sont en 4K vertical, 2160x3840, 30 images par seconde, environ 25
Mbit/s.

### La recette de coupe

Le principe : couper **sans réencoder l'image**, donc sans aucune perte. C'est
possible uniquement si la coupe tombe sur une image clé. Dans ces vidéos, il y en
a une **toutes les 0,967 seconde**, et non à chaque seconde.

Conséquence pratique : demander une coupe à 2 s donne en réalité 1,933 s, la
dernière image clé avant. L'écart de deux images est imperceptible, et c'est le
prix à payer pour ne rien dégrader. Couper à la seconde exacte imposerait un
réencodage complet.

```bash
# 1. Repérer les images clés
ffprobe -v error -read_intervals "%+6" -select_streams v:0 \
  -show_entries packet=pts_time,flags -of csv=p=0 "source.MP4" | grep K

# 2. Couper sur une image clé, image copiée telle quelle
ffmpeg -ss 1.933333 -i "source.MP4" -map 0:v:0 -map 0:a:0 \
  -c:v copy -c:a aac -b:a 128k \
  -af "atrim=start=0.109,asetpts=PTS-STARTPTS" \
  -movflags +faststart "sortie.MP4"
```

Le `atrim` mérite une explication : après la coupe, l'audio commence environ 100
ms avant la première image, ce qui produit une **amorce noire** au lancement.
C'est visible sur une publicité. La seule façon de le supprimer est de
réencoder l'audio, ce qui est sans conséquence audible, alors que l'image reste
copiée bit à bit. La valeur exacte se lit en mesurant `start_time` du flux vidéo
après une première passe en copie.

### Vérification systématique

Comparer l'empreinte de la première image du fichier coupé avec celle de
l'original au même instant. Si elles sont identiques, la copie est intacte.

```bash
ffmpeg -ss 1.9333 -i "source.MP4" -frames:v 1 -y /tmp/a.png
ffmpeg -i "sortie.MP4" -frames:v 1 -y /tmp/b.png
cmp /tmp/a.png /tmp/b.png && echo "identique"
```

### À faire avant diffusion

Les vidéos sont en 4K alors qu'Instagram plafonne à 1080x1920 et réencode
systématiquement. Produire nous-mêmes un 1080x1920 bien encodé donne
généralement un meilleur rendu que de laisser Meta descendre depuis du 4K. Non
fait à ce jour.

---

## 8. Ce qui reste ouvert

- **L'écran de validation des QR côté commerçant.** Sans lui, la promesse faite
  aux partenaires n'est pas tenue.
- **Le jeton `pt` d'App Store Connect**, pour l'attribution iOS.
- **L'identifiant de pixel Meta**, pour mesurer la landing.
- **Le passage des vidéos en 1080x1920** avant diffusion.
- **La version de l'application n'est pas incrémentée** : `pubspec.yaml` est
  toujours en 1.0.152, déjà en production. Une release exige un passage en
  1.0.153, et la mise à jour de la table `app_versions` **après** publication
  seulement, sinon `force_update` bloque les utilisateurs sur une version
  indisponible.

### ⚠️ Un point de sécurité connu et non traité

Avec la seule clé publique embarquée dans l'application, **651 profils
utilisateurs sont lisibles, email et téléphone compris**, et une écriture est
acceptée. Comme la reconnexion sur un nouvel appareil se fait par email plus
téléphone, la chaîne complète permet une prise de contrôle de compte.

La correction a été **volontairement reportée**. Fermer l'écriture ne demande
qu'un changement de politique, sans toucher à l'application. Fermer la lecture
suppose de déplacer trois requêtes vers des fonctions serveur, donc de toucher à
l'onboarding, zone déjà revertée une fois pour cause de risque.

Ce point doit être connu de toute personne qui envisagerait un annuaire
d'utilisateurs ou une messagerie privée : ces fonctionnalités reposeraient sur
une identité que le serveur ne sait pas vérifier.

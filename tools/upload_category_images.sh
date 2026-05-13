#!/usr/bin/env bash
# Upload tous les assets references par `categories.image_url` vers le bucket
# Storage `category-images` du projet Supabase.
#
# Prerequis :
#   - bucket cree (migration 20260513180000_categories_storage_bucket.sql)
#   - variable d'env SUPABASE_SERVICE_ROLE_KEY exportee (cle du projet)
#
# Usage : ./tools/upload_category_images.sh
set -euo pipefail

PROJECT_REF="dpqxefmwjfvoysacwgef"
BUCKET="category-images"
KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [ -z "$KEY" ]; then
  echo "ERROR : exporte SUPABASE_SERVICE_ROLE_KEY avant de lancer le script."
  echo "  (Studio > Project Settings > API > service_role secret)"
  exit 1
fi

cd "$(dirname "$0")/.."

files=(
  "assets/images/carte_plan_touristique.png"
  "assets/images/carte_se_deplacer.png"
  "assets/images/pochette_Golf.jpg"
  "assets/images/pochette_VR.webp"
  "assets/images/pochette_animation.webp"
  "assets/images/pochette_autre.jpg"
  "assets/images/pochette_barajeux.webp"
  "assets/images/pochette_bibliotheque.jpg"
  "assets/images/pochette_boutiquemanga.jpg"
  "assets/images/pochette_boxe.webp"
  "assets/images/pochette_brunch.jpg"
  "assets/images/pochette_cettesemaine.jpg"
  "assets/images/pochette_chicha.webp"
  "assets/images/pochette_concert.webp"
  "assets/images/pochette_cosplay.jpg"
  "assets/images/pochette_course.webp"
  "assets/images/pochette_culture_art.webp"
  "assets/images/pochette_default.jpg"
  "assets/images/pochette_discotheque.webp"
  "assets/images/pochette_enfamille.jpg"
  "assets/images/pochette_escapegame.jpg"
  "assets/images/pochette_exposition.webp"
  "assets/images/pochette_festival.webp"
  "assets/images/pochette_fetedelamusique.webp"
  "assets/images/pochette_gaming.jpg"
  "assets/images/pochette_gamingcafe.jpg"
  "assets/images/pochette_hotel.webp"
  "assets/images/pochette_metronum.jpg"
  "assets/images/pochette_monument.jpg"
  "assets/images/pochette_musee.webp"
  "assets/images/pochette_natation.jpg"
  "assets/images/pochette_opera.jpg"
  "assets/images/pochette_parc_animalier.webp"
  "assets/images/pochette_parc_attraction.webp"
  "assets/images/pochette_pub.webp"
  "assets/images/pochette_restaurant.jpg"
  "assets/images/pochette_rex.jpg"
  "assets/images/pochette_sallearcade.webp"
  "assets/images/pochette_salondethe.jpg"
  "assets/images/pochette_showcase.webp"
  "assets/images/pochette_spa&hammam.webp"
  "assets/images/pochette_spectacle.webp"
  "assets/images/pochette_stagedanse.webp"
  "assets/images/pochette_standup.webp"
  "assets/images/pochette_tabac.webp"
  "assets/images/pochette_theatre.webp"
  "assets/images/pochette_tourisme_toulouse.webp"
  "assets/images/pochette_visite.webp"
  "assets/images/pochette_yoga.jpg"
  "assets/images/salle_auditorium.jpg"
  "assets/images/salle_bikini.png"
  "assets/images/salle_halleauxgrains.jpg"
  "assets/images/salle_interference.jpg"
  "assets/images/salle_zenith.jpg"
  "assets/images/shell_sport_basketball.png"
  "assets/images/shell_sport_fitness.png"
  "assets/images/shell_sport_football.png"
  "assets/images/shell_sport_handball.png"
  "assets/images/shell_sport_rugby.png"
)

ok=0
fail=0
for path in "${files[@]}"; do
  if [ ! -f "$path" ]; then
    echo "SKIP   $path (introuvable)"
    fail=$((fail+1))
    continue
  fi
  name=$(basename "$path")
  case "$name" in
    *.webp) mime="image/webp" ;;
    *.png)  mime="image/png"  ;;
    *.jpg|*.jpeg) mime="image/jpeg" ;;
    *) mime="application/octet-stream" ;;
  esac

  # Encode le nom pour l'URL (le & dans spa&hammam doit etre %26)
  encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=''))" "$name")
  url="https://${PROJECT_REF}.supabase.co/storage/v1/object/${BUCKET}/${encoded}"

  code=$(curl -sS -o /tmp/upload_resp.json -w "%{http_code}" \
    -X POST "$url" \
    -H "Authorization: Bearer $KEY" \
    -H "x-upsert: true" \
    -H "Content-Type: $mime" \
    --data-binary "@$path")

  if [ "$code" = "200" ] || [ "$code" = "201" ]; then
    echo "OK     $name"
    ok=$((ok+1))
  else
    echo "FAIL   $name (HTTP $code) $(cat /tmp/upload_resp.json)"
    fail=$((fail+1))
  fi
done

echo ""
echo "Termine : $ok upload(s) reussi(s), $fail echec(s)."

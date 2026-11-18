#!/usr/bin/env bash
# Build de release avec version datée : AA.MM.JJ (affichée) + AAMMJJn (build).
#
#   ./scripts/release.sh android            nouvelle version du jour + app bundle Play Store
#   ./scripts/release.sh ios                version du jour (reprise si déjà faite aujourd'hui) + ipa
#   ./scripts/release.sh <cible> --dry-run  affiche la version calculée sans rien modifier
#
# Android incrémente n (0, 1, 2…) à chaque build du même jour. iOS reprend la
# version déjà dans pubspec.yaml si elle est du jour (build Android fait puis
# git pull sur le Mac), pour que les deux stores aient le même numéro.
# Fonctionne sous Linux et macOS (perl plutôt que sed -i).
set -euo pipefail

cd "$(dirname "$0")/.."

target="${1:-}"
dry=false
[[ "${2:-}" == "--dry-run" ]] && dry=true
if [[ "$target" != "android" && "$target" != "ios" ]]; then
  echo "Usage : $0 android|ios [--dry-run]" >&2
  exit 1
fi

name="$(date +%y.%m.%d)"
prefix="$(date +%y%m%d)"

current="$(grep -E '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*//')"
cur_build="${current#*+}"

if [[ "$cur_build" == "$prefix"? ]]; then
  n="${cur_build: -1}"
  if [[ "$target" == "android" ]]; then
    n=$((n + 1))
    if (( n > 9 )); then
      echo "Déjà 10 builds aujourd'hui (numéro $cur_build) : impossible d'aller au-delà de ${prefix}9." >&2
      exit 1
    fi
  fi
else
  n=0
fi

build="${prefix}${n}"
echo "Version actuelle : $current"
echo "Nouvelle version : $name+$build"

if $dry; then
  echo "(--dry-run : rien n'est modifié)"
  exit 0
fi

perl -pi -e "s/^version:.*/version: $name+$build/" pubspec.yaml

if [[ "$target" == "android" ]]; then
  flutter build appbundle --release --build-name="$name" --build-number="$build"
  echo "Bundle : build/app/outputs/bundle/release/app-release.aab ($name+$build)"
else
  flutter build ipa --release --build-name="$name" --build-number="$build"
  echo "IPA : build/ios/ipa/ ($name+$build)"
fi

echo "Pense à committer pubspec.yaml : git commit -m \"chore: version $name+$build\" pubspec.yaml"

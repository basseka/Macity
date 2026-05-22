#!/usr/bin/env bash
# Installe la chaîne d'outils du générateur de teaser, en local, sans sudo :
#   - venv Python + yt-dlp + anthropic
#   - ffmpeg / ffprobe statiques dans bin/
# Idempotent : peut être relancé sans risque.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[setup] venv + dépendances Python…"
python3 -m venv "$DIR/.venv"
"$DIR/.venv/bin/pip" install -q --upgrade pip
"$DIR/.venv/bin/pip" install -q -r "$DIR/requirements.txt"

if [[ ! -x "$DIR/bin/ffmpeg" || ! -x "$DIR/bin/ffprobe" ]]; then
  echo "[setup] ffmpeg statique…"
  mkdir -p "$DIR/bin"
  tmp="$(mktemp -d)"
  curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
    -o "$tmp/ffmpeg.tar.xz"
  tar xf "$tmp/ffmpeg.tar.xz" -C "$tmp" --strip-components=1
  cp "$tmp/ffmpeg" "$tmp/ffprobe" "$DIR/bin/"
  rm -rf "$tmp"
fi

chmod +x "$DIR/teaser" "$DIR/make_teaser.py" 2>/dev/null || true
echo "[setup] OK — $("$DIR/bin/ffmpeg" -version | head -1)"
echo "[setup] OK — yt-dlp $("$DIR/.venv/bin/yt-dlp" --version)"

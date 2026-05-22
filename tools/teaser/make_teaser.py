#!/usr/bin/env python3
"""
make_teaser.py — Génère un teaser vidéo 16:9 court pour les fiches détail Sport.

Cible : le champ `video_url` de la table `sport_venues` — la vidéo qui s'affiche
en haut de la fiche détail d'une salle dans l'app (lecteur `_DetailVideoPlayer`,
ratio natif respecté, lecture en boucle, autoplay).

Pipeline :
  1. Télécharge la vidéo source (yt-dlp) — URL YouTube/autre, ou fichier local.
  2. Échantillonne des images réparties sur toute la durée.
  3. Choisit le meilleur extrait (~15-25s) :
       - par défaut : analyse IA des images via l'API Claude (vision) ;
       - repli `--no-ai` : détection de scènes ffmpeg (fenêtre la plus dynamique).
  4. Découpe + ré-encode : 16:9 720p, H.264/yuv420p + AAC, +faststart.
  5. Produit `out/teaser_<slug>.mp4` + `out/teaser_<slug>.json`
     (timestamps début/fin, résumé en une phrase, titre court).

Usage :
  ./teaser --url "https://www.youtube.com/watch?v=XXXX" --name gymnasia
  ./teaser --input ma_video.mp4 --duration 18
  ./teaser --url "..." --no-ai          # sans appel API (détection de scènes)

Variables d'environnement :
  ANTHROPIC_API_KEY   requis pour la sélection IA (sinon : repli automatique).
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path

HERE = Path(__file__).resolve().parent
BIN = HERE / "bin"
OUT = HERE / "out"

# Modèle Claude par défaut pour l'analyse vision. Surchargé par --model.
DEFAULT_MODEL = "claude-opus-4-7"

# Bornes de durée du teaser (secondes).
MIN_TEASER = 8.0
MAX_TEASER = 25.0


# ─────────────────────────── utilitaires ───────────────────────────

def die(msg: str) -> None:
    sys.exit(f"[erreur] {msg}")


def log(msg: str) -> None:
    print(f"[teaser] {msg}", flush=True)


def resolve(name: str) -> str:
    """Trouve un binaire : d'abord bin/ local, sinon le PATH."""
    local = BIN / name
    if local.exists():
        return str(local)
    found = shutil.which(name)
    if found:
        return found
    die(f"{name} introuvable — ni dans {BIN}, ni dans le PATH. "
        f"Lance d'abord setup.sh.")
    raise SystemExit  # inatteignable, pour les linters


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=True, **kw)


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    return text or "teaser"


# ─────────────────────────── étapes ffmpeg ───────────────────────────

def yt_dlp_path() -> str:
    venv = HERE / ".venv" / "bin" / "yt-dlp"
    if venv.exists():
        return str(venv)
    found = shutil.which("yt-dlp")
    if found:
        return found
    die("yt-dlp introuvable — lance d'abord setup.sh.")
    raise SystemExit


def download(url: str, workdir: Path) -> tuple[Path, str]:
    """Télécharge la vidéo. Retourne (chemin, titre)."""
    log(f"téléchargement : {url}")
    out_tpl = str(workdir / "source.%(ext)s")
    run([
        yt_dlp_path(),
        "--no-playlist",
        "--ffmpeg-location", str(BIN),
        "-f", "bv*[height<=1080]+ba/b[height<=1080]/b",
        "--merge-output-format", "mp4",
        "-o", out_tpl,
        url,
    ])
    produced = next((f for f in workdir.iterdir()
                     if f.stem == "source" and f.is_file()), None)
    if produced is None:
        die("téléchargement : fichier source introuvable après yt-dlp.")
    # Récupère le titre pour nommer la sortie / le résumé.
    title = subprocess.run(
        [yt_dlp_path(), "--no-playlist", "--print", "%(title)s", "--skip-download", url],
        capture_output=True, text=True,
    ).stdout.strip()
    return produced, (title or "video")


def probe_duration(path: Path) -> float:
    out = subprocess.run(
        [resolve("ffprobe"), "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nk=1:nw=1", str(path)],
        capture_output=True, text=True,
    )
    try:
        return float(out.stdout.strip())
    except ValueError:
        die(f"impossible de lire la durée de {path}")
        raise SystemExit


def sample_frames(path: Path, dur: float, workdir: Path,
                  max_frames: int = 36, width: int = 512) -> list[tuple[float, Path]]:
    """Extrait des images réparties uniformément. Retourne [(timestamp, fichier)]."""
    fdir = workdir / "frames"
    fdir.mkdir(exist_ok=True)
    every = max(2.0, dur / max_frames)
    fps = 1.0 / every
    log(f"échantillonnage : 1 image / {every:.1f}s")
    run([
        resolve("ffmpeg"), "-v", "error", "-i", str(path),
        "-vf", f"fps={fps},scale={width}:-2",
        "-q:v", "5", str(fdir / "f_%04d.jpg"),
    ])
    frames = sorted(fdir.glob("f_*.jpg"))
    # La i-ème image (1-indexée par ffmpeg) correspond à ~ (i-0.5)*every.
    return [((i + 0.5) * every, p) for i, p in enumerate(frames)]


def detect_scene_changes(path: Path) -> list[float]:
    """Timestamps des changements de scène (proxy de dynamisme visuel)."""
    out = subprocess.run(
        [resolve("ffmpeg"), "-v", "error", "-i", str(path),
         "-vf", "select='gt(scene,0.3)',showinfo", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    return [float(m) for m in re.findall(r"pts_time:([0-9.]+)", out.stderr)]


def encode_teaser(src: Path, start: float, length: float, dest: Path) -> None:
    """Découpe [start, start+length] et ré-encode en 16:9 720p prêt pour l'app."""
    # scale (cover) puis crop centré → 1280x720 quel que soit le ratio source.
    vf = ("scale=1280:720:force_original_aspect_ratio=increase,"
          "crop=1280:720,setsar=1")
    dest.parent.mkdir(parents=True, exist_ok=True)
    run([
        resolve("ffmpeg"), "-v", "error", "-y",
        "-ss", f"{start:.2f}", "-i", str(src), "-t", f"{length:.2f}",
        "-vf", vf, "-r", "30",
        "-c:v", "libx264", "-profile:v", "high", "-pix_fmt", "yuv420p", "-crf", "23",
        "-c:a", "aac", "-b:a", "128k",
        "-movflags", "+faststart",
        str(dest),
    ])


# ─────────────────────────── sélection du moment ───────────────────────────

_AI_PROMPT = (
    "Ces images sont extraites, dans l'ordre chronologique, d'une vidéo de "
    "salle/activité de sport. Chaque image est précédée de son horodatage [t=...s].\n\n"
    "Choisis le MEILLEUR extrait d'environ {length:.0f} secondes pour servir de "
    "teaser en boucle en haut d'une fiche de salle de sport dans une app mobile.\n"
    "Critères : représentatif du lieu/de l'activité, visuellement dynamique et "
    "engageant, lumineux. Évite : génériques d'intro/outro, cartons de texte, "
    "écrans noirs, plans flous, logos plein écran.\n"
    "La vidéo dure {dur:.0f}s — le début choisi doit permettre {length:.0f}s "
    "complètes (donc start <= {max_start:.0f}).\n\n"
    "Réponds via le schéma JSON imposé : `start` (secondes, début de l'extrait), "
    "`summary` (résumé du contenu de l'extrait en UNE phrase, en français), "
    "`title` (titre court et accrocheur, en français, 40 caractères max)."
)

_AI_SCHEMA = {
    "type": "object",
    "properties": {
        "start": {"type": "number"},
        "summary": {"type": "string"},
        "title": {"type": "string"},
    },
    "required": ["start", "summary", "title"],
    "additionalProperties": False,
}


def pick_with_ai(frames: list[tuple[float, Path]], dur: float,
                 length: float, model: str) -> dict:
    """Demande à Claude de choisir le meilleur extrait à partir des images."""
    import anthropic  # importé ici pour ne pas bloquer le mode --no-ai

    client = anthropic.Anthropic()
    content: list[dict] = []
    for ts, p in frames:
        content.append({"type": "text", "text": f"[t={ts:.1f}s]"})
        content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": "image/jpeg",
                "data": base64.b64encode(p.read_bytes()).decode(),
            },
        })
    content.append({"type": "text", "text": _AI_PROMPT.format(
        dur=dur, length=length, max_start=max(0.0, dur - length))})

    log(f"analyse IA ({model}, {len(frames)} images)…")
    msg = client.messages.create(
        model=model,
        max_tokens=3000,
        thinking={"type": "adaptive"},
        output_config={"format": {"type": "json_schema", "schema": _AI_SCHEMA}},
        messages=[{"role": "user", "content": content}],
    )
    text = "".join(b.text for b in msg.content if b.type == "text")
    data = json.loads(text)
    data["method"] = f"IA ({model})"
    return data


def pick_with_scenes(src: Path, dur: float, length: float) -> dict:
    """Repli sans IA : fenêtre contenant le plus de changements de scène."""
    log("analyse des scènes (repli sans IA)…")
    changes = detect_scene_changes(src)
    max_start = max(0.0, dur - length)
    best_start, best_count = 0.0, -1
    t = 0.0
    while t <= max_start:
        count = sum(1 for x in changes if t <= x < t + length)
        if count > best_count:
            best_count, best_start = count, t
        t += 1.0
    return {
        "start": best_start,
        "summary": "Extrait le plus dynamique de la vidéo (détection de scènes).",
        "title": "Teaser",
        "method": "détection de scènes",
    }


# ─────────────────────────── programme principal ───────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser(
        description="Génère un teaser 16:9 court pour les fiches détail Sport.")
    src_group = ap.add_mutually_exclusive_group(required=True)
    src_group.add_argument("--url", help="URL de la vidéo source (YouTube, etc.)")
    src_group.add_argument("--input", help="Fichier vidéo local")
    ap.add_argument("--name", help="Slug pour nommer la sortie (sinon : titre vidéo)")
    ap.add_argument("--duration", type=float, default=20.0,
                    help=f"Durée cible du teaser, s (défaut 20, borné "
                         f"{MIN_TEASER:.0f}-{MAX_TEASER:.0f})")
    ap.add_argument("--no-ai", action="store_true",
                    help="Sélection par détection de scènes, sans appel API")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Modèle Claude pour l'analyse vision (défaut {DEFAULT_MODEL})")
    ap.add_argument("--keep", action="store_true",
                    help="Conserve le dossier de travail temporaire")
    args = ap.parse_args()

    workdir = Path(tempfile.mkdtemp(prefix="teaser_"))
    try:
        # 1. Source
        if args.url:
            src, title = download(args.url, workdir)
        else:
            src = Path(args.input).expanduser().resolve()
            if not src.exists():
                die(f"fichier introuvable : {src}")
            title = src.stem

        dur = probe_duration(src)
        log(f"source : {src.name} — durée {dur:.1f}s")

        # 2. Durée cible bornée
        length = max(MIN_TEASER, min(args.duration, MAX_TEASER, dur))

        # 3. Sélection du moment
        use_ai = not args.no_ai
        if use_ai and not os.environ.get("ANTHROPIC_API_KEY"):
            log("ANTHROPIC_API_KEY absente → repli détection de scènes.")
            use_ai = False

        if use_ai:
            frames = sample_frames(src, dur, workdir)
            try:
                pick = pick_with_ai(frames, dur, length, args.model)
            except Exception as e:  # noqa: BLE001 — repli robuste
                log(f"analyse IA échouée ({e}) → repli détection de scènes.")
                pick = pick_with_scenes(src, dur, length)
        else:
            pick = pick_with_scenes(src, dur, length)

        # 4. Bornes finales
        start = max(0.0, min(float(pick["start"]), dur - length))
        end = start + length

        # 5. Encodage
        slug = slugify(args.name or title)
        dest = OUT / f"teaser_{slug}.mp4"
        log(f"encodage : [{start:.1f}s → {end:.1f}s] → {dest.name}")
        encode_teaser(src, start, length, dest)

        # 6. Résumé
        result = {
            "output": str(dest),
            "source": args.url or str(src),
            "source_duration_s": round(dur, 1),
            "start_s": round(start, 1),
            "end_s": round(end, 1),
            "teaser_duration_s": round(length, 1),
            "title": pick["title"],
            "summary": pick["summary"],
            "method": pick["method"],
        }
        sidecar = dest.with_suffix(".json")
        sidecar.write_text(json.dumps(result, ensure_ascii=False, indent=2))

        print("\n" + "=" * 60)
        print(f"  Teaser   : {dest}")
        print(f"  Extrait  : {start:.1f}s → {end:.1f}s ({length:.0f}s)")
        print(f"  Titre    : {pick['title']}")
        print(f"  Résumé   : {pick['summary']}")
        print(f"  Méthode  : {pick['method']}")
        print(f"  Détails  : {sidecar}")
        print("=" * 60)
    finally:
        if args.keep:
            log(f"dossier de travail conservé : {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    main()

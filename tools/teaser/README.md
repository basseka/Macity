# Générateur de teaser — fiches détail Sport

Outil en ligne de commande qui transforme une vidéo source (lien YouTube ou
fichier local) en un **teaser court 16:9** prêt à servir de `video_url` sur une
fiche `sport_venues` (la vidéo qui s'affiche en haut de la fiche détail d'une
salle dans l'app — lecteur `_DetailVideoPlayer`, ratio natif, lecture en boucle).

## Installation

```bash
bash tools/teaser/setup.sh
```

Installe **en local, sans sudo** : un venv Python (`yt-dlp`, `anthropic`) et des
binaires `ffmpeg`/`ffprobe` statiques dans `bin/`.

## Utilisation

```bash
# Depuis une URL YouTube, sélection du meilleur extrait par IA :
tools/teaser/teaser --url "https://www.youtube.com/watch?v=XXXX" --name gymnasia

# Depuis un fichier local, durée cible 18 s :
tools/teaser/teaser --input ma_video.mp4 --duration 18

# Sans appel API (sélection par détection de scènes) :
tools/teaser/teaser --url "..." --no-ai
```

| Option       | Rôle                                                          |
|--------------|---------------------------------------------------------------|
| `--url`      | URL de la vidéo source (exclusif avec `--input`)              |
| `--input`    | Fichier vidéo local (exclusif avec `--url`)                   |
| `--name`     | Slug pour nommer la sortie (sinon : titre de la vidéo)       |
| `--duration` | Durée cible du teaser en s (défaut 20, borné 8-25)           |
| `--no-ai`    | Sélection par détection de scènes, sans appel API            |
| `--model`    | Modèle Claude pour l'analyse vision (défaut `claude-opus-4-7`)|
| `--keep`     | Conserve le dossier de travail temporaire                    |

## Sélection IA

Par défaut, l'outil échantillonne des images de la vidéo et demande à l'API
Claude (vision) de choisir le meilleur extrait. Il faut une clé API :

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Sans clé, l'outil bascule automatiquement sur la **détection de scènes**
(fenêtre contenant le plus de changements de plan = la plus dynamique).

## Sorties

Dans `out/` :

- `teaser_<slug>.mp4` — le teaser, **16:9 720p, H.264/AAC, +faststart**.
- `teaser_<slug>.json` — métadonnées : timestamps début/fin, résumé en une
  phrase, titre court, méthode de sélection.

## Mettre le teaser sur une fiche

1. Uploader `teaser_<slug>.mp4` dans Supabase Storage (bucket `videos`).
2. Renseigner l'URL publique dans `sport_venues.video_url` de la salle voulue
   (via Studio, ou l'admin une fois l'édition vidéo branchée).

## Format produit

16:9 · 1280×720 · 30 fps · H.264 (high, yuv420p) · AAC 128k · `+faststart` ·
recadrage centré si la source n'est pas en 16:9.

import json, os
from PIL import Image, ImageDraw
ROOT = '/home/carlos.basseka@celadodc-rswl.com/Bureau/cba/appli/pulz_app/communication/charte-graphique'

PALETTE = {
  "marque": [
    ("rose-macity", "Rose MaCity", "#FF1E8E", "Couleur signature : mot City du logo, haut du pin"),
    ("rose-framboise", "Rose framboise", "#FF1E6E", "Milieu du dégradé du pin"),
    ("rouge-corail", "Rouge corail", "#FF2E38", "Pointe du pin, fin du dégradé"),
    ("nuit-macity", "Nuit MaCity", "#1A0F2E", "Mot Ma sur fond clair, texte principal"),
    ("nuit-profonde", "Nuit profonde", "#0A0514", "Fond de l'app en mode sombre"),
    ("violet-nuit", "Violet nuit", "#1A0A38", "Fond de l'icône d'app"),
  ],
  "interface": [
    ("magenta", "Magenta", "#E91E63", "Boutons, éléments actifs, liens"),
    ("violet", "Violet", "#6A1B9A", "Dégradé principal, accents"),
    ("violet-profond", "Violet profond", "#4B1174", "Fin du dégradé principal"),
    ("rose-neon", "Rose néon", "#F4247C", "Badge LIVE, pastille néon"),
    ("cyan", "Cyan", "#22D3EE", "Accent froid, contour néon"),
    ("vert-gratuit", "Vert gratuit", "#0E8A4F", "Mention Gratuit"),
  ],
  "rubriques": [
    ("night", "Night", "#A855F7", "Nuit & sorties"),
    ("food", "Food", "#FB923C", "Food & lifestyle"),
    ("culture", "Culture", "#22D3EE", "Culture & arts"),
    ("sport", "Sport", "#22C55E", "Sport"),
    ("fiesta", "Fiesta", "#EF4444", "Fêtes, événements forts"),
  ],
  "etiquettes": [
    ("tag-food", "Étiquette Food", "#FFD93D", "Pastille catégorie dans les listes"),
    ("tag-night", "Étiquette Night", "#C4B5FD", ""),
    ("tag-culture", "Étiquette Culture", "#A5F3E4", ""),
    ("tag-sport", "Étiquette Sport", "#BFDBFE", ""),
    ("tag-famille", "Étiquette Famille", "#FED7AA", ""),
    ("tag-evasion", "Étiquette Évasion", "#FBCFE8", ""),
  ],
  "neutres": [
    ("blanc", "Blanc", "#FFFFFF", "Fond des listes"),
    ("creme", "Crème", "#FAFAF7", "Fond clair de l'app"),
    ("sable", "Sable", "#F1EEE9", "Fond clair secondaire"),
    ("encre", "Encre", "#15121C", "Texte sur fond blanc"),
    ("ardoise", "Ardoise", "#4A4458", "Texte secondaire sur fond blanc"),
    ("lavande-clair", "Lavande claire", "#F5F0FF", "Texte sur fond sombre"),
    ("lavande", "Lavande", "#B5A8D0", "Texte secondaire sur fond sombre"),
  ],
}
GRADIENTS = [
  ("degrade-pin", "Dégradé du pin", 180, [("#FF1E8E", 0), ("#FF1E6E", 55), ("#FF2E38", 100)]),
  ("degrade-principal", "Dégradé principal", 135, [("#E91E63", 0), ("#6A1B9A", 60), ("#4B1174", 100)]),
  ("degrade-ciel-de-nuit", "Ciel de nuit", 135, [("#362268", 0), ("#6B2FC5", 42), ("#C026D3", 78), ("#F4247C", 100)]),
  ("degrade-editorial", "Éditorial", 135, [("#E91E63", 0), ("#FBBF24", 100)]),
  ("degrade-texte-chaud", "Texte chaud", 90, [("#FFD88A", 0), ("#FF9EC4", 100)]),
]

def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
def cmyk(h):
    r, g, b = [c / 255 for c in rgb(h)]
    k = 1 - max(r, g, b)
    if k == 1: return (0, 0, 0, 100)
    return tuple(round(v * 100) for v in ((1-r-k)/(1-k), (1-g-k)/(1-k), (1-b-k)/(1-k), k))

out = {"note": "Valeurs CMJN calculées automatiquement depuis le RVB, à faire valider par l'imprimeur (profil Fogra39 conseillé).", "couleurs": {}, "degrades": []}
css = [":root {"]
for group, items in PALETTE.items():
    out["couleurs"][group] = []
    css.append(f"  /* {group} */")
    for key, name, hx, use in items:
        out["couleurs"][group].append({"id": key, "nom": name, "hex": hx, "rvb": rgb(hx), "cmjn": cmyk(hx), "usage": use})
        css.append(f"  --macity-{key}: {hx};")
css.append("  /* degrades */")
for key, name, ang, stops in GRADIENTS:
    st = ", ".join(f"{c} {p}%" for c, p in stops)
    css.append(f"  --macity-{key}: linear-gradient({ang}deg, {st});")
    out["degrades"].append({"id": key, "nom": name, "angle": ang, "arrets": [{"hex": c, "position": p} for c, p in stops]})
css.append("}")
os.makedirs(ROOT + '/02-couleurs', exist_ok=True)
json.dump(out, open(ROOT + '/02-couleurs/palette-macity.json', 'w'), ensure_ascii=False, indent=2)
open(ROOT + '/02-couleurs/palette-macity.css', 'w').write("\n".join(css) + "\n")

# Nuancier texte (pour Canva, Figma, imprimeur)
lines = ["NUANCIER MACITY", "", "Nom | HEX | RVB | CMJN (approx.) | Usage", ""]
for group, items in out["couleurs"].items():
    lines.append(f"[{group.upper()}]")
    for c in items:
        lines.append(f"{c['nom']} | {c['hex']} | {', '.join(map(str, c['rvb']))} | {', '.join(map(str, c['cmjn']))} | {c['usage']}")
    lines.append("")
lines.append(out["note"])
open(ROOT + '/02-couleurs/nuancier-macity.txt', 'w').write("\n".join(lines) + "\n")

# Degrades en PNG (1920x1080) pour fonds de visuels
gd = ROOT + '/04-elements-graphiques/degrades'
os.makedirs(gd, exist_ok=True)
import math
W, H = 1920, 1080
for key, name, ang, stops in GRADIENTS:
    img = Image.new('RGB', (W, H)); px = img.load()
    a = math.radians(ang - 90)  # CSS : 0deg = vers le haut
    dx, dy = math.cos(a), math.sin(a)
    L = abs(W * dx) + abs(H * dy)
    cols = [(rgb(c), p / 100) for c, p in stops]
    # ligne par ligne via numpy pour la vitesse
    import numpy as np
    xs, ys = np.meshgrid(np.arange(W) - W / 2, np.arange(H) - H / 2)
    t = np.clip((xs * dx + ys * dy) / L + 0.5, 0, 1)
    arr = np.zeros((H, W, 3))
    for ch in range(3):
        arr[..., ch] = np.interp(t, [p for _, p in cols], [c[ch] for c, _ in cols])
    Image.fromarray(arr.astype('uint8')).save(f'{gd}/{key}.png')
print('ok')

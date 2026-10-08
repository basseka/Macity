# Drapeaux MaCity

Trois formes, chacune en recto-verso (page 1 = recto, mât à gauche ; page 2 = verso, mât à droite). Échelle 1:1, fond perdu de 2 cm autour de la ligne de coupe.

| Fichier | Forme | Taille finie |
|---|---|---|
| `drapeau-plume-recto-verso.pdf` | Plume | 80 x 300 cm |
| `drapeau-goutte-recto-verso.pdf` | Goutte | 80 x 220 cm |
| `drapeau-voile-recto-verso.pdf` | Voile (rectangulaire) | 80 x 300 cm |

`apercu-drapeaux-avec-ligne-de-coupe.png` : les 6 faces, avec la ligne de coupe en pointillés (absente des PDF d'impression).

Les formes sont génériques : si l'imprimeur fournit son gabarit, recaler le visuel dessus (modifier `path`, `bleed` et les positions dans `_sources/gen_drapeaux.py`, puis relancer le script et le rendu Chrome).

    python3 _sources/gen_drapeaux.py
    google-chrome --headless=new --no-pdf-header-footer --print-to-pdf=drapeau-plume-recto-verso.pdf "file://$PWD/drapeau-plume.html"

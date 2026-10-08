"""Génère les visuels drapeaux MaCity (plume, goutte, voile), recto et verso.

Unités : mm, échelle 1:1. Fond perdu de 20 mm autour de la ligne de coupe.
Le verso est le recto en miroir (mât à droite), textes lisibles normalement.
Sortie : un HTML par forme (2 pages) + une version « guides » avec la ligne de coupe.
Usage : python3 gen_drapeaux.py  puis rendu PDF avec Chrome (voir README).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)
CH = '../charte-graphique'
BLEED = 20
SLEEVE = 100  # bande rose le long du mât (fourreau)

SHAPES = {
    'plume': dict(
        W=800, H=3000, label='Plume 80 x 300 cm',
        path='M0,3000 L0,260 C0,100 140,0 360,0 C620,0 800,140 800,380 L800,2820 Z',
        bleed='M-20,3025 L-20,260 C-20,85 130,-20 360,-20 C635,-20 820,130 820,380 L820,2835 Z',
        pin=(455, 470, 300), word=(455, 1480, 950), tag=(455, 2440, 240),
    ),
    'goutte': dict(
        W=800, H=2200, label='Goutte 80 x 220 cm',
        path='M0,2200 L0,330 C0,120 170,0 430,0 C680,0 800,210 800,520 C800,1080 470,1690 0,2200 Z',
        bleed='M-20,2240 L-20,330 C-20,105 160,-20 430,-20 C695,-20 820,200 820,520 C820,1090 485,1710 -5,2235 Z',
        pin=(450, 300, 250), word=(400, 1080, 700), tag=None,
    ),
    'voile': dict(
        W=800, H=3000, label='Voile 80 x 300 cm',
        path='M0,0 L800,0 L800,2800 L0,3000 Z',
        bleed='M-20,-20 L820,-20 L820,2815 L-20,3025 Z',
        pin=(455, 330, 300), word=(455, 1370, 950), tag=(455, 2380, 240),
    ),
}

FONTS = f"""
@font-face {{ font-family: InterLogo; src: url({CH}/03-typographies/Inter/Inter-ExtraBold.ttf); font-weight: 800; }}
@font-face {{ font-family: Poppins; src: url({CH}/03-typographies/Poppins/Poppins-ExtraBold.ttf); font-weight: 800; }}
"""


def side_svg(name, s, verso, guides):
    W, H = s['W'], s['H']
    PW, PH = W + 2 * BLEED, H + 2 * BLEED
    mx = (lambda x: W - x) if verso else (lambda x: x)
    flip = f'translate({W},0) scale(-1,1)' if verso else ''
    sid = f'{name}{"v" if verso else "r"}'
    strip_x = W - SLEEVE - BLEED if verso else -BLEED

    px, py, pw = s['pin']
    wx, wy, wfs = s['word']
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}mm" height="{PH}mm" viewBox="{-BLEED} {-BLEED} {PW} {PH}">',
        '<defs>',
        f'<clipPath id="m{sid}"><path d="{s["bleed"]}" transform="{flip}"/></clipPath>',
        f'<linearGradient id="bg{sid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1A0A38"/><stop offset=".5" stop-color="#1A0F2E"/><stop offset="1" stop-color="#0A0514"/></linearGradient>',
        f'<radialGradient id="g1{sid}" cx="{mx(560)/W}" cy=".3" r=".55"><stop offset="0" stop-color="#FF1E8E" stop-opacity=".45"/><stop offset="1" stop-color="#FF1E8E" stop-opacity="0"/></radialGradient>',
        f'<radialGradient id="g2{sid}" cx="{mx(240)/W}" cy=".72" r=".55"><stop offset="0" stop-color="#6A1B9A" stop-opacity=".6"/><stop offset="1" stop-color="#6A1B9A" stop-opacity="0"/></radialGradient>',
        f'<linearGradient id="st{sid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF1E8E"/><stop offset=".55" stop-color="#FF1E6E"/><stop offset="1" stop-color="#FF2E38"/></linearGradient>',
        '</defs>',
        f'<g clip-path="url(#m{sid})">',
        f'<rect x="{-BLEED}" y="{-BLEED}" width="{PW}" height="{PH}" fill="url(#bg{sid})"/>',
        f'<rect x="{-BLEED}" y="{-BLEED}" width="{PW}" height="{PH}" fill="url(#g1{sid})"/>',
        f'<rect x="{-BLEED}" y="{-BLEED}" width="{PW}" height="{PH}" fill="url(#g2{sid})"/>',
        f'<rect x="{strip_x}" y="{-BLEED}" width="{SLEEVE + BLEED}" height="{PH}" fill="url(#st{sid})"/>',
        '</g>',
        f'<image href="{CH}/01-logos/svg/macity-pin-couleur.svg" x="{mx(px) - pw/2}" y="{py - pw*1020/840/2}" width="{pw}" height="{pw*1020/840}"/>',
        f'<text transform="translate({mx(wx)},{wy}) rotate(-90)" text-anchor="middle" dominant-baseline="central" '
        f'font-family="InterLogo" font-weight="800" font-size="{wfs * 0.3528:.1f}" letter-spacing="-{wfs*0.3528*0.03:.1f}" fill="#fff">'
        f'Ma<tspan fill="#FF1E8E">City</tspan></text>',
    ]
    if s['tag']:
        tx, ty, tfs = s['tag']
        parts.append(
            f'<text transform="translate({mx(tx)},{ty}) rotate(-90)" text-anchor="middle" dominant-baseline="central" '
            f'font-family="Poppins" font-weight="800" font-size="{tfs*0.3528:.1f}" fill="#fff">'
            f'L\'app de <tspan fill="#FF1E8E">ta ville</tspan></text>')
    if guides:
        parts.append(f'<path d="{s["path"]}" transform="{flip}" fill="none" stroke="#22D3EE" stroke-width="4" stroke-dasharray="20 12"/>')
        side = 'mât à droite' if verso else 'mât à gauche'
        parts.append(f'<text x="{W/2}" y="{H + BLEED - 4}" text-anchor="middle" font-family="Poppins" font-size="0" fill="#000">{side}</text>')
    parts.append('</svg>')
    return '\n'.join(parts), PW, PH


def page(name, s, guides):
    pages, size = [], None
    for verso in (False, True):
        svg, PW, PH = side_svg(name, s, verso, guides)
        size = (PW, PH)
        pages.append(f'<div class="pg">{svg}</div>')
    PW, PH = size
    bg = '#fff'
    return f"""<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>Drapeau {s['label']}</title>
<style>{FONTS}
@page {{ size: {PW}mm {PH}mm; margin: 0; }}
html, body {{ margin: 0; padding: 0; background: {bg}; }}
body {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
.pg {{ width: {PW}mm; height: {PH}mm; overflow: hidden; break-after: page; }}
.pg svg {{ display: block; }}
</style></head><body>
<!-- Page 1 : recto (mât à gauche). Page 2 : verso (mât à droite). Fond perdu {BLEED} mm. -->
{''.join(pages)}
</body></html>"""


for name, s in SHAPES.items():
    with open(os.path.join(OUT, f'drapeau-{name}.html'), 'w') as f:
        f.write(page(name, s, guides=False))
    with open(os.path.join(HERE, f'guides-{name}.html'), 'w') as f:
        f.write(page(name, s, guides=True).replace(f"url({CH}", f"url(../{CH}").replace(f'href="{CH}', f'href="../{CH}'))
print('ok')

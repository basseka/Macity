import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

ROOT = '/home/carlos.basseka@celadodc-rswl.com/Bureau/cba/appli/pulz_app/communication/charte-graphique'
OUT = ROOT + '/01-logos/svg'
os.makedirs(OUT, exist_ok=True)
font = TTFont(ROOT + '/03-typographies/Inter/Inter-ExtraBold.ttf')
gs = font.getGlyphSet(); cmap = font.getBestCmap()
cap = font['OS/2'].sCapHeight

PIN = ("M 100 8 C 145 8, 180 42, 180 86 C 180 130, 152 158, 122 184 "
       "C 113 192, 107 198, 103 202 C 101 204, 99 204, 97 202 "
       "C 93 198, 87 192, 78 184 C 48 158, 20 130, 20 86 C 20 42, 55 8, 100 8 Z")
HOLE = "M 78 83 A 22 22 0 1 0 122 83 A 22 22 0 1 0 78 83 Z"

from fontTools.pens.boundsPen import BoundsPen

def text_bbox(txt):
    xmin = xmax = None; x = 0
    for ch in txt:
        g = cmap[ord(ch)]
        bp = BoundsPen(gs); gs[g].draw(bp)
        if bp.bounds:
            l, r = x + bp.bounds[0], x + bp.bounds[2]
            xmin = l if xmin is None else min(xmin, l); xmax = r if xmax is None else max(xmax, r)
        x += font['hmtx'][g][0]
    return xmin, xmax

def fit_text(txt, left, right, baseline):
    # Ajuste l'echelle pour que le mot occupe exactement [left, right]
    xmin, xmax = text_bbox(txt)
    s = (right - left) / (xmax - xmin)
    return text_paths(txt, left - xmin * s, baseline, s * cap)

def text_paths(txt, x0, baseline, capH):
    s = capH / cap
    out = []; x = 0
    lsb0 = None
    for ch in txt:
        g = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x0 + x * s, baseline)))
        out.append((ch, pen.getCommands()))
        x += font['hmtx'][g][0]
    # shift so the left edge of M sits at x0
    return out, x * s

def defs(mono):
    if mono:
        return ''
    return '''<defs>
  <linearGradient id="pinBody" x1="50%" y1="0%" x2="50%" y2="100%">
    <stop offset="0%" stop-color="#FF1E8E"/><stop offset="55%" stop-color="#FF1E6E"/><stop offset="100%" stop-color="#FF2E38"/>
  </linearGradient>
  <radialGradient id="pinHighlight" cx="35%" cy="22%" r="42%">
    <stop offset="0%" stop-color="#FFD2E1" stop-opacity="0.75"/><stop offset="100%" stop-color="#FFD2E1" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="pinHole" cx="40%" cy="40%" r="80%">
    <stop offset="0%" stop-color="#1A0822"/><stop offset="100%" stop-color="#06061B"/>
  </radialGradient>
</defs>'''

def pin_group(transform, mono):
    if mono:
        return f'<g transform="{transform}"><path fill="{mono}" fill-rule="evenodd" d="{PIN} {HOLE}"/></g>'
    return (f'<g transform="{transform}"><path fill="url(#pinBody)" d="{PIN}"/>'
            f'<circle cx="100" cy="83" r="22" fill="url(#pinHole)"/>'
            f'<path fill="url(#pinHighlight)" opacity="0.7" d="{PIN}"/></g>')

def horizontal(name, ma, city, mono=None):
    # Proportions reprises du logo PNG officiel (1275 x 450)
    s = 245 / 160
    tr = f'translate({40 - 20 * s:.2f} {70 - 8 * s:.2f}) scale({s:.4f})'
    glyphs, w = fit_text('MaCity', 348, 1212, 289)
    paths = ''.join(f'<path fill="{ma if i < 2 else city}" d="{d}"/>' for i, (_, d) in enumerate(glyphs))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1275 450" width="1275" height="450">'
           f'{defs(mono)}{pin_group(tr, mono)}{paths}</svg>')
    open(f'{OUT}/{name}.svg', 'w').write(svg)

def vertical(name, ma, city, mono=None):
    s = 300 / 160
    W = 1000
    tr = f'translate({W/2 - 100 * s:.2f} {40 - 8 * s:.2f}) scale({s:.4f})'
    glyphs, w = fit_text('MaCity', 200, W - 200, 580)
    paths = ''.join(f'<path fill="{ma if i < 2 else city}" d="{d}"/>' for i, (_, d) in enumerate(glyphs))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} 720" width="{W}" height="720">'
           f'{defs(mono)}{pin_group(tr, mono)}{paths}</svg>')
    open(f'{OUT}/{name}.svg', 'w').write(svg)

def pin(name, mono=None):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="16 4 168 204" width="840" height="1020">'
           f'{defs(mono)}{pin_group("", mono)}</svg>')
    open(f'{OUT}/{name}.svg', 'w').write(svg)

ROSE, NUIT = '#FF1E8E', '#1A0F2E'
horizontal('macity-logo-couleur-fond-sombre', '#FFFFFF', ROSE)
horizontal('macity-logo-couleur-fond-clair', NUIT, ROSE)
horizontal('macity-logo-noir', '#000000', '#000000', '#000000')
horizontal('macity-logo-blanc', '#FFFFFF', '#FFFFFF', '#FFFFFF')
vertical('macity-logo-vertical-fond-sombre', '#FFFFFF', ROSE)
vertical('macity-logo-vertical-fond-clair', NUIT, ROSE)
pin('macity-pin-couleur')
pin('macity-pin-noir', '#000000')
pin('macity-pin-blanc', '#FFFFFF')
print(sorted(os.listdir(OUT)))

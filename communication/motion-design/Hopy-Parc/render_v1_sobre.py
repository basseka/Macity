"""Motion design Hopy Parc (Beauzelle) : accroche, plans de la vidéo du parc,
collage photos, offre MaCity -50 % sur la 2e entrée, écran de fin.

Usage : python render.py [sortie.mp4]       (PREVIEW=1.0,5.2 pour des images fixes)
Médias : src/vf/NNNN.jpg (images de la vidéo du parc, 30 i/s, 1080x1920),
src/raw/p*.png et cover.png (photos de la fiche), assets/ (polices, logos, badges).
Rythme : coupes calées sur 120 BPM (0,5 s), pour poser une musique ensuite.
"""
import math, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, 'assets')
SRC = os.path.join(HERE, 'src')
W, H, FPS = 1080, 1920, 30
ROSE, NUIT, BLANC = (255, 30, 142), (14, 6, 28), (255, 255, 255)
JAUNE = (255, 214, 0)
BEAT = 0.5

def F(name, size):
    return ImageFont.truetype(os.path.join(A, name), size)

def ease(x):  # ease out cubic
    x = max(0.0, min(1.0, x)); return 1 - (1 - x) ** 3

def back(x):  # ease out back (léger rebond)
    x = max(0.0, min(1.0, x)); c = 1.70158
    return 1 + (c + 1) * (x - 1) ** 3 + c * (x - 1) ** 2

# ---------- médias ----------
_vf = {}
def vframe(i):
    i = max(0, min(341, int(i)))
    if i not in _vf:
        _vf[i] = Image.open(os.path.join(SRC, 'vf', '%04d.jpg' % i)).convert('RGB')
        if len(_vf) > 60: _vf.pop(next(iter(_vf)))
    return _vf[i]

def cover(im, w, h):
    s = max(w / im.width, h / im.height)
    im = im.resize((math.ceil(im.width * s), math.ceil(im.height * s)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))

def zoom(im, z):
    cw, ch = int(W / z), int(H / z)
    x, y = (im.width - cw) // 2, (im.height - ch) // 2
    return im.crop((x, y, x + cw, y + ch)).resize((W, H), Image.BILINEAR)

PHOTOS = [Image.open(os.path.join(SRC, 'raw', f)).convert('RGB')
          for f in ['p4.png', 'p1.png', 'p3.png', 'p2.png', 'p5.png']]
MASCOTTE = Image.open(os.path.join(SRC, 'raw', 'cover.png')).convert('RGB')
LOGO = Image.open(os.path.join(A, 'macity-logo-couleur-fond-sombre.png')).convert('RGBA')
B_APPLE = Image.open(os.path.join(A, 'badge-app-store-fr.png')).convert('RGBA')
B_GOOGLE = Image.open(os.path.join(A, 'badge-google-play-fr.png')).convert('RGBA')

# plans de la vidéo source (début, fin en s), dans l'ordre du montage
SHOTS = [
    (3.07, 3.46),   # 1000 m² de jeux
    (3.67, 3.92),   # climatisé
    (4.02, 4.55),   # mini zone 0-3 ans
    (5.08, 5.49),   # anniversaire
    (5.52, 6.02),   # toboggans
    (6.12, 6.55),   # baby-foot
    (6.68, 7.02),   # laser game
]

# ---------- planning (s) ----------
T_HOOK, T_FACADE, T_CUTS = 0.0, 2.0, 3.0
SHOT_LEN = 0.75                                   # 1,5 temps par plan
T_PHOTOS = T_CUTS + SHOT_LEN * len(SHOTS)         # 8.25
T_OFFRE = T_PHOTOS + 3.0                          # 11.25
T_FIN = T_OFFRE + 4.5                             # 15.75
DUR = T_FIN + 4.5                                 # 20.25

# ---------- dessin ----------
def text_c(d, y, s, font, fill=BLANC, stroke=0, sfill=NUIT, cx=W // 2):
    w = d.textlength(s, font=font)
    d.text((cx - w / 2, y), s, font=font, fill=fill, stroke_width=stroke, stroke_fill=sfill)

def sticker(img, text, cx, cy, t, size=74, bg=ROSE, fg=BLANC, rot=-4):
    """Étiquette arrondie qui arrive avec un rebond."""
    if t <= 0: return
    f = F('Anton-Regular.ttf', size)
    tw = int(ImageDraw.Draw(img).textlength(text, font=f))
    pw, ph = tw + 64, size + 44
    s = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.rounded_rectangle((0, 0, pw - 1, ph - 1), radius=ph // 2, fill=bg)
    d.text((32, 12), text, font=f, fill=fg)
    k = back(t / 0.3)
    s = s.resize((max(1, int(pw * k)), max(1, int(ph * k))), Image.BILINEAR).rotate(rot, expand=True, resample=Image.BICUBIC)
    img.paste(s, (int(cx - s.width / 2), int(cy - s.height / 2)), s)

def polaroid(ph, w, h, label=None):
    pad, bot = 18, 18
    card = Image.new('RGBA', (w + 2 * pad, h + pad + bot), (255, 255, 255, 255))
    card.paste(cover(ph, w, h), (pad, pad))
    return card

def paste_rot(img, card, cx, cy, ang, k=1.0, alpha=1.0):
    if k <= 0.01: return
    c = card.resize((max(1, int(card.width * k)), max(1, int(card.height * k))), Image.BILINEAR)
    c = c.rotate(ang, expand=True, resample=Image.BICUBIC)
    sh = Image.new('RGBA', c.size, (0, 0, 0, 0))
    sh.putalpha(c.getchannel('A').point(lambda v: int(v * 0.45 * alpha)))
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    img.paste(sh, (int(cx - c.width / 2 + 10), int(cy - c.height / 2 + 16)), sh)
    if alpha < 1: c.putalpha(c.getchannel('A').point(lambda v: int(v * alpha)))
    img.paste(c, (int(cx - c.width / 2), int(cy - c.height / 2)), c)

def flash(img, t, dur=0.12, a=90):
    if 0 <= t < dur:
        ov = Image.new('RGB', img.size, BLANC)
        img.paste(Image.blend(img, ov, a / 255 * (1 - t / dur)))

def grad_bg(top, bottom):
    g = Image.new('RGB', (1, 256))
    for y in range(256):
        k = y / 255
        g.putpixel((0, y), tuple(int(top[i] * (1 - k) + bottom[i] * k) for i in range(3)))
    return g.resize((W, H))

BG_NUIT = grad_bg((40, 10, 70), NUIT)
BG_ROSE = grad_bg((255, 60, 160), (120, 20, 140))

def darken(im, a):
    return Image.blend(im, Image.new('RGB', im.size, NUIT), a)

# ---------- scènes ----------
def s_hook(t):
    img = BG_NUIT.copy()
    # mascotte en fond (photo de la fiche)
    card = polaroid(MASCOTTE, 460, 640)
    k = back((t - 0.6) / 0.4)
    paste_rot(img, card, W // 2 + 40, 1240, 6, k)
    d = ImageDraw.Draw(img)
    words = [('SORTIE', 0.0), ('EN FAMILLE', 0.25), ('CE WEEK-END ?', 0.5)]
    for i, (w_, t0) in enumerate(words):
        p = ease((t - t0) / 0.25)
        if p <= 0: continue
        f = F('Anton-Regular.ttf', 150 if i < 2 else 120)
        y = 260 + i * 175 - int((1 - p) * 80)
        col = ROSE if i == 1 else BLANC
        text_c(d, y, w_, f, fill=col)
    flash(img, t)
    return img

def s_facade(t):
    src = 2.58 + min(t, 0.99) * 0.42          # plan façade ralenti
    img = zoom(vframe(src * FPS), 1.0 + 0.06 * t)
    img = darken(img, 0.15)
    sticker(img, 'BEAUZELLE · TOULOUSE', W // 2, 1560, t - 0.1, size=70, rot=-3)
    flash(img, t)
    return img

def s_cuts(t):
    i = min(int(t / SHOT_LEN), len(SHOTS) - 1)
    lt = t - i * SHOT_LEN
    a, b = SHOTS[i]
    src = a + (b - a) * min(lt / SHOT_LEN, 1)
    img = zoom(vframe(src * FPS), 1.04 + 0.05 * lt / SHOT_LEN)
    flash(img, lt, a=70)
    return img

def s_photos(t):
    img = BG_ROSE.copy()
    d = ImageDraw.Draw(img)
    p = ease(t / 0.3)
    text_c(d, 150 - int((1 - p) * 60), 'ILS VONT', F('Anton-Regular.ttf', 140), fill=BLANC)
    text_c(d, 300 - int((1 - p) * 60), 'ADORER', F('Anton-Regular.ttf', 170), fill=JAUNE)
    spots = [(300, 760, -7, 380, 300), (790, 700, 6, 360, 380), (540, 1120, -2, 520, 380),
             (290, 1500, 5, 380, 300), (790, 1470, -6, 360, 340)]
    for k_, ((cx, cy, ang, w, h), ph) in enumerate(zip(spots, PHOTOS)):
        lt = t - 0.3 - k_ * BEAT * 0.5
        if lt <= 0: continue
        drop = 1 - ease(lt / 0.35)
        paste_rot(img, polaroid(ph, w, h), cx, cy - int(drop * 260), ang + drop * 12, 1.0 + 0.25 * drop)
    return img

def s_offre(t):
    src = 9.0 + min(t / 4.5, 1) * 2.35               # plan large de la structure, ralenti
    bg = zoom(vframe(src * FPS), 1.08)
    img = darken(bg.filter(ImageFilter.GaussianBlur(6)), 0.55)
    d = ImageDraw.Draw(img)
    # pastille « OFFRE MACITY »
    if t > 0.1:
        sticker(img, 'OFFRE MACITY', W // 2, 470, t - 0.1, size=72, rot=0)
    # -50 % qui claque
    if t > 0.5:
        k = back((t - 0.5) / 0.35)
        f = F('Anton-Regular.ttf', 400)
        s = '-50%'
        tw = int(d.textlength(s, font=f))
        lay = Image.new('RGBA', (tw + 60, 560), (0, 0, 0, 0))
        ImageDraw.Draw(lay).text((30, 0), s, font=f, fill=ROSE, stroke_width=10, stroke_fill=BLANC)
        pulse = 1 + 0.03 * math.sin(max(0, t - 0.9) * math.pi * 2 / BEAT) if t > 0.9 else 1
        kk = k * pulse
        lay = lay.resize((max(1, int(lay.width * kk)), max(1, int(lay.height * kk))), Image.BILINEAR).rotate(-4, expand=True, resample=Image.BICUBIC)
        img.paste(lay, (W // 2 - lay.width // 2, 880 - lay.height // 2), lay)
        flash(img, t - 0.5, a=110)
    d = ImageDraw.Draw(img)
    if t > 1.1:
        p = ease((t - 1.1) / 0.3)
        text_c(d, 1180 + int((1 - p) * 50), 'SUR LA 2e ENTRÉE', F('Anton-Regular.ttf', 120), fill=BLANC)
    if t > 1.6:
        p = ease((t - 1.6) / 0.3)
        text_c(d, 1360 + int((1 - p) * 40), 'Hopy Parc · 167 rue du Riou, Beauzelle', F('Poppins-SemiBold.ttf', 44), fill=(235, 225, 245))
    if t > 2.2:
        sticker(img, 'DANS L’APPLI MACITY', W // 2, 1560, t - 2.2, size=64, bg=JAUNE, fg=NUIT, rot=3)
    return img

def s_fin(t):
    img = BG_NUIT.copy()
    d = ImageDraw.Draw(img)
    p = ease(t / 0.4)
    lw = 620
    lg = LOGO.resize((lw, int(LOGO.height * lw / LOGO.width)), Image.LANCZOS)
    img.paste(lg, (W // 2 - lw // 2, 330 - int((1 - p) * 60)), lg)
    if t > 0.3:
        q = ease((t - 0.3) / 0.3)
        y0 = 720 + int((1 - q) * 50)
        text_c(d, y0, 'RÉCUPÈRE TON', F('Anton-Regular.ttf', 120))
        text_c(d, y0 + 150, '-50 % HOPY PARC', F('Anton-Regular.ttf', 120), fill=ROSE)
    if t > 0.7:
        q = ease((t - 0.7) / 0.3)
        text_c(d, 1080 + int((1 - q) * 40), "Télécharge MaCity, c'est gratuit", F('Poppins-SemiBold.ttf', 50), fill=(230, 220, 240))
    if t > 1.0:
        q = back((t - 1.0) / 0.35)
        bw = 400
        for i, b in enumerate([B_APPLE, B_GOOGLE]):
            bb = b.resize((bw, int(b.height * bw / b.width)), Image.LANCZOS)
            k = max(0.01, q)
            bb = bb.resize((max(1, int(bb.width * k)), max(1, int(bb.height * k))), Image.BILINEAR)
            cx = W // 2 + (-215 if i == 0 else 215)
            img.paste(bb, (cx - bb.width // 2, 1300 - bb.height // 2), bb)
    if t > 1.4:
        text_c(d, 1480, 'Rubrique Famille · Offres', F('Poppins-Medium.ttf', 40), fill=(170, 150, 200))
    flash(img, t)
    return img

SCENES = [(T_HOOK, s_hook), (T_FACADE, s_facade), (T_CUTS, s_cuts),
          (T_PHOTOS, s_photos), (T_OFFRE, s_offre), (T_FIN, s_fin)]

def frame(t):
    for start, fn in reversed(SCENES):
        if t >= start:
            return fn(t - start)

def main():
    prev = os.environ.get('PREVIEW')
    if prev:
        for s in prev.split(','):
            frame(float(s)).save(os.path.join(SRC, 'apercu_%s.jpg' % s), quality=85)
        return
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'MACITY_Hopy_Parc_offre_sans_son.mp4')
    n = int(DUR * FPS)
    p = subprocess.Popen(['ffmpeg', '-nostdin', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                          '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-preset', 'medium',
                          '-crf', '19', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out], stdin=subprocess.PIPE)
    for i in range(n):
        p.stdin.write(frame(i / FPS).tobytes())
    p.stdin.close(); p.wait()
    print(out, f'{DUR:.2f}s')

if __name__ == '__main__':
    main()

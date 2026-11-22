"""Motion design Hopy Parc (Beauzelle), version spectaculaire.

1. La vidéo du parc défile dans des lettres géantes HOPY PARC, la caméra plonge dans le O.
2. Plans de la vidéo : coups de fouet flous, zooms sur le temps, décalage RGB, secousses.
3. Polaroïds qui volent sur rayons tournants + confettis.
4. Compteur -10 % -> -50 %, explosion de confettis, onde de choc.
5. Téléphone qui affiche l'offre dans l'appli, badges des stores.

Usage : python render.py [sortie.mp4]       (PREVIEW=1.0,5.2 pour des images fixes)
Rythme : 120 BPM (temps = 0,5 s), pour poser une musique ensuite.
"""
import math, os, random, subprocess, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, 'assets')
SRC = os.path.join(HERE, 'src')
W, H, FPS = 1080, 1920, 30
ROSE, NUIT, BLANC = (255, 30, 142), (14, 6, 28), (255, 255, 255)
JAUNE, VIOLET, CYAN, VERT = (255, 214, 0), (120, 40, 200), (40, 220, 255), (120, 230, 60)
BEAT = 0.5

def F(name, size):
    return ImageFont.truetype(os.path.join(A, name), size)
ANTON = lambda s: F('Anton-Regular.ttf', s)

def clamp(x): return max(0.0, min(1.0, x))
def ease(x): x = clamp(x); return 1 - (1 - x) ** 3
def ease_in(x): x = clamp(x); return x ** 3
def back(x):
    x = clamp(x); c = 1.9
    return 1 + (c + 1) * (x - 1) ** 3 + c * (x - 1) ** 2

# ---------- médias ----------
_vf = {}
def vframe(i):
    i = max(0, min(341, int(i)))
    if i not in _vf:
        _vf[i] = Image.open(os.path.join(SRC, 'vf', '%04d.jpg' % i)).convert('RGB')
        if len(_vf) > 40: _vf.pop(next(iter(_vf)))
    return _vf[i]

def cover(im, w, h):
    s = max(w / im.width, h / im.height)
    im = im.resize((math.ceil(im.width * s), math.ceil(im.height * s)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))

def zoom(im, z, cx=0.5, cy=0.5):
    cw, ch = W / z, H / z
    x = (im.width - cw) * cx; y = (im.height - ch) * cy
    return im.crop((int(x), int(y), int(x + cw), int(y + ch))).resize((W, H), Image.BILINEAR)

PHOTOS = [Image.open(os.path.join(SRC, 'raw', f)).convert('RGB')
          for f in ['p4.png', 'p1.png', 'p3.png', 'p2.png', 'p5.png']]
OFFRE = Image.open(os.path.join(SRC, 'raw', 'offre.jpg')).convert('RGB')
LOGO = Image.open(os.path.join(A, 'macity-logo-couleur-fond-sombre.png')).convert('RGBA')
B_APPLE = Image.open(os.path.join(A, 'badge-app-store-fr.png')).convert('RGBA')
B_GOOGLE = Image.open(os.path.join(A, 'badge-google-play-fr.png')).convert('RGBA')

SHOTS = [  # plans de la vidéo source (début, fin), s
    (3.07, 3.46),   # 1000 m² de jeux
    (3.67, 3.92),   # climatisé
    (4.02, 4.55),   # mini zone 0-3 ans
    (5.08, 5.49),   # anniversaire
    (5.52, 6.02),   # toboggans
    (6.12, 6.55),   # baby-foot
    (6.68, 7.02),   # laser game
]

# ---------- planning ----------
T_TITRE = 0.0
T_CUTS = 3.0
SHOT_LEN = 0.75
T_PHOTOS = T_CUTS + SHOT_LEN * len(SHOTS)    # 9.0
T_OFFRE = T_PHOTOS + 3.0                     # 12.0
T_FIN = T_OFFRE + 4.0                        # 16.0
DUR = T_FIN + 4.5                            # 20.5

# ---------- effets ----------
def rgb_split(img, d):
    d = int(d)
    if d <= 0: return img
    r, g, b = img.split()
    r = ImageChops.offset(r, d, 0); b = ImageChops.offset(b, -d, 0)
    return Image.merge('RGB', (r, g, b))

def hblur(img, k):
    """Flou de mouvement horizontal (coup de fouet)."""
    if k < 2: return img
    return img.resize((max(1, int(W / k)), H), Image.BILINEAR).resize((W, H), Image.BILINEAR)

def vblur(img, k):
    if k < 2: return img
    return img.resize((W, max(1, int(H / k))), Image.BILINEAR).resize((W, H), Image.BILINEAR)

def shake(img, t, amp, freq=38):
    """Secousse : décalage pseudo aléatoire qui décroît."""
    if amp < 1: return img
    dx = amp * math.sin(t * freq) ; dy = amp * math.cos(t * freq * 1.3)
    z = 1 + 2.4 * amp / W
    big = img.resize((int(W * z) + 2, int(H * z) + 2), Image.BILINEAR)
    x = (big.width - W) / 2 + dx; y = (big.height - H) / 2 + dy
    return big.crop((int(x), int(y), int(x) + W, int(y) + H))

def flash(img, t, dur=0.12, a=110, col=BLANC):
    if 0 <= t < dur:
        return Image.blend(img, Image.new('RGB', img.size, col), a / 255 * (1 - t / dur))
    return img

def darken(im, a): return Image.blend(im, Image.new('RGB', im.size, NUIT), a)

def vignette():
    m = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((-W * 0.35, -H * 0.2, W * 1.35, H * 1.2), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(160))
    return m
VIG = vignette()
def vig(img, a=0.6):
    dark = Image.blend(img, Image.new('RGB', img.size, (0, 0, 0)), a)
    return Image.composite(img, dark, VIG)

# rayons tournants
def make_rays(c1, c2, n=18):
    S = 2400
    r = Image.new('RGB', (S, S), c1)
    d = ImageDraw.Draw(r)
    for i in range(n):
        a0 = i * 2 * math.pi / n; a1 = a0 + math.pi / n
        d.polygon([(S / 2, S / 2), (S / 2 + S * math.cos(a0), S / 2 + S * math.sin(a0)),
                   (S / 2 + S * math.cos(a1), S / 2 + S * math.sin(a1))], fill=c2)
    return r.resize((1200, 1200), Image.LANCZOS)
RAYS_ROSE = make_rays((230, 20, 130), (255, 70, 170))
RAYS_NUIT = make_rays((30, 8, 60), (60, 15, 100))

def rays_bg(rays, t, speed=18, cy=0.5):
    r = rays.rotate(t * speed, resample=Image.BILINEAR)
    s = 2400 / 1200
    r = r.resize((2400, 2400), Image.BILINEAR)
    x = (2400 - W) // 2; y = int(1200 - H * cy)
    return r.crop((x, y, x + W, y + H))

# confettis (déterministes)
CONF_COLS = [ROSE, JAUNE, CYAN, VERT, BLANC, (255, 120, 40)]
def make_burst(seed, n, cx, cy, power=1.0):
    rnd = random.Random(seed)
    ps = []
    for _ in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        v = rnd.uniform(700, 1900) * power
        ps.append(dict(x=cx, y=cy, vx=math.cos(a) * v, vy=math.sin(a) * v - rnd.uniform(200, 700),
                       w=rnd.randint(14, 30), h=rnd.randint(8, 16), col=rnd.choice(CONF_COLS),
                       rot=rnd.uniform(0, 360), vr=rnd.uniform(-720, 720), sp=rnd.uniform(4, 12)))
    return ps

def draw_confetti(img, parts, t):
    if t < 0: return
    d = ImageDraw.Draw(img)
    drag = 2.2
    for p in parts:
        # vitesse freinée + gravité
        k = (1 - math.exp(-drag * t)) / drag
        x = p['x'] + p['vx'] * k + 30 * math.sin(t * p['sp'])
        y = p['y'] + p['vy'] * k + 520 * t * t * 0.5
        if y > H + 50: continue
        ang = math.radians(p['rot'] + p['vr'] * t)
        fl = abs(math.cos(t * p['sp']))  # effet de rotation 3D
        hw, hh = p['w'] / 2, p['h'] / 2 * (0.3 + 0.7 * fl)
        ca, sa = math.cos(ang), math.sin(ang)
        pts = [(x + ca * dx - sa * dy, y + sa * dx + ca * dy) for dx, dy in ((-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh))]
        d.polygon(pts, fill=p['col'])

def text_layer(s, size, fill, stroke=0, sfill=NUIT, glow=None, pad=60):
    f = ANTON(size)
    tmp = ImageDraw.Draw(Image.new('L', (1, 1)))
    l, t_, r, b = tmp.textbbox((0, 0), s, font=f, stroke_width=stroke)
    lay = Image.new('RGBA', (r - l + 2 * pad, b - t_ + 2 * pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.text((pad - l, pad - t_), s, font=f, fill=fill, stroke_width=stroke, stroke_fill=sfill)
    if glow:
        g = Image.new('RGBA', lay.size, glow + (0,))
        g.putalpha(lay.getchannel('A').filter(ImageFilter.GaussianBlur(22)).point(lambda v: min(255, v * 2)))
        g.alpha_composite(lay); lay = g
    return lay

_tl = {}
def text_cached(*a, **k):
    key = (a, tuple(sorted(k.items())))
    if key not in _tl: _tl[key] = text_layer(*a, **k)
    return _tl[key]

def put(img, lay, cx, cy, k=1.0, rot=0, alpha=1.0):
    if k <= 0.01 or alpha <= 0: return
    if k != 1: lay = lay.resize((max(1, int(lay.width * k)), max(1, int(lay.height * k))), Image.BILINEAR)
    if rot: lay = lay.rotate(rot, expand=True, resample=Image.BICUBIC)
    if alpha < 1:
        lay = lay.copy(); lay.putalpha(lay.getchannel('A').point(lambda v: int(v * alpha)))
    img.paste(lay, (int(cx - lay.width / 2), int(cy - lay.height / 2)), lay)

def pill(text, size, bg, fg):
    f = ANTON(size)
    tw = int(ImageDraw.Draw(Image.new('L', (1, 1))).textlength(text, font=f))
    pw, ph = tw + 70, size + 46
    s = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.rounded_rectangle((0, 0, pw - 1, ph - 1), radius=ph // 2, fill=bg)
    d.text((35, 12), text, font=f, fill=fg)
    return s

def polaroid(ph, w, h):
    pad = 18
    card = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (255, 255, 255, 255))
    card.paste(cover(ph, w, h), (pad, pad))
    return card

def shadowed(img, c, cx, cy, ang, k=1.0, blur=0):
    if k <= 0.01: return
    c = c.resize((max(1, int(c.width * k)), max(1, int(c.height * k))), Image.BILINEAR)
    if blur >= 2:
        a = c.getchannel('A')
        c = c.resize((max(1, int(c.width / blur)), c.height), Image.BILINEAR).resize(a.size, Image.BILINEAR)
    c = c.rotate(ang, expand=True, resample=Image.BICUBIC)
    sh = Image.new('RGBA', c.size, (0, 0, 0, 0))
    sh.putalpha(c.getchannel('A').point(lambda v: int(v * 0.5)).filter(ImageFilter.GaussianBlur(12)))
    img.paste(sh, (int(cx - c.width / 2 + 12), int(cy - c.height / 2 + 18)), sh)
    img.paste(c, (int(cx - c.width / 2), int(cy - c.height / 2)), c)

# ---------- 1. titre : la vidéo dans les lettres ----------
TITLE_LINES = [('HOPY', 470), ('PARC', 470)]
LETTER_T = [0.0, 0.25, 0.5, 0.75]     # H O P Y ; PARC arrive d'un bloc à 1.0
O_GEOM = None

def title_mask(z, focus):
    """Masque des lettres, agrandi d'un facteur z autour du point focus (centre du O)."""
    m = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(m)
    fx, fy = focus
    for li, (word, size) in enumerate(TITLE_LINES):
        f = ANTON(int(size * z))
        f0 = ANTON(size)
        y0 = 480 + li * 560
        x0 = (W - d.textlength(word, font=f0)) / 2
        X = W / 2 + (x0 - fx) * z; Y = H / 2 + (y0 - fy) * z
        d.text((X, Y), word, font=f, fill=255)
    return m

def letter_mask(t):
    """Apparition lettre par lettre (sans zoom)."""
    m = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(m)
    word, size = TITLE_LINES[0]
    f = ANTON(size)
    x0 = (W - d.textlength(word, font=f)) / 2
    x = x0
    for i, ch in enumerate(word):
        p = t - LETTER_T[i]
        cw = d.textlength(ch, font=f)
        if p > 0:
            k = 1 + 1.6 * (1 - ease(p / 0.22))
            fl = ANTON(int(size * k))
            cwk = d.textlength(ch, font=fl)
            d.text((x + cw / 2 - cwk / 2, 480 + (size - size * k) * 0.6), ch, font=fl, fill=255)
        x += cw
    if t > 1.0:
        p = ease((t - 1.0) / 0.25)
        word2 = TITLE_LINES[1][0]
        x2 = (W - d.textlength(word2, font=f)) / 2
        d.text((x2 + (1 - p) * 900, 1040), word2, font=f, fill=255)
    return m

def o_geom():
    """Centre du O et rectangle de son trou (contre-forme), en coordonnées écran."""
    d = ImageDraw.Draw(Image.new('L', (1, 1)))
    f = ANTON(470)
    x0 = (W - d.textlength('HOPY', font=f)) / 2
    l, t_, r, b = d.textbbox((0, 0), 'O', font=f)
    ox = x0 + d.textlength('H', font=f)
    L, T, R, B = ox + l, 480 + t_, ox + r, 480 + b
    dx, dy = (R - L) * 0.27, (B - T) * 0.14
    return ((L + R) / 2, (T + B) / 2), (L + dx, T + dy, R - dx, B - dy)

def s_titre(t):
    global O_GEOM
    if O_GEOM is None: O_GEOM = o_geom()
    vid = zoom(vframe((9.0 + t * 0.6) * FPS), 1.0)
    bg = rays_bg(RAYS_NUIT, t, speed=25)
    if t < 2.0:
        m = letter_mask(t)
        img = Image.composite(vid, bg, m)
        # contour lumineux
        edge = m.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(5))
        img = Image.composite(Image.new('RGB', img.size, ROSE), img, edge)
        d = ImageDraw.Draw(img)
        if t > 1.35:
            p = ease((t - 1.35) / 0.3)
            pl = pill('ESPACE DE JEUX GÉANT · BEAUZELLE', 54, JAUNE, NUIT)
            put(img, pl, W / 2, 1720 + (1 - p) * 200, k=1.0)
        hits = [x for x in LETTER_T + [1.0] if x <= t]
        last = max(hits) if hits else -1
        img = shake(img, t, 26 * math.exp(-(t - last) * 14) if last >= 0 else 0)
        img = flash(img, t - last, dur=0.08, a=70) if last >= 0 else img
        return vig(img, 0.5)
    # plongée dans le trou du O, qui montre le plan suivant : 2.0 -> 3.0
    p = (t - 2.0) / 1.0
    z = 1 + 15 * ease_in(p)
    (fx, fy), (cl, ct, cr, cb) = O_GEOM
    m = title_mask(z, (fx, fy))
    img = Image.composite(vid, bg, m)
    hole = zoom(vframe(3.07 * FPS), 1.36)
    hm = Image.new('L', (W, H), 0)
    X = lambda x: W / 2 + (x - fx) * z
    Y = lambda y: H / 2 + (y - fy) * z
    box = (X(cl), Y(ct), X(cr), Y(cb))
    ImageDraw.Draw(hm).rounded_rectangle(box, radius=(box[2] - box[0]) / 2, fill=255)
    img = Image.composite(hole, img, hm)
    img = vblur(img, 1 + 5 * ease_in(p))
    return img

# ---------- 2. plans rapides ----------
def s_cuts(t):
    i = min(int(t / SHOT_LEN), len(SHOTS) - 1)
    lt = t - i * SHOT_LEN
    a, b = SHOTS[i]
    src = a + (b - a) * clamp(lt / SHOT_LEN)
    z = 1.04 + 0.32 * (1 - ease(lt / 0.25))          # coup de zoom sur le temps
    img = zoom(vframe(src * FPS), z)
    # fouet : fin du plan qui file vers la gauche, début du suivant qui arrive de la droite
    out_p = clamp((lt - (SHOT_LEN - 0.12)) / 0.12)
    in_p = 1 - clamp(lt / 0.12)
    if i < len(SHOTS) - 1 and out_p > 0:
        img = hblur(img, 1 + 30 * out_p)
        img = ImageChops.offset(img, -int(W * 0.6 * out_p * out_p), 0)
    if i > 0 and in_p > 0:
        img = hblur(img, 1 + 30 * in_p)
        img = ImageChops.offset(img, int(W * 0.6 * in_p * in_p), 0)
    img = rgb_split(img, 22 * (1 - ease(lt / 0.2)))
    img = shake(img, t, 14 * math.exp(-lt * 12))
    return vig(img, 0.35)

# ---------- 3. polaroïds ----------
SPOTS = [(300, 760, -8, 380, 300), (790, 700, 7, 360, 380), (540, 1120, -2, 520, 380),
         (290, 1500, 6, 380, 300), (790, 1470, -7, 360, 340)]
CONF3 = make_burst(3, 140, W / 2, 1100, 0.9)

def s_photos(t):
    img = rays_bg(RAYS_ROSE, t, speed=30)
    img = vig(img, 0.45)
    titre1 = text_cached('ILS VONT', 150, BLANC, stroke=6, sfill=NUIT)
    titre2 = text_cached('ADORER', 200, JAUNE, stroke=8, sfill=NUIT, glow=ROSE)
    p = back(t / 0.3)
    put(img, titre1, W / 2, 210, k=p)
    put(img, titre2, W / 2, 390, k=back((t - 0.15) / 0.3), rot=-3)
    for k_, ((cx, cy, ang, w, h), ph) in enumerate(zip(SPOTS, PHOTOS)):
        lt = t - 0.35 - k_ * 0.25
        if lt <= 0: continue
        q = ease(lt / 0.3)
        side = -1 if cx < W / 2 else 1
        x = cx + side * (1 - q) * 900
        shadowed(img, polaroid(ph, w, h), x, cy, ang + side * (1 - q) * 30, 1.0, blur=1 + 12 * (1 - q))
    draw_confetti(img, CONF3, t - 1.6)
    hits = [0.0, 0.15] + [0.35 + 0.25 * k + 0.25 for k in range(5)]
    last = max([h for h in hits if h <= t], default=-1)
    img = shake(img, t, 16 * math.exp(-(t - last) * 14)) if last >= 0 else img
    return img

# ---------- 4. offre ----------
CONF4a = make_burst(41, 220, W / 2, 900, 1.2)
CONF4b = make_burst(42, 120, W / 2, 900, 0.7)
T_HIT = 1.1

def s_offre(t):
    src = 9.0 + clamp(t / 4.0) * 2.35
    bg = zoom(vframe(src * FPS), 1.1).filter(ImageFilter.GaussianBlur(8))
    rays = rays_bg(RAYS_NUIT, t, speed=-22, cy=900 / H)
    img = Image.blend(darken(bg, 0.5), rays, 0.55 if t > T_HIT else 0.25)
    # onde de choc
    if t > T_HIT:
        p = (t - T_HIT) / 0.6
        if p < 1:
            d = ImageDraw.Draw(img)
            r = 120 + 1100 * ease(p); wdt = int(50 * (1 - p)) + 2
            d.ellipse((W / 2 - r, 900 - r, W / 2 + r, 900 + r), outline=ROSE, width=wdt)
            r2 = 60 + 800 * ease(p)
            d.ellipse((W / 2 - r2, 900 - r2, W / 2 + r2, 900 + r2), outline=JAUNE, width=max(2, wdt // 2))
    put(img, pill('OFFRE MACITY', 76, ROSE, BLANC), W / 2, 430, k=back(t / 0.3))
    # compteur -10 -> -50
    if t < T_HIT:
        steps = [10, 20, 30, 40]
        idx = min(int(t / (T_HIT / 4)), 3)
        lt = t - idx * (T_HIT / 4)
        lay = text_cached('-%d%%' % steps[idx], 300, BLANC, stroke=8, sfill=NUIT)
        put(img, lay, W / 2, 900, k=1 + 0.25 * (1 - ease(lt / 0.15)), alpha=0.85)
        img = shake(img, t, 8 * math.exp(-lt * 15))
    else:
        lt = t - T_HIT
        lay = text_cached('-50%', 370, ROSE, stroke=12, sfill=BLANC, glow=ROSE)
        pulse = 1 + 0.04 * max(0, math.sin((lt - 0.4) * math.pi * 2 / BEAT)) if lt > 0.4 else 1
        put(img, lay, W / 2, 900, k=(2.6 - 1.6 * back(lt / 0.25)) * pulse, rot=-5)
        draw_confetti(img, CONF4a, lt)
        draw_confetti(img, CONF4b, lt - 1.0)
        if lt > 0.35:
            put(img, text_cached('SUR LA 2e ENTRÉE', 130, BLANC, stroke=6, sfill=NUIT), W / 2, 1240,
                k=back((lt - 0.35) / 0.3))
        if lt > 0.75:
            put(img, text_cached('HOPY PARC · BEAUZELLE', 70, JAUNE, stroke=4, sfill=NUIT), W / 2, 1390,
                alpha=ease((lt - 0.75) / 0.3))
        img = shake(img, t, 40 * math.exp(-lt * 7))
        img = rgb_split(img, 26 * math.exp(-lt * 9))
        img = flash(img, lt, dur=0.15, a=200)
    return vig(img, 0.4)

# ---------- 5. téléphone + fin ----------
PHONE_W, PHONE_H = 540, 1100
def make_phone():
    ph = Image.new('RGBA', (PHONE_W, PHONE_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ph)
    d.rounded_rectangle((0, 0, PHONE_W - 1, PHONE_H - 1), radius=80, fill=(20, 20, 24))
    d.rounded_rectangle((4, 4, PHONE_W - 5, PHONE_H - 5), radius=76, outline=(90, 90, 100), width=3)
    sx, sy, sw, sh = 22, 22, PHONE_W - 44, PHONE_H - 44
    scr = Image.new('RGB', (sw, sh), NUIT)
    sd = ImageDraw.Draw(scr)
    # barre du haut de l'appli
    lg = LOGO.resize((200, int(LOGO.height * 200 / LOGO.width)), Image.LANCZOS)
    scr.paste(lg, (30, 70), lg)
    sd.text((30, 140), 'Offres à Toulouse', font=F('Poppins-Bold.ttf', 34), fill=BLANC)
    card = cover(OFFRE, sw - 40, int((sw - 40) * 1350 / 1080))
    m = Image.new('L', card.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=28, fill=255)
    scr.paste(card, (20, 205), m)
    by = 205 + card.height + 30
    sd.rounded_rectangle((20, by, sw - 20, by + 96), radius=48, fill=ROSE)
    f = F('Poppins-Bold.ttf', 36)
    s = "J'en profite"
    sd.text(((sw - sd.textlength(s, font=f)) / 2, by + 24), s, font=f, fill=BLANC)
    sm = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(sm).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=60, fill=255)
    ph.paste(scr, (sx, sy), sm)
    d.rounded_rectangle((PHONE_W / 2 - 80, 36, PHONE_W / 2 + 80, 76), radius=20, fill=(0, 0, 0))
    return ph
PHONE = make_phone()
CONF5 = make_burst(5, 90, W / 2, 700, 0.8)

def s_fin(t):
    img = rays_bg(RAYS_NUIT, t, speed=12, cy=0.42)
    img = vig(img, 0.55)
    # téléphone qui monte en tournant
    p = ease(t / 0.55)
    ang = 14 * (1 - p) + 2 * math.sin(t * 2.2)
    y = 800 + (1 - p) * 1400 + 10 * math.sin(t * 3)
    shadowed(img, PHONE, W / 2, y, ang, 0.86)
    # bulle « -50 % » collée au téléphone
    if t > 0.6:
        put(img, text_cached('-50%', 140, BLANC, stroke=8, sfill=ROSE), W / 2 + 255, 300, k=back((t - 0.6) / 0.3), rot=12)
    draw_confetti(img, CONF5, t - 0.6)
    if t > 0.9:
        q = back((t - 0.9) / 0.3)
        put(img, text_cached('TON CODE EST DANS', 92, BLANC, stroke=5, sfill=NUIT), W / 2, 1360, k=q)
        put(img, text_cached("L'APPLI MACITY", 112, ROSE, stroke=6, sfill=BLANC), W / 2, 1480, k=back((t - 1.05) / 0.3))
    if t > 1.4:
        q = back((t - 1.4) / 0.35)
        bw = 400
        for i, b in enumerate([B_APPLE, B_GOOGLE]):
            bb = b.resize((bw, int(b.height * bw / b.width)), Image.LANCZOS)
            put(img, bb, W / 2 + (-215 if i == 0 else 215), 1680, k=q)
    if t > 1.8:
        f = F('Poppins-SemiBold.ttf', 40)
        d = ImageDraw.Draw(img)
        s = "Gratuit · Rubrique Famille, Offres"
        d.text(((W - d.textlength(s, font=f)) / 2, 1790), s, font=f, fill=(225, 210, 240))
    img = flash(img, t, dur=0.12, a=160)
    return img

SCENES = [(T_TITRE, s_titre), (T_CUTS, s_cuts), (T_PHOTOS, s_photos), (T_OFFRE, s_offre), (T_FIN, s_fin)]

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
        p.stdin.write(frame(i / FPS).convert('RGB').tobytes())
    p.stdin.close(); p.wait()
    print(out, f'{DUR:.2f}s')

if __name__ == '__main__':
    main()

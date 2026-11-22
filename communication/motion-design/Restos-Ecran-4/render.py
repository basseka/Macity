"""Motion « écran divisé en 4 » : photos de plats et vidéos qui changent sur les temps.

Usage : /usr/bin/python3 render.py [sortie.mp4]
Les temps forts viennent de src/beats.json (liste de secondes, calée sur la musique),
sinon d'un tempo fixe (BPM ci-dessous).
"""
import glob, json, math, os, random, subprocess, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, 'assets')
W, H, FPS = 1080, 1920, 30
TW, TH = 540, 960            # une case
GUT = 6                      # trait entre les cases
ROSE, NUIT = (255, 30, 142), (10, 5, 20)
BPM = 89.0

beats_file = os.path.join(HERE, 'src', 'beats.json')
if os.path.exists(beats_file):
    BEATS = json.load(open(beats_file))
else:
    BEATS = [i * 60 / BPM for i in range(64)]
NB = 44                       # nombre de temps utilisés
END_B = 36                    # début de l'écran de fin
DUR = BEATS[NB] + 0.2

# ---------- médias ----------
photos = sorted(glob.glob(os.path.join(A, 'photos', '*.jpg')))
clips = {os.path.basename(d): sorted(glob.glob(os.path.join(d, '*.jpg'))) for d in sorted(glob.glob(os.path.join(A, 'cf', '*')))}
rnd = random.Random(7)
rnd.shuffle(photos)
clip_names = list(clips)
pool = []
pi = ci = 0
for k in range(200):
    if k % 4 == 1:
        pool.append(('clip', clip_names[ci % len(clip_names)])); ci += 1
    else:
        pool.append(('photo', photos[pi % len(photos)])); pi += 1

_cache = {}
def cover(path, w, h):
    key = (path, w, h)
    if key not in _cache:
        im = Image.open(path).convert('RGB')
        s = max(w / im.width, h / im.height)
        im = im.resize((math.ceil(im.width * s), math.ceil(im.height * s)), Image.LANCZOS)
        x, y = (im.width - w) // 2, (im.height - h) // 2
        _cache[key] = im.crop((x, y, x + w, y + h))
        if len(_cache) > 220: _cache.pop(next(iter(_cache)))
    return _cache[key]

def media_frame(item, age):
    """Image de la case : photo avec zoom lent, ou image de la vidéo."""
    kind, ref = item
    if kind == 'photo':
        big = cover(ref, int(TW * 1.12), int(TH * 1.12))
        z = 1.12 - 0.08 * min(age / 3.0, 1)
        cw, ch = int(TW * z), int(TH * z)
        x, y = (big.width - cw) // 2, (big.height - ch) // 2
        return big.crop((x, y, x + cw, y + ch)).resize((TW, TH), Image.BILINEAR)
    fr = clips[ref]
    return cover(fr[int(age * FPS) % len(fr)], TW, TH)

# ---------- planning : qui change à quel temps ----------
# case 0 haut gauche, 1 haut droite, 2 bas droite, 3 bas gauche (sens horaire)
POS = [(0, 0), (TW, 0), (TW, TH), (0, TH)]
events = [[] for _ in range(4)]    # (temps, item, direction)
nxt = 0
def put(c, b, d):
    global nxt
    events[c].append((BEATS[b], pool[nxt], d)); nxt += 1
for c in range(4):                 # les 4 cases affichées dès la 1re image
    put(c, 0, c)
rot = 0
for b in range(1, END_B):
    if b % 4 == 0:                 # temps fort : les 4 changent ensemble
        for c in range(4): put(c, b, (b // 4 + c) % 4)
    else:
        put(rot % 4, b, rot % 4); rot += 1

def ease_out(x): return 1 - (1 - x) ** 3
def clamp(x, a=0.0, b=1.0): return max(a, min(b, x))

# ---------- textes ----------
F_ANTON = os.path.join(A, 'Anton-Regular.ttf')
F_POP = os.path.join(A, 'Poppins-ExtraBold.ttf')
F_POPS = os.path.join(A, 'Poppins-SemiBold.ttf')
logo = Image.open(os.path.join(A, 'macity-logo-couleur-fond-sombre.png')).convert('RGBA')
TEXTS = [  # (temps début, temps fin, lignes)
    (4, 12, ['LES MEILLEURS', 'RESTOS']),
    (12, 20, ['DE TOULOUSE']),
    (20, 28, ['BURGERS, SUSHIS,', 'BRUNCHS, BISTROS…']),
    (28, 36, ['TOUS SUR', 'MACITY']),
]

def text_block(lines, size):
    f = ImageFont.truetype(F_ANTON, size)
    pad, lh = 34, int(size * 1.08)
    ws = [f.getbbox(l)[2] for l in lines]
    bw, bh = max(ws) + pad * 2, lh * len(lines) + pad * 1.2
    im = Image.new('RGBA', (int(bw), int(bh)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, im.width - 1, im.height - 1), 26, fill=ROSE + (255,))
    for i, l in enumerate(lines):
        d.text(((im.width - ws[i]) / 2, pad * 0.45 + i * lh), l, font=f, fill='white')
    return im
_tb = {}
def overlay_text(frame, t):
    for b0, b1, lines in TEXTS:
        t0, t1 = BEATS[b0], BEATS[b1]
        if not (t0 <= t < t1): continue
        key = tuple(lines)
        if key not in _tb: _tb[key] = text_block(lines, 128 if max(map(len, lines)) < 14 else 96)
        im = _tb[key]
        p = ease_out(clamp((t - t0) / 0.22))
        out = clamp((t1 - t) / 0.15)
        s = (0.6 + 0.4 * p) * (1 + 0.04 * pulse(t))
        im2 = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.BILINEAR)
        a = im2.getchannel('A').point(lambda v: int(v * min(p, out)))
        im2.putalpha(a)
        # léger penché, façon sticker
        im2 = im2.rotate(-3, expand=True, resample=Image.BICUBIC)
        frame.alpha_composite(im2, ((W - im2.width) // 2, (H - im2.height) // 2))

def pulse(t):
    """Impulsion à chaque temps (1 juste sur le temps, retombe en 0,18 s)."""
    v = 0
    for b in BEATS[:NB]:
        d = t - b
        if 0 <= d < 0.18: v = max(v, 1 - d / 0.18)
    return v

# ---------- écran de fin ----------
def end_card(t):
    t0 = BEATS[END_B]
    p = clamp((t - t0) / 0.5)
    im = Image.new('RGBA', (W, H), NUIT + (int(235 * p),))
    if p <= 0: return im
    d = ImageDraw.Draw(im)
    q = ease_out(clamp((t - t0 - 0.1) / 0.5))
    lw = int(760 * (0.85 + 0.15 * q))
    lg = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
    lg.putalpha(lg.getchannel('A').point(lambda v: int(v * q)))
    im.alpha_composite(lg, ((W - lg.width) // 2, 560 + int((1 - q) * 60)))
    q2 = ease_out(clamp((t - t0 - 0.5) / 0.5))
    f = ImageFont.truetype(F_ANTON, 112)
    for i, l in enumerate(['TON PROCHAIN RESTO', 'EST DANS L\'APP']):
        w = f.getbbox(l)[2]
        d.text(((W - w) / 2, 900 + i * 130 + (1 - q2) * 50), l, font=f, fill=(255, 255, 255, int(255 * q2)))
    q3 = ease_out(clamp((t - t0 - 0.9) / 0.5))
    if q3 > 0:
        f2 = ImageFont.truetype(F_POP, 50)
        lab = 'Télécharge MaCity'
        w = f2.getbbox(lab)[2]
        bw, bh = w + 140, 120
        x, y = (W - bw) / 2, 1250 + (1 - q3) * 40
        sc = 1 + 0.04 * pulse(t)
        bx = Image.new('RGBA', (bw, bh), (0, 0, 0, 0)); bd = ImageDraw.Draw(bx)
        bd.rounded_rectangle((0, 0, bw - 1, bh - 1), 60, fill=ROSE + (255,))
        bd.text((70, 22), lab, font=f2, fill='white')
        bx = bx.resize((int(bw * sc), int(bh * sc)), Image.BILINEAR)
        bx.putalpha(bx.getchannel('A').point(lambda v: int(v * q3)))
        im.alpha_composite(bx, (int(x - (bx.width - bw) / 2), int(y - (bx.height - bh) / 2)))
        f3 = ImageFont.truetype(F_POPS, 40)
        s = 'Gratuit sur iPhone et Android'
        w = f3.getbbox(s)[2]
        d.text(((W - w) / 2, 1420 + (1 - q3) * 40), s, font=f3, fill=(255, 255, 255, int(220 * q3)))
    return im

# ---------- rendu ----------
SLIDE = 0.2
def tile(c, t):
    ev = [e for e in events[c] if e[0] <= t]
    if not ev: return None, 0
    cur = ev[-1]
    age = t - cur[0]
    img = media_frame(cur[1], age)
    if age < SLIDE and len(ev) > 1:
        prev = ev[-2]
        old = media_frame(prev[1], t - prev[0])
        p = ease_out(age / SLIDE)
        dx, dy = [(1, 0), (0, 1), (-1, 0), (0, -1)][cur[2]]
        base = Image.new('RGB', (TW, TH))
        base.paste(old, (int(-dx * TW * p), int(-dy * TH * p)))
        base.paste(img, (int(dx * TW * (1 - p)), int(dy * TH * (1 - p))))
        img = base
    elif age < SLIDE and cur[0] > 0:   # apparition
        p = ease_out(age / SLIDE)
        s = 1.25 - 0.25 * p
        z = img.resize((int(TW * s), int(TH * s)), Image.BILINEAR)
        img = z.crop(((z.width - TW) // 2, (z.height - TH) // 2, (z.width - TW) // 2 + TW, (z.height - TH) // 2 + TH))
        img = Image.blend(Image.new('RGB', (TW, TH), (255, 255, 255)), img, p)
    return img, age

def frame(t):
    fr = Image.new('RGBA', (W, H), NUIT + (255,))
    for c in range(4):
        img, age = tile(c, t)
        if img is None: continue
        fr.paste(img, POS[c])
        if age < 0.12 and t > 0.12:   # flash blanc bref au changement
            fl = Image.new('RGBA', (TW, TH), (255, 255, 255, int(110 * (1 - age / 0.12))))
            fr.alpha_composite(fl, POS[c])
    d = ImageDraw.Draw(fr)
    d.rectangle((W // 2 - GUT // 2, 0, W // 2 + GUT // 2, H), fill=NUIT)
    d.rectangle((0, H // 2 - GUT // 2, W, H // 2 + GUT // 2), fill=NUIT)
    # respiration de toute la grille sur le temps
    pu = pulse(t)
    if pu > 0 and t < BEATS[END_B]:
        s = 1 + 0.018 * pu
        z = fr.resize((int(W * s), int(H * s)), Image.BILINEAR)
        fr = z.crop(((z.width - W) // 2, (z.height - H) // 2, (z.width - W) // 2 + W, (z.height - H) // 2 + H))
    overlay_text(fr, t)
    # petit logo en haut pendant la grille
    if t < BEATS[END_B]:
        lg = logo.resize((300, int(logo.height * 300 / logo.width)), Image.LANCZOS)
        a = 1.0
        if a > 0:
            bg = Image.new('RGBA', (lg.width + 60, lg.height + 36), (0, 0, 0, 0))
            ImageDraw.Draw(bg).rounded_rectangle((0, 0, bg.width - 1, bg.height - 1), 40, fill=NUIT + (200,))
            bg.alpha_composite(lg, (30, 18))
            bg.putalpha(bg.getchannel('A').point(lambda v: int(v * a)))
            fr.alpha_composite(bg, ((W - bg.width) // 2, 70))
    if t >= BEATS[END_B]:
        fr.alpha_composite(end_card(t))
    return fr.convert('RGB')

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'video_sans_son.mp4')
    n = int(DUR * FPS)
    if os.environ.get('PREVIEW'):
        for t in map(float, os.environ['PREVIEW'].split(',')):
            frame(t).save(os.path.join(HERE, f'apercu_{t:05.2f}.jpg'), quality=85)
        sys.exit()
    p = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
                          '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
    for i in range(n):
        p.stdin.write(frame(i / FPS).tobytes())
        if i % 150 == 0: print(f'{i}/{n}', flush=True)
    p.stdin.close(); p.wait()
    print('ok', out, f'{DUR:.2f} s')

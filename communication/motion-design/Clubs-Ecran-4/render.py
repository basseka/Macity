"""Motion « 4 écrans » clubs de Toulouse : une case par club (O Club, La Voile Blanche,
L'Étoile, Hiboo), photos et vidéos qui changent sur les temps de la musique,
puis chaque club en plein écran, puis écran de fin MaCity.

Usage : python render.py [sortie.mp4]      (PREVIEW=1.0,5.2 pour des images fixes)
Temps forts : src/beats.json (secondes depuis le début de l'extrait), sinon BPM fixe.
Médias : assets/photos/<club>_*.jpg et assets/cf/<club><n>/ (images des vidéos).
"""
import glob, json, math, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, 'assets')
W, H, FPS = 1080, 1920, 30
TW, TH = 540, 960
GUT = 6
ROSE, NUIT = (255, 30, 142), (10, 5, 20)

DUR = 23.0                                  # extrait 0:07 -> 0:30
bf = os.path.join(HERE, 'src', 'beats.json')
BEATS = json.load(open(bf)) if os.path.exists(bf) else [i * 0.5 for i in range(60)]
BEATS = [b for b in BEATS if b < DUR]

def beat_at(t):
    """Temps fort le plus proche de t (s)."""
    return min(range(len(BEATS)), key=lambda i: abs(BEATS[i] - t))

CLUBS = [  # (clé, nom affiché) ; case 0 haut gauche, 1 haut droite, 2 bas droite, 3 bas gauche
    ('oclub', "O CLUB"), ('voile', 'LA VOILE BLANCHE'), ('etoile', "L'ÉTOILE"), ('hiboo', 'HIBOO'),
]
POS = [(0, 0), (TW, 0), (TW, TH), (0, TH)]

# ---------- médias par club : vidéo, photo, photo, vidéo… ----------
def club_pool(key):
    photos = sorted(glob.glob(os.path.join(A, 'photos', key + '_*.jpg')))
    clips = sorted(glob.glob(os.path.join(A, 'cf', key + '*')))
    clips = [sorted(glob.glob(os.path.join(c, '*.jpg'))) for c in clips]
    pool, pi, ci = [], 0, 0
    for k in range(max(1, len(photos) + len(clips))):
        if clips and (k % 3 == 0 or not photos):
            pool.append(('clip', clips[ci % len(clips)])); ci += 1
        else:
            pool.append(('photo', photos[pi % len(photos)])); pi += 1
    return pool
POOLS = {k: club_pool(k) for k, _ in CLUBS}
_next = {k: 0 for k, _ in CLUBS}
def take(key):
    p = POOLS[key]; it = p[_next[key] % len(p)]; _next[key] += 1
    return it

_cache = {}
def cover(path, w, h):
    key = (path, w, h)
    if key not in _cache:
        im = Image.open(path).convert('RGB')
        s = max(w / im.width, h / im.height)
        im = im.resize((math.ceil(im.width * s), math.ceil(im.height * s)), Image.LANCZOS)
        x, y = (im.width - w) // 2, (im.height - h) // 2
        _cache[key] = im.crop((x, y, x + w, y + h))
        if len(_cache) > 300: _cache.pop(next(iter(_cache)))
    return _cache[key]

def media_frame(item, age, w, h):
    kind, ref = item
    if kind == 'photo':
        big = cover(ref, int(w * 1.14), int(h * 1.14))
        z = 1.14 - 0.1 * min(age / 2.5, 1)
        cw, ch = int(w * z), int(h * z)
        x, y = (big.width - cw) // 2, (big.height - ch) // 2
        return big.crop((x, y, x + cw, y + ch)).resize((w, h), Image.BILINEAR)
    return cover(ref[int(age * FPS) % len(ref)], w, h)

# ---------- planning ----------
B_INTRO = 4                                  # les 4 cases apparaissent une par une
B_SPOT = beat_at(DUR * 0.46)                 # début des pleins écrans
SPOT_LEN = 4                                 # temps par club en plein écran
B_GRID2 = B_SPOT + 4 * SPOT_LEN
B_END = beat_at(DUR - 3.4)                   # écran de fin
END_T = BEATS[B_END]

tiles = [[] for _ in range(4)]               # (temps, item, direction)
for c in range(4):
    tiles[c].append((BEATS[c], take(CLUBS[c][0]), c))
rot = 0
for b in list(range(B_INTRO, B_SPOT)) + list(range(B_GRID2, B_END)):
    if b % 4 == 0:
        for c in range(4): tiles[c].append((BEATS[b], take(CLUBS[c][0]), (b // 4 + c) % 4))
    else:
        c = rot % 4; tiles[c].append((BEATS[b], take(CLUBS[c][0]), c)); rot += 1

spots = []                                   # (t0, t1, club index, [(t, item)])
for i in range(4):
    b0 = B_SPOT + i * SPOT_LEN
    items = [(BEATS[b0 + k], take(CLUBS[i][0])) for k in range(SPOT_LEN)]
    spots.append((BEATS[b0], BEATS[b0 + SPOT_LEN], i, items))

def ease_out(x): return 1 - (1 - x) ** 3
def clamp(x, a=0.0, b=1.0): return max(a, min(b, x))
def pulse(t):
    v = 0
    for b in BEATS:
        d = t - b
        if 0 <= d < 0.16: v = max(v, 1 - d / 0.16)
    return v

# ---------- textes ----------
F_ANTON = os.path.join(A, 'Anton-Regular.ttf')
F_POP = os.path.join(A, 'Poppins-ExtraBold.ttf')
F_POPS = os.path.join(A, 'Poppins-SemiBold.ttf')
logo = Image.open(os.path.join(A, 'macity-logo-couleur-fond-sombre.png')).convert('RGBA')
badges = [Image.open(os.path.join(A, f)).convert('RGBA') for f in ('badge-app-store-fr.png', 'badge-google-play-fr.png')]

_lab = {}
def label(name, size):
    k = (name, size)
    if k not in _lab:
        f = ImageFont.truetype(F_ANTON, size)
        bb = f.getbbox(name); pad = int(size * .32)
        im = Image.new('RGBA', (bb[2] + 2 * pad, int(size * 1.25) + pad), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((0, 0, im.width - 1, im.height - 1), int(size * .22), fill=ROSE + (255,))
        d.text((pad, pad * .45), name, font=f, fill='white')
        _lab[k] = im
    return _lab[k]

def paste_scaled(fr, im, cx, cy, s, a, rot=0):
    im2 = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.BILINEAR)
    if rot: im2 = im2.rotate(rot, expand=True, resample=Image.BICUBIC)
    im2.putalpha(im2.getchannel('A').point(lambda v: int(v * a)))
    fr.alpha_composite(im2, (int(cx - im2.width / 2), int(cy - im2.height / 2)))

STICKERS = [  # (début s, fin s, lignes)
    (BEATS[B_INTRO], BEATS[min(B_INTRO + 6, B_SPOT - 1)], ['TES NUITS', 'À TOULOUSE']),
    (BEATS[B_GRID2], END_T, ['TOUS LES CLUBS', 'SUR MACITY']),
]
_st = {}
def sticker(lines):
    k = tuple(lines)
    if k not in _st:
        f = ImageFont.truetype(F_ANTON, 120)
        ws = [f.getbbox(l)[2] for l in lines]; pad, lh = 36, 130
        im = Image.new('RGBA', (max(ws) + 2 * pad, lh * len(lines) + int(pad * 1.2)), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((0, 0, im.width - 1, im.height - 1), 28, fill=ROSE + (255,))
        for i, l in enumerate(lines): d.text(((im.width - ws[i]) / 2, pad * .45 + i * lh), l, font=f, fill='white')
        _st[k] = im
    return _st[k]

# ---------- rendu ----------
SLIDE = 0.18
def tile(c, t):
    ev = [e for e in tiles[c] if e[0] <= t]
    if not ev: return None, 0
    cur = ev[-1]; age = t - cur[0]
    img = media_frame(cur[1], age, TW, TH)
    if age < SLIDE and len(ev) > 1:
        prev = ev[-2]; old = media_frame(prev[1], t - prev[0], TW, TH)
        p = ease_out(age / SLIDE)
        dx, dy = [(1, 0), (0, 1), (-1, 0), (0, -1)][cur[2]]
        base = Image.new('RGB', (TW, TH))
        base.paste(old, (int(-dx * TW * p), int(-dy * TH * p)))
        base.paste(img, (int(dx * TW * (1 - p)), int(dy * TH * (1 - p))))
        img = base
    elif age < 0.25:                          # apparition de la case
        p = ease_out(age / 0.25); s = 1.3 - 0.3 * p
        z = img.resize((int(TW * s), int(TH * s)), Image.BILINEAR)
        img = z.crop(((z.width - TW) // 2, (z.height - TH) // 2, (z.width - TW) // 2 + TW, (z.height - TH) // 2 + TH))
        img = Image.blend(Image.new('RGB', (TW, TH), (255, 255, 255)), img, p)
    return img, age

def grid(t):
    fr = Image.new('RGBA', (W, H), NUIT + (255,))
    for c in range(4):
        img, age = tile(c, t)
        if img is None: continue
        fr.paste(img, POS[c])
        if age < 0.1 and t > 0.1:
            fr.alpha_composite(Image.new('RGBA', (TW, TH), (255, 255, 255, int(120 * (1 - age / 0.1)))), POS[c])
        first = tiles[c][0][0]
        q = ease_out(clamp((t - first - .1) / .3))
        if q > 0:
            lb = label(CLUBS[c][1], 54)
            x, y = POS[c]
            paste_scaled(fr, lb, x + TW / 2, y + TH - 90, .7 + .3 * q, q)
    d = ImageDraw.Draw(fr)
    d.rectangle((W // 2 - GUT // 2, 0, W // 2 + GUT // 2, H), fill=NUIT)
    d.rectangle((0, H // 2 - GUT // 2, W, H // 2 + GUT // 2), fill=NUIT)
    return fr

def spot(t, s):
    t0, t1, i, items = s
    cur = [it for it in items if it[0] <= t][-1]
    age = t - cur[0]
    fr = media_frame(cur[1], age, W, H).convert('RGBA')
    if age < 0.1:
        fr.alpha_composite(Image.new('RGBA', (W, H), (255, 255, 255, int(80 * (1 - age / 0.1)))))
    # entrée : la case du club grandit jusqu'au plein écran
    e = ease_out(clamp((t - t0) / .28))
    if e < 1:
        g = grid(t0 - 1 / FPS)
        x, y = POS[i]
        w, h = TW + (W - TW) * e, TH + (H - TH) * e
        cx, cy = x + (0 - x) * e, y + (0 - y) * e
        g.paste(fr.resize((int(w), int(h)), Image.BILINEAR), (int(cx), int(cy)))
        fr = g
    # dégradé bas + nom du club
    sh = Image.new('RGBA', (W, 700), (0, 0, 0, 0)); sd = ImageDraw.Draw(sh)
    for yy in range(700): sd.line((0, yy, W, yy), fill=(10, 5, 20, int(200 * yy / 700)))
    fr.alpha_composite(sh, (0, H - 700))
    q = ease_out(clamp((t - t0 - .15) / .3))
    f = ImageFont.truetype(F_ANTON, 230)
    name = CLUBS[i][1]; wn = f.getbbox(name)[2]
    sc = 1 + .05 * pulse(t)
    txt = Image.new('RGBA', (wn + 20, 300), (0, 0, 0, 0)); ImageDraw.Draw(txt).text((10, 0), name, font=f, fill='white')
    paste_scaled(fr, txt, W / 2, H - 330 + (1 - q) * 80, min(1, (W - 120) / txt.width) * sc, q)
    f2 = ImageFont.truetype(F_POPS, 44); sub = 'TOULOUSE · CLUB'
    ImageDraw.Draw(fr).text(((W - f2.getbbox(sub)[2]) / 2, H - 160 + (1 - q) * 60), sub, font=f2, fill=(255, 255, 255, int(220 * q)))
    return fr

def end_card(t, fr):
    p = clamp((t - END_T) / .45)
    fr.alpha_composite(Image.new('RGBA', (W, H), NUIT + (int(232 * p),)))
    q = ease_out(clamp((t - END_T - .1) / .45))
    lw = int(720 * (.85 + .15 * q)); lg = logo.resize((lw, int(logo.height * lw / logo.width)), Image.LANCZOS)
    paste_scaled(fr, lg, W / 2, 560 + (1 - q) * 60, 1, q)
    q2 = ease_out(clamp((t - END_T - .45) / .45))
    f = ImageFont.truetype(F_ANTON, 118); d = ImageDraw.Draw(fr)
    for k, l in enumerate(['TA SOIRÉE', 'COMMENCE ICI']):
        d.text(((W - f.getbbox(l)[2]) / 2, 790 + k * 132 + (1 - q2) * 50), l, font=f, fill=(255, 255, 255, int(255 * q2)))
    q3 = ease_out(clamp((t - END_T - .85) / .45))
    if q3 > 0:
        f3 = ImageFont.truetype(F_POP, 46); s = 'Télécharge MaCity, c\'est gratuit'
        d.text(((W - f3.getbbox(s)[2]) / 2, 1140 + (1 - q3) * 40), s, font=f3, fill=(255, 255, 255, int(235 * q3)))
        bh = 118; x = W / 2
        bs = [b.resize((int(b.width * bh / b.height), bh), Image.LANCZOS) for b in badges]
        tot = bs[0].width + bs[1].width + 36
        sc = 1 + .03 * pulse(t)
        paste_scaled(fr, bs[0], x - tot / 2 + bs[0].width / 2, 1300 + (1 - q3) * 40, sc, q3)
        paste_scaled(fr, bs[1], x + tot / 2 - bs[1].width / 2, 1300 + (1 - q3) * 40, sc, q3)

def frame(t):
    s = next((s for s in spots if s[0] <= t < s[1]), None)
    fr = spot(t, s) if s else grid(t)
    pu = pulse(t)
    if pu > 0 and t < END_T:
        z = 1 + .02 * pu
        g = fr.resize((int(W * z), int(H * z)), Image.BILINEAR)
        fr = g.crop(((g.width - W) // 2, (g.height - H) // 2, (g.width - W) // 2 + W, (g.height - H) // 2 + H))
    if not s and t < END_T:
        for t0, t1, lines in STICKERS:
            if t0 <= t < t1:
                p = ease_out(clamp((t - t0) / .22)); out = clamp((t1 - t) / .15)
                paste_scaled(fr, sticker(lines), W / 2, H / 2, (.6 + .4 * p) * (1 + .04 * pu), min(p, out), -3)
        lg = logo.resize((280, int(logo.height * 280 / logo.width)), Image.LANCZOS)
        bg = Image.new('RGBA', (lg.width + 56, lg.height + 34), (0, 0, 0, 0))
        ImageDraw.Draw(bg).rounded_rectangle((0, 0, bg.width - 1, bg.height - 1), 40, fill=NUIT + (200,))
        bg.alpha_composite(lg, (28, 17))
        fr.alpha_composite(bg, ((W - bg.width) // 2, 64))
    if t >= END_T: end_card(t, fr)
    return fr.convert('RGB')

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'video_sans_son.mp4')
    if os.environ.get('PREVIEW'):
        for t in map(float, os.environ['PREVIEW'].split(',')):
            frame(t).save(os.path.join(HERE, 'src', f'apercu_{t:05.2f}.jpg'), quality=85)
        sys.exit()
    n = int(DUR * FPS)
    p = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
                          '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
    for i in range(n):
        p.stdin.write(frame(i / FPS).tobytes())
        if i % 150 == 0: print(f'{i}/{n}', flush=True)
    p.stdin.close(); p.wait()
    print('ok', out, f'{DUR:.2f} s')

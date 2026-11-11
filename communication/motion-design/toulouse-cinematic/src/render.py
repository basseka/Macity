"""Rendu image par image du reel MaCity Toulouse (numpy + OpenCV + PIL).

Usage (depuis toulouse-cinematic/) :
  python src/render.py                 # toutes les images -> out/frames/
  python src/render.py 12.0 33.5       # quelques instants (en TEMPS) -> out/check/
Puis : python src/encode.py
"""
import os, sys, math, glob, random
from functools import lru_cache
from multiprocessing import Pool
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont, ImageFilter
sys.path.insert(0, os.path.dirname(__file__))
from timeline import SHOTS, TRANS, LABELS, COL, BEAT, FPS, TOTAL_BEATS, W, H

FONTS = '../src/assets/'
BRAND = 'brand/'
CX, CY = W / 2, H / 2

# ---------------------------------------------------------------- utilitaires
def clamp(x, a=0.0, b=1.0): return a if x < a else b if x > b else x
def lerp(a, b, p): return a + (b - a) * p
def e_out(p): p = clamp(p); return 1 - (1 - p) ** 3
def e_in(p): p = clamp(p); return p ** 3
def e_io(p): p = clamp(p); return 4 * p ** 3 if p < .5 else 1 - (-2 * p + 2) ** 3 / 2
def e_back(p, s=1.7):
    p = clamp(p) - 1; return p * p * ((s + 1) * p + s) + 1

YY, XX = np.mgrid[0:H, 0:W].astype(np.float32)
RR = np.sqrt((XX - CX) ** 2 + (YY - CY) ** 2)
DIRX, DIRY = (XX - CX) / (RR + 1e-3), (YY - CY) / (RR + 1e-3)
VIGN = (1 - 0.55 * np.clip((RR / (0.62 * math.hypot(CX, CY))) - 0.45, 0, 1) ** 1.6)[..., None].astype(np.float32)
RNG = np.random.default_rng(7)
GRAIN = [RNG.normal(0, 1, (H // 2, W // 2)).astype(np.float32) for _ in range(6)]

def affine(img, z=1.0, rot=0.0, dx=0.0, dy=0.0, border=cv2.BORDER_REFLECT):
    if abs(z - 1) < 1e-4 and abs(rot) < 1e-3 and abs(dx) < .5 and abs(dy) < .5:
        return img
    M = cv2.getRotationMatrix2D((CX, CY), rot, z)
    M[0, 2] += dx; M[1, 2] += dy
    return cv2.warpAffine(img, M, (W, H), flags=cv2.INTER_LINEAR, borderMode=border)

def radial_blur(img, strength, n=7):
    if strength < 0.004: return img
    acc = img.astype(np.float32).copy()
    for i in range(1, n + 1):
        acc += affine(img, 1 + strength * i / n).astype(np.float32)
    return acc / (n + 1)

def hblur(img, k):
    k = int(k)
    return img if k < 3 else cv2.blur(img, (k, 1))

def chroma(img, s):
    if s < 0.5: return img
    out = img.copy()
    out[..., 0] = affine(img[..., 0].copy(), 1 + s / 900)
    out[..., 2] = affine(img[..., 2].copy(), 1 - s / 900)
    return out

def shockwave(img, R, amp, width=130):
    d = amp * np.exp(-((RR - R) / width) ** 2)
    mx, my = XX - DIRX * d, YY - DIRY * d
    return cv2.remap(img, mx, my, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)

def ring(R, width, color, inten):
    g = np.exp(-((RR - R) / width) ** 2) * inten
    return g[..., None] * np.array(color, np.float32)[None, None, :]

# ---------------------------------------------------------------- médias
@lru_cache(maxsize=24)
def load_img(path):
    im = cv2.imread(path, cv2.IMREAD_COLOR)
    return cv2.cvtColor(im, cv2.COLOR_BGR2RGB)

@lru_cache(maxsize=160)
def load_frame(path):
    im = cv2.imread(path, cv2.IMREAD_COLOR)
    return cv2.cvtColor(im, cv2.COLOR_BGR2RGB)

def img_frame(path, z, pan, p):
    src = load_img(path); ih, iw = src.shape[:2]
    c = max(W / iw, H / ih) * z
    mx, my = max(0, (iw * c - W) / 2), max(0, (ih * c - H) / 2)
    ox = pan[0] * mx * (p * 2 - 1); oy = pan[1] * my * (p * 2 - 1)
    M = np.array([[c, 0, CX - iw * c / 2 - ox], [0, c, CY - ih * c / 2 - oy]], np.float32)
    return cv2.warpAffine(src, M, (W, H), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)

def vid_frame(i, tl, layout, p):
    fs = sorted(glob.glob(f'cache/vid_{i:02d}/*.jpg'))
    k = int(clamp(tl * FPS, 0, len(fs) - 1))
    fr = load_frame(fs[k])
    if layout != 'window':
        return fr
    # fenêtre cinéma 16:9 au centre, fond = même image floutée
    fh = fr.shape[0]
    small = cv2.resize(fr, (W // 8, max(1, fh // 8)))
    c = max(W / small.shape[1], H / small.shape[0]) * 1.1
    bg = cv2.resize(small, (int(small.shape[1] * c), int(small.shape[0] * c)), interpolation=cv2.INTER_LINEAR)
    oy, ox = (bg.shape[0] - H) // 2, (bg.shape[1] - W) // 2
    bg = cv2.GaussianBlur(bg[oy:oy + H, ox:ox + W], (0, 0), 18).astype(np.float32) * 0.42
    z = lerp(1.0, 1.07, p)
    fg = cv2.resize(fr, (int(W * z), int(fh * z)), interpolation=cv2.INTER_CUBIC)
    fg = fg[:, (fg.shape[1] - W) // 2:(fg.shape[1] - W) // 2 + W]
    y0 = int(CY - fg.shape[0] / 2)
    bg[y0:y0 + fg.shape[0]] = fg
    # fins liserés lumineux
    bg[y0 - 3:y0] = bg[y0 - 3:y0] * 0.3 + 180
    bg[y0 + fg.shape[0]:y0 + fg.shape[0] + 3] = bg[y0 + fg.shape[0]:y0 + fg.shape[0] + 3] * 0.3 + 180
    return np.clip(bg, 0, 255).astype(np.uint8)

STARTS = [s[0] for s in SHOTS]
def shot_index(b):
    for i, s in enumerate(SHOTS):
        if s[0] <= b < s[1]: return i
    return len(SHOTS) - 1

def render_shot(i, b, z=1.0, rot=0.0, dx=0.0, dy=0.0):
    b0, b1, uni, kind, src, o = SHOTS[i]
    p = (b - b0) / (b1 - b0)
    tl = (b - b0) * BEAT
    if kind == 'img':
        z0, z1 = o.get('zoom', (1.0, 1.1))
        fr = img_frame(src, lerp(z0, z1, e_io(clamp(p))), o.get('pan', (0, 0)), clamp(p))
    else:
        fr = vid_frame(i, tl, o.get('layout', 'full'), clamp(p))
    return affine(fr, z, rot, dx, dy).astype(np.float32)

# ---------------------------------------------------------------- étalonnage
TINT = {'food': (1.07, 1.0, 0.88), 'night': (1.0, 0.9, 1.12), 'famille': (1.06, 1.0, 0.92), 'culture': (0.95, 1.0, 1.07),
        'sport': (1.0, 1.03, 0.97), 'evasion': (1.07, 1.0, 0.9), 'final': (1.06, 0.9, 1.1)}
_x = np.arange(256, dtype=np.float32) / 255
CURVE = (np.clip(_x + 0.18 * np.sin(2 * np.pi * (_x - 0.5)) * (_x * (1 - _x)) * 4 * 0.55, 0, 1) * 255).astype(np.float32)

def grade(img, uni, fi):
    img = np.clip(img, 0, 255)
    img = CURVE[img.astype(np.uint8)]
    g = img.mean(axis=2, keepdims=True)
    img = g + (img - g) * 1.12
    img = img * np.array(TINT[uni], np.float32)[None, None, :]
    img = img * VIGN
    gr = cv2.resize(GRAIN[fi % 6], (W, H), interpolation=cv2.INTER_NEAREST)
    img = img + gr[..., None] * 5.0
    return img

# ---------------------------------------------------------------- textes
def font(name, size): return ImageFont.truetype(FONTS + name, size)

def text_sprite(text, fnt, fill=(255, 255, 255), track=0, glow=None, glow_r=18, stroke=0):
    tmp = Image.new('L', (10, 10)); d = ImageDraw.Draw(tmp)
    ws = [d.textlength(ch, font=fnt) for ch in text]
    tw = int(sum(ws) + track * (len(text) - 1)); asc, desc = fnt.getmetrics()
    pad = glow_r * 3 if glow else 10
    im = Image.new('RGBA', (tw + 2 * pad, asc + desc + 2 * pad), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = pad
    for ch, w in zip(text, ws):
        d.text((x, pad), ch, font=fnt, fill=fill + (255,), stroke_width=stroke, stroke_fill=fill + (255,)); x += w + track
    if glow:
        a = im.split()[3].filter(ImageFilter.GaussianBlur(glow_r))
        g = Image.new('RGBA', im.size, glow + (0,)); g.putalpha(a.point(lambda v: min(255, int(v * 1.6))))
        g.alpha_composite(im); im = g
    return np.array(im).astype(np.float32)

def overlay(dst, spr, cx, cy, scale=1.0, alpha=1.0, add=False):
    if alpha <= 0.003 or scale <= 0.01: return dst
    s = spr if abs(scale - 1) < 1e-3 else cv2.resize(spr, (max(1, int(spr.shape[1] * scale)), max(1, int(spr.shape[0] * scale))), interpolation=cv2.INTER_LINEAR)
    h, w = s.shape[:2]; x0, y0 = int(cx - w / 2), int(cy - h / 2)
    xa, ya, xb, yb = max(0, x0), max(0, y0), min(W, x0 + w), min(H, y0 + h)
    if xa >= xb or ya >= yb: return dst
    part = s[ya - y0:yb - y0, xa - x0:xb - x0]
    a = part[..., 3:4] / 255.0 * alpha
    if add: dst[ya:yb, xa:xb] += part[..., :3] * a
    else: dst[ya:yb, xa:xb] = dst[ya:yb, xa:xb] * (1 - a) + part[..., :3] * a
    return dst

@lru_cache(maxsize=1)
def sprites():
    S = {}
    for b0, b1, word, idx in LABELS:
        uni = SHOTS[shot_index(b0)][2]; c = COL[uni]
        S['L_' + word] = text_sprite(word, font('Anton-Regular.ttf', 200), track=6, glow=c, glow_r=22)
        S['K_' + word] = text_sprite(f'TOULOUSE   {idx:02d} / 06', font('Poppins-SemiBold.ttf', 34), fill=c, track=9)
    S['T1'] = text_sprite('TOULOUSE.', font('Anton-Regular.ttf', 210), track=4, glow=(255, 30, 142), glow_r=26)
    S['T2'] = text_sprite('UNE VILLE.', font('Poppins-ExtraBold.ttf', 74), track=4)
    S['T3'] = text_sprite('MILLE EXPÉRIENCES.', font('Poppins-ExtraBold.ttf', 74), fill=(255, 120, 190), track=4)
    S['TAG'] = text_sprite('Toulouse, à toi de vivre.', font('Poppins-SemiBold.ttf', 66), track=1)
    S['L1'] = text_sprite('Peu importe ce que tu aimes,', font('Poppins-Medium.ttf', 38))
    S['L2'] = text_sprite('ta prochaine expérience est sur MaCity.', font('Poppins-Medium.ttf', 38))
    # bouton
    bw, bh = 640, 124
    im = Image.new('RGBA', (bw + 80, bh + 80), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    grad = Image.new('RGBA', (bw, bh)); gd = ImageDraw.Draw(grad)
    for x in range(bw):
        t = x / bw; gd.line([(x, 0), (x, bh)], fill=(int(255 - 22 * t), int(30), int(142 - 40 * t), 255))
    mask = Image.new('L', (bw, bh), 0); ImageDraw.Draw(mask).rounded_rectangle([0, 0, bw - 1, bh - 1], radius=bh // 2, fill=255)
    glow = Image.new('RGBA', im.size, (255, 30, 142, 0)); ga = Image.new('L', im.size, 0)
    ImageDraw.Draw(ga).rounded_rectangle([40, 40, 40 + bw, 40 + bh], radius=bh // 2, fill=200); glow.putalpha(ga.filter(ImageFilter.GaussianBlur(22)))
    im.alpha_composite(glow); im.paste(grad, (40, 40), mask)
    f = font('Poppins-Bold.ttf', 54); txt = 'Télécharge MaCity'
    tw = d.textlength(txt, font=f); d = ImageDraw.Draw(im)
    d.text((40 + (bw - tw) / 2, 40 + (bh - 70) / 2 - 4), txt, font=f, fill=(255, 255, 255, 255))
    S['CTA'] = np.array(im).astype(np.float32)
    # logo officiel (charte) + halo
    lg = Image.open(BRAND + 'macity-logo-couleur-fond-sombre.png').convert('RGBA')
    lw = 880; lg = lg.resize((lw, int(lg.height * lw / lg.width)), Image.LANCZOS)
    pad = 90; can = Image.new('RGBA', (lg.width + 2 * pad, lg.height + 2 * pad), (0, 0, 0, 0)); can.alpha_composite(lg, (pad, pad))
    S['LOGO'] = np.array(can).astype(np.float32)
    a = can.split()[3].filter(ImageFilter.GaussianBlur(34))
    g = Image.new('RGBA', can.size, (255, 30, 142, 0)); g.putalpha(a)
    S['LOGOGLOW'] = np.array(g).astype(np.float32)
    return S

def draw_labels(fr, b):
    S = sprites()
    for b0, b1, word, idx in LABELS:
        if not (b0 - 0.01 <= b <= b1 + 0.4): continue
        pin, pout = (b - b0) / 0.45, (b - b1) / 0.35
        a = e_out(pin) * (1 - e_in(pout))
        sc = lerp(1.22, 1.0, e_out(pin))
        uni = SHOTS[shot_index(b0)][2]
        if uni in ('night', 'sport'):  # pulsation sur chaque temps
            ph = (b - math.floor(b)); sc *= 1 + 0.035 * max(0, 1 - ph / 0.35)
            if uni == 'night' and pin < 1.2 and int(b * 8) % 3 == 0: a *= 0.55
        overlay(fr, S['K_' + word], CX, 1235, 1.0, a * clamp((b - b0 - 0.15) / 0.4))
        overlay(fr, S['L_' + word], CX + lerp(0, 0, pin), 1350, sc, a)
    if b < 4.2:  # ouverture
        a = 1 - e_in((b - 3.75) / 0.4)
        overlay(fr, S['T1'], CX, 470, lerp(1.25, 1.0, e_out(b / 0.5)), e_out(b / 0.3) * a)
        overlay(fr, S['T2'], CX, 1385, lerp(1.2, 1.0, e_out((b - 2) / 0.4)), e_out((b - 2) / 0.3) * a)
        overlay(fr, S['T3'], CX, 1470, lerp(1.2, 1.0, e_out((b - 3) / 0.4)), e_out((b - 3) / 0.3) * a)
    return fr

# ---------------------------------------------------------------- effets globaux
def leak_layer(b, inten):
    if inten <= 0: return 0
    g1 = np.exp(-(((XX - W * (0.2 + 0.5 * math.sin(b * 0.7))) ** 2) / (2 * 380 ** 2) + ((YY - H * 0.3) ** 2) / (2 * 700 ** 2)))
    g2 = np.exp(-(((XX - W * (0.9 - 0.4 * math.cos(b * 0.5))) ** 2) / (2 * 300 ** 2) + ((YY - H * 0.75) ** 2) / (2 * 600 ** 2)))
    return (g1[..., None] * np.array([255, 150, 60], np.float32) + g2[..., None] * np.array([255, 60, 140], np.float32)) * inten

def lasers(fr, b, inten):
    if inten <= 0: return fr
    lay = np.zeros((H, W, 3), np.uint8)
    cols = [(255, 30, 142), (34, 211, 238), (168, 85, 247), (255, 255, 255), (255, 30, 142), (34, 211, 238)]
    for k in range(6):
        ox = [0, W * 0.5, W][k % 3]
        ang = math.radians(-90 + (38 if k < 3 else -38) * math.sin(b * 1.9 + k * 1.1))
        x2, y2 = ox + math.cos(ang) * 3000, H + 40 + math.sin(ang) * 3000
        cv2.line(lay, (int(ox), H + 40), (int(x2), int(y2)), cols[k], 5, cv2.LINE_AA)
    glow = cv2.GaussianBlur(lay, (0, 0), 10).astype(np.float32)
    return fr + (glow * 2.2 + lay.astype(np.float32) * 0.9) * inten

CONF = [(RNG.uniform(0, W), RNG.uniform(-H, 0), RNG.uniform(500, 950), RNG.uniform(0, 6.28), RNG.uniform(-6, 6),
         [(255, 30, 142), (34, 211, 238), (255, 210, 60), (168, 85, 247), (255, 255, 255)][int(RNG.integers(0, 5))]) for _ in range(170)]
def confetti(fr, tau, inten=1.0):
    if tau <= 0: return fr
    for x0, y0, v, ph, sp, c in CONF:
        y = y0 + v * tau; x = x0 + 60 * math.sin(tau * 2.3 + ph)
        if y < -40 or y > H + 40: continue
        a = ph + sp * tau; ca, sa = math.cos(a), math.sin(a) * abs(math.cos(tau * 3 + ph))
        pts = np.array([[x + ca * 9 - sa * 15, y + sa * 9 + ca * 15], [x - ca * 9 - sa * 15, y - sa * 9 + ca * 15],
                        [x - ca * 9 + sa * 15, y - sa * 9 - ca * 15], [x + ca * 9 + sa * 15, y + sa * 9 - ca * 15]], np.int32)
        cv2.fillConvexPoly(fr, pts, tuple(float(cc * inten) for cc in c), cv2.LINE_AA)
    return fr

PART = [(RNG.uniform(0, 6.283), RNG.lognormal(6.6, 0.55), RNG.uniform(2, 7.5),
         [(255, 255, 255), (255, 30, 142), (255, 30, 142), (168, 85, 247), (34, 211, 238), (255, 200, 80)][int(RNG.integers(0, 6))]) for _ in range(1100)]
def particles(tau):
    lay = np.zeros((H, W, 3), np.float32)
    if tau <= 0: return lay
    k = 1.9
    for ang, v, sz, c in PART:
        r = v * (1 - math.exp(-k * tau)) / k
        x, y = CX + math.cos(ang) * r, CY - 60 + math.sin(ang) * r + 90 * tau * tau
        a = math.exp(-tau / 1.1)
        if 0 <= x < W and 0 <= y < H:
            cv2.circle(lay, (int(x), int(y)), int(max(1, sz * (0.6 + 0.4 * a))), tuple(cc * a for cc in c), -1, cv2.LINE_AA)
    return lay + cv2.GaussianBlur(lay, (0, 0), 6) * 1.6

# ---------------------------------------------------------------- composition d'une image
SECTION_OF = lambda b: SHOTS[shot_index(b)][2]

def trans_near(b):
    for bt, ty in TRANS.items():
        w = {'zoomthru': (0.5, 0.5), 'flash': (0, 0.5), 'whip': (0.3, 0.3), 'spin': (0.6, 0.6), 'shock': (0.5, 1.0), 'leak': (1.0, 0.75), 'explode': (0, 99)}[ty]
        if bt - w[0] <= b < bt + w[1]: return bt, ty, w
    return None

def base_frame(b, fi):
    i = shot_index(b); b0, b1, uni, kind, src, o = SHOTS[i]
    tl = b - b0
    z, dx, dy, rot = 1.0, 0.0, 0.0, 0.0
    fx = {'flash': 0.0, 'rblur': 0.0, 'chroma': 0.0, 'white': 0.0, 'hblur': 0}
    # punch à chaque coupe (sauf évasion), pulsation sur les temps
    if uni != 'evasion':
        z *= 1 + (0.085 if uni in ('night', 'sport', 'final') else 0.05) * max(0, 1 - tl / 0.4) ** 2
    if uni in ('night', 'sport', 'final'):
        ph = b - math.floor(b); z *= 1 + 0.018 * max(0, 1 - ph / 0.3)
    if uni == 'sport' and tl < 0.5:  # secousse d'impact
        amp = 18 * (1 - tl / 0.5); dx += amp * math.sin(fi * 2.7); dy += amp * math.cos(fi * 3.1)
        fx['flash'] = max(fx['flash'], 0.18 * max(0, 1 - tl / 0.2))
    if uni in ('night', 'final') and tl < 0.12 and i % 2 == 0: fx['chroma'] = 14
    if uni == 'culture' and tl < 0.2: fx['chroma'] = 7
    tr = trans_near(b)
    fr = None
    if tr:
        bt, ty, (wa, wb) = tr
        ia, ib = shot_index(bt - 0.01), shot_index(bt)
        if ty == 'zoomthru':
            if b < bt:
                p = (b - (bt - wa)) / wa
                fr = render_shot(ia, b, z=lerp(1, 3.6, e_in(p))); fx['rblur'] = 0.35 * e_in(p); fx['white'] = e_in(p) ** 2 * 0.95
            else:
                p = (b - bt) / wb
                fr = render_shot(ib, b, z=lerp(1.7, 1.0, e_out(p))); fx['rblur'] = 0.3 * (1 - e_out(p)); fx['white'] = (1 - e_out(p * 1.6)) * 0.9
        elif ty == 'flash':
            fx['flash'] = max(fx['flash'], 1.0 - e_out((b - bt) / wb))
        elif ty == 'whip':
            p = (b - (bt - wa)) / (wa + wb); u = e_io(p)
            A = render_shot(ia, min(b, bt - 0.001)); B = render_shot(ib, max(b, bt))
            off = int(u * W)
            fr = np.empty_like(A)
            fr[:, :W - off] = A[:, off:]; fr[:, W - off:] = B[:, :off]
            vel = abs(e_io(p + 0.02) - e_io(p - 0.02)) / 0.04
            fx['hblur'] = vel * 120
        elif ty == 'spin':
            if b < bt:
                p = (b - (bt - wa)) / wa
                fr = render_shot(ia, b, z=lerp(1, 2.4, e_in(p)), rot=lerp(0, 140, e_in(p))); fx['rblur'] = 0.28 * e_in(p); fx['white'] = e_in(p) ** 3 * 0.7
            else:
                p = (b - bt) / wb
                fr = render_shot(ib, b, z=lerp(2.2, 1.0, e_out(p)) * z, rot=lerp(-140, 0, e_out(p))); fx['rblur'] = 0.28 * (1 - e_out(p)); fx['white'] = (1 - e_out(p * 2)) * 0.7
        elif ty == 'shock':
            if b < bt:
                p = (b - (bt - wa)) / wa
                fr = render_shot(ia, b, z=z * lerp(1, 1.22, e_in(p))); fx['chroma'] = 18 * e_in(p)
            else:
                p = (b - bt) / wb
                fr = render_shot(ib, b, z=lerp(1.35, 1.0, e_out(p)))
                fr = shockwave(fr, lerp(0, 1.25 * H, e_out(p)), 70 * (1 - p))
                fr += ring(lerp(0, 1.25 * H, e_out(p)), 26, (255, 230, 200), 120 * (1 - p) ** 2)
                fx['flash'] = max(fx['flash'], 0.85 * (1 - e_out(p * 2.5))); fx['chroma'] = 16 * (1 - p)
        elif ty == 'leak':
            p = (b - (bt - wa)) / (wa + wb)
            A = render_shot(ia, min(b, bt - 0.001), z=lerp(1, 1.1, p)); B = render_shot(ib, max(b, bt))
            m = e_io(clamp((p - 0.35) / 0.4))
            fr = A * (1 - m) + B * m
            fr = fr + leak_layer(b, 0.9 * math.sin(math.pi * clamp(p)))
            fx['white'] = 0.25 * math.sin(math.pi * clamp(p))
    if fr is None:
        if uni == 'evasion' and i > 0 and SHOTS[i - 1][2] == 'evasion' and tl < 0.75:  # fondus doux
            A = render_shot(i - 1, b); B = render_shot(i, b, z, rot, dx, dy); m = e_io(tl / 0.75)
            fr = A * (1 - m) + B * m
        else:
            fr = render_shot(i, b, z, rot, dx, dy)
    # stroboscope fin de Night
    if 23.0 <= b < 24.0:
        q = int((b - 23.0) * 8)
        fr = fr * (0.22 if q % 2 else 1.35) + (0 if q % 2 else 25)
    if fx['rblur']: fr = radial_blur(fr, fx['rblur'])
    if fx['hblur']: fr = hblur(fr, fx['hblur'])
    if fx['chroma']: fr = chroma(fr, fx['chroma'])
    fr = grade(fr, uni if not tr or tr[1] != 'leak' else 'evasion', fi)
    if uni == 'evasion' and b > 56.5:  # lumière dorée de respiration
        fr = fr + leak_layer(b, 0.12)
    if uni == 'final':
        ib = clamp((b - 68) / 8)
        fr = lasers(fr, b, 0.35 + 0.65 * ib)
        fr = confetti(fr, (b - 72) * BEAT, 1.0) if b > 72 else fr
        if b >= 75.5:  # convergence vers le centre
            p = (b - 75.5) / 0.5; fr = radial_blur(fr, 0.45 * e_in(p)); fx['white'] = max(fx['white'], e_in(p))
    if fx['white']: fr = fr * (1 - fx['white']) + 255 * fx['white']
    if fx['flash']: fr = fr + (255 - fr) * fx['flash']
    return fr, uni

def final_frame(b, fi):
    """Explosion + reveal du logo (temps 76 -> 88)."""
    S = sprites(); tau = (b - 76) * BEAT
    # fond : foule floutée très sombre + halo rose/violet
    bg = img_frame('media/final/nuit_l-etoile-club_3.jpg', lerp(1.25, 1.05, e_out(tau / 3)), (0, 0), 0.5).astype(np.float32)
    bg = cv2.GaussianBlur(cv2.resize(bg, (W // 4, H // 4)), (0, 0), 6); bg = cv2.resize(bg, (W, H)) * 0.22
    halo = np.exp(-(RR / 760) ** 2)[..., None] * np.array([120, 20, 90], np.float32)
    fr = bg * np.array([0.8, 0.6, 1.1], np.float32) + halo * (0.8 + 0.2 * math.sin(b * math.pi))
    fr = lasers(fr, b, 0.32 * clamp(tau / 1.5))
    # onde de choc et anneaux
    for k, (dl, col) in enumerate([(0, (255, 255, 255)), (0.12, (255, 30, 142)), (0.28, (168, 85, 247))]):
        tt = tau - dl
        if 0 < tt < 1.0:
            R = 2300 * e_out(tt / 1.0) ** 0.7
            fr = fr + ring(R, 14 + 22 * tt, col, 170 * (1 - tt / 1.0) ** 2)
    if tau < 1.2:
        fr = shockwave(fr, 2300 * e_out(tau / 1.2) ** 0.8, 90 * (1 - tau / 1.2))
    fr = fr + particles(tau)
    fr = fr * VIGN
    # pulsation de lumière sur chaque temps
    ph = b - math.floor(b); beat_k = max(0, 1 - ph / 0.3)
    # logo
    pl = (b - 76.15) / 1.0
    if pl > 0:
        sc = lerp(1.5, 1.0, e_back(pl, 1.3)) * (1 + 0.012 * beat_k)
        a = e_out(pl / 0.45)
        overlay(fr, S['LOGOGLOW'], CX, 820, sc * 1.04, a * (0.35 + 0.25 * beat_k), add=True)
        lg = S['LOGO']
        if pl < 0.5:
            blur = int(lerp(25, 0, pl / 0.5)) * 2 + 1
            lg = lg.copy(); lg = cv2.GaussianBlur(lg, (blur, blur), 0) if blur > 1 else lg
        overlay(fr, lg, CX, 820, sc, a)
        # reflet qui traverse le logo
        ps = (b - 78.0) / 1.2
        if 0 < ps < 1:
            band = np.exp(-((XX[600:1040] - lerp(-200, W + 200, e_io(ps)) + (YY[600:1040] - 820) * 0.35) / 60) ** 2)
            m = cv2.resize(S['LOGO'][..., 3], None, fx=sc, fy=sc) if sc != 1 else S['LOGO'][..., 3]
            mm = np.zeros((440, W), np.float32); h, w = m.shape; x0, y0 = int(CX - w / 2), int(220 - h / 2)
            xa, ya = max(0, x0), max(0, y0); mm[ya:min(440, y0 + h), xa:min(W, x0 + w)] = m[ya - y0:min(440, y0 + h) - y0, xa - x0:min(W, x0 + w) - x0] / 255
            fr[600:1040] += (band * mm)[..., None] * 200
    pt = (b - 78.5) / 0.6
    if pt > 0: overlay(fr, S['TAG'], CX, 1020 + 30 * (1 - e_out(pt)), 1.0, e_out(pt))
    pc = (b - 80.5) / 0.6
    if pc > 0: overlay(fr, S['CTA'], CX, 1215, lerp(0.6, 1.0, e_back(pc)) * (1 + 0.02 * beat_k), e_out(pc / 0.5))
    pf = (b - 82.5) / 0.7
    if pf > 0:
        overlay(fr, S['L1'], CX, 1365, 1.0, e_out(pf) * 0.9); overlay(fr, S['L2'], CX, 1415, 1.0, e_out((b - 82.8) / 0.7) * 0.9)
    gr = cv2.resize(GRAIN[fi % 6], (W, H), interpolation=cv2.INTER_NEAREST)
    fr = fr + gr[..., None] * 3.5
    # flash d'explosion
    fl = 1 - e_out(tau / 0.55)
    if fl > 0: fr = fr + (255 - fr) * fl
    return fr

def frame(fi):
    b = fi / FPS / BEAT
    if b >= 76:
        fr = final_frame(b, fi)
    else:
        fr, uni = base_frame(b, fi)
        fr = draw_labels(fr, b)
    return np.clip(fr, 0, 255).astype(np.uint8)

def work(rng):
    os.makedirs('out/frames', exist_ok=True)
    for fi in rng:
        p = f'out/frames/{fi:05d}.jpg'
        if os.path.exists(p): continue
        cv2.imwrite(p, cv2.cvtColor(frame(fi), cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 96])
    return len(rng)

if __name__ == '__main__':
    N = int(round(TOTAL_BEATS * BEAT * FPS))
    if len(sys.argv) > 1:
        os.makedirs('out/check', exist_ok=True)
        for a in sys.argv[1:]:
            fi = int(round(float(a) * BEAT * FPS))
            cv2.imwrite(f'out/check/b{float(a):05.2f}.jpg', cv2.cvtColor(frame(fi), cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 88])
        sys.exit()
    nproc = int(os.environ.get('NPROC', '14'))
    chunks = [range(k, N, nproc) for k in range(nproc)]
    with Pool(nproc) as pool:
        print(sum(pool.map(work, chunks)), 'images')

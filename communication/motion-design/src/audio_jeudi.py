"""Pistes son du reel « Jeudi soir », calées sur 107 BPM (tempo de Tití Me Preguntó).
sfx.wav : effets seuls (pour ajouter le morceau dans Instagram) ; dembow.wav : effets + beat dembow original."""
import numpy as np, wave
SR, DUR, BPM = 44100, 30.0, 107
B = 60 / BPM; N = int(SR * DUR); tt = np.arange(N) / SR
rng = np.random.default_rng(3)
def env(n, a=.002, d=.2): t = np.arange(n) / SR; return np.minimum(1, t / max(a, 1e-6)) * np.exp(-t / d)
def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); y = np.empty_like(x); acc = 0.0
    for k in range(len(x)): acc = (1 - a) * x[k] + a * acc; y[k] = acc
    return y
def hp(x, fc): return x - lowpass(x, fc)
def note(m): return 440 * 2 ** ((m - 69) / 12)
class Track:
    def __init__(s): s.L = np.zeros(N); s.R = np.zeros(N)
    def put(s, sig, t, g=1.0, pan=0.0):
        i = int(t * SR); j = min(N, i + len(sig))
        if i >= N or i < 0: return
        s.L[i:j] += sig[:j - i] * g * (1 - max(0, pan)); s.R[i:j] += sig[:j - i] * g * (1 + min(0, pan))
sfx, beat = Track(), Track()
# --- sons de base ---
n = int(.5 * SR); kick = np.sin(2 * np.pi * np.cumsum(42 + 110 * np.exp(-np.arange(n) / SR / .035)) / SR) * env(n, .001, .2)
n = int(.22 * SR); snare = hp(lowpass(rng.standard_normal(n), 6000), 1200) * env(n, .001, .06) * .8 + np.sin(2 * np.pi * 190 * np.arange(n) / SR) * env(n, .001, .04) * .5
n = int(.05 * SR); hat = hp(rng.standard_normal(n), 8000) * env(n, .0005, .012)
def impact(g=1.0):
    n = int(1.6 * SR); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * np.cumsum(38 + 90 * np.exp(-t / .05)) / SR) * np.exp(-t / .45) + lowpass(rng.standard_normal(n), 1500) * np.exp(-t / .12) * .7) * g
def whoosh(d, up=True):
    n = int(d * SR); x = rng.standard_normal(n); out = np.zeros(n); seg = int(.015 * SR)
    for i in range(0, n, seg):
        f = 400 + 6000 * ((i / n) if up else 1 - i / n); out[i:i + seg] = hp(lowpass(x[i:i + seg], f * 1.5), f * .5)
    return out * np.sin(np.pi * np.arange(n) / n) ** 2
def riser(d):
    n = int(d * SR); t = np.arange(n) / SR; p = (t / d) ** 2
    return hp(rng.standard_normal(n), 2000) * p * .5 + np.sin(2 * np.pi * np.cumsum(150 + 1200 * p) / SR) * p * .2
def click():
    n = int(.08 * SR); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 2000 * t) * .6 + hp(rng.standard_normal(n), 3000) * .4) * env(n, .0005, .012)
def shutter():
    n = int(.12 * SR); return hp(rng.standard_normal(n), 2500) * (env(n, .0005, .01) + .6 * np.roll(env(n, .0005, .015), int(.05 * SR)))
bt = lambda b: b * B
# --- effets sur les temps forts (mêmes temps que la vidéo) ---
for b, g in [(0, 1), (1, 1), (2, .6), (3, .6), (4, .8), (10, 1.2), (40, 1.2), (46, 1), (47, .8), (48, 1.3)]: sfx.put(impact(g * .7), bt(b))
for i in range(6):
    sfx.put(whoosh(.45, True), bt(10 + i * 4) - .2, .6, .5 if i % 2 else -.5); sfx.put(impact(.45), bt(10 + i * 4))
    sfx.put(impact(.3), bt(11 + i * 4)); sfx.put(whoosh(.35, False), bt(13.7 + i * 4), .35)
sfx.put(click(), bt(8) - .01, 1.0); sfx.put(impact(.6), bt(8))
sfx.put(riser(bt(10) - bt(8.2)), bt(8.2), .9); sfx.put(whoosh(.5, True), bt(4) - .25, .6)
for k in range(34, 40): sfx.put(shutter(), bt(k), .8, .3 * (1 if k % 2 else -1)); sfx.put(impact(.35), bt(k))
sfx.put(whoosh(.6, True), bt(42) - .3, .5); sfx.put(riser(bt(46) - bt(44)), bt(44), .7); sfx.put(whoosh(.5, True), bt(46) - .25, .5)
sfx.put(click(), bt(50.5), .5)
# --- beat dembow original (fa mineur) ---
PROG = [53, 49, 56, 51]  # Fa, Ré b, La b, Mi b
for k in range(int(DUR / B) + 1):
    b = k; t = bt(b)
    full = 10 <= b < 42 or b >= 46
    light = 4 <= b < 10 or 42 <= b < 46
    if full or (light and b % 2 == 0): beat.put(kick, t, .9 if full else .5)
    if full:
        for s16 in (.75, 1.5) if b % 2 == 0 else (.75,):
            pass
    # motif dembow sur 2 temps : caisse claire à 3/4 du 1er temps et sur le 2e temps et demi
    if full and b % 2 == 0:
        beat.put(snare, t + .75 * B, .55, .1); beat.put(snare, t + 1.5 * B, .55, .1)
    if full or light:
        for q in (0, .5):
            beat.put(hat, t + q * B, .18 if q else .1, -.25)
        if 34 <= b < 40:
            for q in (.25, .75): beat.put(hat, t + q * B, .1, .25)
    if full:
        root = PROG[(k // 4) % 4] - 24; n = int(B * .95 * SR); tn = np.arange(n) / SR
        bass = np.sin(2 * np.pi * note(root) * tn) * env(n, .003, .45) * .55
        beat.put(np.tanh(bass * 2) * .45, t)
    if (full or light) and b % 4 == 0:
        n = int(4 * B * SR); tn = np.arange(n) / SR; r = PROG[(k // 4) % 4]
        pad = sum(np.sign(np.sin(2 * np.pi * note(m) * tn * (1 + d))) for m in (r, r + 3, r + 7) for d in (-.003, .003)) / 6
        beat.put(lowpass(pad, 1100) * np.minimum(1, tn / .05) * .09, t)
beat.put(impact(.8), bt(53))
def write(name, L, R):
    mix = np.stack([L, R], 1) * np.interp(tt, [0, .02, 29.2, 30], [0, 1, 1, 0])[:, None]
    mix = np.tanh(mix * 1.2) / np.tanh(1.2); mix /= np.max(np.abs(mix)) / .9
    with wave.open(name, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype('<i2').tobytes())
write('sfx.wav', sfx.L, sfx.R)
write('dembow.wav', sfx.L * .8 + beat.L, sfx.R * .8 + beat.R)
print('ok')

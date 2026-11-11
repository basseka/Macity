"""Bande-son originale (synthétisée, donc libre de droits) calée sur la timeline du reel."""
import numpy as np, wave
SR, DUR, BPM = 44100, 30.0, 120
N = int(SR * DUR); B = 60 / BPM
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)
def at(t): return int(t * SR)
def put(sig, t, gain=1.0, pan=0.0):
    i = at(t); j = min(N, i + len(sig))
    if i >= N: return
    L[i:j] += sig[:j - i] * gain * (1 - max(0, pan)); R[i:j] += sig[:j - i] * gain * (1 + min(0, pan))
def env(n, a=.002, d=.2):
    t = np.arange(n) / SR; return np.minimum(1, t / a) * np.exp(-t / d)
def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); y = np.zeros_like(x); acc = 0.0
    for k in range(len(x)): acc = (1 - a) * x[k] + a * acc; y[k] = acc
    return y
def hp(x, fc): return x - lowpass(x, fc)
def note(m): return 440 * 2 ** ((m - 69) / 12)
def saw(f, n, det=0.0):
    t = np.arange(n) / SR; return 2 * ((t * f * (1 + det)) % 1) - 1

kick = np.sin(2 * np.pi * np.cumsum(45 + 95 * np.exp(-np.arange(int(.35 * SR)) / SR / .04)) / SR) * env(int(.35 * SR), .001, .16)
hat_n = int(.06 * SR); hat = hp(rng.standard_normal(hat_n), 7000) * env(hat_n, .0005, .018)
ohat_n = int(.22 * SR); ohat = hp(rng.standard_normal(ohat_n), 6000) * env(ohat_n, .001, .07)
clap_n = int(.25 * SR); cl = hp(lowpass(rng.standard_normal(clap_n), 3500), 900)
clap = cl * (env(clap_n, .001, .09) + .6 * np.roll(env(clap_n, .001, .02), int(.012 * SR)))

PROG = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [48, 52, 55]), (55, [55, 59, 62])]  # Am F C G
def chord_at(t): return PROG[int(t // (4 * B)) % 4]

# Pad (tout le long, plus discret en intro)
pad = np.zeros(N)
for bar in range(int(DUR / (4 * B)) + 1):
    t0 = bar * 4 * B; n = int(4 * B * SR); _, ch = chord_at(t0)
    s = sum(saw(note(m + 12), n, d) for m in ch for d in (-.004, .004)) / 6
    seg = lowpass(s, 1400) * np.minimum(1, np.arange(n) / (.3 * SR))
    i = at(t0); j = min(N, i + n)
    if i < N: pad[i:j] += seg[:j - i]
duck = np.ones(N)
for k in range(int(9 / B), int(27 / B)):
    i = at(k * B); n = int(.3 * SR); j = min(N, i + n); duck[i:j] = .35 + .65 * (np.arange(j - i) / n) ** .6
tt = np.arange(N) / SR
pad_gain = np.interp(tt, [0, 3, 8.8, 9, 27, 28, 30], [.0, .16, .2, .26, .26, .3, .0])
L += pad * pad_gain * duck * .9; R += pad * pad_gain * duck

# Batterie et basse
for k in range(int(DUR / B)):
    t = k * B
    if 4 <= t < 9 and k % 2 == 0: put(kick, t, .55)
    if 9 <= t < 27:
        put(kick, t, .95)
        if k % 2 == 1: put(clap, t, .42, .1)
        put(ohat, t + B / 2, .16, -.3)
        root, ch = chord_at(t)
        for h in (0, .5):
            n = int(.22 * SR); f = note(root - 12)
            bs = lowpass(saw(f, n) + .5 * saw(f, n, .01), 600) * env(n, .003, .09)
            put(bs, t + h * B + B / 2 if h else t + B / 2, .5)
        if k % 4 in (1, 3):
            n = int(.18 * SR)
            st = sum(saw(note(m + 24), n) for m in ch) / 3
            put(lowpass(st, 2600) * env(n, .002, .06), t + B * .75, .17, .35)
    if 2 <= t < 27:
        for q in (0, .25, .5, .75):
            put(hat, t + q * B, .1 if q in (0, .5) else .06, .25)

# Effets : whoosh, clic, riser, impact
def whoosh(d, up=True, g=.5):
    n = int(d * SR); x = rng.standard_normal(n)
    out = np.zeros(n); seg = int(.02 * SR)
    for i in range(0, n, seg):
        f = 300 + 5000 * ((i / n) if up else (1 - i / n))
        out[i:i + seg] = hp(lowpass(x[i:i + seg], f * 1.6), f * .5)
    e = np.sin(np.pi * np.arange(n) / n) ** 2
    return out * e * g
def click():
    n = int(.08 * SR); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 1800 * t) * .6 + hp(rng.standard_normal(n), 3000) * .4) * env(n, .0005, .012)
def pop():
    n = int(.25 * SR); t = np.arange(n) / SR
    return np.sin(2 * np.pi * (880 + 600 * np.exp(-t / .03)) * t) * env(n, .001, .07)
put(whoosh(1.3, True, .55), 0.0)
put(whoosh(.9, True, .35), 5.2, pan=.3)
put(click(), 7.03, .9); put(pop(), 7.05, .35)
put(whoosh(.6, False, .45), 7.5, pan=-.2)
rn = int(1.4 * SR); rt = np.arange(rn) / SR
riser = hp(rng.standard_normal(rn), 2500) * (rt / 1.4) ** 2 * .32 + np.sin(2 * np.pi * np.cumsum(200 + 900 * (rt / 1.4) ** 2) / SR) * (rt / 1.4) ** 2 * .12
put(riser, 7.6)
for s in [10.5, 12.3, 14.1, 15.9, 17.7, 19.5]: put(whoosh(.55, True, .32), s - .05, pan=.4 if int(s) % 2 else -.4)
for s in [14.6, 17.2, 19.9, 23.4]: put(whoosh(.7, False, .28), s)
put(riser * .8, 26.0)
imp_n = int(2.5 * SR); it = np.arange(imp_n) / SR
impact = np.sin(2 * np.pi * np.cumsum(70 * np.exp(-it / .6) + 35) / SR) * np.exp(-it / .7) * .9 + lowpass(rng.standard_normal(imp_n), 900) * np.exp(-it / .35) * .5
put(impact, 27.45)
put(pop(), 28.4, .3)

mix = np.stack([L, R], 1)
mix *= np.interp(tt, [0, .05, 29.0, 30], [0, 1, 1, 0])[:, None]
mix = np.tanh(mix * 1.3) / np.tanh(1.3)
mix /= np.max(np.abs(mix)) / .9
with wave.open('music.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((mix * 32767).astype('<i2').tobytes())
print('ok', mix.shape)

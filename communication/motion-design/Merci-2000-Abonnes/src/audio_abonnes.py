"""Bande-son originale « Merci 2 000 abonnés Instagram », version luxe (100 % synthétisée, libre de droits). 120 BPM, drop à 2,5 s. Sortie : abonnes_audio.wav"""
import numpy as np, wave

SR, DUR = 44100, 16.0
N = int(SR * DUR); L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)
B = 0.5; T0 = 2.5                      # temps, ancrage du drop

def put(sig, t, g=1.0, pan=0.0):
    i = int(t * SR)
    if i < 0: sig = sig[-i:]; i = 0
    j = min(N, i + len(sig))
    if i >= N or j <= i: return
    L[i:j] += sig[:j - i] * g * (1 - max(0, pan)); R[i:j] += sig[:j - i] * g * (1 + min(0, pan))

def tvec(d): return np.arange(int(d * SR)) / SR
def lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); y = np.empty_like(x); acc = 0.0
    for k in range(len(x)): acc = (1 - a) * x[k] + a * acc; y[k] = acc
    return y
def hp(x, fc): return x - lp(x, fc)
def noise(d): return rng.standard_normal(int(d * SR))
def nf(f): return 440 * 2 ** ((f - 69) / 12)

# ---------- Instruments ----------
def kick(g=1.0):
    t = tvec(.45); f = 45 + 140 * np.exp(-t / .035)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .16)
    s[:200] += np.linspace(1, 0, 200) * .6
    return np.tanh(s * 2.4) * g
def clap(g=.5):
    n = noise(.25); t = tvec(.25)
    e = np.exp(-t / .06) + .6 * np.exp(-((t - .012) % .011) / .002) * (t < .035)
    return hp(lp(n, 3200), 900) * e * g
def hat(g=.18, d=.05):
    t = tvec(d); return hp(noise(d), 7000) * np.exp(-t / (d / 3)) * g
def sub_hit(g=1.0, d=1.6):
    t = tvec(d); f = 38 + 120 * np.exp(-t / .06)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (d * .35))
    return np.tanh(s * 2.5) * g
def crash(g=.35, d=2.2):
    t = tvec(d); return hp(noise(d), 4500) * np.exp(-t / .7) * g
def bass(note, d, g=.5):
    t = tvec(d); f = nf(note)
    s = np.sin(2 * np.pi * f * t) + .5 * np.sin(2 * np.pi * 2 * f * t) + .25 * np.sign(np.sin(2 * np.pi * f * t)) * .4
    e = np.minimum(1, t / .005) * np.exp(-t / (d * .9)) * (1 - np.clip((t - d + .03) / .03, 0, 1))
    return np.tanh(s * 1.4) * e * g
def saw(f, t, det=0.0):
    ph = (f * (1 + det)) * t; return 2 * (ph - np.floor(ph + .5))
def chord(notes, d, g=.12, att=.01, rel=.25):
    t = tvec(d); s = np.zeros_like(t)
    for n in notes:
        for det in (-.006, 0, .006): s += saw(nf(n), t, det)
    s = lp(s, 2600)
    e = np.minimum(1, t / att) * np.where(t > d - rel, np.clip((d - t) / rel, 0, 1), 1)
    return s * e * g
def pluck(note, g=.22, d=.32):
    t = tvec(d); f = nf(note)
    s = saw(f, t) * .6 + np.sin(2 * np.pi * f * 2 * t) * .4
    return lp(s, 3800) * np.exp(-t / .09) * g
def pop(g=.35, f0=900):
    t = tvec(.09); f = f0 * (1 + 1.5 * np.exp(-t / .01))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .025) * g
def bloop(g=.3, f0=520):
    t = tvec(.18); f = f0 * (1 + 1.2 * (1 - np.exp(-t / .04)))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .06) * g
def click(g=.25):
    t = tvec(.03); return hp(noise(.03), 2500) * np.exp(-t / .004) * g
def ding(g=.3):
    t = tvec(1.2); return sum(np.sin(2 * np.pi * f * t) * np.exp(-t / (.5 / (k + 1))) / (k + 1) for k, f in enumerate([1318, 2637, 3951])) * g
def tick(g=.12):
    t = tvec(.04); return np.sin(2 * np.pi * 2400 * t) * np.exp(-t / .006) * g
def whoosh(d, up=True, g=.45):
    n = int(d * SR); x = noise(d); out = np.zeros(n); seg = int(.015 * SR)
    for i in range(0, n, seg):
        k = i / n; f = 300 + 6500 * (k if up else 1 - k) ** 1.6
        out[i:i + seg] = hp(lp(x[i:i + seg], f * 1.6), f * .5)
    return out * np.sin(np.pi * np.arange(n) / n) ** 2 * g
def riser(d, g=.35):
    t = tvec(d); f = 200 * 2 ** (t / d * 3)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * .5 + whoosh(d, True, 1.0)[:len(t)] * .7
    return s * (t / d) ** 2 * g
def drone(d, g=.12):
    t = tvec(d); s = np.sin(2 * np.pi * 55 * t) + .5 * np.sin(2 * np.pi * 82.4 * t + np.sin(t * .7))
    return s * np.minimum(1, t / .4) * np.minimum(1, (d - t) / .2) * g

# ---------- Sons « luxe » ----------
def pad(notes, d, g=.08, att=.5, rel=1.0, fc=1500):
    t = tvec(d); s = np.zeros_like(t)
    for n in notes:
        f = nf(n)
        for det in (-.004, 0, .004): s += saw(f, t, det) * .5 + np.sin(2 * np.pi * f * (1 + det) * t)
    s = lp(lp(s, fc), fc * 1.2)
    e = np.minimum(1, t / att) * np.where(t > d - rel, np.clip((d - t) / rel, 0, 1), 1)
    return s * e * g
def bell(note, g=.16, d=2.2):
    t = tvec(d); f = nf(note)
    s = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t / (dd)) for r, a, dd in ((1, 1, .9), (2.01, .45, .5), (3.0, .25, .3), (4.17, .15, .2), (5.43, .08, .12)))
    return s * np.minimum(1, t / .002) * g
def keys(note, g=.14, d=1.4):
    t = tvec(d); f = nf(note)
    s = np.sin(2 * np.pi * f * t) + .35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t / .3) + .15 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t / .15)
    return s * np.exp(-t / .55) * np.minimum(1, t / .003) * g
def glint(g=.05):
    d = .5; t = tvec(d); f = rng.uniform(3500, 7500)
    return np.sin(2 * np.pi * f * t) * np.exp(-t / .07) * g
def shimmer(a, d, dens=20, g=.05):
    for _ in range(int(d * dens)): put(glint(g * rng.uniform(.4, 1)), a + rng.random() * d, pan=rng.uniform(-.9, .9))
def soft_kick(g=.7):
    t = tvec(.5); f = 42 + 90 * np.exp(-t / .03)
    return np.tanh(np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .2) * 1.6) * g
def snap(g=.18):
    t = tvec(.18); return hp(lp(noise(.18), 5000), 1500) * np.exp(-t / .035) * g
def applause(a, d, g=.5):
    for i in range(int(d * 220)):
        tt = a + (rng.random() ** 1.6) * d; env = (1 - (tt - a) / d) ** 1.5
        put(clap(.1 * env * g * (.5 + rng.random())), tt, pan=rng.uniform(-.8, .8))
    put(lp(hp(noise(d), 700), 4500) * np.exp(-tvec(d) / (d * .45)) * .1 * g, a)

# Progression ample : Fmaj9 - G6 - Em7 - Am9 (do majeur)
PROG = [(41, [57, 64, 67, 72]), (43, [59, 62, 64, 71]), (40, [55, 59, 62, 67]), (45, [60, 64, 67, 71])]
ARP = [0, 1, 2, 3, 2, 1, 3, 2]

def groove(a, b, drums=True, arp=True, g=1.0):
    k = int(round((a - T0) / B)); t = a
    while t < b - 1e-6:
        root, ch = PROG[(k // 4) % 4]
        if drums:
            put(soft_kick(.75 * g), t)
            if k % 2 == 1: put(snap(.2 * g), t, pan=.08)
            put(hat(.06 * g, .04), t + B / 2, pan=.35)
            put(bass(root, B * .9, .3 * g), t)
        if k % 4 == 0:
            p = pad(ch, B * 4 + .4, .06 * g, .25, .5); put(p, t, pan=-.2); put(p, t, .7, pan=.2)
        if arp:
            for h in (0, 1):
                put(keys(ch[ARP[(2 * k + h) % 8]] + 12, .1 * g), t + h * B / 2, pan=(.3 if h else -.3))
        t += B; k += 1

# 0 - 2,5 : compteur, nappe qui monte, cloches à chaque tic
put(pad([57, 64, 67, 71], 2.8, .07, 1.2, .3, 900), 0, pan=-.1); put(pad([45, 52], 2.8, .06, 1.0, .3, 600), 0, pan=.1)
TICKS = [.35, .7, 1.0, 1.25, 1.46, 1.64, 1.8, 1.94, 2.06, 2.17]
SC = [76, 79, 81, 83, 84, 86, 88, 91, 93, 95]
for i, tk in enumerate(TICKS): put(bell(SC[i], .09 + i * .006, 1.2), tk, pan=(i % 2 - .5) * .5); put(tick(.06), tk)
put(riser(1.4, .3), 1.1); shimmer(1.4, 1.1, 30, .035)
# 2,5 : 2 000
put(sub_hit(.9, 2.4), 2.5); put(crash(.22, 3), 2.5); put(whoosh(.5, False, .2), 2.4)
put(pad([60, 64, 67, 72, 76, 79], 2.6, .07, .02, 1.2, 2600), 2.5)
for n in (84, 88, 91, 96): put(bell(n, .12, 2.6), 2.52 + (n - 84) * .004)
shimmer(2.5, 2.2, 40, .06); applause(2.6, 3.0, .55)
groove(2.5, 5.5)
# 5,5 : Merci (respiration : nappe et piano seuls)
put(sub_hit(.6, 1.8), 5.5); put(whoosh(.5, True, .18), 5.3)
put(pad([53, 60, 64, 69, 72], 2.2, .085, .3, .8, 1300), 5.5)
for i, n in enumerate([72, 76, 79, 84, 88]): put(keys(n, .13, 2.0), 5.65 + i * .12, pan=(i - 2) * .2)
put(bell(91, .12, 2.5), 6.25); shimmer(6.1, 1.2, 18, .04)
groove(6.0, 7.5, drums=False, arp=True, g=.8)
# 7,5 : l'appli
put(sub_hit(.7, 1.6), 7.5); put(crash(.15, 2), 7.5); put(whoosh(.45, True, .2), 7.3)
for a in (9.0, 10.5): put(whoosh(.35, True, .16), a - .25, pan=.4); put(bell(88, .1, 1.5), a + .1); shimmer(a, .6, 20, .04)
groove(7.5, 12.0)
put(riser(.9, .22), 11.1)
# 12 : fin
put(sub_hit(.9, 2.4), 12.0); put(crash(.2, 3), 12.0); put(whoosh(.6, False, .18), 11.85)
for n in (84, 88, 91, 96): put(bell(n, .11, 2.6), 12.02)
shimmer(12.0, 1.8, 35, .05); applause(12.1, 2.2, .35)
groove(12.0, 14.0, g=.9)
put(pad([60, 64, 67, 71, 74, 79], 2.4, .08, .05, 1.6, 2200), 14.0); put(bass(36, 2.2, .3), 14.0)
put(bell(84, .14, 2.4), 14.0); put(bell(91, .1, 2.4), 14.25); shimmer(14.0, 1.6, 20, .04)

# ---------- Mixage : petite réverbération (échos diffus) ----------
x = np.stack([L, R])
for dl, gg in ((.071, .22), (.113, .18), (.167, .15), (.233, .12), (.311, .09)):
    s = int(dl * SR); x[0, s:] += x[1, :-s] * gg * .5; x[1, s:] += x[0, :-s] * gg * .5
x = np.tanh(x * 1.05) / np.tanh(1.05)
fade = np.ones(N); fn = int(1.2 * SR); fade[-fn:] = np.linspace(1, 0, fn) ** 2
x *= fade; x /= np.max(np.abs(x)) / .92
pcm = (x.T * 32767).astype(np.int16)
with wave.open('abonnes_audio.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print('abonnes_audio.wav', DUR, 's')

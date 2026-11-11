"""Bande-son originale « Merci 2 000 abonnés » (100 % synthétisée, libre de droits). 120 BPM, drop à 2,5 s. Sortie : abonnes_audio.wav"""
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

# ---------- Progression (do majeur, festive) : C G Am F ----------
PROG = [(48, [64, 67, 72]), (55, [62, 67, 71]), (57, [64, 69, 72]), (53, [65, 69, 72])]
MEL = [72, 74, 76, 79, 76, 74, 72, 67]

def beat_section(a, b, full=True, melody=False, filt=False):
    k = int(round((a - T0) / B)); t = a
    while t < b - 1e-6:
        root, ch = PROG[(k // 4) % 4]
        put(kick(.9 if full else .55), t)
        if k % 2 == 1: put(clap(.42 if full else .25), t, pan=.05)
        put(hat(.14), t + B / 2, pan=.3); put(hat(.08, .03), t + B / 4, pan=-.3); put(hat(.08, .03), t + 3 * B / 4, pan=-.3)
        put(bass(root - 12, B / 2 * .95, .42 if full else .3), t + B / 2)
        if k % 4 == 0:
            c = chord(ch, B * 4 * .98, .07 if full else .045)
            put(lp(c, 900) if filt else c, t, pan=-.15); put(lp(c, 900) if filt else c, t, .6, pan=.15)
        if melody: put(pluck(MEL[k % 8] + (12 if k % 16 >= 8 else 0)), t + B / 2, pan=.2)
        t += B; k += 1

def applause(a, d, g=.5):
    n = int(d * 260)
    for i in range(n):
        tt = a + (rng.random() ** 1.6) * d
        env = (1 - (tt - a) / d) ** 1.5
        put(clap(.12 * env * g * (.5 + rng.random())), tt, pan=rng.uniform(-.8, .8))
    put(lp(hp(noise(d), 600), 5000) * np.exp(-tvec(d) / (d * .45)) * .12 * g, a)

# 0 - 2,5 : le compteur monte
TICKS = [.35, .7, 1.0, 1.25, 1.46, 1.64, 1.8, 1.94, 2.06, 2.17]
put(drone(2.6, .1), 0); put(sub_hit(.5, 1.0), 0.0)
for i, tk in enumerate(TICKS):
    put(tick(.16), tk); put(bloop(.18, 300 + i * 45), tk, pan=(i % 2 - .5) * .4)
put(riser(1.3, .5), 1.2)
for i in range(12): put(clap(.04 + i * .02), 2.0 + i * .042)
# 2,5 : DROP 2 000
put(sub_hit(1.0, 2.0), DROP := 2.5); put(crash(.5, 2.6), DROP); put(whoosh(.5, False, .35), 2.4)
applause(2.5, 3.2, .9)
for k in range(8): put(pop(.2, 700 + k * 120), 2.55 + k * .05, pan=(k % 3 - 1) * .5)
put(ding(.25), 2.95); put(pop(.3, 1000), 3.0)
beat_section(2.5, 5.5, full=True, melody=True)
put(riser(.6, .3), 4.9)
# 5,5 : MERCI
put(sub_hit(.9), 5.5); put(crash(.4), 5.5); put(whoosh(.35, True, .3), 5.35)
for i in range(5): put(pop(.35, 600 + i * 150), 5.75 + i * .125, pan=(i - 2) * .2)
put(ding(.3), 6.45)
beat_section(5.5, 7.5, full=False, melody=True, filt=True)
# 7,5 : l'appli
put(sub_hit(.8), 7.5); put(crash(.3), 7.5); put(whoosh(.45, True, .35), 7.3)
for a in (9.0, 10.5): put(whoosh(.35, True, .3), a - .2, pan=.4); put(pop(.35, 950), a + .1); put(ding(.15), a + .12)
beat_section(7.5, 12.0, full=True, melody=True)
put(riser(.8, .35), 11.2)
# 12 : fin
put(sub_hit(1.0, 2.2), 12.0); put(crash(.45, 3), 12.0); put(whoosh(.6, False, .3), 11.85)
applause(12.0, 2.4, .5)
beat_section(12.0, 14.5, full=True, melody=True)
put(pop(.3, 900), 12.5); put(click(.45), 13.5); put(ding(.3), 13.55)
put(chord([72, 76, 79, 84], 2.0, .07, .02, 1.2), 14.5, pan=-.1); put(chord([48, 55, 60], 2.0, .06, .02, 1.2), 14.5, pan=.1); put(sub_hit(.6, 1.5), 14.5)

# ---------- Mixage ----------
x = np.stack([L, R])
x = np.tanh(x * 1.1) / np.tanh(1.1)
fade = np.ones(N); fn = int(1.0 * SR); fade[-fn:] = np.linspace(1, 0, fn) ** 2
x *= fade; x /= np.max(np.abs(x)) / .92
pcm = (x.T * 32767).astype(np.int16)
with wave.open('abonnes_audio.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print('abonnes_audio.wav', DUR, 's')

"""Bande-son originale de la pub « Ta ville bouge » (100 % synthétisée, libre de droits).
Calée sur pub.html : grille 100 BPM (1 temps = 0,6 s) ancrée sur le drop à 3,4 s. Sortie : pub_audio.wav"""
import numpy as np, wave

SR, DUR = 44100, 28.0
N = int(SR * DUR); L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)
B = 0.6; T0 = 3.4                      # temps, ancrage du drop

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

# ---------- Progression (la mineur, énergique) : Am F C G ----------
PROG = [(57, [69, 72, 76]), (53, [65, 69, 72]), (60, [67, 72, 76]), (55, [67, 71, 74])]
MEL = [76, 74, 72, 74, 76, 79, 76, 74]

def beat_section(a, b, full=True, melody=False, filt=False):
    k = 0; t = a
    while t < b - 1e-6:
        bar_i = int(round((t - T0) / B)) // 4
        root, ch = PROG[bar_i % 4]
        kg = .9 if full else .55
        put(kick(kg), t)
        if k % 2 == 1: put(clap(.42 if full else .25), t, pan=.05)
        put(hat(.14), t + B / 2, pan=.3); put(hat(.08, .03), t + B / 4, pan=-.3); put(hat(.08, .03), t + 3 * B / 4, pan=-.3)
        put(bass(root - 12, B / 2 * .95, .42 if full else .3), t + B / 2)
        if k % 4 == 0:
            c = chord(ch, B * 4 * .98, .07 if full else .045)
            put(lp(c, 900) if filt else c, t, pan=-.15); put(lp(c, 900) if filt else c, t, .6, pan=.15)
        if melody:
            put(pluck(MEL[k % 8] + (12 if k % 16 >= 8 else 0)), t + B / 2, pan=.2)
        t += B; k += 1

# 0 - 2,05 : accroche terne (bourdon + tic-tac)
put(drone(2.2), 0)
for i in range(4): put(tick(), .2 + i * .5)
put(bloop(.18, 300), 1.0)          # « RIEN »
# 2,05 - 3,35 : « Eh bien… » silence puis montée
put(riser(1.25, .4), 2.15)
for i in range(8): put(clap(.05 + i * .02), 2.75 + i * .075)
# 3,4 : drop
put(sub_hit(1.0), 3.38); put(crash(.4), 3.38); put(whoosh(.5, False, .35), 3.3)
beat_section(T0, 10.6, full=True)
for k in range(6):                  # mots du montage
    put(pop(.35, 800 + k * 90), 4.6 + k * .6); put(whoosh(.35, True, .22), 4.6 + k * .6 - .3)
put(sub_hit(.7, 1.0), 8.2); put(crash(.25), 8.2)
for k in range(6): put(pop(.18, 1300), 8.2 + k * .07)
for k in range(15): put(tick(.08), 9.0 + k * .06)     # compteur
# 10,6 - 13 : chaos des onglets (break filtré)
beat_section(10.6, 13.0, full=False, filt=True)
for k in range(10): put(click(.3), 10.62 + k * .17); put(pop(.12, 600 + k * 40), 10.64 + k * .17)
put(riser(1.4, .45), 11.6); put(whoosh(.5, False, .4), 12.75)
# 13 : téléphone
put(sub_hit(.9), 12.95); put(crash(.35), 12.95)
beat_section(13.0, 17.8, full=True, melody=True)
put(bloop(.3, 480), 14.0); put(bloop(.2, 720), 14.3)
for k in range(5): put(pop(.06, 500), 14.3 + k * .45)
put(click(.4), 14.95); put(whoosh(.3, True, .25), 15.15); put(whoosh(.3, True, .25), 16.25)
# 17,6 - 19,9 : 10 sites -> 1 appli
put(whoosh(.4, False, .3), 17.55); put(sub_hit(.5, .8), 17.7)
put(whoosh(.3, True, .35), 18.42); put(ding(.3), 18.85)
beat_section(17.8, 19.6, full=False, melody=True)
put(riser(.6, .3), 19.3)
# 19,9 : toute ta ville bouge
put(sub_hit(1.0), 19.88); put(crash(.4), 19.88)
beat_section(19.6, 22.6, full=True, melody=True)
for k in range(12): put(bloop(.16, 500 + (k % 5) * 110), 20.2 + k * .12, pan=(k % 3 - 1) * .4)
put(pop(.3, 700), 20.35)
# 22,45 : fin
put(sub_hit(1.0, 2.2), 22.45); put(crash(.45, 3), 22.45); put(whoosh(.6, False, .3), 22.3)
beat_section(22.6, 26.2, full=True, melody=True)
put(chord([69, 72, 76, 81], 3.4, .07, .02, 1.6), 25.0, pan=-.1); put(chord([57, 64, 69], 3.4, .05, .02, 1.6), 25.0, pan=.1)
put(pop(.3, 900), 24.0); put(click(.45), 25.6); put(ding(.25), 25.65)

# ---------- Mixage ----------
x = np.stack([L, R])
x = np.tanh(x * 1.1) / np.tanh(1.1)
fade = np.ones(N); fn = int(1.2 * SR); fade[-fn:] = np.linspace(1, 0, fn) ** 2
x *= fade; x /= np.max(np.abs(x)) / .92
pcm = (x.T * 32767).astype(np.int16)
with wave.open('pub_audio.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print('pub_audio.wav', DUR, 's')

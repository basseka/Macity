"""Sound design original (100 % synthétisé, donc libre de droits) calé sur live.html. Sortie : live_audio.wav"""
import numpy as np, wave, os
SR, DUR = 44100, 26.0
N = int(SR * DUR); L = np.zeros(N); R = np.zeros(N); tt = np.arange(N) / SR
rng = np.random.default_rng(42)
def at(t): return int(t * SR)
def put(sig, t, g=1.0, pan=0.0):
    i = at(t)
    if i < 0: sig = sig[-i:]; i = 0
    j = min(N, i + len(sig))
    if i >= N or j <= i: return
    L[i:j] += sig[:j - i] * g * (1 - max(0, pan)); R[i:j] += sig[:j - i] * g * (1 + min(0, pan))
def env(n, a=.002, d=.2):
    t = np.arange(n) / SR; return np.minimum(1, t / a) * np.exp(-t / d)
def lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); y = np.empty_like(x); acc = 0.0
    for k in range(len(x)): acc = (1 - a) * x[k] + a * acc; y[k] = acc
    return y
def hp(x, fc): return x - lp(x, fc)
def noise(d): return rng.standard_normal(int(d * SR))

# ---- Briques sonores ----
def sub_hit(d=1.4, f0=48, sweep=160, g=1.0):
    n = int(d * SR); t = np.arange(n) / SR
    f = f0 + sweep * np.exp(-t / .05)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (d * .4))
    click = hp(noise(.03), 1500)[:n] * env(int(.03 * SR), .0003, .006)
    s[:len(click)] += click * .8
    return np.tanh(s * 2.2) * g
def metal(d=1.6, base=310, g=.5):
    n = int(d * SR); t = np.arange(n) / SR
    parts = [1, 2.76, 5.40, 8.93, 13.34, 4.1]
    s = sum(np.sin(2 * np.pi * base * p * t + i) * np.exp(-t / (d * .35 / (1 + i * .5))) / (1 + i * .6) for i, p in enumerate(parts))
    return s * np.minimum(1, t / .001) * g
def whoosh(d, up=True, g=.5):
    n = int(d * SR); x = noise(d); out = np.zeros(n); seg = int(.015 * SR)
    for i in range(0, n, seg):
        k = i / n; f = 250 + 6000 * (k if up else 1 - k) ** 1.5
        out[i:i + seg] = hp(lp(x[i:i + seg], f * 1.7), f * .5)
    return out * np.sin(np.pi * np.arange(n) / n) ** 2 * g
def boom(d=3.0, g=1.0):
    n = int(d * SR); t = np.arange(n) / SR
    body = np.sin(2 * np.pi * np.cumsum(30 + 120 * np.exp(-t / .12)) / SR) * np.exp(-t / .9)
    crack = lp(noise(d), 2500)[:n] * np.exp(-t / .35) * .9 + hp(noise(d), 4000)[:n] * np.exp(-t / .08) * .6
    return np.tanh((body * 1.4 + crack) * 1.8) * g
def riser(d, g=.4):
    n = int(d * SR); t = np.arange(n) / SR; k = t / d
    tone = sum(np.sin(2 * np.pi * np.cumsum(f0 * (1 + 3 * k ** 2)) / SR) for f0 in (110, 110.7, 220.5)) / 3
    return (hp(noise(d), 1800)[:n] * .5 + tone * .7) * k ** 2.2 * g
def shimmer(d=2.0, g=.25):
    n = int(d * SR); t = np.arange(n) / SR; s = np.zeros(n)
    for i, f in enumerate([1318.5, 1975.5, 2637, 3136, 3951]):
        s += np.sin(2 * np.pi * f * t + i) * np.exp(-t / (d * .4)) * (1 + .5 * np.sin(2 * np.pi * (6 + i) * t))
    return s / 5 * np.minimum(1, t / .02) * g
def zap(d=.25, g=.3):
    n = int(d * SR); t = np.arange(n) / SR
    return np.sign(np.sin(2 * np.pi * np.cumsum(2400 * np.exp(-t / .05) + 120) / SR)) * env(n, .001, .06) * g


def pop(g=.35, f=880):
    n = int(.14 * SR); t = np.arange(n) / SR
    return np.sin(2 * np.pi * np.cumsum(f * (1 + 1.2 * np.exp(-t / .02))) / SR) * env(n, .001, .045) * g
def tick(g=.12): n = int(.03 * SR); return hp(noise(.03), 3000)[:n] * env(n, .0005, .006) * g
def click(g=.3): n = int(.06 * SR); t = np.arange(n) / SR; return (np.sin(2 * np.pi * 1800 * t) * env(n, .0005, .012) + hp(noise(.06), 2000)[:n] * env(n, .0005, .008)) * g
def chord(fs, d, g):
    n = int(d * SR); t = np.arange(n) / SR
    return sum(np.sin(2 * np.pi * f * t) + .3 * np.sin(2 * np.pi * f * 2.003 * t) for f in fs) / len(fs) * np.minimum(1, t / .5) * np.minimum(1, (d - t) / .6) * g

kick = sub_hit(.4, 50, 110, .9)
clap_n = int(.22 * SR); clap = hp(lp(noise(.22), 4000), 1000) * (env(clap_n, .001, .08) + .6 * np.roll(env(clap_n, .001, .02), int(.011 * SR)))
hat = hp(noise(.05), 7500) * env(int(.05 * SR), .0004, .014)
B = 60 / 120  # 120 BPM, comme la foule qui danse dans la story

# Accroche : 3 impacts sur les 3 lignes
put(riser(.6, .3), -.4)
for k, ti in enumerate([.2, .55, .9]):
    put(whoosh(.14, False, .3), ti - .13); put(sub_hit(.9, 48, 160, .85), ti); put(metal(1.0, 330 + 50 * k, .22), ti, pan=-.2 + .2 * k)
put(whoosh(.45, True, .55), 2.65)
# Ambiance de soirée « filmée » (étouffée comme à travers le téléphone) de 3,4 à 7,1
club = np.zeros(at(4.0)); ct = np.arange(len(club)) / SR
for t0 in np.arange(0, 4.0, B):
    i = at(t0); k2 = kick[:len(club) - i]; club[i:i + len(k2)] += k2 * .9
bassl = lp(np.sign(np.sin(2 * np.pi * 55 * ct)), 300) * .35
club = lp(club + bassl + hp(noise(4.0), 3000)[:len(club)] * .03, 900) * np.minimum(1, ct / .3) * np.minimum(1, (4.0 - ct) / .4)
put(club * .6, 3.15)
put(pop(.3, 660), 3.4)  # début d'enregistrement
for k in range(12): put(tick(.08), 3.4 + k * (2.0 / 12))
put(pop(.25, 520), 5.4); put(whoosh(.3, True, .25), 5.45)
for k in range(9): put(tick(.07), 5.75 + k * .05)  # saisie du lieu
put(click(.35), 6.3); put(shimmer(1.0, .2), 6.45); put(zap(.15, .14), 6.7)
# Envol vers la carte puis pin
put(whoosh(.85, True, .7), 7.05); put(riser(.8, .4), 7.1)
put(sub_hit(1.4, 40, 190, .95), 7.9); put(shimmer(2.2, .3), 7.92); put(metal(1.8, 520, .22), 7.9, pan=.2)
# Groove MaCity de 8,3 à 22,5
t = 8.3
while t < 22.4:
    put(kick, t, .75); put(hat, t + B / 2, .2, .3); put(hat, t + B / 4, .08, -.3); put(hat, t + 3 * B / 4, .08, -.3); t += B
for t in np.arange(8.3 + B, 22.4, 2 * B): put(clap, t, .32, -.1)
bn = at(14.1); bt = np.arange(bn) / SR
notes = [55, 55, 65.4, 49]
bf = np.array([notes[int(x / (4 * B)) % 4] for x in bt])
bass = lp(np.sign(np.sin(2 * np.pi * np.cumsum(bf) / SR)) * .6 + np.sin(2 * np.pi * np.cumsum(bf * 2) / SR) * .4, 280) * (.5 + .5 * np.abs(np.sin(np.pi * bt / B)))
put(bass * .38, 8.3)
put(chord([220, 277.2, 329.6, 440], 14.0, .07), 8.3)
# Pins des autres stories
for k in range(13): put(pop(.12, 700 + 60 * (k % 5)), 8.3 + k * .2, pan=(-1) ** k * .4)
# Les jeunes voient la story
for k in range(14): put(pop(.14, 1200 + 90 * (k % 4)), 12.0 + k * .1, pan=(-1) ** k * .3); put(shimmer(.4, .06), 12.2 + k * .22, pan=(-1) ** k * .5)
# Fiche + Y aller
put(whoosh(.4, True, .35), 15.75); put(click(.4), 16.75); put(riser(.6, .3), 16.8)
put(sub_hit(.8, 55, 140, .7), 17.4); put(whoosh(.6, True, .4), 17.4)
# Arrivées (un « +1 » chacun)
ts = [17.4 + k * .05 + 1.0 + nb * .11 for k, nb in enumerate([7, 7, 7, 8, 7, 7, 5, 6, 5, 4, 6, 4, 5, 8])]
for k, ta in enumerate(sorted(ts)): put(pop(.2, 880 * 2 ** ((k % 7) / 12 * 2)), ta, pan=(-1) ** k * .3)
# Partenaires en vert
put(whoosh(.4, False, .35), 20.0); put(shimmer(1.4, .22), 20.3); put(chord([329.6, 415.3, 493.9], 2.0, .06), 20.3)
# Final
put(riser(.8, .45), 21.8); put(whoosh(.25, False, .4), 22.65)
put(boom(2.6, .9), 22.9); put(metal(2.4, 260, .3), 22.9); put(shimmer(2.4, .28), 22.95)
for k, ti in enumerate([23.05, 23.45, 23.85]): put(sub_hit(.7, 52, 150, .7), ti); put(metal(.8, 400 + 60 * k, .18), ti)
put(sub_hit(1.4, 42, 200, .95), 24.35); put(zap(.18, .15), 24.36); put(shimmer(1.6, .25), 24.4)
fin_n = at(2.0); ft = np.arange(fin_n) / SR
put(sum(np.sin(2 * np.pi * f * ft) for f in (55, 110, 164.8, 220, 277.2)) / 5 * np.exp(-ft / 1.0) * .5, 24.35)

mix = np.stack([L, R], 1)
mix *= np.interp(tt, [0, .01, DUR - .5, DUR], [0, 1, 1, 0])[:, None]
mix = np.tanh(mix * 1.15) / np.tanh(1.15)
mix /= np.max(np.abs(mix)) / .95
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'live_audio.wav')
with wave.open(out, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype('<i2').tobytes())
print('ok', out)

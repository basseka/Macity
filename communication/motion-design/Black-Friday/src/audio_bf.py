"""Sound design original (100 % synthétisé, donc libre de droits) calé sur bf.html. Sortie : bf_audio.wav"""
import numpy as np, wave, os
SR, DUR = 44100, 15.0
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

kick = sub_hit(.4, 50, 110, .9)
clap_n = int(.22 * SR); clap = hp(lp(noise(.22), 4000), 1000) * (env(clap_n, .001, .08) + .6 * np.roll(env(clap_n, .001, .02), int(.011 * SR)))
hat = hp(noise(.05), 7500) * env(int(.05 * SR), .0004, .014)

# ---- Montée continue pendant le compte à rebours (0 -> 3,15) ----
drone_n = at(3.2); dt = np.arange(drone_n) / SR
drone = sum(np.sin(2 * np.pi * f * (1 + .25 * (dt / 3.2) ** 2) * dt) for f in (55, 55.4, 82.4)) / 3
drone *= (dt / 3.2) ** 1.3 * .55
put(drone, 0); put(riser(3.15, .5), 0)
# Impacts 3, 2, 1 (chute = whoosh descendant juste avant)
for k, ti in enumerate([.15, 1.15, 2.15]):
    put(whoosh(.18, False, .35), ti - .17)
    put(sub_hit(1.1, 45, 170, .95), ti); put(metal(1.3, 300 + 40 * k, .32), ti, pan=-.15 + .15 * k)
    put(whoosh(.3, True, .3), ti + .7, pan=.3)
# Zéro : explosion
put(whoosh(.18, False, .4), 2.98)
put(boom(3.2, 1.0), 3.15); put(metal(2.2, 220, .4), 3.15); put(zap(.35, .25), 3.16, pan=.2)
# Plongée dans le tunnel puis révélation de l'iPhone
put(whoosh(1.5, True, .7), 3.3); put(riser(1.35, .45), 3.4)
put(sub_hit(1.8, 38, 200, .9), 4.75); put(shimmer(2.6, .3), 4.78); put(metal(2.5, 520, .25), 4.75, pan=.2)
# Beat électronique 128 BPM de 5,5 s à 9,8 s
B = 60 / 128
t = 5.62
while t < 9.75:
    put(kick, t, .8)
    put(hat, t + B / 2, .22, .3)
    put(hat, t + B / 4, .09, -.3); put(hat, t + 3 * B / 4, .09, -.3)
    t += B
for t in np.arange(5.62 + B, 9.75, 2 * B): put(clap, t, .35, -.1)
bass_n = at(4.2); bt = np.arange(bass_n) / SR
bass = lp(np.sign(np.sin(2 * np.pi * 41.2 * bt)) * .6 + np.sin(2 * np.pi * 82.4 * bt) * .4, 260) * (.55 + .45 * np.abs(np.sin(np.pi * bt / B)))
put(bass * .45, 5.62)
# Textes de la révélation
put(whoosh(.15, False, .3), 6.22); put(sub_hit(.9, 55, 140, .8), 6.35); put(metal(1.2, 410, .3), 6.35); put(zap(.2, .18), 6.36, pan=-.3)
put(zap(.12, .12), 7.97, pan=.4)
put(whoosh(.15, False, .25), 7.75); put(sub_hit(.7, 60, 120, .6), 7.9); put(shimmer(1.2, .18), 7.92)
# Transition volet + CTA
put(riser(.7, .35), 9.1); put(whoosh(.5, True, .65), 9.75)
put(sub_hit(1.0, 48, 170, .9), 10.3); put(metal(1.1, 350, .3), 10.3, pan=-.2)
put(sub_hit(1.0, 44, 180, .95), 10.6); put(metal(1.2, 330, .32), 10.6, pan=.2)
put(whoosh(.2, True, .3), 11.1); put(sub_hit(.8, 60, 120, .6), 11.3); put(zap(.18, .15), 11.31)
# Tenue entre 11,3 et 12,5 : nappe tendue
pad_n = at(4.0); ptt = np.arange(pad_n) / SR
pad = sum(np.sin(2 * np.pi * f * ptt) for f in (110, 164.8, 220.4, 277.2)) / 4 * np.minimum(1, ptt / .4)
put(pad * np.exp(-ptt / 1.5) * .18, 11.3)
put(riser(1.1, .4), 11.4)
# Final : coup massif + queue métallique
put(whoosh(.2, False, .4), 12.35); put(boom(2.8, .95), 12.55); put(metal(2.6, 260, .35), 12.55); put(shimmer(2.6, .3), 12.6)
fin_n = at(2.4); ft = np.arange(fin_n) / SR
fin = sum(np.sin(2 * np.pi * f * ft) for f in (55, 110, 164.8, 220, 329.6)) / 5 * np.exp(-ft / 1.1)
put(fin * .5, 12.55)
put(shimmer(.9, .22), 13.8, pan=.4)

mix = np.stack([L, R], 1)
mix *= np.interp(tt, [0, .01, 14.6, 15], [0, 1, 1, 0])[:, None]
mix = np.tanh(mix * 1.15) / np.tanh(1.15)
mix /= np.max(np.abs(mix)) / .95
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bf_audio.wav')
with wave.open(out, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype('<i2').tobytes())
print('ok', out)

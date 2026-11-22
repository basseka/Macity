"""Bande son du tuto : voix off (edge-tts Denise +22 %, calée par timeline.py), musique synthétisée libre de droits (118 BPM), clic à chaque tap, atténuation sous la voix."""
import numpy as np, wave, json
SR = 44100
V = json.load(open('voix/cues.json')); DUR = V['DUR']; N = int(SR*DUR)
def rd(p):
    w = wave.open(p); return np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)/32768
voice = np.zeros(N)
for k in [k for k in V if not k.endswith('_end') and k != 'DUR']:
    a = rd(f'voix/{k}.wav'); i = int(V[k]*SR); voice[i:i+len(a)] += a[:N-i]
t = np.arange(N)/SR
BPM = 118; beat = 60/BPM; rng = np.random.default_rng(7); mus = np.zeros(N); fx = np.zeros(N)
def env(n, a=.005, d=.2):
    x = np.arange(n)/SR; return np.minimum(1, x/a)*np.exp(-x/d)
def add(buf, sig, start):
    i = int(start*SR); n = min(len(sig), N-i)
    if n > 0 and i >= 0: buf[i:i+n] += sig[:n]
end_beats = V['g1'] + 3
for k in range(int(end_beats/beat)):
    tb = k*beat; n = int(.3*SR); x = np.arange(n)/SR
    f = 52 + 80*np.exp(-x*30)
    add(mus, .7*np.sin(2*np.pi*np.cumsum(f)/SR)*env(n, .002, .14), tb)
    hn = int(.05*SR); add(mus, .11*rng.standard_normal(hn)*env(hn, .001, .02), tb + beat/2)
    if k % 2 == 1:
        cn = int(.16*SR); add(mus, .22*rng.standard_normal(cn)*env(cn, .001, .05), tb)
CH = [(60, 64, 67), (57, 60, 64), (53, 57, 60), (55, 59, 62)]
hz = lambda m: 440*2**((m-69)/12); bar = 4*beat
for b in range(int(DUR/bar)+1):
    ch = CH[b % 4]; tb = b*bar; n = int(bar*SR); x = np.arange(n)/SR
    pad = sum(np.sin(2*np.pi*hz(m)*x) + .5*np.sin(2*np.pi*hz(m)*2.003*x) for m in ch)/6
    add(mus, .2*pad*np.minimum(1, x/.3)*np.minimum(1, (bar-x)/.2), tb)
    if tb < end_beats:
        for q in range(8):
            bn = int(beat/2*SR); xb = np.arange(bn)/SR
            add(mus, .24*np.tanh(2*np.sin(2*np.pi*hz(ch[0]-24)*xb))*env(bn, .003, .1), tb + q*beat/2)
# clics des taps (mêmes instants que tuto.html)
T1 = V['b1_end']+.45; T2 = V['c1_end']+.55; T3 = V['d5_end']+.25; T4 = V['e1']+1.0; T5 = V['e3_end']+.55; T6 = V['f1']+1.4
taps = [T1, T2, V['d2']+.35, V['d2']+1.25, T3, T4, V['e3']+1.05, V['e3']+1.75, V['e3']+2.45, T5, T6]
for tt in taps:
    n = int(.04*SR); x = np.arange(n)/SR
    add(fx, .5*np.sin(2*np.pi*1800*x)*np.exp(-x/.008) + .15*rng.standard_normal(n)*np.exp(-x/.004), tt)
# ding de paiement confirmé
TOK = T6 + 1.1
for j, m in enumerate((76, 83)):
    n = int(1.2*SR); x = np.arange(n)/SR
    add(fx, .35*np.sin(2*np.pi*hz(m)*x)*np.exp(-x/.35), TOK + j*.12)
# whoosh aux changements de scène
for tw in (V['a1_end']+.45, V['f2_end']+1.1, V['f2']+.3):
    n = int(.6*SR); x = np.arange(n)/SR; no = np.convolve(rng.standard_normal(n), np.ones(8)/8, 'same')
    add(fx, .4*no*np.sin(np.pi*x/.6)**2, tw-.35)
n = int(4*SR); x = np.arange(n)/SR
add(mus, .35*sum(np.sin(2*np.pi*hz(m)*x) for m in (60, 64, 67, 72))/4*np.exp(-x/1.8), end_beats)
ve = np.convolve(np.abs(voice), np.ones(2205)/2205, 'same')
duck = 1 - .6*np.clip(ve/.05, 0, 1)
fade = np.minimum(1, (DUR - t)/.8)
mix = (.55*mus*duck + fx + voice)*fade; mix = mix/np.max(np.abs(mix))*.92
w = wave.open('audio_voix.wav', 'w'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
w.writeframes((mix*32767).astype(np.int16).tobytes()); w.close()
print('ok', DUR)

"""Bande son African Safari : voix Denise +22 % + musique synthétisée 124 BPM, calée sur voix/cues.json."""
import numpy as np, wave, json
SR = 44100
cue = json.load(open('voix/cues.json')); DUR = cue['DUR']; N = int(SR*DUR)
def rd(p):
    w = wave.open(p); return np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)/32768
voice = np.zeros(N)
for k in [k for k in cue if not k.endswith('_end') and k != 'DUR']:
    a = rd(f'voix/{k}.wav'); i = int(cue[k]*SR); voice[i:i+len(a)] += a[:N-i]
t = np.arange(N)/SR
BPM = 124; beat = 60/BPM; rng = np.random.default_rng(5); mus = np.zeros(N)
def env(n, a=.005, d=.2):
    x = np.arange(n)/SR; return np.minimum(1, x/a)*np.exp(-x/d)
def add(sig, start):
    i = int(start*SR); n = min(len(sig), N-i)
    if n > 0: mus[i:i+n] += sig[:n]
start = 0.0; end_beats = cue['e1'] + 2.0
for k in range(int((end_beats-start)/beat)):
    tb = start + k*beat; n = int(.35*SR); x = np.arange(n)/SR
    f = 50 + 90*np.exp(-x*30)
    add(.8*np.sin(2*np.pi*np.cumsum(f)/SR)*env(n, .002, .16), tb)
    hn = int(.06*SR); add(.14*rng.standard_normal(hn)*env(hn, .001, .02), tb + beat/2)
    if k % 2 == 1:
        cn = int(.18*SR); add(.28*rng.standard_normal(cn)*env(cn, .001, .05), tb)
CH = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)]
hz = lambda m: 440*2**((m-69)/12); bar = 4*beat
for b in range(int(DUR/bar)+1):
    ch = CH[b % 4]; tb = start + b*bar; n = int(bar*SR); x = np.arange(n)/SR
    pad = sum(np.sin(2*np.pi*hz(m)*x) + .5*np.sin(2*np.pi*hz(m)*2.003*x) for m in ch)/6
    add(.2*pad*np.minimum(1, x/.3)*np.minimum(1, (bar-x)/.2), tb)
    if tb < end_beats:
        for q in range(8):
            bn = int(beat/2*SR); xb = np.arange(bn)/SR
            add(.3*np.tanh(2*np.sin(2*np.pi*hz(ch[0]-24)*xb))*env(bn, .003, .12), tb + q*beat/2)
# whoosh aux changements de scène
for tw in (cue['a2_end']+.35, cue['b3_end']+1.15, cue['c4_end']+.55, cue['d1_end']+.95):
    n = int(.6*SR); x = np.arange(n)/SR; no = np.convolve(rng.standard_normal(n), np.ones(8)/8, 'same')
    add(.45*no*np.sin(np.pi*x/.6)**2, tw-.35)
n = int(4*SR); x = np.arange(n)/SR
add(.35*sum(np.sin(2*np.pi*hz(m)*x) for m in (57, 60, 64, 69))/4*np.exp(-x/1.8), end_beats)
ve = np.convolve(np.abs(voice), np.ones(2205)/2205, 'same')
duck = 1 - .6*np.clip(ve/.05, 0, 1)
fade = np.minimum(1, (DUR - t)/.8)
mix = (.6*mus*duck + voice)*fade; mix = mix/np.max(np.abs(mix))*.92
for name, sig in (('audio_voix.wav', mix), ('audio_sans_voix.wav', mus/np.max(np.abs(mus))*.9*fade)):
    w = wave.open(name, 'w'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((sig*32767).astype(np.int16).tobytes()); w.close()
print('ok', DUR)

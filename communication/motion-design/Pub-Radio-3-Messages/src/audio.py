"""Bande son de la pub 3 messages : voix off (edge-tts Henri) + musique synthétisée (libre de droits)."""
import numpy as np, wave
SR = 44100; DUR = 22.5; N = int(SR*DUR)
def rd(p):
    w = wave.open(p); a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)/32768
    return a
VO = [('voix/t1.wav', 0.40), ('voix/t2.wav', 2.60), ('voix/t3.wav', 9.90), ('voix/t4.wav', 14.00), ('voix/t5.wav', 18.70)]
voice = np.zeros(N)
for p, t in VO:
    a = rd(p); i = int(t*SR); voice[i:i+len(a)] += a[:N-i]
t = np.arange(N)/SR
BPM = 118; beat = 60/BPM
rng = np.random.default_rng(3)
mus = np.zeros(N)
def env(n, a=0.005, d=0.2):
    x = np.arange(n)/SR; return np.minimum(1, x/a)*np.exp(-x/d)
def add(sig, start):
    i = int(start*SR); n = min(len(sig), N-i)
    if n > 0: mus[i:i+n] += sig[:n]
# kick + hats + clap à partir de 0,4 s, coupure avant la fin
start = 0.4; nb = int((DUR-1.2-start)/beat)
for k in range(nb):
    tb = start + k*beat
    n = int(0.35*SR); x = np.arange(n)/SR
    f = 50 + 90*np.exp(-x*30)
    add(0.9*np.sin(2*np.pi*np.cumsum(f)/SR)*env(n, .002, .16), tb)
    hn = int(0.06*SR); add(0.18*rng.standard_normal(hn)*env(hn, .001, .02), tb + beat/2)
    if k % 2 == 1:
        cn = int(0.18*SR); add(0.35*rng.standard_normal(cn)*env(cn, .001, .05), tb)
# basse + nappe : Am F C G (2 temps chacun x 2)
CH = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)]
def hz(m): return 440*2**((m-69)/12)
bar = 4*beat
for b in range(int((DUR-1)/bar)+1):
    ch = CH[b % 4]; tb = start + b*bar
    n = int(bar*SR); x = np.arange(n)/SR
    pad = sum(np.sin(2*np.pi*hz(m)*x) + 0.5*np.sin(2*np.pi*hz(m)*2.003*x) for m in ch)/6
    add(0.22*pad*np.minimum(1, x/0.3)*np.minimum(1, (bar-x)/0.2), tb)
    for q in range(8):
        bn = int(beat/2*SR); xb = np.arange(bn)/SR
        add(0.35*np.tanh(2*np.sin(2*np.pi*hz(ch[0]-24)*xb))*env(bn, .003, .12), tb + q*beat/2)
# whoosh aux transitions
for tw in (2.3, 9.5, 13.7, 18.3):
    n = int(0.6*SR); x = np.arange(n)/SR
    no = rng.standard_normal(n); no = np.convolve(no, np.ones(8)/8, 'same')
    add(0.5*no*np.sin(np.pi*x/0.6)**2, tw-0.4)
# accord final
n = int(3.2*SR); x = np.arange(n)/SR
add(0.35*sum(np.sin(2*np.pi*hz(m)*x) for m in (57, 60, 64, 69))/4*np.exp(-x/1.6), 18.4)
# ducking sous la voix
ve = np.convolve(np.abs(voice), np.ones(2205)/2205, 'same')
duck = 1 - 0.55*np.clip(ve/0.05, 0, 1)
mix = 0.55*mus*duck + 1.0*voice
fade = np.minimum(1, (DUR - t)/0.6); mix *= fade
mix = mix/np.max(np.abs(mix))*0.92
for name, sig in (('audio_pub.wav', mix), ('audio_sans_voix.wav', mus/np.max(np.abs(mus))*0.9*fade)):
    w = wave.open(name, 'w'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((sig*32767).astype(np.int16).tobytes()); w.close()
print('ok', DUR)

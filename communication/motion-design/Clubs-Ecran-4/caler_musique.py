"""Cale la vidéo sur la musique puis ajoute le son.

Usage : python caler_musique.py src/musique.wav [debut=7] [fin=30]
1. coupe l'extrait (0:07 -> 0:30 par défaut) dans src/extrait.wav
2. détecte les temps (librosa) -> src/beats.json
3. relance render.py puis mixe le son -> MACITY_Clubs_Toulouse_4ecrans.mp4
"""
import json, os, subprocess, sys
import librosa

HERE = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1]
a = float(sys.argv[2]) if len(sys.argv) > 2 else 7.0
b = float(sys.argv[3]) if len(sys.argv) > 3 else 30.0
ext = os.path.join(HERE, 'src', 'extrait.wav')
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(a), '-to', str(b), '-i', src,
                '-af', 'afade=t=out:st=%.2f:d=0.8' % (b - a - 0.8), '-ar', '44100', ext], check=True)
y, sr = librosa.load(ext, sr=None)
tempo, frames = librosa.beat.beat_track(y=y, sr=sr, units='frames')
beats = [round(float(t), 4) for t in librosa.frames_to_time(frames, sr=sr)]
# premier temps à 0 pour que les 4 cases s'allument dès l'ouverture
if beats and beats[0] > 0.05: beats = [0.0] + beats
json.dump(beats, open(os.path.join(HERE, 'src', 'beats.json'), 'w'))
print('tempo', float(tempo), 'bpm,', len(beats), 'temps')
mute = os.path.join(HERE, 'MACITY_Clubs_Toulouse_4ecrans_sans_son.mp4')
subprocess.run([sys.executable, os.path.join(HERE, 'render.py'), mute], check=True)
out = os.path.join(HERE, 'MACITY_Clubs_Toulouse_4ecrans.mp4')
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', mute, '-i', ext, '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k',
                '-shortest', '-movflags', '+faststart', out], check=True)
print('ok', out)

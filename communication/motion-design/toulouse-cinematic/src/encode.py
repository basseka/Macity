"""Encode out/frames en MP4 (sans son) + un aperçu avec métronome 130 BPM pour vérifier le calage.
Usage (depuis toulouse-cinematic/) : python src/encode.py
"""
import os, sys, wave, subprocess
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from timeline import BEAT, FPS, TOTAL_BEATS
OUT = 'MACITY_Toulouse_Cinematic_Reel.mp4'
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-framerate', str(FPS), '-i', 'out/frames/%05d.jpg', '-c:v', 'libx264', '-preset', 'slow',
                '-crf', '18', '-maxrate', '24M', '-bufsize', '48M', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-r', str(FPS), '-movflags', '+faststart', OUT], check=True)
# métronome : clic aigu sur le 1er temps de chaque mesure, grave sur les autres
sr = 48000; dur = TOTAL_BEATS * BEAT; a = np.zeros(int(sr * dur) + sr, np.float32)
for k in range(TOTAL_BEATS):
    t0 = int(k * BEAT * sr); n = int(0.05 * sr); tt = np.arange(n) / sr
    f = 1760 if k % 4 == 0 else 880
    a[t0:t0 + n] += np.sin(2 * np.pi * f * tt) * np.exp(-tt * 70) * (0.8 if k % 4 == 0 else 0.5)
with wave.open('out/click.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((np.clip(a, -1, 1) * 32000).astype(np.int16).tobytes())
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', OUT, '-i', 'out/click.wav', '-c:v', 'copy', '-c:a', 'aac', '-shortest',
                'MACITY_Toulouse_apercu_metronome_130bpm.mp4'], check=True)
print('ok', OUT)

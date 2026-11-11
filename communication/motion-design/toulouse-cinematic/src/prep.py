"""Extrait les images des vidéos utilisées dans la timeline (30 i/s, recadrées).
Usage (depuis toulouse-cinematic/) : python src/prep.py
Sortie : cache/vid_<n>/0001.jpg ...
"""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from timeline import SHOTS, BEAT, FPS, W, H

os.makedirs('cache', exist_ok=True)
for i, (b0, b1, uni, kind, src, o) in enumerate(SHOTS):
    if kind != 'vid':
        continue
    out = f'cache/vid_{i:02d}'
    if os.path.isdir(out) and os.listdir(out):
        continue
    os.makedirs(out, exist_ok=True)
    sp = o.get('speed', 1.0)
    dur = (b1 - b0 + 1.5) * BEAT + 0.3  # durée de sortie (après ralenti)
    if o.get('layout') == 'window':
        sc = f'scale={W}:-2:flags=lanczos'
    else:
        sc = f'scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,crop={W}:{H}'
    vf = f'setpts=(PTS-STARTPTS)/{sp},fps={FPS},{sc}'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(o.get('start', 0)), '-i', src, '-t', f'{dur:.3f}',
                    '-vf', vf, '-q:v', '2', f'{out}/%04d.jpg'], check=True)
    print(out, len(os.listdir(out)), 'images', flush=True)

"""Calage voix off (Denise +22 %) : écrit voix/cues.json puis l'injecte dans animaparc.html."""
import json, re
d = {k: float(v) for k, v in (l.split('\t') for l in open('voix/durs.tsv').read().split('\n') if l)}
plan = [('a1', .4), ('a2', .35), ('b1', .9), ('b2', .45), ('b3', .6),
        ('c0', 1.1), ('c1', .35), ('c2', .4), ('c3', .4), ('c4', .4),
        ('d1', 1.0), ('e1', 1.1)]
PAUSE = 0.75
t = 0; cue = {}
for k, gap in plan:
    t += gap * PAUSE; cue[k] = round(t, 3); cue[k + '_end'] = round(t + d[k], 3); t += d[k]
cue['DUR'] = round(t + 2.6, 2)
json.dump(cue, open('voix/cues.json', 'w'), indent=1)
h = open('africansafari.html').read()
h = re.sub(r'/\*CUES\*/.*?/\*END\*/', '/*CUES*/' + json.dumps(cue) + '/*END*/', h, flags=re.S)
open('africansafari.html', 'w').write(h)
print(json.dumps(cue))

"""Calage voix off (Denise +22 %) : place chaque phrase, écrit voix/cues.json et l'injecte dans tuto.html."""
import json, re
d = {k: float(v) for k, v in (l.split('\t') for l in open('voix/durs.tsv').read().split('\n') if l)}
plan = [  # (id, pause avant, en s) : pauses longues = temps des gestes à l'écran
 ('a1', .3), ('b1', 1.0), ('c1', 1.5), ('d1', 1.5), ('d2', .3), ('d3', .9), ('d4', 1.0), ('d5', .8),
 ('e1', 1.6), ('e2', .5), ('e3', .5), ('f1', 1.8), ('f2', 1.6), ('g1', 1.4),
]
t = 0; cue = {}
for k, gap in plan:
    t += gap; cue[k] = round(t, 3); cue[k + '_end'] = round(t + d[k], 3); t += d[k]
cue['DUR'] = round(t + 2.2, 2)
json.dump(cue, open('voix/cues.json', 'w'), indent=1)
h = open('tuto.html').read()
h = re.sub(r'/\*CUES\*/.*?/\*END\*/', '/*CUES*/' + json.dumps(cue) + '/*END*/', h, flags=re.S)
open('tuto.html', 'w').write(h)
print(json.dumps(cue))

"""Calage voix off : place chaque phrase, écrit voix/cues.json (lu par alaune.html)."""
import json
d = dict(l.split('\t') for l in open('voix/durs.tsv').read().split('\n') if l)
d = {k: float(v) for k, v in d.items()}
plan = [  # (id, pause avant)
 ('a1', .4), ('a2', .3),
 ('b1', .9), ('b2', .35), ('b3', .5),
 ('c1', .8), ('c2', .45),
 ('d0', .8), ('d1', .3), ('d2', .4), ('d3', .4),
 ('e0', 2.0), ('e1', .2), ('e2', .2), ('e3', .2), ('e4', .2),
 ('f1', 1.0),
]
t = 0; cue = {}
for k, gap in plan:
    t += gap; cue[k] = round(t, 3); cue[k + '_end'] = round(t + d[k], 3); t += d[k]
cue['DUR'] = round(t + 1.6, 2)
json.dump(cue, open('voix/cues.json', 'w'), indent=1)
print(json.dumps(cue))

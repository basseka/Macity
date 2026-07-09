# Pub MaCity — kit Gemini Veo (clips 10 s)

Tout pour générer la vidéo pub MaCity avec **Gemini Veo** (clips de ~10 s),
puis la finaliser au montage.

## Ce que Veo fait / ne fait pas
- ✅ Veo fait : ambiance lifestyle, ville, gens qui sortent, néons, concerts.
- ❌ Veo NE fait PAS : l'UI réelle de MaCity, ni du texte/logo lisible.
  → Le **texte, le logo et l'écran de l'app** s'ajoutent au MONTAGE
    (CapCut, InShot, Premiere…), par-dessus les clips Veo.

## Deux façons de faire

### A. Rapide (1 seul clip 10 s)
1. Génère le clip avec `veo_prompt_principal.txt` (format 9:16 vertical).
2. Au montage : ajoute les sous-titres + la carte de fin (cf.
   `overlay_et_carte_fin.txt`).
3. Export selon `specs_export.txt`.

### B. Mieux (montage de 2-3 clips Veo = ~20 s)
1. Génère séparément les 3 scènes de `veo_prompts_scenes.txt`.
2. Optionnel : insère une **capture d'écran de l'app** (10 s filmées dans
   MaCity : accueil « À la une », Map Live, une Offre) entre la scène 2 et 3.
3. Monte dans l'ordre Hook → App → Payoff, ajoute textes + carte de fin.

## Fichiers
- `veo_prompt_principal.txt` — le prompt à coller dans Veo (V1 rapide).
- `veo_prompts_scenes.txt` — 3 prompts modulaires (hook / ambiance / payoff).
- `overlay_et_carte_fin.txt` — sous-titres + carte de fin + CTA, avec timing.
- `specs_export.txt` — formats/ratios à exporter pour Google Ads.
- `logo_macity_carre.png` — icône MaCity (pin), pour la carte de fin.
- `capture_app_macity.png` — screenshot du home, à incruster comme « écran
  de l'app » dans le montage (Veo ne génère pas l'UI réelle).

## Astuce
Génère **plusieurs variantes** de chaque prompt (Veo est aléatoire) et garde
la meilleure. Les prompts sont en anglais : Veo rend mieux le cinématique
ainsi. Tu peux les coller tels quels.

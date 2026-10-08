import json, html

ROOT = '/home/carlos.basseka@celadodc-rswl.com/Bureau/cba/appli/pulz_app/communication/charte-graphique'
pal = json.load(open(ROOT + '/02-couleurs/palette-macity.json'))

def lum(hexc):
    r, g, b = [int(hexc[i:i+2], 16) / 255 for i in (1, 3, 5)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def swatch(c, big=False):
    fg = '#15121C' if lum(c['hex']) > 0.35 else '#FFFFFF'
    border = ' swatch--line' if c['hex'].upper() in ('#FFFFFF', '#FAFAF7', '#F5F0FF', '#F1EEE9') else ''
    use = f'<div class="sw-use">{html.escape(c["usage"])}</div>' if c['usage'] else ''
    return f'''<div class="swatch{' swatch--big' if big else ''}{border}">
  <div class="sw-chip" style="background:{c['hex']};color:{fg}"><span>{html.escape(c['nom'])}</span></div>
  <div class="sw-meta"><b>{c['hex']}</b><br>RVB {', '.join(map(str, c['rvb']))}<br>CMJN {', '.join(map(str, c['cmjn']))}</div>
  {use}
</div>'''

def grid(group, big=False):
    return '<div class="swatches">' + ''.join(swatch(c, big) for c in pal['couleurs'][group]) + '</div>'

def gradients():
    out = []
    for g in pal['degrades']:
        stops = ', '.join(f"{s['hex']} {s['position']}%" for s in g['arrets'])
        codes = ' , '.join(s['hex'] for s in g['arrets'])
        out.append(f'''<div class="grad">
  <div class="grad-chip" style="background:linear-gradient({g['angle']}deg, {stops})"></div>
  <div class="grad-meta"><b>{html.escape(g['nom'])}</b><br>{codes}<br><span class="mono">{g['angle']}°</span></div>
</div>''')
    return ''.join(out)

L = '_apercus/'
page_n = [0]
def page(content, cls=''):
    page_n[0] += 1
    num = f'<div class="folio">MaCity · Charte graphique · {page_n[0]:02d}</div>' if page_n[0] > 1 else ''
    return f'<section class="page {cls}">{content}{num}</section>'

pages = []

# 1. Couverture
pages.append(page(f'''
<div class="cover">
  <img class="cover-logo" src="{L}macity-logo-couleur-fond-sombre.png" alt="Logo MaCity">
  <div class="cover-title">Charte graphique</div>
  <div class="cover-sub">Identité visuelle, logo, couleurs, typographies et usages</div>
  <div class="cover-foot">Version 1.0 · septembre 2026 · macity.app</div>
</div>''', 'page--dark'))

# 2. Sommaire + marque
pages.append(page('''
<div class="eyebrow">01 · La marque</div>
<h1>L'app de ta ville</h1>
<p class="lead">MaCity rassemble tout ce qui bouge dans une ville, dans une seule application : concerts, soirées, spectacles, sport, food, sorties en famille, culture et évasion. Les habitants y trouvent quoi faire aujourd'hui et ce soir ; les lieux et organisateurs y gagnent en visibilité.</p>

<div class="two">
  <div>
    <h3>Promesse</h3>
    <p class="quote">Tout ce qui bouge dans ta ville, dans une seule app.</p>
    <h3>Signature</h3>
    <p class="quote">L'app de ta ville</p>
  </div>
  <div>
    <h3>Ton de voix</h3>
    <ul class="list">
      <li><b>On tutoie.</b> MaCity parle comme un ami qui connaît les bons plans.</li>
      <li><b>Des phrases courtes</b>, concrètes, orientées action : « Quoi faire ce soir ? ».</li>
      <li><b>Énergique sans en faire trop.</b> Les emojis servent à repérer une rubrique, pas à décorer.</li>
      <li><b>Pas de jargon</b>, pas d'anglicismes inutiles, et jamais de tiret cadratin.</li>
    </ul>
  </div>
</div>

<h3>Valeurs <span class="tag-todo">proposition à valider</span></h3>
<div class="values">
  <div class="value"><div class="v-ico">📍</div><b>Local d'abord</b><p>Ta ville, tes quartiers, tes lieux. Chaque contenu est ancré quelque part.</p></div>
  <div class="value"><div class="v-ico">✨</div><b>Tout au même endroit</b><p>Concerts, sport, food, famille, nuit : plus besoin de dix applis.</p></div>
  <div class="value"><div class="v-ico">🎟️</div><b>Accessible</b><p>Gratuit pour les utilisateurs. Les bons plans et les sorties gratuites sont mis en avant.</p></div>
  <div class="value"><div class="v-ico">⚡</div><b>Vivant</b><p>Ce qui se passe aujourd'hui, ce soir, en direct : stories, live, nouveautés.</p></div>
  <div class="value"><div class="v-ico">🤝</div><b>Communauté</b><p>Ce sont les habitants et les pros locaux qui font MaCity.</p></div>
</div>
'''))

# 3. Logo
pages.append(page(f'''
<div class="eyebrow">02 · Le logo</div>
<h1>Le logo</h1>
<p class="lead">Le logo associe le <b>pin</b> (le repère sur la carte, symbole du « ici ») et le mot <b>MaCity</b> composé en Inter ExtraBold. « Ma » porte la proximité, « City » en rose porte l'énergie de la ville.</p>

<div class="logo-main">
  <div class="tile tile--dark"><img src="{L}macity-logo-couleur-fond-sombre.png" alt=""></div>
  <div class="tile tile--light"><img src="{L}macity-logo-couleur-fond-clair.png" alt=""></div>
</div>
<div class="caption-row"><span>Version principale, fond sombre</span><span>Version principale, fond clair</span></div>

<h3>Déclinaisons</h3>
<div class="logo-grid">
  <div class="tile tile--white"><img src="{L}macity-logo-noir.png" alt=""><em>Monochrome noir</em></div>
  <div class="tile tile--pink"><img src="{L}macity-logo-blanc.png" alt=""><em>Monochrome blanc</em></div>
  <div class="tile tile--dark"><img src="{L}macity-logo-vertical-fond-sombre.png" alt=""><em>Vertical</em></div>
  <div class="tile tile--light sq"><img src="{L}macity-pin-couleur.png" alt=""><em>Pin seul</em></div>
  <div class="tile tile--dark sq"><img src="{L}macity-pin-blanc.png" alt=""><em>Pin blanc</em></div>
  <div class="tile tile--none sq"><img class="icon" src="{L}macity-icone-app.png" alt=""><em>Icône d'application</em></div>
</div>
'''))

# 4. Logo règles
pages.append(page(f'''
<div class="eyebrow">02 · Le logo</div>
<h1>Règles d'utilisation</h1>

<div class="two">
  <div>
    <h3>Zone de protection</h3>
    <div class="clear">
      <div class="clear-box"><img src="{L}macity-logo-couleur-fond-clair.png" alt=""></div>
    </div>
    <p>Autour du logo, garder une marge vide au moins égale à la <b>hauteur du « M »</b>. Aucun texte, bord de page ou autre logo ne doit y entrer.</p>
  </div>
  <div>
    <h3>Tailles minimales</h3>
    <table class="tbl">
      <tr><th>Version</th><th>Écran</th><th>Impression</th></tr>
      <tr><td>Logo horizontal</td><td>120 px de large</td><td>30 mm</td></tr>
      <tr><td>Logo vertical</td><td>80 px de large</td><td>20 mm</td></tr>
      <tr><td>Pin seul</td><td>24 px de haut</td><td>6 mm</td></tr>
    </table>
    <h3>Choisir la bonne version</h3>
    <ul class="list">
      <li>Fond sombre ou photo foncée : <b>version fond sombre</b> (Ma en blanc).</li>
      <li>Fond blanc ou clair : <b>version fond clair</b> (Ma en Nuit MaCity).</li>
      <li>Fond rose, violet ou dégradé : <b>monochrome blanc</b>.</li>
      <li>Impression une couleur, tampon, gravure : <b>monochrome noir</b>.</li>
      <li>Avatar de réseau social, favicon : <b>icône d'application</b>.</li>
    </ul>
  </div>
</div>

<h3>À ne pas faire</h3>
<div class="donts">
  <div class="dont"><div class="dont-img"><img style="transform:scaleX(1.45)" src="{L}macity-logo-couleur-fond-clair.png" alt=""></div><span>Déformer ou étirer</span></div>
  <div class="dont"><div class="dont-img"><img style="filter:hue-rotate(150deg)" src="{L}macity-logo-couleur-fond-clair.png" alt=""></div><span>Changer les couleurs</span></div>
  <div class="dont"><div class="dont-img"><img style="transform:rotate(-12deg)" src="{L}macity-logo-couleur-fond-clair.png" alt=""></div><span>Pivoter</span></div>
  <div class="dont"><div class="dont-img" style="background:#FF1E8E"><img src="{L}macity-logo-couleur-fond-clair.png" alt=""></div><span>Logo couleur sur fond rose</span></div>
  <div class="dont"><div class="dont-img"><img style="filter:drop-shadow(6px 6px 4px rgba(0,0,0,.6))" src="{L}macity-logo-couleur-fond-clair.png" alt=""></div><span>Ajouter une ombre ou un effet</span></div>
  <div class="dont"><div class="dont-img"><img src="_apercus/ancien-logo-texte-violet.png" alt=""></div><span>Utiliser l'ancien logo violet</span></div>
</div>
'''))

# 5. Couleurs de marque
pages.append(page(f'''
<div class="eyebrow">03 · Couleurs</div>
<h1>Couleurs de marque</h1>
<p class="lead">Le <b>Rose MaCity</b> est la couleur signature : c'est lui qui rend la marque reconnaissable. Il s'appuie sur une base <b>nuit</b> (violet très sombre) qui évoque la ville le soir.</p>
{grid('marque', True)}
<h3>Proportions conseillées</h3>
<div class="ratio">
  <div style="flex:55;background:#1A0F2E">Nuit 55 %</div>
  <div style="flex:25;background:#FAFAF7;color:#15121C">Clair 25 %</div>
  <div style="flex:12;background:#FF1E8E">Rose 12 %</div>
  <div style="flex:8;background:#22D3EE;color:#15121C">Cyan 8 %</div>
</div>
<p class="note">Le rose reste un accent : un titre, un bouton, un mot clé. Un visuel entièrement rose perd en impact et en lisibilité. Le cyan sert de contrepoint froid, par petites touches.</p>
'''))

# 6. Couleurs interface + rubriques
pages.append(page(f'''
<div class="eyebrow">03 · Couleurs</div>
<h1>Couleurs de l'application</h1>
<p class="lead">Couleurs utilisées dans l'interface de l'app (fichier <span class="mono">design_tokens.dart</span>). Le <b>Magenta</b> sert aux éléments interactifs ; il est volontairement un peu plus froid que le Rose MaCity du logo.</p>
{grid('interface')}
<h3>Rubriques</h3>
<p>Chaque rubrique a sa couleur, utilisée pour les icônes, pastilles et accents de la rubrique.</p>
{grid('rubriques')}
'''))

# 7. Étiquettes + neutres
pages.append(page(f'''
<div class="eyebrow">03 · Couleurs</div>
<h1>Étiquettes et neutres</h1>
<h3>Étiquettes de catégorie</h3>
<p>Teintes pastel des pastilles dans les listes d'événements, toujours avec un texte Encre (#15121C).</p>
{grid('etiquettes')}
<h3>Neutres</h3>
{grid('neutres')}
<p class="note">{html.escape(pal['note'])}</p>
'''))

# 8. Dégradés
pages.append(page(f'''
<div class="eyebrow">03 · Couleurs</div>
<h1>Dégradés</h1>
<p class="lead">Les dégradés donnent la sensation de lumière et de soirée propre à MaCity. Les fichiers prêts à l'emploi (1920 × 1080) sont dans <span class="mono">04-elements-graphiques/degrades</span>.</p>
<div class="grads">{gradients()}</div>
<p class="note">Dégradé du pin : réservé au logo et au pin. Dégradé principal : bannières et boutons forts. Ciel de nuit : tout ce qui touche au soir (« Quoi faire ce soir »). Éditorial : mises en avant. Texte chaud : un mot en relief sur fond sombre.</p>
'''))

# 9. Typographies
pages.append(page('''
<div class="eyebrow">04 · Typographies</div>
<h1>Typographies</h1>
<p class="lead">Quatre familles, toutes gratuites (licence SIL Open Font), fournies dans <span class="mono">03-typographies</span> et disponibles sur Google Fonts.</p>

<div class="font">
  <div class="font-head"><b>Inter ExtraBold</b><span>Logo uniquement</span></div>
  <div class="spec" style="font-family:Inter;font-weight:800;font-size:44px;letter-spacing:-0.5px">MaCity</div>
  <p>Réservée au mot-symbole. Ne pas l'utiliser pour les titres, afin que le logo reste unique.</p>
</div>

<div class="font">
  <div class="font-head"><b>Geist</b><span>Typographie principale de l'app : titres et textes</span></div>
  <div class="spec" style="font-family:Geist;font-weight:500;font-size:30px;letter-spacing:-0.6px">Quoi faire ce soir à Toulouse ?</div>
  <div class="spec" style="font-family:Geist;font-size:15px">Concerts, soirées, spectacles et bons plans : tout ce qui bouge dans ta ville, dans une seule app.</div>
  <div class="weights"><span style="font-weight:400">Regular 400</span><span style="font-weight:500">Medium 500</span><span style="font-weight:600">SemiBold 600</span><span style="font-weight:700">Bold 700</span></div>
</div>

<div class="font">
  <div class="font-head"><b>Geist Mono</b><span>Surtitres, étiquettes, chiffres</span></div>
  <div class="spec" style="font-family:'Geist Mono';font-weight:500;font-size:13px;letter-spacing:2.6px">CE SOIR · 21H00 · GRATUIT</div>
  <p>Toujours en majuscules espacées, en petite taille.</p>
</div>

<div class="font">
  <div class="font-head"><b>Poppins</b><span>Supports de communication : flyers, affiches, posts, écran de démarrage</span></div>
  <div class="spec" style="font-family:Poppins;font-weight:700;font-size:30px">Ta ville, en plus vivant.</div>
  <div class="spec" style="font-family:Poppins;font-size:15px">Plus ronde et chaleureuse, elle convient aux visuels grand format et aux réseaux sociaux.</div>
</div>

<h3>Hiérarchie dans l'app</h3>
<table class="tbl">
  <tr><th>Rôle</th><th>Police</th><th>Taille</th><th>Graisse</th></tr>
  <tr><td>Grand titre</td><td>Geist</td><td>28 px</td><td>Regular, interlettrage -3,5 %</td></tr>
  <tr><td>Titre de section</td><td>Geist</td><td>22 px</td><td>Medium</td></tr>
  <tr><td>Titre de carte</td><td>Geist</td><td>16 px</td><td>SemiBold</td></tr>
  <tr><td>Texte courant</td><td>Geist</td><td>13 à 14 px</td><td>Regular</td></tr>
  <tr><td>Bouton</td><td>Geist</td><td>13 px</td><td>SemiBold</td></tr>
  <tr><td>Surtitre</td><td>Geist Mono</td><td>10,5 px</td><td>Medium, capitales, interlettrage 20 %</td></tr>
</table>
'''))

# 10. Éléments graphiques
pages.append(page('''
<div class="eyebrow">05 · Éléments graphiques</div>
<h1>Éléments graphiques</h1>

<div class="elements">
  <div class="el">
    <div class="el-demo" style="background:#FAFAF7"><img src="_apercus/macity-pin-couleur.png" style="height:92px" alt=""></div>
    <b>Le pin</b><p>Symbole central. Seul, il marque un lieu, une ville, un point de rendez-vous.</p>
  </div>
  <div class="el">
    <div class="el-demo" style="background:#FAFAF7"><div class="neon"><span>Quoi faire<br>ce soir</span></div></div>
    <b>Pastille néon</b><p>Rond sombre #160C2E, contour rose néon #F4247C et reflet cyan. Réservée au soir.</p>
  </div>
  <div class="el">
    <div class="el-demo" style="background:#FAFAF7">
      <div class="chips"><span class="chip chip--on">Concerts</span><span class="chip">Soirées</span><span class="chip">Gratuit</span></div>
    </div>
    <b>Pastilles de filtre</b><p>Entièrement arrondies. Active : fond magenta, texte blanc.</p>
  </div>
  <div class="el">
    <div class="el-demo" style="background:#FAFAF7">
      <div class="tags"><span style="background:#FFD93D">Food</span><span style="background:#C4B5FD">Night</span><span style="background:#A5F3E4">Culture</span><span style="background:#FED7AA">Famille</span></div>
    </div>
    <b>Étiquettes de catégorie</b><p>Pastel, texte Encre, en petite taille au-dessus du titre d'un événement.</p>
  </div>
  <div class="el">
    <div class="el-demo" style="background:#1A0F2E">
      <div class="btn">Voir le programme</div>
    </div>
    <b>Bouton principal</b><p>Dégradé principal ou magenta plein, texte blanc Geist SemiBold, coins arrondis 14 px.</p>
  </div>
  <div class="el">
    <div class="el-demo" style="background:#FAFAF7"><div class="card-demo"><div></div><span>Carte · rayon 20 px</span></div></div>
    <b>Cartes</b><p>Photo en pleine largeur, coins arrondis 20 px, dégradé sombre en bas pour lire le texte.</p>
  </div>
</div>

<h3>Rubriques et pictogrammes</h3>
<div class="rubriques">
  <span>☀️ Concerts &amp; spectacles</span><span>🌙 Nuit &amp; sorties</span><span>🍽️ Food</span><span>🎨 Culture</span>
  <span>👨‍👩‍👧‍👦 Famille</span><span>⚽ Sport</span><span>✈️ Évasion</span><span>🎮 Gaming</span>
</div>

<h3>Arrondis</h3>
<table class="tbl">
  <tr><th>Élément</th><th>Rayon</th></tr>
  <tr><td>Pastilles, filtres</td><td>totalement arrondi</td></tr>
  <tr><td>Boutons icône</td><td>14 px</td></tr>
  <tr><td>Champs de saisie</td><td>16 px</td></tr>
  <tr><td>Cartes</td><td>20 px</td></tr>
  <tr><td>Grandes cartes, barre d'onglets</td><td>22 px</td></tr>
</table>
'''))

# 11. Mockups
pages.append(page('''
<div class="eyebrow">06 · Applications</div>
<h1>L'app en situation</h1>
<p class="lead">Écrans actuels de l'application. Captures haute définition dans <span class="mono">05-mockups/captures-app</span>.</p>
<div class="phones">
  <div class="phone"><img src="_apercus/ecran-1.jpg" alt=""></div>
  <div class="phone"><img src="_apercus/ecran-2.jpg" alt=""></div>
  <div class="phone"><img src="_apercus/ecran-5.jpg" alt=""></div>
  <div class="phone"><img src="_apercus/ecran-6.jpg" alt=""></div>
</div>
<div class="phones phones--sm">
  <div class="phone"><img src="_apercus/ecran-3.jpg" alt=""></div>
  <div class="phone"><img src="_apercus/ecran-4.jpg" alt=""></div>
  <div class="phone"><img src="_apercus/ecran-7.jpg" alt=""></div>
  <div class="qr"><img src="_apercus/qr.png" alt=""><span>QR code de téléchargement</span></div>
</div>
'''))

# 12. Contenu du dossier
pages.append(page('''
<div class="eyebrow">07 · Fichiers</div>
<h1>Contenu du dossier</h1>
<table class="tbl tbl--files">
  <tr><th>Dossier</th><th>Contenu</th></tr>
  <tr><td class="mono">01-logos/svg</td><td>Logos vectoriels (fond sombre, fond clair, noir, blanc, vertical, pin, icône). À privilégier pour l'impression et les grands formats.</td></tr>
  <tr><td class="mono">01-logos/png</td><td>Les mêmes logos en PNG transparent haute définition.</td></tr>
  <tr><td class="mono">01-logos/originaux-app</td><td>Fichiers d'origine utilisés dans l'application et sur les stores.</td></tr>
  <tr><td class="mono">01-logos/archive</td><td>Ancienne identité violette (avril 2026). Ne plus utiliser.</td></tr>
  <tr><td class="mono">02-couleurs</td><td>Palette en CSS, JSON et nuancier texte (HEX, RVB, CMJN).</td></tr>
  <tr><td class="mono">03-typographies</td><td>Inter, Geist, Geist Mono, Poppins (TTF) avec leurs licences.</td></tr>
  <tr><td class="mono">04-elements-graphiques</td><td>Dégradés en PNG, QR codes de téléchargement.</td></tr>
  <tr><td class="mono">05-mockups</td><td>Captures de l'app actuelle, et de l'ancienne interface pour mémoire.</td></tr>
</table>

<div class="contact">
  <img src="_apercus/macity-logo-couleur-fond-sombre.png" alt="">
  <div>macity.app<br>Une question sur l'utilisation de la marque : contacter l'équipe MaCity.</div>
</div>
''', 'page--end'))


doc = f'''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Charte graphique MaCity</title>
<link rel="stylesheet" href="charte-graphique-macity.css">
</head>
<body>
{''.join(pages)}
</body>
</html>
'''
open(ROOT + '/charte-graphique-macity.html', 'w').write(doc)
print('pages', page_n[0])

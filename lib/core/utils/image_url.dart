/// Réécrit une URL Supabase Storage vers l'endpoint de transformation, pour
/// servir une image redimensionnée et compressée.
///
/// POURQUOI
/// Les photos de partenaires sont stockées en PNG, format inadapté aux photos :
/// 446 ko pour la fiche « Les Jardins du Museum », 545 ko pour un domaine
/// d'évasion. Sur une connexion faible — H+ en zone mal couverte — le
/// placeholder reste visible plusieurs secondes et l'utilisateur voit un bloc
/// vide là où un partenaire a payé sa place.
///
/// Mesuré le 2026-07-30 sur cette même image :
///   brut (PNG)                                446 477 o
///   render width=800 quality=70               440 891 o   ← inutile sans format
///   render width=800 quality=70 format=webp    49 532 o   ← 9× plus léger
///
/// ⚠️ `format=webp` est indispensable : sans lui Supabase conserve le PNG
/// d'origine et la transformation n'apporte presque rien.
library;

const _objetPublic = '/storage/v1/object/public/';
const _renderPublic = '/storage/v1/render/image/public/';

/// Version allégée de [url], ou [url] inchangée si la transformation ne
/// s'applique pas — URL externe, chemin d'asset, champ vide.
///
/// [width] est la largeur d'affichage souhaitée en pixels logiques ; prévoir
/// large, l'écran a un ratio de pixels supérieur à 1.
String optimizedImageUrl(String? url, {int width = 800, int quality = 70}) {
  final u = (url ?? '').trim();
  // Les chemins d'assets et les URL d'autres hébergeurs sont laissés tels
  // quels : l'endpoint de transformation ne sait traiter que notre storage.
  if (!u.startsWith('http') || !u.contains(_objetPublic)) return u;
  // Déjà transformée (double appel, ou URL déjà stockée sous cette forme).
  if (u.contains(_renderPublic)) return u;

  final base = u.replaceFirst(_objetPublic, _renderPublic);
  final sep = base.contains('?') ? '&' : '?';
  return '$base${sep}width=$width&quality=$quality&format=webp';
}

import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Rectangle d'ancrage de la feuille de partage iOS.
///
/// iOS refuse d'ouvrir la feuille de partage sans `sharePositionOrigin`
/// (exception, donc rien ne se passe a l'ecran). On ancre sur le widget
/// appelant ; s'il n'a pas encore de taille, on retombe sur le centre de
/// l'ecran pour ne jamais envoyer d'origine vide.
Rect? shareOriginFor(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize && box.attached) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.maybeSizeOf(context);
  if (size == null) return null;
  return Rect.fromCenter(
    center: size.center(Offset.zero),
    width: 1,
    height: 1,
  );
}

/// Partage un texte (lien inclus) en ancrant la feuille pour iOS.
/// En cas d'echec, affiche « Partage impossible, réessaie » au lieu de rien.
/// Renvoie true si la feuille de partage s'est ouverte.
Future<bool> shareText(
  BuildContext context,
  String text, {
  String? subject,
}) async {
  final origin = shareOriginFor(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failedLabel = context.l10n.pvShareFailed;
  try {
    await Share.share(text, subject: subject, sharePositionOrigin: origin);
    return true;
  } catch (e) {
    debugPrint('[share] partage KO : $e');
    messenger?.showSnackBar(SnackBar(content: Text(failedLabel)));
    return false;
  }
}

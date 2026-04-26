import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Kicker uppercase letter-spaced — typique du design imprime.
/// Ex: "RUBRIQUE · MUSIQUE", "VEN. · 20H30".
class EditorialKicker extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const EditorialKicker(
    this.text, {
    super.key,
    this.color,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: EditorialText.kicker(
        color: color ?? EditorialColors.paperMuted,
        size: size,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

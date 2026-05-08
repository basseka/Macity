import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Avatar circulaire pour fake_users / device_pseudonyms / real_comments.
/// Si [avatarUrl] est null → fallback : cercle dégradé (rose pour F, bleu
/// pour M) + 1ère lettre du prénom en blanc gras.
class EngagementAvatar extends StatelessWidget {
  final String displayName;
  final String gender; // 'M' | 'F'
  final String? avatarUrl;
  final double size;

  const EngagementAvatar({
    super.key,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialFallback(),
          errorWidget: (_, __, ___) => _initialFallback(),
        ),
      );
    }
    return _initialFallback();
  }

  Widget _initialFallback() {
    final initial = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';
    final gradient = gender == 'F'
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEC4899), Color(0xFFF97316)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.geist(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

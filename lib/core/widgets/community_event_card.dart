import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Carte epuree pour les evenements communautaires ("A venir").
/// Utilisee dans toutes les pages : day, sport, night, etc.
class CommunityEventCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String date;
  final String? time;
  final String? location;
  final String? photoUrl;
  final String fallbackAsset;
  final String? tag;
  final bool isFree;
  final VoidCallback? onTap;

  const CommunityEventCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.date,
    this.time,
    this.location,
    this.photoUrl,
    this.fallbackAsset = 'assets/images/pochette_default.png',
    this.tag,
    this.isFree = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    final dateLabel = parsed != null ? DateFormat('EEE d MMM', 'fr_FR').format(parsed) : date;
    final timeLabel = time != null && time!.isNotEmpty ? time! : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _buildPhoto(),
              ),
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Date + time
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          timeLabel != null ? '$dateLabel  $timeLabel' : dateLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Location
                  if (location != null && location!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side: tag or free badge
            if (tag != null || isFree)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tag != null && tag!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag!,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (isFree) ...[
                      if (tag != null) const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Gratuit',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE91E8C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _assetFallback(),
          errorWidget: (_, __, ___) => _assetFallback(),
        );
      }
      return Image.file(
        File(photoUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetFallback(),
      );
    }
    return _assetFallback();
  }

  Widget _assetFallback() {
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0F0F5),
        child: const Icon(Icons.event, size: 24, color: Colors.grey),
      ),
    );
  }
}

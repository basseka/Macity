import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/reported_events/state/tonight_events_provider.dart';

/// Carrousel des événements d'aujourd'hui (journée + soirée), ouvert au tap
/// sur la bulle « Quoi faire ce soir ».
class TonightEventsSheet extends ConsumerWidget {
  const TonightEventsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const TonightEventsSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tonightEventsProvider);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.nightlife_rounded,
                    color: Color(0xFFE91E8C), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Quoi faire aujourd'hui ?",
                    style: GoogleFonts.geist(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A0F2E),
                    ),
                  ),
                ),
                async.maybeWhen(
                  data: (e) => e.isEmpty
                      ? const SizedBox.shrink()
                      : Text('${e.length}',
                          style: GoogleFonts.geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE91E8C),
                          )),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          async.when(
            loading: () => const SizedBox(
              height: 262,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFC77DFF)),
              ),
            ),
            error: (_, __) => _empty('Impossible de charger les événements.'),
            data: (events) {
              if (events.isEmpty) {
                return _empty("Aucun événement aujourd'hui dans cette ville.");
              }
              return SizedBox(
                height: 262,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _EventPoster(event: events[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(String msg) => SizedBox(
        height: 150,
        child: Center(
          child: Text(
            msg,
            style: GoogleFonts.geist(fontSize: 13, color: const Color(0xFF6A6480)),
          ),
        ),
      );
}

class _EventPoster extends StatelessWidget {
  final Event event;
  const _EventPoster({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (event.photoPath ?? '').startsWith('http');
    return GestureDetector(
      onTap: () => EventFullscreenPopup.show(
        context,
        event,
        'assets/images/pochette_concert.webp',
      ),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 172,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                spreadRadius: -3,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                CachedNetworkImage(
                  imageUrl: event.photoPath!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFF2A1546)),
                  errorWidget: (_, __, ___) => _fallback(),
                )
              else
                _fallback(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xD9000000)],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              if (event.categorie.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.categorie,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.12,
                        shadows: const [Shadow(blurRadius: 6, color: Colors.black87)],
                      ),
                    ),
                    if (event.horaires.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.horaires,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.geist(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF3A1D5E),
        alignment: Alignment.center,
        child: Text(event.categoryEmoji, style: const TextStyle(fontSize: 44)),
      );
}

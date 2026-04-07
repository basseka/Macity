import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/home/state/discovery_providers.dart';

class NearbySheet extends ConsumerStatefulWidget {
  const NearbySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NearbySheet(),
    );
  }

  @override
  ConsumerState<NearbySheet> createState() => _NearbySheetState();
}

class _NearbySheetState extends ConsumerState<NearbySheet> {
  static const _accent = Color(0xFF7B2D8E);
  static const _filters = ['Tout', 'Restaurant', 'Bar', 'Musee', 'Sport'];
  String _activeFilter = 'Tout';
  NearbyParams? _params;
  bool _loadingGps = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) {
        setState(() {
          _loadingGps = false;
          _error = 'Position GPS non disponible';
        });
        return;
      }
      setState(() {
        _params = NearbyParams(lat: pos.latitude, lon: pos.longitude);
        _loadingGps = false;
      });
    } catch (e) {
      setState(() {
        _loadingGps = false;
        _error = 'Erreur GPS: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F0FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '\uD83D\uDCCD Autour de moi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1259),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = f == _activeFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeFilter = f);
                    if (_params != null) {
                      final cat = f == 'Tout' ? null : f;
                      _params = NearbyParams(
                        lat: _params!.lat,
                        lon: _params!.lon,
                        category: cat,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active ? _accent : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: active ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingGps) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent),
            SizedBox(height: 12),
            Text('Localisation en cours...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadingGps = true;
                  _error = null;
                });
                _requestLocation();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text('Reessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_params == null) return const SizedBox.shrink();

    final venuesAsync = ref.watch(nearbyProvider(_params!));
    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return Center(
            child: Text(
              'Aucun lieu trouve a proximite',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: venues.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CommerceRowCard(commerce: venues[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

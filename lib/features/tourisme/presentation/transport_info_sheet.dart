import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Donnees transport d'une ville.
class CityTransport {
  final List<dynamic> metro;
  final List<dynamic> tram;
  final Map<String, dynamic> velo;
  final int metroCount;
  final int tramCount;
  final int veloCount;

  const CityTransport({
    required this.metro,
    required this.tram,
    required this.velo,
    required this.metroCount,
    required this.tramCount,
    required this.veloCount,
  });

  factory CityTransport.fromJson(Map<String, dynamic> json) => CityTransport(
    metro: json['metro'] as List? ?? [],
    tram: json['tram'] as List? ?? [],
    velo: json['velo'] as Map<String, dynamic>? ?? {},
    metroCount: json['metro_count'] as int? ?? 0,
    tramCount: json['tram_count'] as int? ?? 0,
    veloCount: json['velo_count'] as int? ?? 0,
  );

  bool get isEmpty => metroCount == 0 && tramCount == 0 && veloCount == 0;
}

/// Sites de transport par ville (pour le lien externe).
const _transportSites = <String, ({String name, String url, Color color})>{
  'Toulouse': (name: 'Tisseo', url: 'https://www.tisseo.fr/', color: Color(0xFFE3051B)),
  'Paris': (name: 'RATP', url: 'https://www.ratp.fr/', color: Color(0xFF003DA5)),
  'Lyon': (name: 'TCL', url: 'https://www.tcl.fr/', color: Color(0xFF00A1DE)),
  'Marseille': (name: 'RTM', url: 'https://www.rtm.fr/', color: Color(0xFF0072BC)),
  'Bordeaux': (name: 'TBM', url: 'https://www.infotbm.com/', color: Color(0xFF6F2282)),
  'Lille': (name: 'Ilevia', url: 'https://www.ilevia.fr/', color: Color(0xFFE30613)),
  'Nantes': (name: 'TAN', url: 'https://www.tan.fr/', color: Color(0xFF00A551)),
  'Strasbourg': (name: 'CTS', url: 'https://www.cts-strasbourg.eu/', color: Color(0xFF00A4E4)),
  'Nice': (name: 'Lignes d\'Azur', url: 'https://www.lignesdazur.com/', color: Color(0xFFE30613)),
  'Montpellier': (name: 'TaM', url: 'https://www.tam-voyages.com/', color: Color(0xFF005DA5)),
  'Rennes': (name: 'STAR', url: 'https://www.star.fr/', color: Color(0xFFE30613)),
  'Grenoble': (name: 'TAG', url: 'https://www.tag.fr/', color: Color(0xFF00A551)),
  'Geneve': (name: 'TPG', url: 'https://www.tpg.ch/', color: Color(0xFFE30613)),
};

final cityTransportProvider = FutureProvider<CityTransport?>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  try {
    final res = await dio.get('city_transport_info', queryParameters: {
      'select': '*',
      'ville': 'eq.$city',
      'limit': '1',
    });
    final data = res.data as List;
    if (data.isEmpty) return null;
    return CityTransport.fromJson(data[0] as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

/// Widget qui affiche les infos transport d'une ville.
class TransportInfoView extends ConsumerWidget {
  const TransportInfoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final transportAsync = ref.watch(cityTransportProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final site = _transportSites[city];

    return transportAsync.when(
      data: (transport) {
        if (transport == null || transport.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Infos transport pour $city\nbientot disponibles',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                if (site != null) ...[
                  const SizedBox(height: 16),
                  _buildTransportLink(site.name, site.url, site.color),
                ],
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Lien vers le site de transport
            if (site != null) ...[
              _buildTransportLink(site.name, site.url, site.color),
              const SizedBox(height: 16),
            ],

            // Resume
            _buildSummaryCards(transport, modeTheme),
            const SizedBox(height: 16),

            // Metro
            if (transport.metroCount > 0) ...[
              _sectionTitle('Metro', Icons.subway, '${transport.metroCount} stations'),
              const SizedBox(height: 8),
              _buildStationChips(transport.metro, const Color(0xFF1565C0)),
              const SizedBox(height: 16),
            ],

            // Tram
            if (transport.tramCount > 0) ...[
              _sectionTitle('Tramway', Icons.tram, '${transport.tramCount} arrets'),
              const SizedBox(height: 8),
              _buildStationChips(transport.tram.take(30).toList(), const Color(0xFF2E7D32)),
              const SizedBox(height: 16),
            ],

            // Velo
            if (transport.veloCount > 0) ...[
              _sectionTitle('Velo en libre-service', Icons.pedal_bike, '${transport.veloCount} stations'),
              const SizedBox(height: 8),
              if (transport.velo['name'] != null && (transport.velo['name'] as String).isNotEmpty)
                Text(transport.velo['name'] as String,
                    style: TextStyle(fontSize: 13, color: AppColors.textDim)),
            ],
          ],
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }

  Widget _buildTransportLink(String name, String url, Color color) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text('Ouvrir $name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(CityTransport transport, dynamic modeTheme) {
    return Row(
      children: [
        if (transport.metroCount > 0)
          _summaryCard(Icons.subway, '${transport.metroCount}', 'Metro', const Color(0xFF1565C0)),
        if (transport.tramCount > 0)
          _summaryCard(Icons.tram, '${transport.tramCount}', 'Tram', const Color(0xFF2E7D32)),
        if (transport.veloCount > 0)
          _summaryCard(Icons.pedal_bike, '${transport.veloCount}', 'Velo', const Color(0xFFE65100)),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(count, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textDim),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textFaint)),
      ],
    );
  }

  Widget _buildStationChips(List<dynamic> stations, Color color) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: stations.map((s) {
        final name = (s as Map<String, dynamic>)['name'] as String? ?? '';
        final line = s['line'] as String? ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            line.isNotEmpty ? '$name ($line)' : name,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }
}

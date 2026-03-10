import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fiche info d'une course du Marathon de Toulouse.
class MarathonRaceInfo extends ConsumerWidget {
  final String subcategory;

  const MarathonRaceInfo({super.key, required this.subcategory});

  static const _raceData = <String, Map<String, String>>{
    'Marathon info': {
      'distance': '42,195 km a travers Toulouse',
      'parcours':
          'Depart : Stade Ernest-Wallon\n'
          'Arrivee : Place du Capitole\n\n'
          'Le parcours traverse les plus beaux quartiers de la Ville Rose : '
          'Saint-Cyprien, les bords de la Garonne, la Prairie des Filtres, '
          'le quartier des Carmes et le centre historique.',
      'tarif': '55 EUR',
      'info':
          'Ravitaillements : tous les 5 km (eau, fruits, sucre)\n\n'
          'Consignes : disponibles au village depart, ouverture 1h30 avant le depart\n\n'
          'Transports : navettes gratuites depuis le centre-ville vers le depart\n\n'
          'Parking : Stade Ernest-Wallon (gratuit le jour de la course)\n\n'
          'Chronometrage : puce electronique integree au dossard',
    },
    'Semi-Marathon info': {
      'distance': '21,1 km a travers Toulouse',
      'parcours':
          'Depart : Place du Capitole\n'
          'Arrivee : Place du Capitole\n\n'
          'Une boucle passant par les quais de la Garonne, '
          'le quartier Saint-Cyprien, la Prairie des Filtres '
          'et le centre historique.',
      'tarif': '35 EUR',
      'info':
          'Ravitaillements : tous les 5 km (eau, fruits, sucre)\n\n'
          'Consignes : disponibles au village depart, ouverture 1h30 avant le depart\n\n'
          'Transports : navettes gratuites vers le depart\n\n'
          'Parking : parkings centre-ville\n\n'
          'Chronometrage : puce electronique integree au dossard',
    },
    '10K info': {
      'distance': '10 km dans le centre de Toulouse',
      'parcours':
          'Depart : Place du Capitole\n'
          'Arrivee : Place du Capitole\n\n'
          'Un parcours urbain accessible a tous, longeant '
          'les bords de la Garonne et traversant le coeur historique.',
      'tarif': '15 EUR',
      'info':
          'Ravitaillements : au km 3 et km 7\n\n'
          'Consignes : disponibles au village depart\n\n'
          'Transports : metro Capitole (ligne A)\n\n'
          'Chronometrage : puce electronique integree au dossard',
    },
    'Marathon relais info': {
      'distance': '42,195 km en equipe (2 a 5 relayeurs)',
      'parcours':
          'Depart : Stade Ernest-Wallon\n'
          'Arrivee : Place du Capitole\n\n'
          'Meme parcours que le marathon individuel, '
          'avec des zones de passage de relais aux km 8, 16, 25 et 34.',
      'tarif': '100 EUR par equipe',
      'info':
          'Equipes de 2 a 5 coureurs\n\n'
          'Zones de relais balisees avec vestiaires\n\n'
          'Navettes entre les zones de relais\n\n'
          'Chronometrage : puce par relayeur + temps cumule equipe\n\n'
          'Certificat medical obligatoire pour chaque relayeur',
    },
    'Course Enfants info': {
      'distance': '1 km ou 2 km selon la categorie',
      'parcours':
          'Depart et arrivee : Prairie des Filtres\n\n'
          'Parcours securise et entierement ferme a la circulation, '
          'adapte aux enfants de 6 a 14 ans.',
      'tarif': 'Gratuit',
      'info':
          'Categories : 6-9 ans (1 km) et 10-14 ans (2 km)\n\n'
          'Autorisation parentale obligatoire\n\n'
          'Medaille et gouter offerts a l\'arrivee\n\n'
          'Animations et echauffement collectif avant le depart\n\n'
          'Encadrement par des benevoles tout au long du parcours',
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final data = _raceData[subcategory]!;
    final displayTitle = subcategory.replaceAll(' info', '');

    return Column(
      children: [
        SportBackButton(
          title: displayTitle,
          label: 'Marathon',
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Marathon'),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              _buildInfoCard(
                modeTheme,
                icon: Icons.route,
                title: 'Parcours',
                children: [
                  Text(data['distance']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(data['parcours']!, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                modeTheme,
                icon: Icons.app_registration,
                title: 'Inscription',
                children: [
                  Text(
                    'Tarif : ${data['tarif']!}\n\n'
                    'Certificat medical ou licence FFA obligatoire.\n'
                    'Dossards a retirer au village depart la veille ou le matin.',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse('https://in.njuko.com/harmonie-mutuelle-toulouse-metropole-run-experience-2026?currentPage=form_formulaire-participant'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text("S'inscrire en ligne"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modeTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoCard(
                modeTheme,
                icon: Icons.info_outline,
                title: 'Info pratique',
                children: [
                  Text(data['info']!, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ModeTheme modeTheme, {required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: modeTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: modeTheme.primaryDarkColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

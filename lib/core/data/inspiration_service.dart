import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/premium_banner_service.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Carte unique du carrousel "Inspirations du moment" d'une rubrique.
/// Alimentee par la table `inspirations` (editee depuis /admin.html).
class Inspiration {
  final int id;
  final String rubrique; // food | family | sport | culture | night
  final String title;
  final String description;
  final String photoUrl;
  final String siteUrl;

  /// Thème filtrable au tap (matche une chip de la rubrique si possible).
  /// Vide => le tap ouvre directement le site s'il y en a un.
  final String theme;

  /// Établissement rattaché (emplacement Gold). Null = carte éditoriale.
  /// Quand il est renseigné, le tap ouvre la fiche plutôt que [siteUrl].
  final String? sourceTable;
  final int? sourceId;

  const Inspiration({
    required this.id,
    required this.rubrique,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.siteUrl,
    required this.theme,
    this.sourceTable,
    this.sourceId,
  });

  /// Carte vendue à un partenaire, par opposition à une carte éditoriale.
  bool get isPartnerCard => sourceId != null && (sourceTable?.isNotEmpty ?? false);

  /// Carte générée à la volée depuis un partenaire Gold, sans ligne en base.
  ///
  /// Le carrousel « Inspirations » est l'emplacement vendu au palier Gold :
  /// exiger une carte saisie à la main pour chaque abonné serait ingérable
  /// (il faudrait la créer, la maintenir, et la supprimer à la résiliation).
  /// L'id est négatif pour ne jamais entrer en collision avec une vraie ligne.
  factory Inspiration.fromPartner({
    required String rubrique,
    required String nom,
    required String photoUrl,
    required String siteUrl,
    required String sourceTable,
    required int sourceId,
  }) =>
      Inspiration(
        id: -sourceId,
        rubrique: rubrique,
        title: nom,
        description: '',
        photoUrl: photoUrl,
        siteUrl: siteUrl,
        theme: '',
        sourceTable: sourceTable,
        sourceId: sourceId,
      );

  factory Inspiration.fromJson(Map<String, dynamic> json) {
    return Inspiration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rubrique: json['rubrique'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      siteUrl: json['site_url'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      sourceTable: (json['source_table'] as String?)?.trim(),
      sourceId: (json['source_id'] as num?)?.toInt(),
    );
  }
}

/// Recupere les cartes actives pour une rubrique et une ville donnees.
/// Les lignes en `ville = '*'` s'affichent dans toutes les villes
/// (meme convention que `mode_banners`).
class InspirationService {
  final Dio _dio;

  InspirationService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<List<Inspiration>> fetchInspirations({
    required String ville,
    required String rubrique,
  }) async {
    final response = await _dio.get(
      'inspirations',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'rubrique': 'eq.$rubrique',
        'order': 'sort_order.asc,id.asc',
      },
    );
    final data = response.data as List;
    final v = ville.trim().toLowerCase();
    final result = <Inspiration>[];
    for (final raw in data) {
      final json = raw as Map<String, dynamic>;
      final rowVille = (json['ville'] as String? ?? '*').trim();
      if (rowVille == '*' || rowVille.toLowerCase() == v) {
        result.add(Inspiration.fromJson(json));
      }
    }
    return _partnersFirst(result);
  }

  /// Les cartes partenaires (Gold) passent devant les cartes éditoriales,
  /// **mélangées entre elles chaque heure** : sans ça, `sort_order` désignerait
  /// toujours le même gagnant et les autres ne seraient jamais vus.
  /// Même principe que la rotation des bannières.
  static List<Inspiration> _partnersFirst(List<Inspiration> all) {
    final partenaires = all.where((i) => i.isPartnerCard).toList();
    final editoriales = all.where((i) => !i.isPartnerCard).toList();
    if (partenaires.length > 1) {
      final hourSlot = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
      partenaires.shuffle(math.Random(hourSlot));
    }
    return [...partenaires, ...editoriales];
  }
}

/// Cartes Inspirations actives pour une rubrique donnee, dans la ville
/// selectionnee. Usage : `ref.watch(inspirationsProvider('food'))`.
final inspirationsProvider =
    FutureProvider.family<List<Inspiration>, String>((ref, rubrique) async {
  final city = ref.watch(selectedCityProvider);
  return InspirationService().fetchInspirations(ville: city, rubrique: rubrique);
});

/// Cartes « Inspirations » d'une rubrique : **uniquement les partenaires Gold**
/// de la ville, générés depuis leur fiche.
///
/// L'emplacement est vendu au palier Gold, point. Les cartes éditoriales de la
/// table `inspirations` ne sont plus affichées (décision produit 2026-07-28) :
/// le carrousel est un espace commercial, pas une tribune éditoriale, et mêler
/// les deux rendait l'inventaire imprévisible pour un abonné.
///
/// La table et son onglet admin restent en place — rien n'est supprimé en base
/// — mais plus rien ne les lit.
final inspirationsWithPartnersProvider =
    FutureProvider.family<List<Inspiration>, String>((ref, rubrique) async {
  final golds = await ref
      .watch(partnerPoolProvider((rubrique: rubrique, tier: 'gold')).future);

  final cartes = golds
      .where((g) => g.photoUrl.isNotEmpty && g.commerce.sourceId != null)
      .map((g) => Inspiration.fromPartner(
            rubrique: rubrique,
            nom: g.nom,
            photoUrl: g.photoUrl,
            siteUrl: g.siteUrl,
            sourceTable: g.commerce.sourceTable ?? '',
            sourceId: g.commerce.sourceId!,
          ))
      .toList();

  // Mélange horaire : sans lui, l'ordre de la base placerait toujours les
  // mêmes Gold en tête, et seules ~2,8 cartes sont visibles avant défilement.
  if (cartes.length > 1) {
    cartes.shuffle(
        math.Random(DateTime.now().millisecondsSinceEpoch ~/ 3600000));
  }
  return cartes;
});

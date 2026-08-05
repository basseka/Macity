import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Bannière hero d'une rubrique : rotation sur les partenaires **Premium** de
/// la ville qui ont une vidéo — à défaut leur photo.
///
/// Le lien entre la vidéo et l'établissement est structurel : la vidéo est une
/// colonne de la fiche (`video_url`), pas une ligne d'une table séparée. Donc
/// pas de clé à maintenir, le tap ouvre naturellement la bonne fiche, et les
/// impressions sont attribuables sans ambiguïté.
///
/// `mode_banners` reste le repli : quand aucun Premium n'a de média pour cette
/// rubrique dans cette ville, l'appelant retombe sur la bannière générique.

/// Une place dans la rotation.
class PremiumBannerSlot {
  final CommerceModel commerce;

  /// Vidéo de l'établissement. Vide → on affiche [photoUrl].
  final String videoUrl;

  /// Photo de repli. Le partenaire a payé sa place : il l'occupe même sans
  /// vidéo (décision produit, 2026-07-28).
  final String photoUrl;

  /// Site du partenaire. C'est lui que « En savoir plus » doit ouvrir — pas le
  /// `link_url` générique de `mode_banners`.
  final String siteUrl;

  const PremiumBannerSlot({
    required this.commerce,
    required this.videoUrl,
    required this.photoUrl,
    this.siteUrl = '',
  });

  String get nom => commerce.nom;
  bool get hasVideo => videoUrl.isNotEmpty;

  /// Un slot sans aucun média ne sert à rien : ni vidéo, ni photo à montrer.
  bool get hasMedia => videoUrl.isNotEmpty || photoUrl.isNotEmpty;
}

/// Table + colonnes par rubrique. Même correspondance que
/// `partners_of_day_service.dart` : chaque rubrique lit la table que l'app
/// affiche réellement pour elle.
/// `cityCol` : Évasion se filtre sur `hub_ville` (ville de rattachement) et
/// non sur `ville`, qui contient le village où se trouve le domaine.
const _sources = <String, ({String table, String nameCol, String siteCol, String cityCol, String? filterKey, String? filterVal})>{
  'food': (table: 'etablissements', nameCol: 'nom', siteCol: 'site_web', cityCol: 'ville', filterKey: 'rubrique', filterVal: 'eq.food'),
  'night': (table: 'venues', nameCol: 'name', siteCol: 'website_url', cityCol: 'ville', filterKey: 'mode', filterVal: 'eq.night'),
  'culture': (table: 'venues', nameCol: 'name', siteCol: 'website_url', cityCol: 'ville', filterKey: 'mode', filterVal: 'eq.culture'),
  'sport': (table: 'sport_venues', nameCol: 'nom', siteCol: 'site_web', cityCol: 'ville', filterKey: null, filterVal: null),
  'family': (table: 'family_venues', nameCol: 'name', siteCol: 'website_url', cityCol: 'ville', filterKey: null, filterVal: null),
  'evasion': (table: 'evasion_venues', nameCol: 'nom', siteCol: 'site_web', cityCol: 'hub_ville', filterKey: null, filterVal: null),
};

/// Les partenaires d'un palier donné, dans une rubrique et la ville
/// sélectionnée, qui ont un média affichable.
///
/// Clé : `(rubrique: 'food', tier: 'premium')`. Le palier est un paramètre et
/// non une constante, parce que les surfaces vendues diffèrent : la bannière
/// hero est réservée aux Premium, le carrousel « Inspirations » aux Gold.
final partnerPoolProvider = FutureProvider.family<List<PremiumBannerSlot>,
    ({String rubrique, String tier})>((ref, key) async {
  final rubrique = key.rubrique;
  final src = _sources[rubrique];
  if (src == null) return const [];

  final city = ref.watch(selectedCityProvider);
  final like = '*${city.split('(').first.trim()}*';

  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());

  try {
    final params = <String, String>{
      'select':
          'id,${src.nameCol},${src.siteCol},${src.cityCol},photo,video_url,adresse,latitude,longitude',
      'is_partner': 'eq.true',
      'is_active': 'eq.true',
      // Réservé au palier Premium — dénormalisé depuis venue_subscriptions
      // par trigger, donc aucune jointure ici.
      'partner_tier': 'eq.${key.tier}',
      src.cityCol: 'ilike.$like',
      'order': 'display_priority.desc',
    };
    if (src.filterKey != null) params[src.filterKey!] = src.filterVal!;

    final res = await dio.get<dynamic>(src.table, queryParameters: params);
    final data = res.data;
    if (data is! List) return const [];

    String s(dynamic v) => (v as String?)?.trim() ?? '';
    return data
        .whereType<Map>()
        .map((raw) {
          final e = raw.cast<String, dynamic>();
          return PremiumBannerSlot(
            commerce: CommerceModel(
              nom: s(e[src.nameCol]),
              ville: s(e[src.cityCol]),
              adresse: s(e['adresse']),
              photo: s(e['photo']),
              videoUrl: s(e['video_url']),
              latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
              siteWeb: s(e[src.siteCol]),
              isPartner: true,
              sourceTable: src.table,
              sourceId: (e['id'] as num?)?.toInt(),
            ),
            videoUrl: s(e['video_url']),
            photoUrl: s(e['photo']),
            siteUrl: s(e[src.siteCol]),
          );
        })
        .where((slot) => slot.nom.isNotEmpty && slot.hasMedia)
        .toList();
  } catch (_) {
    // Colonne partner_tier absente ou réseau : liste vide, l'appelant retombe
    // sur son comportement par défaut (bannière générique, éditorial seul…).
    return const [];
  }
});

/// Raccourci historique : les Premium d'une rubrique, pour la bannière hero.
final premiumBannerPoolProvider =
    FutureProvider.family<List<PremiumBannerSlot>, String>((ref, rubrique) =>
        ref.watch(partnerPoolProvider((rubrique: rubrique, tier: 'premium')).future));

/// Curseur de rotation, partagé par toutes les bannières.
///
/// Volontairement **pas** `autoDispose` : il doit survivre à la navigation.
/// Sortir de Food et y revenir doit montrer une AUTRE vidéo — d'où [advance]
/// appelé aussi au montage, pas seulement au tic du minuteur.
///
/// Le départ est **aléatoire par appareil** et non calculé sur l'horloge : le
/// digest de 18 h fait ouvrir l'app à des centaines d'utilisateurs dans la même
/// minute, et un index horaire leur montrerait tous le même annonceur.
class BannerCursor extends Notifier<int> {
  @override
  int build() => math.Random().nextInt(1 << 20);

  void advance() => state = state + 1;
}

final bannerCursorProvider =
    NotifierProvider<BannerCursor, int>(BannerCursor.new);

/// Ordre rebattu **chaque heure**, identique sur tous les appareils : personne
/// ne reste durablement collé derrière le même voisin.
///
/// Parcourir cette permutation en round-robin garantit qu'un utilisateur ne
/// revoit jamais le même annonceur avant de les avoir tous vus.
List<PremiumBannerSlot> shuffledForCurrentHour(List<PremiumBannerSlot> pool) {
  if (pool.length < 2) return pool;
  final hourSlot = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
  final copy = [...pool]..shuffle(math.Random(hourSlot));
  return copy;
}

/// Le slot à afficher pour [cursor], dans l'ordre de l'heure courante.
PremiumBannerSlot? slotAt(List<PremiumBannerSlot> pool, int cursor) {
  if (pool.isEmpty) return null;
  final ordered = shuffledForCurrentHour(pool);
  return ordered[cursor % ordered.length];
}

/// Relit une fiche depuis sa clé polymorphe `(source_table, source_id)`.
///
/// Sert aux surfaces qui ne portent que le lien et pas les données du commerce
/// — les cartes « Inspirations » vendues au palier Gold, par exemple.
/// Retourne null si la fiche a disparu ou si la table est inconnue.
Future<CommerceModel?> fetchCommerceBySource(String sourceTable, int sourceId) async {
  // Les colonnes ne portent pas le même nom selon la table : on réutilise la
  // correspondance déjà déclarée pour les bannières.
  final src = _sources.values.where((e) => e.table == sourceTable);
  if (src.isEmpty) return null;
  final cols = src.first;

  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());
  try {
    final res = await dio.get<dynamic>(sourceTable, queryParameters: {
      'select':
          'id,${cols.nameCol},${cols.siteCol},${cols.cityCol},adresse,photo,photos,video_url,telephone,horaires,latitude,longitude,is_partner',
      'id': 'eq.$sourceId',
      'limit': '1',
    });
    final data = res.data;
    if (data is! List || data.isEmpty) return null;
    final e = (data.first as Map).cast<String, dynamic>();
    String s(dynamic v) => (v as String?)?.trim() ?? '';
    return CommerceModel(
      nom: s(e[cols.nameCol]),
      ville: s(e[cols.cityCol]),
      adresse: s(e['adresse']),
      photo: s(e['photo']),
      photos: (e['photos'] is List)
          ? (e['photos'] as List).whereType<String>().where((p) => p.isNotEmpty).toList()
          : const <String>[],
      videoUrl: s(e['video_url']),
      telephone: s(e['telephone']),
      horaires: s(e['horaires']),
      siteWeb: s(e[cols.siteCol]),
      latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
      isPartner: e['is_partner'] as bool? ?? false,
      sourceTable: sourceTable,
      sourceId: (e['id'] as num?)?.toInt(),
    );
  } catch (_) {
    return null;
  }
}

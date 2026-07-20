import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

/// Un coupon récompense (débloqué à chaque palier de 40 City-Miles).
class RewardCoupon {
  final int id;
  final int palier;
  final String code;
  final String status; // unlocked | opened | redeemed
  final int? giftId;

  const RewardCoupon({
    required this.id,
    required this.palier,
    required this.code,
    required this.status,
    this.giftId,
  });

  bool get isUnopened => status == 'unlocked';

  factory RewardCoupon.fromJson(Map<String, dynamic> j) => RewardCoupon(
        id: (j['id'] as num?)?.toInt() ?? 0,
        palier: (j['palier'] as num?)?.toInt() ?? 0,
        code: (j['code'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'unlocked',
        giftId: (j['gift_id'] as num?)?.toInt(),
      );
}

/// État City-Miles de l'utilisateur.
class CityMilesState {
  final int cityMiles;
  final int nextAt; // palier suivant (multiple de 40)
  final int newCount; // coupons créés lors de ce check
  final List<RewardCoupon> coupons;

  const CityMilesState({
    required this.cityMiles,
    required this.nextAt,
    required this.newCount,
    required this.coupons,
  });

  /// City-Miles restants avant le prochain cadeau.
  int get toNext => (nextAt - cityMiles).clamp(0, 40);

  /// Progression dans le palier courant (0..40).
  int get inCycle => cityMiles % 40;

  List<RewardCoupon> get unopened =>
      coupons.where((c) => c.isUnopened).toList();

  factory CityMilesState.fromJson(Map<String, dynamic> j) => CityMilesState(
        cityMiles: (j['city_miles'] as num?)?.toInt() ?? 0,
        nextAt: (j['next_at'] as num?)?.toInt() ?? 40,
        newCount: (j['new'] as num?)?.toInt() ?? 0,
        coupons: (j['coupons'] is List)
            ? (j['coupons'] as List)
                .whereType<Map>()
                .map((e) => RewardCoupon.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
      );
}

/// Le cadeau révélé à l'ouverture d'un coupon.
class GiftReward {
  final String code;
  final int palier;
  final String nom;
  final String description;
  final String imageUrl;

  const GiftReward({
    required this.code,
    required this.palier,
    required this.nom,
    required this.description,
    required this.imageUrl,
  });

  factory GiftReward.fromJson(Map<String, dynamic> j) {
    final gift = (j['gift'] is Map)
        ? (j['gift'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return GiftReward(
      code: (j['code'] as String?) ?? '',
      palier: (j['palier'] as num?)?.toInt() ?? 0,
      nom: (gift['nom'] as String?) ?? 'Cadeau',
      description: (gift['description'] as String?) ?? '',
      imageUrl: (gift['image_url'] as String?) ?? '',
    );
  }
}

class StoryRewardsService {
  Dio get _dio => DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());

  /// Recalcule les City-Miles, crée les coupons manquants, renvoie l'état.
  Future<CityMilesState> check() async {
    final userId = await UserIdentityService.getUserId();
    final res = await _dio.post<dynamic>(
      'rpc/check_story_rewards',
      data: {'p_user_id': userId},
    );
    final data = res.data;
    if (data is Map) return CityMilesState.fromJson(data.cast<String, dynamic>());
    return const CityMilesState(cityMiles: 0, nextAt: 40, newCount: 0, coupons: []);
  }

  /// Ouvre un coupon → tire un cadeau actif au hasard et le fige.
  Future<GiftReward> openCoupon(int couponId) async {
    final userId = await UserIdentityService.getUserId();
    final res = await _dio.post<dynamic>(
      'rpc/open_story_coupon',
      data: {'p_user_id': userId, 'p_coupon_id': couponId},
    );
    final data = res.data;
    if (data is Map && data['error'] == null) {
      return GiftReward.fromJson(data.cast<String, dynamic>());
    }
    throw Exception(
      data is Map ? (data['error'] ?? 'open_failed') : 'open_failed',
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/rewards/data/story_rewards_service.dart';

/// État City-Miles de l'utilisateur (points = stories publiées, coupons).
/// autoDispose : recalculé à chaque ouverture de la section Publications.
final cityMilesProvider =
    FutureProvider.autoDispose<CityMilesState>((ref) async {
  return StoryRewardsService().check();
});

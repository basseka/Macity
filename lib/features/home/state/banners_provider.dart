import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/home/data/banner_supabase_service.dart';
import 'package:pulz_app/features/home/domain/models/banner.dart';

final activeBannersProvider = FutureProvider<List<Banner>>((ref) async {
  try {
    return await BannerSupabaseService().fetchActiveBanners();
  } catch (e) {
    debugPrint('[Banners] fetchActiveBanners error: $e');
    return [];
  }
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

class BoostPrice {
  final String priority;
  final String label;
  final String description;
  final int amountCents;

  const BoostPrice({
    required this.priority,
    required this.label,
    required this.description,
    required this.amountCents,
  });

  String get priceLabel => '${(amountCents / 100).toStringAsFixed(0)}\u20AC/jour';
}

final boostPricesProvider = FutureProvider<List<BoostPrice>>((ref) async {
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  final response = await dio.get('boost_prices', queryParameters: {
    'select': '*',
    'is_active': 'eq.true',
    'order': 'amount_cents.desc',
  });

  final data = response.data as List;
  return data.map((e) => BoostPrice(
    priority: e['priority'] as String,
    label: e['label'] as String,
    description: e['description'] as String? ?? '',
    amountCents: e['amount_cents'] as int,
  )).toList();
});

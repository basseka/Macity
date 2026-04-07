import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

class DayAvailability {
  final DateTime date;
  final int reserved;
  final int maxSlots;

  const DayAvailability({required this.date, required this.reserved, required this.maxSlots});

  bool get isFull => reserved >= maxSlots;
  int get available => (maxSlots - reserved).clamp(0, maxSlots);
}

class AvailabilityParams {
  final String priority;
  final DateTime startDate;
  final DateTime endDate;

  const AvailabilityParams({required this.priority, required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      other is AvailabilityParams && priority == other.priority && startDate == other.startDate && endDate == other.endDate;

  @override
  int get hashCode => Object.hash(priority, startDate, endDate);
}

final boostAvailabilityProvider =
    FutureProvider.family<List<DayAvailability>, AvailabilityParams>((ref, params) async {
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  final startStr = '${params.startDate.year}-${params.startDate.month.toString().padLeft(2, '0')}-${params.startDate.day.toString().padLeft(2, '0')}';
  final endStr = '${params.endDate.year}-${params.endDate.month.toString().padLeft(2, '0')}-${params.endDate.day.toString().padLeft(2, '0')}';

  final response = await dio.post(
    'rpc/boost_availability',
    data: {
      'p_priority': params.priority,
      'p_start_date': startStr,
      'p_end_date': endStr,
    },
  );

  final data = response.data as List;
  return data.map((d) => DayAvailability(
    date: DateTime.parse(d['boost_date'] as String),
    reserved: (d['reserved_count'] as num).toInt(),
    maxSlots: (d['max_slots'] as num).toInt(),
  )).toList();
});

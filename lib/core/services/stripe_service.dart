import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service pour créer une session Stripe Checkout et rediriger l'utilisateur.
class StripeService {
  StripeService._();

  /// Crée une session Stripe Checkout et ouvre la page de paiement.
  /// Retourne true si la redirection a réussi.
  static Future<bool> checkout({
    required String eventId,
    required String eventTitle,
    required String priority,
    required String userId,
    int days = 1,
    DateTime? startDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final dio = Dio();
      final response = await dio.post(
        '${SupabaseConfig.supabaseUrl}/functions/v1/create-checkout',
        data: {
          'event_id': eventId,
          'priority': priority,
          'user_id': userId,
          'event_title': eventTitle,
          'days': days,
          'start_date': startStr,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final url = response.data['url'] as String?;
      if (url == null || url.isEmpty) {
        debugPrint('[Stripe] No checkout URL returned');
        return false;
      }

      debugPrint('[Stripe] Opening checkout: $url');
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Stripe] Error: $e');
      return false;
    }
  }
}

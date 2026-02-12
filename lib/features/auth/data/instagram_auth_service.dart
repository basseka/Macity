import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/network/dio_client.dart';

class InstagramAuthService {
  static const _keyIsConnected = 'is_connected';
  static const _keyUsername = 'instagram_username';
  static const _keyUserId = 'user_id';

  final Dio _dio;

  InstagramAuthService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Get Instagram auth URL from Supabase Edge Function
  Future<String?> getAuthUrl() async {
    try {
      final response = await _dio.get(
        SupabaseConfig.instagramAuthFunction,
        queryParameters: {'action': 'get_auth_url'},
        options: Options(
          headers: {
            'apikey': SupabaseConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          },
        ),
      );
      return response.data['auth_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Exchange authorization code for token
  Future<({bool success, String? username, String? error})> exchangeCode(
    String code,
  ) async {
    try {
      final userId = await _getOrCreateUserId();

      final response = await _dio.post(
        SupabaseConfig.instagramAuthFunction,
        queryParameters: {'action': 'exchange_code'},
        data: jsonEncode({
          'code': code,
          'user_id': userId,
        }),
        options: Options(
          headers: {
            'apikey': SupabaseConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final success = response.data['success'] == true;
      final username = response.data['username'] as String?;
      final error = response.data['error'] as String?;

      if (success && username != null) {
        await _saveConnection(username);
      }

      return (success: success, username: username, error: error);
    } catch (e) {
      return (success: false, username: null, error: e.toString());
    }
  }

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsConnected) ?? false;
  }

  Future<String?> getConnectedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsConnected, false);
    await prefs.remove(_keyUsername);
  }

  Future<void> _saveConnection(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsConnected, true);
    await prefs.setString(_keyUsername, username);
  }

  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_keyUserId);
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_keyUserId, userId);
    }
    return userId;
  }
}

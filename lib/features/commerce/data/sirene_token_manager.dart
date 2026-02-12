import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/constants/api_constants.dart';

class SireneTokenManager {
  static const _keyConsumerKey = 'consumer_key';
  static const _keyConsumerSecret = 'consumer_secret';
  static const _keyAccessToken = 'access_token';
  static const _keyTokenExpiry = 'token_expiry';

  /// Save SIRENE API credentials
  Future<void> saveCredentials(String consumerKey, String consumerSecret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConsumerKey, consumerKey);
    await prefs.setString(_keyConsumerSecret, consumerSecret);
  }

  /// Get a valid access token (cached or request new)
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString(_keyAccessToken);
    final expiry = prefs.getInt(_keyTokenExpiry) ?? 0;

    // Return cached if still valid (with 1 minute margin)
    if (cachedToken != null &&
        DateTime.now().millisecondsSinceEpoch < expiry - 60000) {
      return cachedToken;
    }

    return _requestNewToken();
  }

  Future<String?> _requestNewToken() async {
    final prefs = await SharedPreferences.getInstance();
    final consumerKey = prefs.getString(_keyConsumerKey);
    final consumerSecret = prefs.getString(_keyConsumerSecret);

    if (consumerKey == null || consumerSecret == null) return null;

    try {
      final credentials =
          base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

      final dio = Dio();
      final response = await dio.post(
        ApiConstants.sireneTokenUrl,
        data: 'grant_type=client_credentials',
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      final accessToken = response.data['access_token'] as String;
      final expiresIn = response.data['expires_in'] as int;
      final expiryMs =
          DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setInt(_keyTokenExpiry, expiryMs);

      return accessToken;
    } catch (e) {
      return null;
    }
  }
}

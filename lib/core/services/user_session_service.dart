import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserSessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? userJson = prefs.getString(_userKey);

    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(userJson));
  }

  Future<bool> isLoggedIn() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
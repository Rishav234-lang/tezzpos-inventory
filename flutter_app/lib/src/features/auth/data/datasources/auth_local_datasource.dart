import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<void> cacheToken(String token);
  Future<String?> getToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  static const String _userKey = 'cached_user';
  static const String _tokenKey = 'auth_token';

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> cacheUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = _prefs.getString(_userKey);
    if (jsonString == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_tokenKey);
  }

  @override
  Future<void> cacheToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }
}

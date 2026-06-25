import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../utils/error_utils.dart';



class AuthUser {

  final String id;

  final String email;

  final String name;

  final String role;

  final String? companyId;

  final String? companyName;



  AuthUser({

    required this.id,

    required this.email,

    required this.name,

    required this.role,

    this.companyId,

    this.companyName,

  });



  factory AuthUser.fromJson(Map<String, dynamic> json) {

    return AuthUser(

      id: json['id'] ?? '',

      email: json['email'] ?? '',

      name: json['name'] ?? '',

      role: json['role'] ?? '',

      companyId: json['companyId'],

      companyName: json['companyName'],

    );

  }

}



final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {

  return AuthNotifier(ref.read(apiClientProvider));

});



class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {

  final ApiClient _apiClient;



  AuthNotifier(this._apiClient) : super(const AsyncValue.data(null)) {

    _checkAuth();

  }



  Future<void> _checkAuth() async {

    final token = await _apiClient.getToken();

    if (token != null) {

      try {

        final response = await _apiClient.get(ApiConstants.me);

        state = AsyncValue.data(AuthUser.fromJson(response.data));

      } catch (e) {

        await _apiClient.clearToken();

        state = const AsyncValue.data(null);

      }

    }

  }



  Future<bool> login(String email, String password) async {

    state = const AsyncValue.loading();

    try {

      final response = await _apiClient.post(

        ApiConstants.login,

        data: {'email': email, 'password': password},

      );

      await _apiClient.setToken(response.data['token']);

      state = AsyncValue.data(AuthUser.fromJson(response.data['user']));

      return true;

    } catch (e) {
      state = AsyncValue.error(parseApiError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> superAdminLogin(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.post(
        ApiConstants.superAdminLogin,
        data: {'email': email, 'password': password},
      );
      await _apiClient.setToken(response.data['token']);
      state = AsyncValue.data(AuthUser.fromJson(response.data['user']));
      return true;
    } catch (e) {
      state = AsyncValue.error(parseApiError(e), StackTrace.current);
      return false;
    }
  }



  Future<void> logout() async {

    await _apiClient.clearToken();

    state = const AsyncValue.data(null);

  }



  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.put(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginAsCompany(String companyId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.post(
        ApiConstants.superAdminLoginAs(companyId),
      );
      await _apiClient.setToken(response.data['token']);
      final userJson = response.data['user'];
      state = AsyncValue.data(AuthUser(
        id: userJson['id'],
        email: userJson['email'],
        name: userJson['name'],
        role: 'owner',
        companyId: userJson['companyId'],
      ));
      return true;
    } catch (e) {
      state = AsyncValue.error(parseApiError(e), StackTrace.current);
      return false;
    }
  }
}


import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  final _authStateController = StreamController<AuthState>.broadcast();

  AuthNotifier({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AsyncValue.loading()) {
    _init();
  }

  Stream<AuthState> get authStateStream => _authStateController.stream;

  void _init() {
    _authSubscription = _authRepository.authStateStream.listen((authState) {
      _authStateController.add(authState);
      state = AsyncValue.data(authState);
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  Future<void> loginCompanyOwner({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.loginCompanyOwner(
      email: email,
      password: password,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) {},
    );
  }

  Future<void> registerCompany({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? companyGstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? planId,
    String? billingCycle,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.registerCompany(
      companyName: companyName,
      companyEmail: companyEmail,
      companyPhone: companyPhone,
      companyAddress: companyAddress,
      companyGstNumber: companyGstNumber,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPassword: ownerPassword,
      planId: planId,
      billingCycle: billingCycle,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) {},
    );
  }

  Future<void> loginSuperAdmin({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.loginSuperAdmin(
      email: email,
      password: password,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) {},
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await _authRepository.logout();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) {},
    );
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) {
        state = AsyncValue.data(AuthState(user: user));
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
    super.dispose();
  }
}

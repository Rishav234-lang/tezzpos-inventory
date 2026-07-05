import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> loginCompanyOwner({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> loginSuperAdmin({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> registerCompany({
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
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Stream<AuthState> get authStateStream;
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final _authStateController = StreamController<AuthState>.broadcast();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _initAuthState();
  }

  void _initAuthState() async {
    final cachedUser = await localDataSource.getCachedUser();
    if (cachedUser != null) {
      _authStateController.add(AuthState(user: cachedUser.toEntity()));
    } else {
      _authStateController.add(const AuthState(user: null));
    }
  }

  @override
  Future<Either<Failure, User>> loginCompanyOwner({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.loginCompanyOwner(
        email: email,
        password: password,
      );
      await _saveUser(user);
      _authStateController.add(AuthState(user: user.toEntity()));
      return Right(user.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final user = await remoteDataSource.registerCompany(
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
      await _saveUser(user);
      _authStateController.add(AuthState(user: user.toEntity()));
      return Right(user.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> loginSuperAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.loginSuperAdmin(
        email: email,
        password: password,
      );
      await _saveUser(user);
      _authStateController.add(AuthState(user: user.toEntity()));
      return Right(user.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearCache();
      _authStateController.add(const AuthState(user: null));
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<void> _saveUser(UserModel user) async {
    await localDataSource.cacheUser(user);
    if (user.token != null) {
      await localDataSource.cacheToken(user.token!);
    }
  }

  @override
  Stream<AuthState> get authStateStream => _authStateController.stream;
}

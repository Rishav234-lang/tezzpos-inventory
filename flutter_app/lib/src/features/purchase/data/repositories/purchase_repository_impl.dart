import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_datasource.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource _remoteDataSource;

  PurchaseRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPurchases({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
    String? sortOrder,
  }) async {
    try {
      final result = await _remoteDataSource.getPurchases(
        page: page,
        limit: limit,
        vendorId: vendorId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        sortOrder: sortOrder,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Purchase>> getPurchaseById(String id) async {
    try {
      final purchase = await _remoteDataSource.getPurchaseById(id);
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Purchase>> createPurchase(Map<String, dynamic> data) async {
    try {
      final purchase = await _remoteDataSource.createPurchase(data);
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Purchase>> updatePurchase(String id, Map<String, dynamic> data) async {
    try {
      final purchase = await _remoteDataSource.updatePurchase(id, data);
      return Right(purchase.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchase(String id) async {
    try {
      await _remoteDataSource.deletePurchase(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordVendorPayment(Map<String, dynamic> data) async {
    try {
      await _remoteDataSource.recordVendorPayment(data);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

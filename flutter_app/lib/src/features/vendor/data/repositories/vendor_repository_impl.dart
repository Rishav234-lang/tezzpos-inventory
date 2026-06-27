import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_remote_datasource.dart';

class VendorRepositoryImpl implements VendorRepository {
  final VendorRemoteDataSource _remoteDataSource;

  VendorRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Vendor>>> getVendors({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final vendors = await _remoteDataSource.getVendors(
        search: search,
        page: page,
        limit: limit,
      );
      return Right(vendors);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vendor>> getVendorById(String id) async {
    try {
      final vendor = await _remoteDataSource.getVendorById(id);
      return Right(vendor);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vendor>> createVendor(Map<String, dynamic> data) async {
    try {
      final vendor = await _remoteDataSource.createVendor(data);
      return Right(vendor);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vendor>> updateVendor(
      String id, Map<String, dynamic> data) async {
    try {
      final vendor = await _remoteDataSource.updateVendor(id, data);
      return Right(vendor);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVendor(String id) async {
    try {
      await _remoteDataSource.deleteVendor(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getVendorLedger(String id) async {
    try {
      final ledger = await _remoteDataSource.getVendorLedger(id);
      return Right(ledger);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_return.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource _remoteDataSource;

  SaleRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Sale>>> getSales({
    String? customerId,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final sales = await _remoteDataSource.getSales(
        customerId: customerId,
        status: status,
        search: search,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      return Right(sales);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    try {
      final sale = await _remoteDataSource.getSaleById(id);
      return Right(sale);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Sale>> createSale(Map<String, dynamic> data) async {
    try {
      final sale = await _remoteDataSource.createSale(data);
      return Right(sale);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Sale>> updateSalePayment(String id, Map<String, dynamic> data) async {
    try {
      final sale = await _remoteDataSource.updateSalePayment(id, data);
      return Right(sale);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Sale>>> searchSalesByInvoice(String invoiceNumber) async {
    try {
      final sales = await _remoteDataSource.searchSalesByInvoice(invoiceNumber);
      return Right(sales);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleReturn>>> getSaleReturns({int page = 1, int limit = 20}) async {
    try {
      final returns = await _remoteDataSource.getSaleReturns(page: page, limit: limit);
      return Right(returns);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SaleReturn>> getSaleReturnById(String id) async {
    try {
      final saleReturn = await _remoteDataSource.getSaleReturnById(id);
      return Right(saleReturn);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SaleReturn>> createSaleReturn(Map<String, dynamic> data) async {
    try {
      final saleReturn = await _remoteDataSource.createSaleReturn(data);
      return Right(saleReturn);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

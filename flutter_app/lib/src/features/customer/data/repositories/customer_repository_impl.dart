import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remoteDataSource;

  CustomerRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Customer>>> getCustomers({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final customers = await _remoteDataSource.getCustomers(
        search: search,
        page: page,
        limit: limit,
      );
      return Right(customers);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final customer = await _remoteDataSource.getCustomerById(id);
      return Right(customer);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer(Map<String, dynamic> data) async {
    try {
      final customer = await _remoteDataSource.createCustomer(data);
      return Right(customer);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final customer = await _remoteDataSource.updateCustomer(id, data);
      return Right(customer);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await _remoteDataSource.deleteCustomer(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerLedger(String id) async {
    try {
      final ledger = await _remoteDataSource.getCustomerLedger(id);
      return Right(ledger);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerSales(String id, {int page = 1, int limit = 20}) async {
    try {
      final sales = await _remoteDataSource.getCustomerSales(id, page: page, limit: limit);
      return Right(sales);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> receivePayment(Map<String, dynamic> data) async {
    try {
      await _remoteDataSource.receivePayment(data);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

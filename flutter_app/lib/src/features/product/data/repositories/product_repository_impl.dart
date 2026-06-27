import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    String? search,
    String? categoryId,
    String? status,
    String? stockFilter,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final products = await _remoteDataSource.getProducts(
        search: search,
        categoryId: categoryId,
        status: status,
        stockFilter: stockFilter,
        page: page,
        limit: limit,
      );
      return Right(products);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final product = await _remoteDataSource.getProductById(id);
      return Right(product);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> data) async {
    try {
      final product = await _remoteDataSource.createProduct(data);
      return Right(product);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      final product = await _remoteDataSource.updateProduct(id, data);
      return Right(product);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _remoteDataSource.deleteProduct(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProductImage(File imageFile) async {
    try {
      final path = await _remoteDataSource.uploadProductImage(imageFile);
      return Right(path);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

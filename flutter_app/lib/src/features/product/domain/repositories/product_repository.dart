import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    String? search,
    String? categoryId,
    String? status,
    String? stockFilter,
    int page,
    int limit,
  });
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> data);
  Future<Either<Failure, Product>> updateProduct(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, String>> uploadProductImage(File imageFile);
}

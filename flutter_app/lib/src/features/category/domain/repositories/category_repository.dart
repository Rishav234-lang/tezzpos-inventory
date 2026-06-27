import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories({String? search, String? status});
  Future<Either<Failure, Category>> getCategoryById(String id);
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
    String status,
  });
  Future<Either<Failure, Category>> updateCategory({
    required String id,
    String? name,
    String? description,
    String? imageUrl,
    String? status,
  });
  Future<Either<Failure, void>> deleteCategory(String id);
  Future<Either<Failure, String>> uploadCategoryImage(File imageFile);
}

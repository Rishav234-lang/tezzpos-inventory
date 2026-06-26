import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Category>>> getCategories({String? search, String? status}) async {
    try {
      final categories = await _remoteDataSource.getCategories(search: search, status: status);
      return Right(categories.map((m) => m.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final category = await _remoteDataSource.getCategoryById(id);
      return Right(category.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
    String status = 'ACTIVE',
  }) async {
    try {
      final data = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'status': status,
      };
      final category = await _remoteDataSource.createCategory(data);
      return Right(category.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory({
    required String id,
    String? name,
    String? description,
    String? imageUrl,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (status != null) data['status'] = status;
      final category = await _remoteDataSource.updateCategory(id, data);
      return Right(category.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await _remoteDataSource.deleteCategory(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

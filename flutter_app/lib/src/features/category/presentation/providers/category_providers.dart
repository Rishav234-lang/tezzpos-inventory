import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSourceImpl(ref.watch(dioProvider).dio);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryRemoteDataSourceProvider));
});

final categoriesProvider = FutureProvider.autoDispose.family<List<Category>, String>((ref, search) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories(search: search.isEmpty ? null : search);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

final categoryDetailProvider = FutureProvider.autoDispose.family<Category, String>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategoryById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (category) => category,
  );
});

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref.watch(categoryRepositoryProvider));
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createCategory({
    required String name,
    String? description,
    String? imageUrl,
    String status = 'ACTIVE',
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCategory(
      name: name,
      description: description,
      imageUrl: imageUrl,
      status: status,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    String? imageUrl,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCategory(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      status: status,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteCategory(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<String?> uploadCategoryImage(File imageFile) async {
    state = const AsyncValue.loading();
    final result = await _repository.uploadCategoryImage(imageFile);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (path) {
        state = const AsyncValue.data(null);
        return path;
      },
    );
  }
}

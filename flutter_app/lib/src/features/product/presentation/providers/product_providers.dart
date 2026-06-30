import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => ProductRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider)),
);

final productsProvider = FutureProvider.family<List<Product>, ProductFilter>(
  (ref, filter) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProducts(
      search: filter.search,
      categoryId: filter.categoryId,
      status: filter.status,
      stockFilter: filter.stockFilter,
      page: filter.page,
      limit: filter.limit,
    );
    return result.fold(
      (failure) => throw failure,
      (products) => products,
    );
  },
);

final productDetailProvider = FutureProvider.family<Product, String>(
  (ref, id) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductById(id);
    return result.fold(
      (failure) => throw failure,
      (product) => product,
    );
  },
);

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>(
  (ref) => ProductNotifier(ref.watch(productRepositoryProvider)),
);

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createProduct(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createProduct(data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateProduct(id, data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteProduct(id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<String?> uploadProductImage(File imageFile) async {
    state = const AsyncValue.loading();
    final result = await _repository.uploadProductImage(imageFile);
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

class ProductFilter {
  final String? search;
  final String? categoryId;
  final String? status;
  final String? stockFilter;
  final int page;
  final int limit;

  ProductFilter({
    this.search,
    this.categoryId,
    this.status,
    this.stockFilter,
    this.page = 1,
    this.limit = 20,
  });

  ProductFilter copyWith({
    String? search,
    String? categoryId,
    String? status,
    String? stockFilter,
    int? page,
    int? limit,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      stockFilter: stockFilter ?? this.stockFilter,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductFilter &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.status == status &&
        other.stockFilter == stockFilter &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(
      search,
      categoryId,
      status,
      stockFilter,
      page,
      limit,
    );
  }
}

final inventoryStatsProvider = FutureProvider<InventoryStats>((ref) async {
  final dio = ref.watch(dioProvider).dio;
  final response = await dio.get(ApiConstants.inventoryStats);
  final data = response.data as Map<String, dynamic>;
  return InventoryStats(
    totalProducts: data['totalProducts'] ?? 0,
    totalStockQuantity: data['totalStockQuantity'] ?? 0,
    inventoryValue: (data['inventoryValue'] as num?)?.toDouble() ?? 0.0,
    lowStockCount: data['lowStockCount'] ?? 0,
    outOfStockCount: data['outOfStockCount'] ?? 0,
    expiringSoonCount: data['expiringSoonCount'] ?? 0,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/purchase_remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

final purchaseRemoteDataSourceProvider = Provider<PurchaseRemoteDataSource>((ref) {
  return PurchaseRemoteDataSourceImpl(ref.watch(dioProvider).dio);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl(ref.watch(purchaseRemoteDataSourceProvider));
});

final purchasesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, PurchaseFilter>((ref, filter) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.getPurchases(
    page: filter.page,
    limit: filter.limit,
    vendorId: filter.vendorId,
    status: filter.status,
    startDate: filter.startDate,
    endDate: filter.endDate,
    sortOrder: filter.sortOrder,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

final purchaseDetailProvider = FutureProvider.autoDispose.family<Purchase, String>((ref, id) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.getPurchaseById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (purchase) => purchase,
  );
});

final purchaseNotifierProvider = StateNotifierProvider<PurchaseNotifier, AsyncValue<void>>((ref) {
  return PurchaseNotifier(ref.watch(purchaseRepositoryProvider));
});

class PurchaseNotifier extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repository;

  PurchaseNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createPurchase(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createPurchase(data);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> updatePurchase(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updatePurchase(id, data);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> deletePurchase(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deletePurchase(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> recordPayment(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.recordVendorPayment(data);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}

class PurchaseFilter {
  final int page;
  final int limit;
  final String? vendorId;
  final String? status;
  final String? startDate;
  final String? endDate;
  final String sortOrder;

  const PurchaseFilter({
    this.page = 1,
    this.limit = 20,
    this.vendorId,
    this.status,
    this.startDate,
    this.endDate,
    this.sortOrder = 'desc',
  });

  PurchaseFilter copyWith({
    int? page,
    int? limit,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
    String? sortOrder,
  }) {
    return PurchaseFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      vendorId: vendorId ?? this.vendorId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseFilter &&
        other.page == page &&
        other.limit == limit &&
        other.vendorId == vendorId &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(page, limit, vendorId, status, startDate, endDate, sortOrder);
}

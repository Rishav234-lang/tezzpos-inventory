import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/vendor_remote_datasource.dart';
import '../../data/repositories/vendor_repository_impl.dart';
import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';

final vendorRemoteDataSourceProvider = Provider<VendorRemoteDataSource>(
  (ref) => VendorRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => VendorRepositoryImpl(ref.watch(vendorRemoteDataSourceProvider)),
);

final vendorFilterProvider = StateProvider<VendorFilter>((ref) => VendorFilter());

final vendorsProvider = FutureProvider.autoDispose<List<Vendor>>(
  (ref) async {
    final filter = ref.watch(vendorFilterProvider);
    final repository = ref.watch(vendorRepositoryProvider);
    final result = await repository.getVendors(
      search: filter.search,
      page: filter.page,
      limit: filter.limit,
    );
    return result.fold(
      (failure) => throw failure,
      (vendors) => vendors,
    );
  },
);

final vendorPickerProvider = FutureProvider.autoDispose.family<List<Vendor>, String?>((ref, search) async {
  final repository = ref.watch(vendorRepositoryProvider);
  final result = await repository.getVendors(search: search, page: 1, limit: 50);
  return result.fold(
    (failure) => throw failure,
    (vendors) => vendors,
  );
});

final allVendorsProvider = FutureProvider.autoDispose<List<Vendor>>((ref) async {
  final repository = ref.watch(vendorRepositoryProvider);
  final result = await repository.getVendors(search: null, page: 1, limit: 200);
  return result.fold(
    (failure) => throw failure,
    (vendors) => vendors,
  );
});

final vendorDetailProvider = FutureProvider.autoDispose.family<Vendor, String>(
  (ref, id) async {
    final repository = ref.watch(vendorRepositoryProvider);
    final result = await repository.getVendorById(id);
    return result.fold(
      (failure) => throw failure,
      (vendor) => vendor,
    );
  },
);

final vendorLedgerProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, id) async {
    final repository = ref.watch(vendorRepositoryProvider);
    final result = await repository.getVendorLedger(id);
    return result.fold(
      (failure) => throw failure,
      (ledger) => ledger,
    );
  },
);

final vendorNotifierProvider =
    StateNotifierProvider<VendorNotifier, AsyncValue<void>>(
  (ref) => VendorNotifier(ref.watch(vendorRepositoryProvider)),
);

class VendorNotifier extends StateNotifier<AsyncValue<void>> {
  final VendorRepository _repository;

  VendorNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createVendor(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createVendor(data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateVendor(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateVendor(id, data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> deleteVendor(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteVendor(id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

class VendorFilter {
  final String? search;
  final int page;
  final int limit;

  VendorFilter({
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  VendorFilter copyWith({
    String? search,
    int? page,
    int? limit,
  }) {
    return VendorFilter(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorFilter &&
        other.search == search &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(search, page, limit);
}

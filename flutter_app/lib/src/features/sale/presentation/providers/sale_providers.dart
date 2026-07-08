import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/sale_remote_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_return.dart';
import '../../domain/repositories/sale_repository.dart';

final saleRemoteDataSourceProvider = Provider<SaleRemoteDataSource>(
  (ref) => SaleRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepositoryImpl(ref.watch(saleRemoteDataSourceProvider)),
);

final saleFilterProvider = StateProvider<SaleFilter>((ref) => SaleFilter());

final salesProvider = FutureProvider.autoDispose<List<Sale>>(
  (ref) async {
    final filter = ref.watch(saleFilterProvider);
    final repository = ref.watch(saleRepositoryProvider);
    final result = await repository.getSales(
      customerId: filter.customerId,
      status: filter.status,
      search: filter.search,
      startDate: filter.startDate,
      endDate: filter.endDate,
      page: filter.page,
      limit: filter.limit,
    );
    return result.fold(
      (failure) => throw failure,
      (sales) => sales,
    );
  },
);

final saleDetailProvider = FutureProvider.autoDispose.family<Sale, String>(
  (ref, id) async {
    final repository = ref.watch(saleRepositoryProvider);
    final result = await repository.getSaleById(id);
    return result.fold(
      (failure) => throw failure,
      (sale) => sale,
    );
  },
);

final saleReturnsProvider = FutureProvider.autoDispose.family<List<SaleReturn>, SaleReturnFilter>(
  (ref, filter) async {
    final repository = ref.watch(saleRepositoryProvider);
    final result = await repository.getSaleReturns(page: filter.page, limit: filter.limit);
    return result.fold(
      (failure) => throw failure,
      (returns) => returns,
    );
  },
);

final saleReturnDetailProvider = FutureProvider.autoDispose.family<SaleReturn, String>(
  (ref, id) async {
    final repository = ref.watch(saleRepositoryProvider);
    final result = await repository.getSaleReturnById(id);
    return result.fold(
      (failure) => throw failure,
      (saleReturn) => saleReturn,
    );
  },
);

final saleNotifierProvider = StateNotifierProvider<SaleNotifier, AsyncValue<void>>(
  (ref) => SaleNotifier(ref.watch(saleRepositoryProvider)),
);

class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repository;

  SaleNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Sale?> createSale(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createSale(data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (sale) {
        state = const AsyncValue.data(null);
        return sale;
      },
    );
  }

  Future<void> updateSalePayment(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateSalePayment(id, data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<SaleReturn?> createSaleReturn(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createSaleReturn(data);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (saleReturn) {
        state = const AsyncValue.data(null);
        return saleReturn;
      },
    );
  }
}

class SaleFilter {
  final String? customerId;
  final String? status;
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  SaleFilter({
    this.customerId,
    this.status,
    this.search,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  SaleFilter copyWith({
    String? customerId,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) {
    return SaleFilter(
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      search: search ?? this.search,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleFilter &&
        other.customerId == customerId &&
        other.status == status &&
        other.search == search &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(customerId, status, search, startDate, endDate, page, limit);
}

class SaleReturnFilter {
  final int page;
  final int limit;

  SaleReturnFilter({this.page = 1, this.limit = 20});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleReturnFilter && other.page == page && other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(page, limit);
}

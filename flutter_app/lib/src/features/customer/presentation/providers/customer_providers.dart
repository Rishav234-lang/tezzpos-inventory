import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>(
  (ref) => CustomerRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(ref.watch(customerRemoteDataSourceProvider)),
);

final customerFilterProvider = StateProvider<CustomerFilter>((ref) => CustomerFilter());

final customersProvider = FutureProvider.autoDispose<List<Customer>>(
  (ref) async {
    final filter = ref.watch(customerFilterProvider);
    final repository = ref.watch(customerRepositoryProvider);
    final result = await repository.getCustomers(
      search: filter.search,
      page: filter.page,
      limit: filter.limit,
    );
    return result.fold(
      (failure) => throw failure,
      (customers) => customers,
    );
  },
);

final customerPickerProvider = FutureProvider.autoDispose.family<List<Customer>, String?>((ref, search) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomers(search: search, page: 1, limit: 50);
  return result.fold(
    (failure) => throw failure,
    (customers) => customers,
  );
});

final allCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomers(page: 1, limit: 200);
  return result.fold(
    (failure) => throw failure,
    (customers) => customers,
  );
});

final customerDetailProvider = FutureProvider.autoDispose.family<Customer, String>(
  (ref, id) async {
    final repository = ref.watch(customerRepositoryProvider);
    final result = await repository.getCustomerById(id);
    return result.fold(
      (failure) => throw failure,
      (customer) => customer,
    );
  },
);

final customerLedgerProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, id) async {
    final repository = ref.watch(customerRepositoryProvider);
    final result = await repository.getCustomerLedger(id);
    return result.fold(
      (failure) => throw failure,
      (ledger) => ledger,
    );
  },
);

final customerSalesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, id) async {
    final repository = ref.watch(customerRepositoryProvider);
    final result = await repository.getCustomerSales(id);
    return result.fold(
      (failure) => throw failure,
      (sales) => sales,
    );
  },
);

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<void>>(
  (ref) => CustomerNotifier(ref.watch(customerRepositoryProvider)),
);

class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createCustomer(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCustomer(data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCustomer(id, data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteCustomer(id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> receivePayment(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.receivePayment(data);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

class CustomerFilter {
  final String? search;
  final int page;
  final int limit;

  CustomerFilter({
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  CustomerFilter copyWith({
    String? search,
    int? page,
    int? limit,
  }) {
    return CustomerFilter(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerFilter &&
        other.search == search &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(search, page, limit);
}

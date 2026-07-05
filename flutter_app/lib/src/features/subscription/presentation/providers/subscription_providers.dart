import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';

final subscriptionPlansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider).dio;
  try {
    final response = await dio.get(ApiConstants.subscriptionPlans);
    if (response.statusCode == 200) {
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    }
  } on DioException catch (e) {
    final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
    throw Exception('Failed to load plans: $msg');
  }
  throw Exception('Failed to load plans');
});

final mySubscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider).dio;
  try {
    final response = await dio.get(ApiConstants.mySubscription);
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    return null;
  }
  return null;
});

final subscriptionPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider).dio;
  final response = await dio.get(ApiConstants.subscriptionPayments);
  if (response.statusCode == 200) {
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }
  throw Exception('Failed to load payments');
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<void>> {
  final Dio _dio;
  SubscriptionNotifier(this._dio) : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>?> createOrder({
    required String planId,
    required String billingCycle,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post(ApiConstants.createOrder, data: {
        'planId': planId,
        'billingCycle': billingCycle,
      });
      state = const AsyncValue.data(null);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String planId,
    required String billingCycle,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post(ApiConstants.verifyPayment, data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'planId': planId,
        'billingCycle': billingCycle,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<Map<String, dynamic>?> createRazorpaySubscription({
    required String planId,
    required String billingCycle,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post(ApiConstants.createRazorpaySubscription, data: {
        'planId': planId,
        'billingCycle': billingCycle,
      });
      state = const AsyncValue.data(null);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<bool> cancelAutoPay() async {
    state = const AsyncValue.loading();
    try {
      await _dio.post(ApiConstants.cancelRazorpaySubscription);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> toggleAutoRenew(bool autoRenew) async {
    state = const AsyncValue.loading();
    try {
      await _dio.put(ApiConstants.toggleAutoRenew, data: {
        'autoRenew': autoRenew,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<void>>((ref) {
  final dio = ref.watch(dioProvider).dio;
  return SubscriptionNotifier(dio);
});

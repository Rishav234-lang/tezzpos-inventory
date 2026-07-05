// Stub for razorpay_flutter on web platform
class Razorpay {
  static const String eventPaymentSuccess = 'payment.success';
  static const String eventPaymentError = 'payment.error';
  static const String eventExternalWallet = 'payment.external_wallet';

  // Legacy names for compatibility with Razorpay SDK naming
  static const String EVENT_PAYMENT_SUCCESS = eventPaymentSuccess;
  static const String EVENT_PAYMENT_ERROR = eventPaymentError;
  static const String EVENT_EXTERNAL_WALLET = eventExternalWallet;

  void on(String event, Function handler) {}
  void open(Map<String, dynamic> options) {}
  void clear() {}
}

class PaymentSuccessResponse {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  PaymentSuccessResponse(this.paymentId, this.orderId, this.signature);
}

class PaymentFailureResponse {
  final int? code;
  final String? message;

  PaymentFailureResponse(this.code, this.message);
}

class ExternalWalletResponse {
  final String? walletName;

  ExternalWalletResponse(this.walletName);
}

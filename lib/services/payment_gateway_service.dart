import '../config/payment_config.dart';

class PaymentGatewayService {
  static bool get isRazorpayReady =>
      PaymentConfig.razorpayEnabled && PaymentConfig.razorpayKeyId.isNotEmpty;

  static String get razorpayStatusMessage {
    if (isRazorpayReady) {
      return 'Razorpay key is configured for this build. Enable backend order creation and signature verification before switching it on for customer payments.';
    }
    return 'Razorpay is not configured in this build yet. Add RAZORPAY_ENABLED=true and RAZORPAY_KEY_ID through dart-define when the backend payment flow is ready.';
  }

  static Map<String, dynamic> buildRazorpayCheckoutOptions({
    required int amountPaise,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String orderId,
    Map<String, dynamic>? notes,
  }) {
    if (!isRazorpayReady) {
      throw StateError(razorpayStatusMessage);
    }
    if (orderId.trim().isEmpty) {
      throw StateError(
        'A backend-generated Razorpay order_id is required before checkout can start.',
      );
    }
    return {
      'key': PaymentConfig.razorpayKeyId,
      'amount': amountPaise,
      'name': PaymentConfig.razorpayMerchantName,
      'description': 'ZyroMart order payment',
      'order_id': orderId,
      'prefill': {
        'name': customerName,
        'contact': customerPhone,
        'email': customerEmail,
      },
      'notes': notes ?? const <String, dynamic>{},
      'theme': {'color': '#1D8C3A'},
    };
  }
}

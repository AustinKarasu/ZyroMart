import '../config/payment_config.dart';

class PaymentGatewayService {
  static bool get isRazorpayReady =>
      PaymentConfig.razorpayEnabled && PaymentConfig.razorpayKeyId.isNotEmpty;

  static String get razorpayStatusMessage {
    if (isRazorpayReady) {
      return 'Razorpay keys are configured for this build. Switch customer checkout to online payment only after backend order creation and signature verification are enabled.';
    }
    return 'Razorpay is not configured in this build yet. Add RAZORPAY_ENABLED=true and RAZORPAY_KEY_ID through dart-define when the payment backend is ready.';
  }
}


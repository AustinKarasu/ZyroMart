class PaymentConfig {
  static const bool razorpayEnabled = bool.fromEnvironment(
    'RAZORPAY_ENABLED',
    defaultValue: false,
  );

  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  static const String razorpayMerchantName = String.fromEnvironment(
    'RAZORPAY_MERCHANT_NAME',
    defaultValue: 'ZyroMart',
  );
}

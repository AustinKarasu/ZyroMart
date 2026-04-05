class DeliveryFeedback {
  final String orderId;
  final String customerId;
  final String deliveryPersonId;
  final int rating;
  final String feedback;
  final DateTime createdAt;

  const DeliveryFeedback({
    required this.orderId,
    required this.customerId,
    required this.deliveryPersonId,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });
}

class AppNotification {
  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  bool isRead;
  final String? orderId;

  AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.orderId,
    this.isRead = false,
  });
}

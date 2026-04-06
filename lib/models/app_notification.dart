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

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'].toString(),
      recipientUserId: (map['user_id'] ?? map['recipient_user_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      category: (map['category'] ?? 'system').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      orderId: map['order_id']?.toString(),
      isRead: map['is_read'] == true,
    );
  }
}

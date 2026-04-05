import 'package:latlong2/latlong.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double rating;
  final String imageUrl;
  final bool isOpen;
  final String ownerId;
  final String phone;
  final String openTime;
  final String closeTime;
  final int totalOrders;
  final double totalRevenue;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.rating = 4.5,
    required this.imageUrl,
    this.isOpen = true,
    required this.ownerId,
    this.phone = '',
    this.openTime = '08:00 AM',
    this.closeTime = '10:00 PM',
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
  });
}

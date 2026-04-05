import 'package:latlong2/latlong.dart';

enum UserRole { customer, storeOwner, delivery }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String address;
  final LatLng location;
  final String? profileImageUrl;
  final double? deliveryRating;
  final int? completedDeliveries;
  final bool isOnline;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address = '',
    required this.location,
    this.profileImageUrl,
    this.deliveryRating,
    this.completedDeliveries,
    this.isOnline = true,
  });
}

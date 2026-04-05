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

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? address,
    LatLng? location,
    String? profileImageUrl,
    double? deliveryRating,
    int? completedDeliveries,
    bool? isOnline,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

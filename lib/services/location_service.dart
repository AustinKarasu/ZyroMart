import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService extends ChangeNotifier {
  LatLng? _currentLocation;
  String? _currentPlaceName;
  LocationPermission? _permission;
  bool _isLoading = false;
  String? _errorMessage;

  LatLng? get currentLocation => _currentLocation;
  String? get currentPlaceName => _currentPlaceName;
  LocationPermission? get permission => _permission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUsableLocation =>
      _currentLocation != null &&
      (_permission == LocationPermission.always ||
          _permission == LocationPermission.whileInUse);

  Future<void> initialize() async {
    await refreshLocation();
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        _errorMessage = 'Location services are disabled on this device.';
        return;
      }

      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
      }

      if (_permission == LocationPermission.denied ||
          _permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permission is needed for delivery maps and nearby store coverage.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentPlaceName = await reverseGeocode(_currentLocation);
    } catch (error) {
      _errorMessage = 'Could not load device location. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> reverseGeocode([LatLng? location]) async {
    final target = location ?? _currentLocation;
    if (target == null) return null;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=${target.latitude}'
        '&lon=${target.longitude}'
        '&zoom=18'
        '&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'ZyroMart/1.0 (support@zyromart.app)',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map) return null;
      final displayName = payload['display_name']?.toString().trim();
      if (displayName == null || displayName.isEmpty) return null;
      return displayName;
    } catch (_) {
      return null;
    }
  }
}

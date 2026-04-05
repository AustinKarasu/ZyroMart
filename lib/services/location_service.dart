import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService extends ChangeNotifier {
  LatLng? _currentLocation;
  LocationPermission? _permission;
  bool _isLoading = false;
  String? _errorMessage;

  LatLng? get currentLocation => _currentLocation;
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
    } catch (error) {
      _errorMessage = 'Could not load device location. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

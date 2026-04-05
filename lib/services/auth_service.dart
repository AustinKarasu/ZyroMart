import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/mock_data.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  UserRole? _selectedRole;

  AppUser? get currentUser => _currentUser;
  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _currentUser != null;

  void selectRole(UserRole role) {
    _selectedRole = role;
    switch (role) {
      case UserRole.customer:
        _currentUser = MockData.defaultCustomer;
        break;
      case UserRole.storeOwner:
        _currentUser = MockData.defaultStoreOwner;
        break;
      case UserRole.delivery:
        _currentUser = MockData.deliveryPersons[0];
        break;
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _selectedRole = null;
    notifyListeners();
  }
}

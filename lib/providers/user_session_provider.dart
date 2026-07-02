import 'package:flutter/material.dart';

class UserSessionProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  bool _hasSeenHostOnboarding = false;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String _userAvatar = 'assets/images/man.jpeg';

  bool get isLoggedIn => _isLoggedIn;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSeenHostOnboarding => _hasSeenHostOnboarding;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String get userAvatar => _userAvatar;

  void setHasSeenOnboarding(bool value) {
    _hasSeenOnboarding = value;
    notifyListeners();
  }

  void setHasSeenHostOnboarding(bool value) {
    _hasSeenHostOnboarding = value;
    notifyListeners();
  }

  void login(String name, String email, String phone) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    _userAvatar = email.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _userAvatar = 'assets/images/man.jpeg';
    _hasSeenHostOnboarding = false;
    notifyListeners();
  }
}

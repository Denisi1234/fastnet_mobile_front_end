import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';

class UserSessionProvider extends ChangeNotifier {
  bool get isLoggedIn => UserSession.isLoggedIn;
  bool get hasSeenOnboarding => UserSession.hasSeenOnboarding;
  bool get hasSeenHostOnboarding => UserSession.hasSeenHostOnboarding;
  String? get userName => UserSession.userName;
  String? get userEmail => UserSession.userEmail;
  String? get userPhone => UserSession.userPhone;
  String get userAvatar => UserSession.userAvatar;
  ImageProvider get profileImage => UserSession.getProfileImageProvider();

  /// Web parity (`profile_sidebar.php` role gating).
  String get userRole => UserSession.userRole;
  bool get isOwnerOrAdmin =>
      UserSession.userRole == 'owner' || UserSession.userRole == 'admin';
  bool get isAdmin => UserSession.userRole == 'admin';
  String? get avatarBg => UserSession.avatarBg;
  String? get avatarFg => UserSession.avatarFg;

  void updateSession() {
    notifyListeners();
  }

  void setHasSeenOnboarding(bool value) {
    UserSession.setHasSeenOnboarding(value);
    notifyListeners();
  }

  void setHasSeenHostOnboarding(bool value) {
    UserSession.setHasSeenHostOnboarding(value);
    notifyListeners();
  }

  void login(String name, String email, String phone) {
    UserSession.login(name, email, phone);
    notifyListeners();
  }

  Future<bool> loginWithApi(String email, String password) async {
    final success = await UserSession.loginWithApi(email, password);
    notifyListeners();
    return success;
  }

  Future<bool> registerWithApi({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final success = await UserSession.registerWithApi(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
    notifyListeners();
    return success;
  }

  void logout() {
    UserSession.logout();
    notifyListeners();
  }

  Future<void> logoutWithApi() async {
    await UserSession.logoutWithApi();
    notifyListeners();
  }
}

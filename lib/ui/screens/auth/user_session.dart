import 'package:fastnet_mobile_front_end/models/destination.dart';

class UserSession {
  static bool isLoggedIn = false;
  static bool hasSeenOnboarding = false;
  static bool hasSeenHostOnboarding = false;
  static String? userName;
  static String? userEmail;
  static String? userPhone;
  static String userAvatar = 'assets/images/man.jpeg';

  static void login(String name, String email, String phone) {
    isLoggedIn = true;
    userName = name;
    userEmail = email;
    userPhone = phone;
    userAvatar = email.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
  }

  static void logout() {
    isLoggedIn = false;
    userName = null;
    userEmail = null;
    userPhone = null;
    userAvatar = 'assets/images/man.jpeg';
    hasSeenHostOnboarding = false;
  }
}  }
}

class RecentlyViewedData {
  static final List<Destination> list = [];

  static void add(Destination destination) {
    list.removeWhere((item) => item.name == destination.name);
    list.insert(0, destination);
    if (list.length > 6) {
      list.removeLast();
    }
  }
}

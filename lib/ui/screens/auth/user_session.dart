import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

class UserSession {
  static bool isLoggedIn = false;
  static bool hasSeenOnboarding = false;
  static bool hasSeenHostOnboarding = false;
  static String? userName;
  static String? userEmail;
  static String? userPhone;
  static int? userId;
  static String userAvatar = 'assets/images/man.jpeg';

  // Extended profile fields
  static String? profileImagePath; // real device file path (null = use asset avatar)
  static String? dateOfBirth;       // e.g. "1995-06-15"
  static String? gender;            // e.g. "Male" / "Female" / "Other"
  static String? bio;
  static String? address;
  static String? emergencyContact;

  static ImageProvider getProfileImageProvider() {
    if (profileImagePath != null) {
      final f = File(profileImagePath!);
      if (f.existsSync()) return FileImage(f);
    }
    return AssetImage(userAvatar);
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = prefs.getBool('session_isLoggedIn') ?? false;
      hasSeenOnboarding = prefs.getBool('session_hasSeenOnboarding') ?? false;
      hasSeenHostOnboarding = prefs.getBool('session_hasSeenHostOnboarding') ?? false;
      userName = prefs.getString('session_userName');
      userEmail = prefs.getString('session_userEmail');
      userPhone = prefs.getString('session_userPhone');
      userId = prefs.getInt('session_userId');
      userAvatar = prefs.getString('session_userAvatar') ?? 'assets/images/man.jpeg';
      profileImagePath = prefs.getString('session_profileImagePath');
      dateOfBirth = prefs.getString('session_dateOfBirth');
      gender = prefs.getString('session_gender');
      bio = prefs.getString('session_bio');
      address = prefs.getString('session_address');
      emergencyContact = prefs.getString('session_emergencyContact');

      // Load wishlist
      final wishNames = prefs.getStringList('wishlist_names') ?? [];
      WishlistData.list.clear();
      for (final name in wishNames) {
        final match = destinations.where((d) => d.name == name);
        if (match.isNotEmpty) {
          WishlistData.list.add(match.first);
        }
      }

      // Load bookings
      final bookingsJson = prefs.getString('bookings_data');
      if (bookingsJson != null) {
        final decoded = jsonDecode(bookingsJson) as List;
        BookingsData.list.clear();
        BookingsData.list.addAll(decoded.map((item) {
          final map = Map<String, dynamic>.from(item);
          if (map['imageUrl'] == 'assets/images/house1.webp') {
            map['imageUrl'] = 'assets/images/house3.webp';
          }
          return map;
        }));
        await BookingsData.save();
      }

      // Load recently viewed
      final recentNames = prefs.getStringList('recent_names') ?? [];
      RecentlyViewedData.list.clear();
      for (final name in recentNames) {
        final match = destinations.where((d) => d.name == name);
        if (match.isNotEmpty) {
          RecentlyViewedData.list.add(match.first);
        }
      }
    } catch (e) {
      // Fallback silently if platform doesn't support SharedPreferences
    }
  }

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_isLoggedIn', isLoggedIn);
      await prefs.setBool('session_hasSeenOnboarding', hasSeenOnboarding);
      await prefs.setBool('session_hasSeenHostOnboarding', hasSeenHostOnboarding);
      if (userName != null) {
        await prefs.setString('session_userName', userName!);
      } else {
        await prefs.remove('session_userName');
      }
      if (userEmail != null) {
        await prefs.setString('session_userEmail', userEmail!);
      } else {
        await prefs.remove('session_userEmail');
      }
      if (userPhone != null) {
        await prefs.setString('session_userPhone', userPhone!);
      } else {
        await prefs.remove('session_userPhone');
      }
      if (userId != null) {
        await prefs.setInt('session_userId', userId!);
      } else {
        await prefs.remove('session_userId');
      }
      await prefs.setString('session_userAvatar', userAvatar);
      if (profileImagePath != null) {
        await prefs.setString('session_profileImagePath', profileImagePath!);
      } else {
        await prefs.remove('session_profileImagePath');
      }
      if (dateOfBirth != null) {
        await prefs.setString('session_dateOfBirth', dateOfBirth!);
      } else {
        await prefs.remove('session_dateOfBirth');
      }
      if (gender != null) {
        await prefs.setString('session_gender', gender!);
      } else {
        await prefs.remove('session_gender');
      }
      if (bio != null) {
        await prefs.setString('session_bio', bio!);
      } else {
        await prefs.remove('session_bio');
      }
      if (address != null) {
        await prefs.setString('session_address', address!);
      } else {
        await prefs.remove('session_address');
      }
      if (emergencyContact != null) {
        await prefs.setString('session_emergencyContact', emergencyContact!);
      } else {
        await prefs.remove('session_emergencyContact');
      }
    } catch (e) {
      // Ignore
    }
  }

  static void setHasSeenOnboarding(bool value) {
    hasSeenOnboarding = value;
    save();
  }

  static void setHasSeenHostOnboarding(bool value) {
    hasSeenHostOnboarding = value;
    save();
  }

  static void login(String name, String email, String phone) {
    isLoggedIn = true;
    userName = name;
    userEmail = email;
    userPhone = phone;
    userId = 2; // Default fallback local ID
    userAvatar = email.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
    save();
  }

  static Future<bool> loginWithApi(String email, String password) async {
    final response = await ApiService.login(email, password);
    if (response != null) {
      final user = response['user'];
      isLoggedIn = true;
      userName = user['name'] ?? 'Traveler';
      userEmail = user['email'] ?? email;
      userPhone = user['phone_number'] ?? '';
      userId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
      userAvatar = userEmail!.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
      await save();
      await BookingsData.syncFromApi();
      return true;
    }
    return false;
  }

  static Future<bool> registerWithApi({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final response = await ApiService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
    if (response != null) {
      final user = response['user'];
      isLoggedIn = true;
      userName = user['name'] ?? name;
      userEmail = user['email'] ?? email;
      userPhone = user['phone_number'] ?? phone;
      userId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
      userAvatar = userEmail!.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
      await save();
      await BookingsData.syncFromApi();
      return true;
    }
    return false;
  }

  static void logout() {
    isLoggedIn = false;
    userName = null;
    userEmail = null;
    userPhone = null;
    userId = null;
    userAvatar = 'assets/images/man.jpeg';
    profileImagePath = null;
    dateOfBirth = null;
    gender = null;
    bio = null;
    address = null;
    emergencyContact = null;
    hasSeenHostOnboarding = false;
    save();
  }

  static Future<void> logoutWithApi() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    isLoggedIn = false;
    userName = null;
    userEmail = null;
    userPhone = null;
    userId = null;
    userAvatar = 'assets/images/man.jpeg';
    profileImagePath = null;
    dateOfBirth = null;
    gender = null;
    bio = null;
    address = null;
    emergencyContact = null;
    hasSeenHostOnboarding = false;
    await save();
  }
}

class WishlistData {
  static final List<Destination> list = [];

  static bool contains(Destination destination) {
    return list.any((item) => item.name == destination.name);
  }

  static void toggle(Destination destination) {
    if (contains(destination)) {
      list.removeWhere((item) => item.name == destination.name);
    } else {
      list.add(destination);
    }
    save();
  }

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final names = list.map((d) => d.name).toList();
      await prefs.setStringList('wishlist_names', names);
    } catch (e) {
      // Ignore
    }
  }
}

class BookingsData {
  static final List<Map<String, dynamic>> list = [
    {
      'name': 'Kariakoo Budget Lodge',
      'city': 'Dar es Salaam',
      'area': 'Kariakoo',
      'dates': 'Jun 12 – 15, 2026',
      'nights': 3,
      'price': 110000,
      'code': 'TZ-84920-DAR',
      'imageUrl': 'assets/images/house3.webp',
      'status': 'Completed',
      'paymentTime': 'Jun 01, 2026 - 10:15 AM',
    },
    {
      'name': 'Zanzibar Sunset Beach Villa',
      'city': 'Zanzibar',
      'area': 'Nungwi',
      'dates': 'Jun 26 – 29, 2026',
      'nights': 3,
      'price': 555000,
      'code': 'TZ-74312-ZNBR',
      'imageUrl': 'assets/images/home.webp',
      'status': 'Checked In',
      'paymentTime': 'Jun 15, 2026 - 02:30 PM',
    },
    {
      'name': 'Arusha Highlands Lodge',
      'city': 'Arusha',
      'area': 'Mount Meru',
      'dates': 'Jul 10 – 14, 2026',
      'nights': 4,
      'price': 420000,
      'code': 'TZ-39201-ARS',
      'imageUrl': 'assets/images/house3.webp',
      'status': 'Confirmed',
      'paymentTime': 'Jul 01, 2026 - 07:34 AM',
    }
  ];

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bookings_data', jsonEncode(list));
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> syncFromApi() async {
    if (!UserSession.isLoggedIn) return;
    try {
      final apiBookings = await ApiService.fetchBookings();
      if (apiBookings.isNotEmpty) {
        list.clear();
        for (var b in apiBookings) {
          final room = b['room'] ?? {};
          final property = room['property'] ?? {};
          final checkInStr = b['check_in'] ?? '';
          final checkOutStr = b['check_out'] ?? '';
          
          // Format date range nicely
          String datesText = '$checkInStr – $checkOutStr';
          try {
            final checkInDate = DateTime.parse(checkInStr);
            final checkOutDate = DateTime.parse(checkOutStr);
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            datesText = '${months[checkInDate.month - 1]} ${checkInDate.day} – ${checkOutDate.day}, ${checkInDate.year}';
          } catch (_) {}

          final checkInDate = DateTime.tryParse(checkInStr) ?? DateTime.now();
          final checkOutDate = DateTime.tryParse(checkOutStr) ?? DateTime.now();
          final nights = checkOutDate.difference(checkInDate).inDays;

          list.add({
            'id': b['id'],
            'name': property['name'] ?? 'Lodge Stay',
            'city': property['city'] ?? 'Dar es Salaam',
            'area': property['area'] ?? 'Mikocheni',
            'dates': datesText,
            'nights': nights > 0 ? nights : 1,
            'price': (double.tryParse(b['total_price']?.toString() ?? '0') ?? 0).toInt(),
            'code': 'TZ-${b['id'] ?? 10000}-DAR',
            'imageUrl': property['image_url'] ?? 'assets/images/house3.webp',
            'status': b['payment_status'] == 'paid' 
                ? 'Confirmed' 
                : b['payment_status'] == 'refunded' 
                    ? 'Cancelled' 
                    : 'Confirmed',
            'roomNumber': room['room_number'] ?? '101',
          });
        }
        await save();
      }
    } catch (e) {
      debugPrint('Error syncing bookings from API: $e');
    }
  }
}

class RecentlyViewedData {
  static final List<Destination> list = [];

  static void add(Destination destination) {
    list.removeWhere((item) => item.name == destination.name);
    list.insert(0, destination);
    if (list.length > 6) {
      list.removeLast();
    }
    save();
  }

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final names = list.map((d) => d.name).toList();
      await prefs.setStringList('recent_names', names);
    } catch (e) {
      // Ignore
    }
  }
}

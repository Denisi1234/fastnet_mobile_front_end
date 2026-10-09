import 'dart:convert';
import 'dart:io';
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

  /// Web parity (`profile_sidebar.php` role gating): 'guest' | 'owner' | 'admin'.
  static String userRole = 'guest';

  /// Web parity (`my-profile.php` avatar badges): initial-letter avatar
  /// colors, e.g. bg '#f0f9ff' / fg '#0284c7'. Null = default blue badge.
  static String? avatarBg;
  static String? avatarFg;

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
      userRole = prefs.getString('session_userRole') ?? 'guest';
      avatarBg = prefs.getString('session_avatarBg');
      avatarFg = prefs.getString('session_avatarFg');
      profileImagePath = prefs.getString('session_profileImagePath');
      dateOfBirth = prefs.getString('session_dateOfBirth');
      gender = prefs.getString('session_gender');
      bio = prefs.getString('session_bio');
      address = prefs.getString('session_address');
      emergencyContact = prefs.getString('session_emergencyContact');

      // Load wishlist (persisted as full JSON so it survives before the
      // live `destinations` cache is filled from the backend).
      try {
        final wishRaw = prefs.getString('wishlist_json');
        WishlistData.list.clear();
        if (wishRaw != null) {
          final decoded = jsonDecode(wishRaw) as List;
          for (final item in decoded) {
            try {
              WishlistData.list.add(Destination.fromDraftJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        } else {
          // Legacy name-based entries from before the backend cutover.
          final wishNames = prefs.getStringList('wishlist_names') ?? [];
          for (final name in wishNames) {
            final match = destinations.where((d) => d.name == name);
            if (match.isNotEmpty) WishlistData.list.add(match.first);
          }
        }
      } catch (_) {}

      // Load bookings (+ last successful sync stamp for the
      // offline "Updated X ago" banner).
      BookingsData.lastSyncedAt = DateTime.tryParse(
          prefs.getString('bookings_synced_at') ?? '');
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
      await prefs.setString('session_userRole', userRole);
      if (avatarBg != null) {
        await prefs.setString('session_avatarBg', avatarBg!);
      } else {
        await prefs.remove('session_avatarBg');
      }
      if (avatarFg != null) {
        await prefs.setString('session_avatarFg', avatarFg!);
      } else {
        await prefs.remove('session_avatarFg');
      }
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

  static String _normalizeRole(dynamic raw, String fallback) {
    final r = (raw ?? '').toString().toLowerCase().trim();
    if (r == 'owner' || r == 'admin' || r == 'guest' || r == 'host') {
      return r == 'host' ? 'owner' : r;
    }
    return fallback;
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
      userRole = _normalizeRole(user['role'], 'guest');
      userAvatar = userEmail!.toLowerCase().contains('traveler') ? 'assets/images/man.jpeg' : 'assets/images/man2.jpeg';
      await save();
      await BookingsData.syncFromApi();
      return true;
    }
    return false;
  }

  /// Passwordless sign-in (web parity: `LoginOtpController@verify`
  /// returns the same `{access_token, user}` shape as password login).
  static Future<bool> loginWithOtp(String contact, String code) async {
    final data = await ApiService.verifyLoginOtp(contact, code);
    if (data != null) {
      final user = data['user'];
      isLoggedIn = true;
      if (user is Map) {
        userName = user['name']?.toString() ?? contact;
        userEmail = user['email']?.toString() ?? contact;
        userPhone = user['phone_number']?.toString() ?? '';
        userId = user['id'] is int
            ? user['id'] as int
            : int.tryParse(user['id']?.toString() ?? '');
        userRole = _normalizeRole(user['role'], 'customer');
      } else {
        userName = contact;
        userEmail = contact;
        userRole = 'customer';
      }
      userAvatar = (userEmail ?? '').toLowerCase().contains('traveler')
          ? 'assets/images/man.jpeg'
          : 'assets/images/man2.jpeg';
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
      userRole = _normalizeRole(user['role'], _normalizeRole(role, 'guest'));
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
    userRole = 'guest';
    avatarBg = null;
    avatarFg = null;
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
    userRole = 'guest';
    avatarBg = null;
    avatarFg = null;
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
    if (destination.id != null) {
      return list.any((item) => item.id == destination.id);
    }
    return list.any((item) => item.name == destination.name);
  }

  static void toggle(Destination destination) {
    if (contains(destination)) {
      if (destination.id != null) {
        list.removeWhere((item) => item.id == destination.id);
      } else {
        list.removeWhere((item) => item.name == destination.name);
      }
    } else {
      list.add(destination);
    }
    save();
  }

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wishlist_json', jsonEncode(list.map((d) => d.toJson()).toList()));
      await prefs.remove('wishlist_names');
    } catch (e) {
      // Ignore
    }
  }
}

class BookingsData {
  /// Live bookings from the backend (`GET /bookings`) — same rows as web
  /// `/my-booking`. Starts empty; never fake entries (web rule).
  static final List<Map<String, dynamic>> list = [];

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bookings_data', jsonEncode(list));
    } catch (e) {
      // Ignore
    }
  }

  /// Syncs the live booking list from the backend — same rows as web
  /// `/my-booking`. Uses the real `booking_code` + `status`; never invents
  /// codes (previous `TZ-id-DAR` scheme) or statuses.
  /// Last successful sync moment (persisted). Null = never synced.
  static DateTime? lastSyncedAt;

  static Future<void> _persistSyncedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (lastSyncedAt != null) {
        await prefs.setString(
            'bookings_synced_at', lastSyncedAt!.toIso8601String());
      } else {
        await prefs.remove('bookings_synced_at');
      }
    } catch (_) {}
  }

  /// Returns true only when the backend round-trip actually succeeded, so
  /// callers can distinguish "no bookings" from "offline".
  static Future<bool> syncFromApi() async {
    if (!UserSession.isLoggedIn) return false;
    try {
      final apiBookings = await ApiService.fetchBookings();
      if (ApiService.lastError != null) return false;
      list.clear();
      for (var b in apiBookings) {
        if (b is! Map) continue;
        final m = Map<String, dynamic>.from(b);
        final room = m['room'] is Map ? Map<String, dynamic>.from(m['room']) : <String, dynamic>{};
        final property = room['property'] is Map
            ? Map<String, dynamic>.from(room['property'])
            : (m['property'] is Map ? Map<String, dynamic>.from(m['property']) : <String, dynamic>{});
        final checkInStr = (m['check_in'] ?? '').toString();
        final checkOutStr = (m['check_out'] ?? '').toString();

        // Format date range nicely
        String datesText = '$checkInStr – $checkOutStr';
        try {
          final checkInDate = DateTime.parse(checkInStr);
          final checkOutDate = DateTime.parse(checkOutStr);
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          datesText = '${months[checkInDate.month - 1]} ${checkInDate.day} – ${checkOutDate.day}, ${checkInDate.year}';
        } catch (_) {}

        final checkInDate = DateTime.tryParse(checkInStr) ?? DateTime.now();
        final checkOutDate = DateTime.tryParse(checkOutStr) ?? DateTime.now();
        final nights = checkOutDate.difference(checkInDate).inDays;

        final rawStatus = (m['status'] ?? '').toString();
        final payStatus = (m['payment_status'] ?? '').toString().toLowerCase();
        String status;
        switch (rawStatus.toLowerCase()) {
          case 'completed':
            status = 'Completed';
            break;
          case 'checked in':
          case 'checked_in':
            status = 'Checked In';
            break;
          case 'cancelled':
          case 'canceled':
            status = 'Cancelled';
            break;
          case 'confirmed':
            status = 'Confirmed';
            break;
          default:
            status = payStatus == 'paid'
                ? 'Confirmed'
                : (payStatus == 'refunded' ? 'Cancelled' : (rawStatus.isNotEmpty ? rawStatus : 'Pending'));
        }

        final img = property['primary_image_url'] ?? property['image_url'];
        list.add({
          'id': m['id'],
          'propertyId': property['id'],
          'name': property['name'] ?? 'Lodge Stay',
          'city': property['city'] ?? 'Dar es Salaam',
          'area': property['area'] ?? 'Mikocheni',
          'dates': datesText,
          'nights': nights > 0 ? nights : 1,
          'price': (double.tryParse(m['total_price']?.toString() ?? '0') ?? 0).toInt(),
          'code': (m['booking_code'] ?? m['code'] ?? '').toString(),
          'verify_url': (m['verify_url'] ?? '').toString(),
          'check_in': checkInStr,
          'check_out': checkOutStr,
          'imageUrl': (img is String && img.isNotEmpty) ? img : 'assets/images/house3.webp',
          'status': status,
          'payment_status': m['payment_status'],
          'roomNumber': room['room_number'] ?? '101',
        });
      }
      await save();
      lastSyncedAt = DateTime.now();
      await _persistSyncedAt();
      return true;
    } catch (e) {
      debugPrint('Error syncing bookings from API: $e');
      return false;
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

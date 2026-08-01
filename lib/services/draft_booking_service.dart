import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves an unfinished booking draft to/from local storage.
/// On app relaunch, the draft is loaded and the user can resume checkout.
class DraftBookingService {
  static const String _key = 'fastnet_draft_booking';

  static Future<void> save({
    required Map<String, dynamic> destinationJson,
    required String selectedDatesText,
    required int numNights,
    required String selectedRoomNumber,
    required int selectedRoomId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'destination': destinationJson,
      'selectedDatesText': selectedDatesText,
      'numNights': numNights,
      'selectedRoomNumber': selectedRoomNumber,
      'selectedRoomId': selectedRoomId,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_key, jsonEncode(draft));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Drafts expire after 24 hours to avoid stale holds.
  static bool isExpired(Map<String, dynamic> draft) {
    try {
      final savedAt = DateTime.parse(draft['savedAt'] as String);
      return DateTime.now().difference(savedAt).inHours >= 24;
    } catch (_) {
      return true;
    }
  }
}

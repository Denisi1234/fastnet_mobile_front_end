import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';

/// Sync state for the My Bookings tab — drives loading / error / offline
/// UI instead of leaving screens to guess.
enum BookingsSyncStatus { idle, loading, success, error }

/// Single mutation point for bookings: every change persists the cache
/// and notifies listeners (previously screens mutated
/// `BookingsData.list` directly, so the tab only refreshed by accident).
class BookingsProvider extends ChangeNotifier {
  BookingsSyncStatus status = BookingsSyncStatus.idle;
  String? errorMessage;

  List<Map<String, dynamic>> get bookings => BookingsData.list;
  DateTime? get lastSyncedAt => BookingsData.lastSyncedAt;

  /// Backend round-trip. Returns true only on real success; on failure the
  /// persisted cache is left untouched for the offline banner.
  Future<bool> refresh() async {
    status = BookingsSyncStatus.loading;
    errorMessage = null;
    notifyListeners();
    final ok = await BookingsData.syncFromApi();
    if (ok) {
      status = BookingsSyncStatus.success;
    } else {
      status = BookingsSyncStatus.error;
      errorMessage =
          ApiService.lastError ?? 'Could not refresh bookings.';
    }
    notifyListeners();
    return ok;
  }

  void addBooking(Map<String, dynamic> booking) {
    BookingsData.list.add(booking);
    BookingsData.save();
    notifyListeners();
  }

  void updateStatus(int index, String status) {
    if (index >= 0 && index < BookingsData.list.length) {
      BookingsData.list[index]['status'] = status;
      BookingsData.save();
      notifyListeners();
    }
  }

  /// Server-side cancellation (`DELETE /bookings/{id}`): on success the
  /// row is marked Cancelled locally (next refresh replaces it with server
  /// truth, mirroring web `/my-booking`). Returns true on success.
  Future<bool> cancelOnServer({int? id, String? code}) async {
    int? targetId = id;
    if (targetId == null) return false;
    final ok = await ApiService.cancelBooking(targetId);
    if (!ok) return false;
    final idx = BookingsData.list.indexWhere((b) {
      if (b['id'] == targetId) return true;
      return code != null &&
          code.isNotEmpty &&
          b['code']?.toString() == code;
    });
    if (idx >= 0) {
      BookingsData.list[idx]['status'] = 'Cancelled';
      await BookingsData.save();
      notifyListeners();
    }
    return true;
  }
}

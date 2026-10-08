import 'package:flutter/foundation.dart';

/// Retired parallel backend.
///
/// The Laravel API is the single source of truth (same as web). This stub
/// keeps old imports compiling while every flow uses [ApiService]
/// (`POST /bookings/create`, `POST /receipts/generate`). It performs no I/O.
class SupabaseService {
  static bool get isInitialized => false;

  static Future<void> init() async {
    debugPrint('SupabaseService retired: using Laravel backend only.');
  }

  static dynamic get client => null;

  static Future<bool> createBookingRecord(Map<String, dynamic> _) async => false;

  static Future<bool> triggerConfirmationEmail({
    required String userEmail,
    required String guestName,
    required String guestPhone,
    required String bookingCode,
    required String lodgeName,
    required String roomNumber,
    required String location,
    required String dates,
    required int numNights,
    required int pricePerNight,
    required String paymentMethod,
    String? paymentTime,
    required int amount,
    String? receiptUrl,
  }) async {
    debugPrint('SupabaseService retired: confirmation goes via POST /receipts/generate.');
    return false;
  }

  static Future<String?> uploadReceiptPdf(String _, Uint8List __) async => null;

  static Stream<List<Map<String, dynamic>>>? listenToBookingStatus(String _) => null;
}

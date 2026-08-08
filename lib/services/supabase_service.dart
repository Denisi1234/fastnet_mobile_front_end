import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fastnet_mobile_front_end/config/constants.dart';

/// Service class orchestrating all real-time database, storage, and authentication
/// operations with Supabase.
class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Safely initializes Supabase client at application startup.
  static Future<void> init() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        debugPrint('Supabase Notice: Using placeholder Supabase credentials. Configure SUPABASE_URL and SUPABASE_ANON_KEY for production.');
        return;
      }

      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('Supabase initialized successfully!');
    } catch (e) {
      debugPrint('Supabase Initialization Warning: $e');
    }
  }

  /// Returns the global Supabase client instance if initialized.
  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Saves a newly confirmed booking directly to Supabase `bookings` table.
  static Future<bool> createBookingRecord(Map<String, dynamic> bookingData) async {
    final sb = client;
    if (sb == null) return false;

    try {
      await sb.from('bookings').insert(bookingData);
      debugPrint('Supabase: Booking record created successfully!');
      return true;
    } catch (e) {
      debugPrint('Supabase Create Booking Error: $e');
      return false;
    }
  }

  /// Triggers a Supabase Edge Function to dispatch the real-time confirmation email & PDF.
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
    final sb = client;
    if (sb == null) return false;

    try {
      final response = await sb.functions.invoke(
        'send-receipt-email',
        body: {
          'email': userEmail,
          'guest_name': guestName,
          'guest_phone': guestPhone,
          'booking_code': bookingCode,
          'lodge_name': lodgeName,
          'room_number': roomNumber,
          'location': location,
          'dates': dates,
          'num_nights': numNights,
          'price_per_night': pricePerNight,
          'payment_method': paymentMethod,
          'payment_time': paymentTime,
          'amount': amount,
          'receipt_url': receiptUrl,
          'sent_at': DateTime.now().toIso8601String(),
        },
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Supabase Edge Function Email Error: $e');
      return false;
    }
  }

  /// Uploads a generated e-receipt PDF file to Supabase Storage bucket `receipts`.
  static Future<String?> uploadReceiptPdf(String bookingCode, Uint8List pdfBytes) async {
    final sb = client;
    if (sb == null) return null;

    try {
      final fileName = 'receipts/$bookingCode.pdf';
      await sb.storage.from('receipts').uploadBinary(
        fileName,
        pdfBytes,
        fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
      );
      final publicUrl = sb.storage.from('receipts').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Upload Receipt Error: $e');
      return null;
    }
  }

  /// Listens to real-time status changes for a specific booking code.
  static Stream<List<Map<String, dynamic>>>? listenToBookingStatus(String bookingCode) {
    final sb = client;
    if (sb == null) return null;

    return sb
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('booking_code', bookingCode);
  }
}

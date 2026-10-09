import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Single backend source of truth — same URL the web app uses via
  /// `BACKEND_API_URL` (see web/src/Service/FastnetApiClient.php,
  /// web/config/app.php `backendApiUrl`).
  ///
  /// Resolution order:
  ///   1. `--dart-define=BACKEND_API_URL=https://api.fastnetstays.com/api`
  ///      (production + physical devices — REQUIRED, no default can reach
  ///      your LAN from a phone).
  ///   2. `--dart-define=IS_PRODUCTION=true` → production URL.
  ///   3. Local dev: Android emulator → 10.0.2.2, iOS simulator/web → localhost.
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('BACKEND_API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl; // --dart-define=BACKEND_API_URL=https://api.fastnetstays.com/api
    const String productionUrl = 'https://api.fastnetstays.com/api';
    const String devUrl = 'http://10.0.2.2:8000/api';
    const String devUrliOS = 'http://localhost:8000/api';
    const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
    if (isProduction) return productionUrl;
    if (!kIsWeb && Platform.isAndroid) return devUrl;
    return devUrliOS;
  }

  static String? _token;

  /// Human-readable message from the last failed call (login/register/etc).
  /// Screens can display this instead of a generic "try again".
  static String? lastError;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('api_token');
    } catch (e) {
      debugPrint('SharedPreferences init error: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', token);
    } catch (e) {
      debugPrint('SharedPreferences saveToken error: $e');
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_token');
    } catch (e) {
      debugPrint('SharedPreferences clearToken error: $e');
    }
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static const Duration _timeout = Duration(seconds: 15);

  /// Laravel paginators return `{data: [...], current_page, total}` while
  /// some endpoints return a raw list. Unwrap both (+ `{items: [...]}`).
  static List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
      final items = decoded['items'];
      if (items is List) return items;
    }
    return [];
  }

  static String _errorMessage(int status, dynamic decoded, String fallback) {
    try {
      if (decoded is Map) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return '$fallback (HTTP $status)';
  }

  // ---------------------------------------------------------
  // AUTHENTICATION METHODS
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token is String) await saveToken(token);
        return Map<String, dynamic>.from(data);
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Invalid credentials');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl. Is Laravel running? ($e)';
      debugPrint('API Login Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone_number': phone,
          'role': role,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token is String) await saveToken(token);
        return Map<String, dynamic>.from(data);
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Registration failed');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl. Is Laravel running? ($e)';
      debugPrint('API Register Error: $e');
    }
    return null;
  }

  static Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: _headers,
      ).timeout(_timeout);
      await clearToken();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Logout Error: $e');
      await clearToken();
    }
    return true;
  }

  // ---------------------------------------------------------
  // PROPERTY METHODS
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchProperties({String? city, double? priceMax}) async {
    try {
      String url = '$baseUrl/properties?limit=50';
      List<String> queryParams = [];
      if (city != null && city.isNotEmpty) queryParams.add('city=${Uri.encodeComponent(city)}');
      if (priceMax != null) queryParams.add('price_max=$priceMax');
      if (queryParams.isNotEmpty) {
        url += '&${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body));
      }
      debugPrint('API Fetch Properties HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('API Fetch Properties Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: _headers,
        body: jsonEncode(propertyData),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Create Property Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // BOOKINGS METHODS
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchBookings() async {
    lastError = null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings?per_page=50'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body));
      }
      lastError = _errorMessage(
          response.statusCode, jsonDecode(response.body), 'Could not load bookings');
      debugPrint('API Fetch Bookings HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Fetch Bookings Error: $e');
    }
    return [];
  }

  /// Single booking with relations (`room.property.host`, guest, payments).
  /// Used to resolve the host contact for guest messaging. Returns null on
  /// any failure; callers keep working with the cached list row instead.
  static Future<Map<String, dynamic>?> fetchBookingDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$id'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final map = body is Map<String, dynamic>
            ? body
            : (body is Map ? Map<String, dynamic>.from(body) : null);
        final data = map?['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
        return map;
      }
      debugPrint('API Fetch Booking Detail HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('API Fetch Booking Detail Error: $e');
    }
    return null;
  }

  /// Backend `BookingController@store` requires room_id + dates and accepts
  /// guest/payment extras (used for guest checkout + host notes). Returns the
  /// full creation payload: `{booking, booking_code, total_price, ...}`.
  static Future<Map<String, dynamic>?> createBooking(
    int roomId,
    String checkIn,
    String checkOut, {
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? paymentMethod,
    String? paymentPhone,
    String? specialRequests,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create'),
        headers: _headers,
        body: jsonEncode({
          'room_id': roomId,
          'check_in': checkIn,
          'check_out': checkOut,
          if (guestName != null) 'guest_name': guestName,
          if (guestEmail != null) 'guest_email': guestEmail,
          if (guestPhone != null) 'guest_phone': guestPhone,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (paymentPhone != null) 'payment_phone': paymentPhone,
          if (specialRequests != null) 'special_requests': specialRequests,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Booking failed');
      debugPrint('API Create Booking HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Create Booking Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> lockRoom(int roomId, String checkIn, String checkOut) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/lock'),
        headers: _headers,
        body: jsonEncode({
          'room_id': roomId,
          'check_in': checkIn,
          'check_out': checkOut,
        }),
      ).timeout(_timeout);
      return {
        'status': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint('API Lock Room Error: $e');
    }
    return null;
  }

  static Future<bool> unlockRoom(int roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/unlock'),
        headers: _headers,
        body: jsonEncode({
          'room_id': roomId,
        }),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Unlock Room Error: $e');
    }
    return false;
  }

  // ---------------------------------------------------------
  // PAYMENT METHODS
  // ---------------------------------------------------------

  /// Matches backend `PaymentController@checkout` (+ `web/PaymentService.php`):
  /// booking_id or booking_code + provider + mobile-money number. Web rejects
  /// card here — same rule.
  static Future<Map<String, dynamic>?> checkoutPayment(
    int bookingId,
    String gateway, {
    String? bookingCode,
    String? phoneNumber,
  }) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/checkout'),
        headers: _headers,
        body: jsonEncode({
          if (bookingId > 0) 'booking_id': bookingId,
          if (bookingCode != null) 'booking_code': bookingCode,
          'gateway': gateway,
          'payment_method': gateway,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Payment failed');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Checkout Payment Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> paymentStatus(String codeOrId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/status/${Uri.encodeComponent(codeOrId)}'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        if (d is Map<String, dynamic>) return d;
        if (d is Map) return Map<String, dynamic>.from(d);
      }
    } catch (e) {
      debugPrint('API Payment Status Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // PROPERTY DETAIL / QUOTE (web parity: StaysDetailTrait + QuoteTrait)
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>?> getProperty(int id, {Map<String, String>? context}) async {
    try {
      var url = '$baseUrl/properties/$id';
      if (context != null && context.isNotEmpty) {
        url += '?${context.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        if (d is Map<String, dynamic>) return d['data'] is Map ? Map<String, dynamic>.from(d['data']) : d;
        if (d is Map) return Map<String, dynamic>.from(d);
      }
    } catch (e) {
      debugPrint('API Get Property Error: $e');
    }
    return null;
  }

  static Future<List<dynamic>> fetchRooms(int propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$propertyId/rooms'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
    } catch (e) {
      debugPrint('API Fetch Rooms Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> calculateBooking({
    required int propertyId,
    int? roomId,
    required String checkIn,
    required String checkOut,
    int guests = 2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/calculate'),
        headers: _headers,
        body: jsonEncode({
          'property_id': propertyId,
          if (roomId != null) 'room_id': roomId,
          'check_in': checkIn,
          'check_out': checkOut,
          'guests': guests,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Price calculation failed');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Calculate Error: $e');
    }
    return null;
  }

  static Future<List<dynamic>> fetchReviews(int propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$propertyId/reviews'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
    } catch (e) {
      debugPrint('API Fetch Reviews Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> me() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/me'), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        if (d is Map<String, dynamic>) return d;
        if (d is Map) return Map<String, dynamic>.from(d);
      }
    } catch (e) {
      debugPrint('API Me Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // MESSAGING METHODS
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchMessageThreads() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/threads'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Fetch Message Threads Error: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchMessages(int partnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$partnerId'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Fetch Messages Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> sendMessage({
    required int recipientId,
    required String lodgeName,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'recipient_id': recipientId,
          'lodge_name': lodgeName,
          'text': text,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Send Message Error: $e');
    }
    return null;
  }

  static Future<String?> uploadImage(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      }
    } catch (e) {
      debugPrint('API Upload Image Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // SUPPORT TICKETS METHODS
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Fetch Tickets Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createTicket({
    required String issue,
    required String description,
    required String initialMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: _headers,
        body: jsonEncode({
          'issue': issue,
          'description': description,
          'initial_message': initialMessage,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Create Ticket Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> sendTicketMessage(int ticketId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets/$ticketId/messages'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Send Ticket Message Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateTicketStatus(int ticketId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Update Ticket Status Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // STAFF MANAGEMENT METHODS
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('API Fetch Staff Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addStaff({
    required String name,
    required String role,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'role': role,
          'phone': phone,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Add Staff Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateStaff(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/staff/$id'),
        headers: _headers,
        body: jsonEncode(updates),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Update Staff Error: $e');
    }
    return null;
  }

  static Future<bool> deleteStaff(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/staff/$id'),
        headers: _headers,
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Delete Staff Error: $e');
    }
    return false;
  }

  // ---------------------------------------------------------
  // LODGE SERVICE REQUESTS METHODS
  // ---------------------------------------------------------



  static Future<Map<String, dynamic>?> createLodgeRequest({
    required String roomNumber,
    required String type,
    required Map<String, dynamic> details,
    required double price,
    String? status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lodge-requests'),
        headers: _headers,
        body: jsonEncode({
          'room_number': roomNumber,
          'type': type,
          'details': details,
          'price': price,
          if (status != null) 'status': status,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Create Lodge Request Error: $e');
    }
    return null;
  }



  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: _headers,
      ).timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('API Cancel Booking Error: $e');
    }
    return false;
  }

  /// Live reprice quote for moving a booking to new dates
  /// (`POST /bookings/{id}/reschedule/quote`). Returns the quote map on
  /// success (including `valid:false` + message when unavailable), or null
  /// on transport failure with [lastError] set.
  static Future<Map<String, dynamic>?> rescheduleQuote(
      int id, String checkIn, String checkOut) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$id/reschedule/quote'),
        headers: _headers,
        body: jsonEncode({'check_in': checkIn, 'check_out': checkOut}),
      ).timeout(_timeout);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        lastError = null;
        return body is Map<String, dynamic>
            ? body
            : Map<String, dynamic>.from(body as Map);
      }
      lastError = _errorMessage(
          response.statusCode, body, 'Could not price the new dates.');
      debugPrint(
          'API Reschedule Quote HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Reschedule Quote Error: $e');
    }
    return null;
  }

  /// Applies a quoted date move (`POST /bookings/{id}/reschedule`).
  /// Returns the result map (`booking`, `balance_due`, `message`) or null
  /// on transport failure with [lastError] set.
  static Future<Map<String, dynamic>?> rescheduleApply(
      int id, String checkIn, String checkOut) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$id/reschedule'),
        headers: _headers,
        body: jsonEncode({'check_in': checkIn, 'check_out': checkOut}),
      ).timeout(_timeout);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        lastError = null;
        return body is Map<String, dynamic>
            ? body
            : Map<String, dynamic>.from(body as Map);
      }
      lastError = _errorMessage(
          response.statusCode, body, 'Could not move the booking.');
      debugPrint(
          'API Reschedule Apply HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Reschedule Apply Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Forgot Password Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> resetPassword(String email, String token, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: _headers,
        body: jsonEncode({'email': email, 'token': token, 'password': password, 'password_confirmation': password}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Password reset failed');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Reset Password Error: $e');
    }
    return null;
  }

  /// Web parity (`LoginOtpController`): verifies a password-reset code
  /// (`POST /verify-otp {email, token}`) before allowing a new password.
  static Future<Map<String, dynamic>?> verifyResetOtp(String email, String token) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: _headers,
        body: jsonEncode({'email': email, 'token': token}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      lastError = _errorMessage(response.statusCode, jsonDecode(response.body), 'Invalid verification code.');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Verify Reset OTP Error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------
  // PASSWORDLESS SIGN-IN (web parity: LoginOtpController)
  // ---------------------------------------------------------

  /// POST /login/otp/request {contact} — always 200 when the contact is
  /// valid (never an existence oracle). Returns the decoded body.
  static Future<Map<String, dynamic>?> requestLoginOtp(String contact) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/otp/request'),
        headers: _headers,
        body: jsonEncode({'contact': contact}),
      ).timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        return Map<String, dynamic>.from(decoded);
      }
      lastError = _errorMessage(
          response.statusCode,
          decoded,
          'We could not send a code. Please try again.');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Request Login OTP Error: $e');
    }
    return null;
  }

  /// POST /login/otp/resend — same work as request, honest button label.
  static Future<Map<String, dynamic>?> resendLoginOtp(String contact) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/otp/resend'),
        headers: _headers,
        body: jsonEncode({'contact': contact}),
      ).timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        return Map<String, dynamic>.from(decoded);
      }
      lastError = _errorMessage(
          response.statusCode,
          decoded,
          'We could not send a code. Please try again.');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Resend Login OTP Error: $e');
    }
    return null;
  }

  /// POST /login/otp/verify {contact, code} — exchanges a correct code for
  /// a real access token (mirrors `login()`: token is stored).
  static Future<Map<String, dynamic>?> verifyLoginOtp(String contact, String code) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/otp/verify'),
        headers: _headers,
        body: jsonEncode({'contact': contact, 'code': code}),
      ).timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        final data = Map<String, dynamic>.from(decoded);
        final token = data['access_token'] ?? data['token'];
        if (token is String) await saveToken(token);
        return data;
      }
      lastError = _errorMessage(
          response.statusCode,
          decoded,
          'That code is not correct. Please try again.');
    } catch (e) {
      lastError = 'Cannot reach backend at $baseUrl ($e)';
      debugPrint('API Verify Login OTP Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> submitReview({
    required int propertyId,
    int? bookingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: _headers,
        body: jsonEncode({
          'property_id': propertyId,
          if (bookingId != null) 'booking_id': bookingId,
          'rating': rating,
          'comment': comment,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Submit Review Error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchLodgeRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lodge-requests'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return _unwrapList(jsonDecode(response.body)).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('API Fetch Lodge Requests Error: $e');
    }
    return [];
  }

  /// Backend route is PATCH /lodge-requests/{id}/status (routes/api.php).
  static Future<bool> updateLodgeRequestStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/lodge-requests/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Update Lodge Request Status Error: $e');
    }
    return false;
  }

  // ---------------------------------------------------------
  // PROFILE UPDATE METHODS
  // ---------------------------------------------------------

  /// Updates the authenticated user's profile details on the backend.
  static Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? dateOfBirth,
    String? gender,
    String? bio,
    String? address,
    String? emergencyContact,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'phone_number': phone,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (bio != null) 'bio': bio,
        if (address != null) 'address': address,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
      };
      final response = await http.patch(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Update Profile Error: $e');
    }
    return false;
  }

  /// E-receipt via the real backend endpoint `POST /receipts/generate`
  /// (BookingController@generateReceipt — shared with web `/booking-receipt`).
  /// There is no `/bookings/{code}/send-confirmation-email` route.
  static Future<Map<String, dynamic>?> generateReceipt({
    required String bookingCode,
    String? guestName,
    String? propertyName,
    String? propertyAddress,
    String? checkIn,
    String? checkOut,
    dynamic totalPrice,
    String? pdfBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/generate'),
        headers: _headers,
        body: jsonEncode({
          'booking_code': bookingCode,
          if (guestName != null) 'guest_name': guestName,
          if (propertyName != null) 'property_name': propertyName,
          if (propertyAddress != null) 'property_address': propertyAddress,
          if (checkIn != null) 'check_in': checkIn,
          if (checkOut != null) 'check_out': checkOut,
          if (totalPrice != null) 'total_price': totalPrice,
          if (pdfBase64 != null) 'pdf_base64': pdfBase64,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Generate Receipt Error: $e');
    }
    return null;
  }

  /// Kept for old call sites: now delegates to the real receipts endpoint.
  static Future<bool> sendConfirmationEmail({
    required String email,
    required String bookingCode,
    required String lodgeName,
    required int amount,
  }) async {
    final res = await generateReceipt(
      bookingCode: bookingCode,
      guestName: email,
      propertyName: lodgeName,
      totalPrice: amount,
    );
    return res != null;
  }

  /// Uploads a profile photo from the device and returns the remote URL.
  static Future<String?> uploadProfilePhoto(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile/photo'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('API Upload Profile Photo Error: $e');
    }
    return null;
  }
  /// Backend returns `{status, notifications:[...], unread_count}`
  /// (NotificationController) — not a raw list.
  static Future<List<dynamic>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?limit=30'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['notifications'] is List) {
          return decoded['notifications'] as List<dynamic>;
        }
        return _unwrapList(decoded);
      }
    } catch (e) {
      debugPrint('API Fetch Notifications Error: $e');
    }
    return [];
  }

  static Future<int> fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        if (d is Map && d['unread_count'] is int) return d['unread_count'] as int;
      }
    } catch (e) {
      debugPrint('API Unread Count Error: $e');
    }
    return 0;
  }

  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: _headers,
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Mark Notification Read Error: $e');
    }
    return false;
  }

  // ---------------------------------------------------------
  // WISHLIST (web parity: /my-wishlists + /wishlist-lists)
  // ---------------------------------------------------------

  static Future<List<dynamic>> fetchWishlist() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wishlist'), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
    } catch (e) {
      debugPrint('API Fetch Wishlist Error: $e');
    }
    return [];
  }

  static Future<bool> addWishlist(int propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist'),
        headers: _headers,
        body: jsonEncode({'property_id': propertyId}),
      ).timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('API Add Wishlist Error: $e');
    }
    return false;
  }

  static Future<bool> removeWishlist(int propertyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/$propertyId'),
        headers: _headers,
      ).timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('API Remove Wishlist Error: $e');
    }
    return false;
  }

  static Future<List<dynamic>> fetchWishlistLists() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wishlist-lists'), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
    } catch (e) {
      debugPrint('API Fetch Wishlist Lists Error: $e');
    }
    return [];
  }
}

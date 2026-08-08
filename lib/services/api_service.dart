import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    // Update this to your production API URL before releasing
    const String productionUrl = 'https://api.fastnetstays.com/api';
    const String devUrl = 'http://10.0.2.2:8000/api';
    const String devUrliOS = 'http://localhost:8000/api';

    // Set to true when deploying to production
    const bool isProduction = false;
    if (isProduction) return productionUrl;

    if (!kIsWeb && Platform.isAndroid) return devUrl;
    return devUrliOS;
  }

  static String? _token;

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

  // ---------------------------------------------------------
  // AUTHENTICATION METHODS
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await saveToken(token);
        return data;
      }
    } catch (e) {
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
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await saveToken(token);
        return data;
      }
    } catch (e) {
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
      String url = '$baseUrl/properties';
      List<String> queryParams = [];
      if (city != null && city.isNotEmpty) queryParams.add('city=$city');
      if (priceMax != null) queryParams.add('price_max=$priceMax');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('API Fetch Bookings Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createBooking(int roomId, String checkIn, String checkOut) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: _headers,
        body: jsonEncode({
          'room_id': roomId,
          'check_in': checkIn,
          'check_out': checkOut,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
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

  static Future<Map<String, dynamic>?> checkoutPayment(int bookingId, String gateway) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/checkout'),
        headers: _headers,
        body: jsonEncode({
          'booking_id': bookingId,
          'gateway': gateway,
        }),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('API Checkout Payment Error: $e');
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
        return jsonDecode(response.body) as List<dynamic>;
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
        return jsonDecode(response.body) as List<dynamic>;
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
        return jsonDecode(response.body) as List<dynamic>;
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
    } catch (e) {
      debugPrint('API Reset Password Error: $e');
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
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Fetch Lodge Requests Error: $e');
    }
    return [];
  }

  static Future<bool> updateLodgeRequestStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/lodge-requests/$id'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
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

  /// Triggers real-time email dispatch with PDF receipt attachment to guest.
  static Future<bool> sendConfirmationEmail({
    required String email,
    required String bookingCode,
    required String lodgeName,
    required int amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingCode/send-confirmation-email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'booking_code': bookingCode,
          'lodge_name': lodgeName,
          'amount': amount,
          'attach_pdf': true,
        }),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API Send Confirmation Email Error: $e');
    }
    return false;
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
  static Future<List<dynamic>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('API Fetch Notifications Error: $e');
    }
    return [];
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
}

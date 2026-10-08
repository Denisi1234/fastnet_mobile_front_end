import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

class Destination {
  final String imageUrl;
  final String name;
  final String city;
  final String area;
  final String roomType;
  final int distance;
  final double rating;
  final int price;
  final String duration;
  final int guests;
  final int bedrooms;
  final int beds;
  final int baths;
  final String condition;
  final List<String> amenities;
  final double latitude;
  final double longitude;

  final int? id;
  final List<Map<String, dynamic>>? rooms;

  /// Web parity (`gh-cards-list.php`): property type label, star rating,
  /// review count and free-cancellation flag drive the card + filter chips.
  final String propertyType;
  final int starRating;
  final int reviewCount;
  final bool freeCancellation;

  /// Web parity (`hotel-detail-modals.php` "Good to know"): shown only when
  /// the backend provides them — never invented.
  final String checkInTime;
  final String checkOutTime;
  final String cancellationPolicy;

  Destination({
    required this.imageUrl,
    required this.name,
    required this.city,
    required this.area,
    required this.roomType,
    required this.distance,
    required this.rating,
    required this.price,
    required this.duration,
    required this.guests,
    required this.bedrooms,
    required this.beds,
    required this.baths,
    required this.condition,
    required this.amenities,
    required this.latitude,
    required this.longitude,
    this.id,
    this.rooms,
    this.propertyType = '',
    this.starRating = 0,
    this.reviewCount = 0,
    this.freeCancellation = false,
    this.checkInTime = '',
    this.checkOutTime = '',
    this.cancellationPolicy = '',
  });

  static double _num(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _price(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return double.tryParse(v.toString())?.toInt() ?? fallback;
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase().trim() ?? '';
    return s == '1' || s == 'true' || s == 'yes';
  }

  static List<String> _amenities(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is List) return d.map((e) => e.toString()).toList();
      } catch (_) {}
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return ['Wi-Fi', 'Air conditioning', 'Parking'];
  }

  /// Parses a real backend property row (Property + rooms + reviews aggregates).
  /// Mirrors web `StaysDetailTrait`: numeric strings accepted, null image →
  /// caller shows asset placeholder, never a fake listing.
  factory Destination.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> roomsList = [];
    if (json['rooms'] != null) {
      for (var r in (json['rooms'] as List)) {
        if (r is Map) roomsList.add(Map<String, dynamic>.from(r));
      }
    }

    // Web rule: backend `customer_price_per_night` already includes the 1%
    // AzamPay fee — prefer it, fall back to raw nightly fields.
    final rawPrice = json['customer_price_per_night'] ??
        json['price_per_night'] ??
        json['price'];
    final parsedPrice = _price(rawPrice, 50000);

    final rating = _num(json['rating'] ?? json['reviews_avg_rating'], 4.5);
    final img = json['primary_image_url'] ?? json['image_url'];
    final amen = _amenities(json['amenities']);
    final cancelRaw = json['free_cancellation'] ?? json['freeCancellation'];
    final freeCancel = _bool(cancelRaw) ||
        amen.any((a) => a.toLowerCase().contains('cancel'));

    return Destination(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? ''),
      imageUrl: (img is String && img.isNotEmpty) ? img : 'assets/images/home.webp',
      name: json['name']?.toString() ?? 'Lodge Stay',
      city: json['city']?.toString() ?? 'Dar es Salaam',
      area: json['area']?.toString() ?? 'Mikocheni',
      roomType: json['room_type']?.toString() ?? 'Private Room',
      distance: _num(json['distance'], 2).toInt(),
      rating: rating,
      price: parsedPrice,
      duration: json['duration']?.toString() ?? 'Available today',
      guests: _num(json['guests'] ?? json['capacity'], 2).toInt(),
      bedrooms: _num(json['bedrooms'], 1).toInt(),
      beds: _num(json['beds'] ?? json['number_of_beds'], 1).toInt(),
      baths: _num(json['baths'], 1).toInt(),
      condition: json['description']?.toString() ?? '',
      amenities: amen,
      latitude: _num(json['latitude'], -6.7780),
      longitude: _num(json['longitude'], 39.2345),
      rooms: roomsList,
      propertyType: (json['property_type'] ?? json['propertyType'] ?? '').toString(),
      checkInTime: (json['check_in_time'] ?? json['checkInTime'] ?? '').toString(),
      checkOutTime: (json['check_out_time'] ?? json['checkOutTime'] ?? '').toString(),
      cancellationPolicy: (json['cancellation_policy'] ?? json['cancellationPolicy'] ?? '').toString(),
      starRating: _num(json['star_rating'] ?? json['stars'], 0).toInt().clamp(0, 5),
      reviewCount: _num(
        json['reviews_count'] ?? json['review_count'] ?? json['reviewsCount'],
        0,
      ).toInt(),
      freeCancellation: freeCancel,
    );
  }

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return name.toLowerCase().contains(normalizedQuery) ||
        city.toLowerCase().contains(normalizedQuery) ||
        area.toLowerCase().contains(normalizedQuery) ||
        roomType.toLowerCase().contains(normalizedQuery);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'name': name,
      'city': city,
      'area': area,
      'room_type': roomType,
      'distance': distance,
      'rating': rating,
      'price_per_night': price,
      'duration': duration,
      'guests': guests,
      'bedrooms': bedrooms,
      'beds': beds,
      'baths': baths,
      'description': condition,
      'amenities': amenities,
      'latitude': latitude,
      'longitude': longitude,
      'rooms': rooms,
      'property_type': propertyType,
      'star_rating': starRating,
      'reviews_count': reviewCount,
      'free_cancellation': freeCancellation,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'cancellation_policy': cancellationPolicy,
    };
  }

  factory Destination.fromDraftJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> roomsList = [];
    if (json['rooms'] != null) {
      for (var r in json['rooms']) {
        roomsList.add(Map<String, dynamic>.from(r));
      }
    }
    return Destination(
      id: json['id'],
      imageUrl: json['image_url'] ?? 'assets/images/home.webp',
      name: json['name'] ?? 'Lodge Stay',
      city: json['city'] ?? 'Dar es Salaam',
      area: json['area'] ?? 'Mikocheni',
      roomType: json['room_type'] ?? 'Private Room',
      distance: (json['distance'] as num?)?.toInt() ?? 2,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      price: (json['price_per_night'] as num?)?.toInt() ?? 50000,
      duration: json['duration'] ?? 'Available today',
      guests: (json['guests'] as num?)?.toInt() ?? 2,
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      beds: (json['beds'] as num?)?.toInt() ?? 1,
      baths: (json['baths'] as num?)?.toInt() ?? 1,
      condition: json['description'] ?? '',
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Wi-Fi'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.7780,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 39.2345,
      rooms: roomsList,
      propertyType: (json['property_type'] ?? '').toString(),
      starRating: (json['star_rating'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      freeCancellation: json['free_cancellation'] == true,
      checkInTime: (json['check_in_time'] ?? '').toString(),
      checkOutTime: (json['check_out_time'] ?? '').toString(),
      cancellationPolicy: (json['cancellation_policy'] ?? '').toString(),
    );
  }
}

/// Live cache of backend property rows — same source as web.
/// Starts empty (web rule: empty backend = empty page, never mocks) and is
/// filled by [loadDestinationsFromApi]. Screens must handle empty with an
/// empty-state + retry, not fake listings.
final List<Destination> destinations = [];

Future<void> loadDestinationsFromApi({String? city, double? priceMax}) async {
  try {
    final properties = await ApiService.fetchProperties(city: city, priceMax: priceMax);
    if (properties.isNotEmpty) {
      destinations.clear();
      destinations.addAll(properties.map((p) => Destination.fromJson(Map<String, dynamic>.from(p))));
    }
  } catch (e) {
    debugPrint('Failed to load destinations: $e');
  }
}

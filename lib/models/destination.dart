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
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> roomsList = [];
    if (json['rooms'] != null) {
      for (var r in json['rooms']) {
        roomsList.add(Map<String, dynamic>.from(r));
      }
    }

    final rawPrice = json['price_per_night'];
    int parsedPrice = 50000;
    if (rawPrice != null) {
      if (rawPrice is String) {
        parsedPrice = double.parse(rawPrice).toInt();
      } else if (rawPrice is num) {
        parsedPrice = rawPrice.toInt();
      }
    }

    return Destination(
      id: json['id'],
      imageUrl: json['image_url'] ?? 'assets/images/home.webp',
      name: json['name'] ?? 'Lodge Stay',
      city: json['city'] ?? 'Dar es Salaam',
      area: json['area'] ?? 'Mikocheni',
      roomType: 'Private Room',
      distance: 2,
      rating: 4.5,
      price: parsedPrice,
      duration: 'Available today',
      guests: 2,
      bedrooms: 1,
      beds: 1,
      baths: 1,
      condition: json['description'] ?? '',
      amenities: ['Wi-Fi', 'Air conditioning', 'Parking'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : -6.7780,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : 39.2345,
      rooms: roomsList,
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
    );
  }
}

final List<Destination> destinations = [
  Destination(
    imageUrl: 'assets/images/home.webp',
    name: 'Palm Garden Lodge',
    city: 'Dar es Salaam',
    area: 'Mikocheni',
    roomType: 'Deluxe private room',
    distance: 3,
    rating: 4.87,
    price: 85000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Clean private room with air conditioning and secure parking.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Breakfast', 'Parking'],
    latitude: -6.7780,
    longitude: 39.2345,
  ),
  Destination(
    imageUrl: 'assets/images/room.webp',
    name: 'Sabasaba Comfort Rooms',
    city: 'Dodoma',
    area: 'Sabasaba',
    roomType: 'Standard room',
    distance: 1,
    rating: 4.49,
    price: 45000,
    duration: 'Available this week',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Quiet room near transport, shops, and local food places.',
    amenities: ['Wi-Fi', 'Fan', 'Private bathroom', 'Reception'],
    latitude: -6.1664,
    longitude: 35.7443,
  ),
  Destination(
    imageUrl: 'assets/images/home2.webp',
    name: 'Mtumba Executive Stay',
    city: 'Dodoma',
    area: 'Mtumba',
    roomType: 'Executive room',
    distance: 2,
    rating: 4.57,
    price: 65000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Modern room close to government offices and main roads.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Workspace', 'Parking'],
    latitude: -6.2167,
    longitude: 35.8895,
  ),
  Destination(
    imageUrl: 'assets/images/house2.webp',
    name: 'Kisasa Family Lodge',
    city: 'Dodoma',
    area: 'Kisasa',
    roomType: 'Family room',
    distance: 4,
    rating: 4.03,
    price: 95000,
    duration: 'Available tomorrow',
    guests: 4,
    bedrooms: 2,
    beds: 2,
    baths: 1,
    condition: 'Spacious room for family stays with a calm compound.',
    amenities: ['Wi-Fi', 'Breakfast', 'Two beds', 'Parking'],
    latitude: -6.1552,
    longitude: 35.7924,
  ),
  Destination(
    imageUrl: 'assets/images/house3.webp',
    name: 'Kariakoo Budget Lodge',
    city: 'Dar es Salaam',
    area: 'Kariakoo',
    roomType: 'Budget room',
    distance: 1,
    rating: 4.35,
    price: 35000,
    duration: 'Few rooms left',
    guests: 1,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Simple affordable room close to the market and bus routes.',
    amenities: ['Fan', 'Private bathroom', 'Reception', 'Security'],
    latitude: -6.8182,
    longitude: 39.2783,
  ),
  Destination(
    imageUrl: 'assets/images/house4.webp',
    name: 'Njiro Garden Rooms',
    city: 'Arusha',
    area: 'Njiro',
    roomType: 'Garden room',
    distance: 5,
    rating: 4.90,
    price: 70000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Comfortable lodge room with garden space and mountain air.',
    amenities: ['Wi-Fi', 'Hot shower', 'Garden', 'Breakfast'],
    latitude: -3.4005,
    longitude: 36.7103,
  ),
  Destination(
    imageUrl: 'assets/images/home.webp',
    name: 'Zanzibar Sunset Beach Villa',
    city: 'Zanzibar',
    area: 'Nungwi',
    roomType: 'Oceanfront suite',
    distance: 45,
    rating: 4.92,
    price: 185000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Stunning luxury villa directly on the sands of Nungwi beach with pool access.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Pool', 'Breakfast', 'Ocean view'],
    latitude: -5.7335,
    longitude: 39.2974,
  ),
  Destination(
    imageUrl: 'assets/images/home2.webp',
    name: 'Arusha Safari Lodge',
    city: 'Arusha',
    area: 'Sakina',
    roomType: 'Luxury chalet',
    distance: 8,
    rating: 4.88,
    price: 120000,
    duration: 'Available this week',
    guests: 4,
    bedrooms: 2,
    beds: 2,
    baths: 2,
    condition: 'Perfect safari chalet with panoramic views of Mount Meru and cozy fireplace.',
    amenities: ['Wi-Fi', 'Fireplace', 'Workspace', 'Breakfast', 'Scenic views'],
    latitude: -3.3662,
    longitude: 36.6661,
  ),
  Destination(
    imageUrl: 'assets/images/house2.webp',
    name: 'Mbezi Beach Resort Suite',
    city: 'Dar es Salaam',
    area: 'Mbezi Beach',
    roomType: 'Resort apartment',
    distance: 12,
    rating: 4.79,
    price: 150000,
    duration: 'Few rooms left',
    guests: 3,
    bedrooms: 1,
    beds: 2,
    baths: 1,
    condition: 'Elegant resort apartment steps away from Mbezi beach shores with modern kitchen.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Kitchen', 'Pool', 'Gym'],
    latitude: -6.7192,
    longitude: 39.2274,
  ),
  Destination(
    imageUrl: 'assets/images/house3.webp',
    name: 'Golden Crest Executive Stay',
    city: 'Dodoma',
    area: 'Area D',
    roomType: 'Executive suite',
    distance: 3,
    rating: 4.65,
    price: 80000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Premium executive room with business desk, high-speed fiber internet, and gym access.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Workspace', 'Gym', 'Breakfast'],
    latitude: -6.1650,
    longitude: 35.7601,
  ),
  Destination(
    imageUrl: 'assets/images/home.webp',
    name: 'Masaki Coral Luxury Villa',
    city: 'Dar es Salaam',
    area: 'Masaki Peninsula',
    roomType: 'Luxury villa',
    distance: 2,
    rating: 4.95,
    price: 190000,
    duration: 'Available today',
    guests: 4,
    bedrooms: 2,
    beds: 2,
    baths: 2,
    condition: 'High-end villa in prestigious Masaki peninsula with private garden and ocean breeze.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Pool', 'Ocean view', 'Security'],
    latitude: -6.7482,
    longitude: 39.2764,
  ),
  Destination(
    imageUrl: 'assets/images/home3.jpg',
    name: 'Upanga Parkside Suites',
    city: 'Dar es Salaam',
    area: 'Upanga East',
    roomType: 'Apartment suite',
    distance: 1,
    rating: 4.70,
    price: 95000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Cozy modern apartment near city center, hospital, and peace park.',
    amenities: ['Wi-Fi', 'Air conditioning', 'Elevator', 'Workspace'],
    latitude: -6.8052,
    longitude: 39.2811,
  ),
  Destination(
    imageUrl: 'assets/images/house.jpeg',
    name: 'Slipway Waterfront Haven',
    city: 'Dar es Salaam',
    area: 'Msasani',
    roomType: 'Waterfront suite',
    distance: 3,
    rating: 4.88,
    price: 160000,
    duration: 'Available today',
    guests: 2,
    bedrooms: 1,
    beds: 1,
    baths: 1,
    condition: 'Exclusive stay steps away from Slipway shopping, restaurants, and boat trips.',
    amenities: ['Wi-Fi', 'Sea view', 'Restaurant', 'Cocktail lounge'],
    latitude: -6.7530,
    longitude: 39.2740,
  ),
];

Future<void> loadDestinationsFromApi({String? city, double? priceMax}) async {
  try {
    final properties = await ApiService.fetchProperties(city: city, priceMax: priceMax);
    if (properties.isNotEmpty) {
      destinations.clear();
      destinations.addAll(properties.map((p) => Destination.fromJson(Map<String, dynamic>.from(p))));
    }
  } catch (e) {
    print('Failed to load destinations: $e');
  }
}

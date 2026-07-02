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
  });

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
  ),
];

import 'package:flutter/material.dart';

class BookingsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _bookings = [
    {
      'name': 'Kariakoo Budget Lodge',
      'city': 'Dar es Salaam',
      'area': 'Kariakoo',
      'dates': 'Jun 12 – 15, 2026',
      'nights': 3,
      'price': 110000,
      'code': 'TZ-84920-DAR',
      'imageUrl': 'assets/images/house3.webp',
      'status': 'Completed',
    },
    {
      'name': 'Zanzibar Sunset Beach Villa',
      'city': 'Zanzibar',
      'area': 'Nungwi',
      'dates': 'Jun 26 – 29, 2026',
      'nights': 3,
      'price': 555000,
      'code': 'TZ-74312-ZNBR',
      'imageUrl': 'assets/images/home.webp',
      'status': 'Checked In',
    },
    {
      'name': 'Arusha Highlands Lodge',
      'city': 'Arusha',
      'area': 'Mount Meru',
      'dates': 'Jul 10 – 14, 2026',
      'nights': 4,
      'price': 420000,
      'code': 'TZ-39201-ARS',
      'imageUrl': 'assets/images/house1.webp',
      'status': 'Confirmed',
    }
  ];

  List<Map<String, dynamic>> get bookings => _bookings;

  void addBooking(Map<String, dynamic> booking) {
    _bookings.add(booking);
    notifyListeners();
  }
}

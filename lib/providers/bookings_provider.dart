import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';

class BookingsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> get bookings => BookingsData.list;

  void addBooking(Map<String, dynamic> booking) {
    BookingsData.list.add(booking);
    notifyListeners();
  }

  void updateStatus(int index, String status) {
    if (index >= 0 && index < BookingsData.list.length) {
      BookingsData.list[index]['status'] = status;
      notifyListeners();
    }
  }
}

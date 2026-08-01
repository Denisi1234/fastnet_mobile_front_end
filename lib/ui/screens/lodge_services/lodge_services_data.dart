import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:flutter/foundation.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final String prepTime;
  final String imageUrl;
  final bool isAvailable;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.prepTime,
    required this.imageUrl,
    this.isAvailable = true,
  });
}

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({
    required this.food,
    required this.quantity,
  });
}

class FoodOrder {
  final String id;
  final List<CartItem> items;
  final String instructions;
  final String timestamp;
  final int totalAmount;
  String status; // 'Received', 'Preparing', 'Ready', 'On the Way', 'Delivered'

  FoodOrder({
    required this.id,
    required this.items,
    required this.instructions,
    required this.timestamp,
    required this.totalAmount,
    this.status = 'Received',
  });
}

class ServiceRequest {
  final String id;
  final String serviceType;
  final String preferredTime;
  final String notes;
  final String timestamp;
  String status; // 'Pending', 'Accepted', 'In Progress', 'Completed'

  ServiceRequest({
    required this.id,
    required this.serviceType,
    required this.preferredTime,
    required this.notes,
    required this.timestamp,
    this.status = 'Pending',
  });
}

class BillItem {
  final String id;
  final String description;
  final String date;
  final int quantity;
  final int price;

  BillItem({
    required this.id,
    required this.description,
    required this.date,
    required this.quantity,
    required this.price,
  });
}

class LodgeServicesData {
  static final List<FoodItem> menu = [
    FoodItem(
      id: 'f1',
      name: 'Zanzibar Mix Pizza',
      description: 'Zanzibari street pizza with eggs, minced beef, onion, and chili paste.',
      category: 'Mains',
      price: 18000,
      prepTime: '20 mins',
      imageUrl: 'assets/images/house2.webp',
    ),
    FoodItem(
      id: 'f2',
      name: 'Swahili Coconut Curry Chicken',
      description: 'Slow-cooked chicken in coconut milk, turmeric, cumin, with spiced rice.',
      category: 'Mains',
      price: 24000,
      prepTime: '25 mins',
      imageUrl: 'assets/images/house4.webp',
    ),
    FoodItem(
      id: 'f3',
      name: 'Spiced Pilau Beef',
      description: 'Aromatic basmati rice cooked in broth with beef, ginger, garlic, and cloves.',
      category: 'Mains',
      price: 20000,
      prepTime: '15 mins',
      imageUrl: 'assets/images/room.webp',
    ),
    FoodItem(
      id: 'f4',
      name: 'Fresh Mango & Passion Juice',
      description: 'Chilled freshly blended juice with Zanzibar sweet mangoes and local passion fruit.',
      category: 'Drinks',
      price: 7000,
      prepTime: '5 mins',
      imageUrl: 'assets/images/house3.webp',
    ),
    FoodItem(
      id: 'f5',
      name: 'Ginger Cardamom Coffee',
      description: 'Traditional spiced Tanzanian black coffee served with dates.',
      category: 'Drinks',
      price: 6000,
      prepTime: '5 mins',
      imageUrl: 'assets/images/home2.webp',
    ),
    FoodItem(
      id: 'f6',
      name: 'Coconut Banana Fritters',
      description: 'Fried sweet local bananas coated in coconut batter, dusted with cinnamon sugar.',
      category: 'Desserts',
      price: 9000,
      prepTime: '10 mins',
      imageUrl: 'assets/images/home.webp',
    ),
  ];

  static final List<FoodOrder> orders = [];
  static final List<ServiceRequest> serviceRequests = [];
  static final List<BillItem> billItems = [];

  static Future<void> syncFromBackend() async {
    try {
      final backendRequests = await ApiService.fetchLodgeRequests();
      
      orders.clear();
      serviceRequests.clear();
      billItems.clear();

      // Add default room stay bill item
      billItems.add(
        BillItem(
          id: 'b_room',
          description: 'Zanzibar Sunset Beach Villa Stay (3 Nights)',
          date: 'Jun 26, 2026',
          quantity: 1,
          price: 555000,
        ),
      );

      for (var req in backendRequests) {
        final id = req['id'].toString();
        final type = req['type'];
        final status = req['status'] ?? 'Pending';
        final price = (req['price'] ?? 0.0).toInt();
        final date = req['created_at'] != null ? req['created_at'].toString().substring(0, 10) : 'Today';
        
        final details = req['details'] as Map<String, dynamic>? ?? {};

        if (type == 'food_order') {
          final List<CartItem> items = [];
          final itemsList = details['items'] as List<dynamic>?;
          if (itemsList != null) {
            for (var item in itemsList) {
              final foodId = item['food_id'];
              final qty = item['quantity'] ?? 1;
              final food = menu.firstWhere((f) => f.id == foodId, orElse: () => menu[0]);
              items.add(CartItem(food: food, quantity: qty));
            }
          }

          orders.add(FoodOrder(
            id: id,
            items: items,
            instructions: details['instructions'] ?? '',
            timestamp: details['timestamp'] ?? date,
            totalAmount: price,
            status: status,
          ));

          billItems.add(BillItem(
            id: 'bill_$id',
            description: 'Food Order #$id',
            date: date,
            quantity: 1,
            price: price,
          ));
        } else {
          // General service request
          final serviceType = details['serviceType'] ?? type.toString().replaceAll('_', ' ');
          serviceRequests.add(ServiceRequest(
            id: id,
            serviceType: serviceType,
            preferredTime: details['preferredTime'] ?? 'As soon as possible',
            notes: details['notes'] ?? '',
            timestamp: details['timestamp'] ?? date,
            status: status,
          ));

          if (price > 0) {
            billItems.add(BillItem(
              id: 'bill_$id',
              description: '$serviceType Request',
              date: date,
              quantity: 1,
              price: price,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Sync Lodge Requests Error: $e');
    }
  }

  static int getOutstandingBalance() {
    int total = 0;
    for (var item in billItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  static Future<void> addFoodOrder(FoodOrder order) async {
    final details = {
      'instructions': order.instructions,
      'timestamp': order.timestamp,
      'items': order.items.map((i) => {
        'food_id': i.food.id,
        'quantity': i.quantity,
      }).toList(),
    };

    await ApiService.createLodgeRequest(
      roomNumber: 'Room 204',
      type: 'food_order',
      details: details,
      price: order.totalAmount.toDouble(),
      status: order.status,
    );

    await syncFromBackend();
  }

  static Future<void> addServiceRequest(ServiceRequest request) async {
    int cost = 0;
    if (request.serviceType == 'Laundry Service') {
      cost = 15000;
    } else if (request.serviceType == 'Spa & Wellness') {
      cost = 60000;
    } else if (request.serviceType == 'Airport/Taxi Pickup') {
      cost = 45000;
    }

    final details = {
      'serviceType': request.serviceType,
      'preferredTime': request.preferredTime,
      'notes': request.notes,
      'timestamp': request.timestamp,
    };

    await ApiService.createLodgeRequest(
      roomNumber: 'Room 204',
      type: request.serviceType.toLowerCase().replaceAll(' ', '_'),
      details: details,
      price: cost.toDouble(),
      status: request.status,
    );

    await syncFromBackend();
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final id = int.tryParse(orderId);
    if (id != null) {
      await ApiService.updateLodgeRequestStatus(id, status);
    }
  }

  static Future<void> updateRequestStatus(String requestId, String status) async {
    final id = int.tryParse(requestId);
    if (id != null) {
      await ApiService.updateLodgeRequestStatus(id, status);
    }
  }

  static void clearAll() {
    // Keep local sync compatibility
    orders.clear();
    serviceRequests.clear();
    billItems.clear();
    billItems.add(
      BillItem(
        id: 'b_room',
        description: 'Zanzibar Sunset Beach Villa Stay (3 Nights)',
        date: 'Jun 26, 2026',
        quantity: 1,
        price: 555000,
      ),
    );
  }
}

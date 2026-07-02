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
  static final List<BillItem> billItems = [
    BillItem(
      id: 'b_room',
      description: 'Zanzibar Sunset Beach Villa Stay (3 Nights)',
      date: 'Jun 26, 2026',
      quantity: 1,
      price: 555000,
    ),
  ];

  static int getOutstandingBalance() {
    int total = 0;
    for (var item in billItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  static void addFoodOrder(FoodOrder order) {
    orders.insert(0, order);
    // Add to bill items
    billItems.add(
      BillItem(
        id: 'bill_${order.id}',
        description: 'Food Order #${order.id}',
        date: order.timestamp,
        quantity: 1,
        price: order.totalAmount,
      ),
    );
  }

  static void addServiceRequest(ServiceRequest request) {
    serviceRequests.insert(0, request);
    // If the service has a cost (e.g. Laundry is 15,000, Spa is 60,000), add to bill
    int cost = 0;
    if (request.serviceType == 'Laundry Service') {
      cost = 15000;
    } else if (request.serviceType == 'Spa & Wellness') {
      cost = 60000;
    } else if (request.serviceType == 'Airport/Taxi Pickup') {
      cost = 45000;
    }
    
    if (cost > 0) {
      billItems.add(
        BillItem(
          id: 'bill_${request.id}',
          description: '${request.serviceType} Request',
          date: request.timestamp,
          quantity: 1,
          price: cost,
        ),
      );
    }
  }

  static void clearAll() {
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

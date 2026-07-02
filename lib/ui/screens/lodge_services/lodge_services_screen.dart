import 'package:airbnb_ui_clone/ui/screens/lodge_services/lodge_services_data.dart';
import 'package:airbnb_ui_clone/ui/screens/main_screen.dart';
import 'package:flutter/material.dart';

class LodgeServicesDashboard extends StatefulWidget {
  const LodgeServicesDashboard({Key? key}) : super(key: key);

  @override
  State<LodgeServicesDashboard> createState() => _LodgeServicesDashboardState();
}

class _LodgeServicesDashboardState extends State<LodgeServicesDashboard> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _triggerRebuild() {
    setState(() {});
  }



  void _openConciergeChat(BuildContext context) {
    final List<Map<String, String>> chatMessages = [
      {
        'sender': 'concierge',
        'text': 'Jambo! Welcome to Sunset Beach Villa Resort. I am your Digital Concierge. How can I assist you in Room 204 today?',
        'time': 'Just now',
      }
    ];

    final TextEditingController chatController = TextEditingController();
    final ScrollController scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setChatState) {
          void scrollToEnd() {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          radius: 18,
                          child: const Icon(Icons.support_agent, color: Color(0xFFD4AF37), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Concierge',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            Text(
                              'Online • Ready to assist',
                              style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      final isUser = msg['sender'] == 'user';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                backgroundColor: Colors.grey.shade100,
                                radius: 12,
                                child: const Icon(Icons.support_agent, size: 12, color: Colors.grey),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser 
                                      ? const Color(0xFF1E1E1E) 
                                      : const Color(0xFFF1F1F1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text']!,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : Colors.black87,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg['time']!,
                                      style: TextStyle(
                                        color: isUser ? Colors.white60 : Colors.black45,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chatController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Type your request here...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isEmpty) return;
                          setChatState(() {
                            chatMessages.add({
                              'sender': 'user',
                              'text': val,
                              'time': 'Just now',
                            });
                          });
                          chatController.clear();
                          scrollToEnd();

                          Future.delayed(const Duration(milliseconds: 600), () {
                            setChatState(() {
                              chatMessages.add({
                                'sender': 'concierge',
                                'text': 'Understood. Let me log that request for Room 204. I am dispatching our resort staff to handle this immediately!',
                                'time': 'Just now',
                              });
                            });
                            scrollToEnd();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFD4AF37),
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black87, size: 16),
                        onPressed: () {
                          final text = chatController.text;
                          if (text.trim().isEmpty) return;
                          setChatState(() {
                            chatMessages.add({
                              'sender': 'user',
                              'text': text,
                              'time': 'Just now',
                            });
                          });
                          chatController.clear();
                          scrollToEnd();

                          Future.delayed(const Duration(milliseconds: 600), () {
                            setChatState(() {
                              chatMessages.add({
                                'sender': 'concierge',
                                'text': 'Understood. I have logged that request for Room 204. Our resort staff will attend to this right away!',
                                'time': 'Just now',
                              });
                            });
                            scrollToEnd();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = LodgeServicesData.getOutstandingBalance();
    final activeOrdersCount = LodgeServicesData.orders.where((o) => o.status != 'Delivered').length;
    final activeRequestsCount = LodgeServicesData.serviceRequests.where((r) => r.status != 'Completed').length;
    final totalActiveItems = activeOrdersCount + activeRequestsCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: CustomScrollView(
        slivers: [
          // Premium Resort Collapsible Banner Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contacting Concierge desk...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.amberAccent),
                tooltip: 'Staff Simulation Panel',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaffSimulationScreen(onStatusChanged: _triggerRebuild),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home.webp',
                    fit: BoxFit.cover,
                  ),
                  // Dark overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Room Info overlay sitting directly on the gradient (no card container, no blur)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ROOM 204',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const Text(
                              'Sunset Beach Villa Resort',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Jambo, Guest',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            const Text(
                              'Zanzibar, Tanzania',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Checkout: Jun 29',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Horizontal quick actions bar
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildHeaderQuickInfo(
                        title: 'Outstanding Bill',
                        value: _formatPrice(balance),
                        icon: Icons.receipt_long,
                        color: Colors.red.shade900,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LodgeBillingScreen(onCheckoutCompleted: _triggerRebuild),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      _buildHeaderQuickInfo(
                        title: 'Active Requests',
                        value: totalActiveItems > 0 ? '$totalActiveItems Active' : 'No Active Tasks',
                        icon: Icons.pending_actions,
                        color: totalActiveItems > 0 ? Colors.amber.shade800 : Colors.grey.shade700,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      _buildHeaderQuickInfo(
                        title: 'Resort Wi-Fi',
                        value: 'Sunset_Lodge_5G',
                        icon: Icons.wifi,
                        color: Colors.teal.shade800,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wi-Fi Password is: "ZanzibarSunset" (Copied to Clipboard)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Gastronomy & Dining Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Gastronomy & Dining',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.2),
                  ),
                ),
                const SizedBox(height: 12),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildLuxuryServiceCard(
                        icon: Icons.restaurant_menu,
                        label: 'Order Food',
                        subText: 'Room delivery menu',
                        gradientColors: [Colors.orange.shade800, Colors.red.shade800],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LodgeFoodMenuScreen()),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      _buildLuxuryServiceCard(
                        icon: Icons.coffee,
                        label: 'Drinks & Beverages',
                        subText: 'Spiced coffees & juice',
                        gradientColors: [Colors.amber.shade900, Colors.brown.shade800],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LodgeFoodMenuScreen()),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Comfort & Cleaning Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Room Comfort & Cleaning',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.2),
                  ),
                ),
                const SizedBox(height: 12),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildLuxuryServiceCard(
                        icon: Icons.local_laundry_service,
                        label: 'Laundry Service',
                        subText: 'Washing & ironing',
                        gradientColors: [Colors.blue.shade700, Colors.indigo.shade800],
                        onTap: () => _openServiceRequestForm(context, 'Laundry Service'),
                      ),
                      _buildLuxuryServiceCard(
                        icon: Icons.cleaning_services,
                        label: 'Room Cleaning',
                        subText: 'Deep clean request',
                        gradientColors: [Colors.teal.shade700, Colors.green.shade800],
                        onTap: () => _openServiceRequestForm(context, 'Room Cleaning'),
                      ),
                      _buildLuxuryServiceCard(
                        icon: Icons.soap,
                        label: 'Extra Amenities',
                        subText: 'Towels, pillows, soaps',
                        gradientColors: [Colors.pink.shade700, Colors.purple.shade700],
                        onTap: () => _openServiceRequestForm(context, 'Extra Amenities'),
                      ),
                      _buildLuxuryServiceCard(
                        icon: Icons.build,
                        label: 'Maintenance',
                        subText: 'Report room issues',
                        gradientColors: [Colors.amber.shade900, Colors.orange.shade800],
                        onTap: () => _openServiceRequestForm(context, 'Maintenance Request'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Wellness Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Wellness & Concierge',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.2),
                  ),
                ),
                const SizedBox(height: 12),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildFullWidthLuxuryCard(
                    icon: Icons.spa,
                    label: 'Spa & Wellness Sanctuary',
                    subText: 'Indulge in organic therapies, deep-tissue massages, facial care, and holistic treatments in our private beachside wellness pavilions.',
                    gradientColors: [Colors.purple.shade800, Colors.pink.shade900],
                    onTap: () => _openServiceRequestForm(context, 'Spa & Wellness'),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Track Requests Floating Panel Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Request Tracking Feed',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalActiveItems > 0 
                                  ? 'You have $totalActiveItems active deliveries in progress.' 
                                  : 'No ongoing request tasks.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                            ).then((_) => setState(() {}));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('Track Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openConciergeChat(context),
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 6,
        child: const Icon(Icons.forum_outlined, color: Colors.black87),
      ),
    );
  }

  Widget _buildHeaderQuickInfo({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryServiceCard({
    required IconData icon,
    required String label,
    required String subText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthLuxuryCard({
    required IconData icon,
    required String label,
    required String subText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  void _openServiceRequestForm(BuildContext context, String serviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => LodgeServiceRequestForm(serviceType: serviceName, onSubmitted: _triggerRebuild),
    );
  }
}

// ------------------------------------
// 2. FOOD ORDERING SCREEN
// ------------------------------------

class LodgeFoodMenuScreen extends StatefulWidget {
  const LodgeFoodMenuScreen({Key? key}) : super(key: key);

  @override
  State<LodgeFoodMenuScreen> createState() => _LodgeFoodMenuScreenState();
}

class _LodgeFoodMenuScreenState extends State<LodgeFoodMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<CartItem> _cart = [];
  final TextEditingController _instructionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  int _getCartTotal() {
    int total = 0;
    for (var item in _cart) {
      total += item.food.price * item.quantity;
    }
    return total;
  }

  void _addToCart(FoodItem food) {
    setState(() {
      final index = _cart.indexWhere((c) => c.food.id == food.id);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(food: food, quantity: 1));
      }
    });
  }

  void _removeFromCart(FoodItem food) {
    setState(() {
      final index = _cart.indexWhere((c) => c.food.id == food.id);
      if (index >= 0) {
        if (_cart[index].quantity > 1) {
          _cart[index].quantity--;
        } else {
          _cart.removeAt(index);
        }
      }
    });
  }

  int _getItemQuantity(FoodItem food) {
    final index = _cart.indexWhere((c) => c.food.id == food.id);
    return index >= 0 ? _cart[index].quantity : 0;
  }

  @override
  Widget build(BuildContext context) {
    final mains = LodgeServicesData.menu.where((f) => f.category == 'Mains').toList();
    final drinks = LodgeServicesData.menu.where((f) => f.category == 'Drinks').toList();
    final desserts = LodgeServicesData.menu.where((f) => f.category == 'Desserts').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('In-Villa Dining', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Mains'),
            Tab(text: 'Drinks'),
            Tab(text: 'Desserts'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFoodGrid(mains),
              _buildFoodGrid(drinks),
              _buildFoodGrid(desserts),
            ],
          ),
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildFloatingCartBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodGrid(List<FoodItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.69,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final qty = _getItemQuantity(item);
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  item.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(item.price),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.green.shade800),
                        ),
                        Text(
                          '⏱ ${item.prepTime}',
                          style: const TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (qty > 0)
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.remove, color: Colors.black54, size: 16),
                              onPressed: () => _removeFromCart(item),
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add, color: Colors.black54, size: 16),
                              onPressed: () => _addToCart(item),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => _addToCart(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Add to Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCartBar() {
    final total = _getCartTotal();
    final itemsCount = _cart.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemsCount item${itemsCount > 1 ? 's' : ''} added',
                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                _formatPrice(total),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _showCheckoutBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
            child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = _getCartTotal();
          
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant, color: Colors.orange.shade800),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Review Dining Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delivering to Room 204 • Zanzibar Sunset Beach Villa',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Special Prep Requests',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _instructionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Extra cutlery, no ice, well done...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Billed to Room:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      _formatPrice(total),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final newOrder = FoodOrder(
                        id: 'F-${1000 + LodgeServicesData.orders.length}',
                        items: List.from(_cart),
                        instructions: _instructionController.text,
                        timestamp: 'Jun 26, 2026',
                        totalAmount: total,
                      );
                      LodgeServicesData.addFoodOrder(newOrder);
                      Navigator.pop(context); // Close sheet
                      Navigator.pop(context); // Go back to dashboard
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order placed successfully! Billed to Room 204.'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Place Room Service Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

// ------------------------------------
// 3. SERVICE REQUESTS FORM
// ------------------------------------

class LodgeServiceRequestForm extends StatefulWidget {
  final String serviceType;
  final VoidCallback onSubmitted;
  
  const LodgeServiceRequestForm({
    Key? key,
    required this.serviceType,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<LodgeServiceRequestForm> createState() => _LodgeServiceRequestFormState();
}

class _LodgeServiceRequestFormState extends State<LodgeServiceRequestForm> {
  final TextEditingController _notesController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _getServiceCost(String service) {
    if (service == 'Laundry Service') return 15000;
    if (service == 'Spa & Wellness') return 60000;
    if (service == 'Airport/Taxi Pickup') return 45000;
    return 0; // Cleaning, Towels, Maintenance are free
  }

  @override
  Widget build(BuildContext context) {
    final cost = _getServiceCost(widget.serviceType);
    
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_outlined, color: Colors.pink.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Request ${widget.serviceType}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Premium Cost transparency badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cost > 0 ? Colors.amber.shade50.withValues(alpha: 0.6) : Colors.green.shade50.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cost > 0 ? Colors.amber.shade200 : Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  cost > 0 ? Icons.info_outline : Icons.check_circle_outline,
                  color: cost > 0 ? Colors.amber.shade800 : Colors.green.shade800,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cost > 0 
                      ? 'Billed service: TSh ${cost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} will be added to your invoice.'
                      : 'Complimentary service: No charge will be billed to your room stay.',
                    style: TextStyle(
                      color: cost > 0 ? Colors.amber.shade900 : Colors.green.shade900,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Time Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scheduled delivery:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              TextButton.icon(
                icon: const Icon(Icons.access_time, size: 18, color: Colors.black87),
                label: Text(_formatTime(_selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          const Divider(),
          
          const SizedBox(height: 8),
          const Text('Special Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Please knock lightly, clean while I am out, extra hangers...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final newReq = ServiceRequest(
                  id: 'SR-${100 + LodgeServicesData.serviceRequests.length}',
                  serviceType: widget.serviceType,
                  preferredTime: _formatTime(_selectedTime),
                  notes: _notesController.text,
                  timestamp: 'Jun 26, 2026',
                );
                LodgeServicesData.addServiceRequest(newReq);
                widget.onSubmitted();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service request sent to housekeeping desk.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Send Service Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------
// 4. BILLING INTEGRATION & CHECKOUT
// ------------------------------------

class LodgeBillingScreen extends StatefulWidget {
  final VoidCallback onCheckoutCompleted;
  const LodgeBillingScreen({Key? key, required this.onCheckoutCompleted}) : super(key: key);

  @override
  State<LodgeBillingScreen> createState() => _LodgeBillingScreenState();
}

class _LodgeBillingScreenState extends State<LodgeBillingScreen> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _triggerCheckout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Express Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Completing checkout will finalize payment and deactivate your digital key card access to Room 204.'),
            const SizedBox(height: 16),
            Text(
              'Total Charge: ${_formatPrice(LodgeServicesData.getOutstandingBalance())}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
            ),
            const SizedBox(height: 12),
            const Text(
              'A receipt will be emailed to you, and your card ending in *4829 will be charged.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              // Update booking status to completed
              for (int i = 0; i < BookingsData.list.length; i++) {
                if (BookingsData.list[i]['status'] == 'Checked In') {
                  BookingsData.list[i]['status'] = 'Completed';
                }
              }
              // Clear Lodge Services state
              LodgeServicesData.clearAll();
              widget.onCheckoutCompleted();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from billing page
              Navigator.pop(context); // Go back from dashboard
              
              // Return to MainScreen at Home tab
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen(initialTab: 0)),
                (route) => false,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checkout successful! Safe travels!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pay & Check Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = LodgeServicesData.billItems;
    final total = LodgeServicesData.getOutstandingBalance();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Resort Statement Invoice', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${item.date} • Qty: ${item.quantity}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatPrice(item.price * item.quantity),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Checkout pricing footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Invoice Grand Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        _formatPrice(total),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _triggerCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Express Checkout & Pay Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------
// 5. ORDER HISTORY & REQUESTS TRACKER
// ------------------------------------

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Color _getFoodStatusColor(String status) {
    switch (status) {
      case 'Received': return Colors.grey;
      case 'Preparing': return Colors.orange;
      case 'Ready': return Colors.blue;
      case 'On the Way': return Colors.purple;
      case 'Delivered': return Colors.green;
      default: return Colors.black;
    }
  }

  Color _getServiceStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.grey;
      case 'Accepted': return Colors.orange;
      case 'In Progress': return Colors.blue;
      case 'Completed': return Colors.green;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodOrders = LodgeServicesData.orders;
    final requests = LodgeServicesData.serviceRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('My Service Invoices', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Food Deliveries'),
            Tab(text: 'Room Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Food Orders List
          foodOrders.isEmpty
            ? const Center(child: Text('No food orders placed yet.', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: foodOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = foodOrders[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getFoodStatusColor(order.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status,
                                  style: TextStyle(
                                    color: _getFoodStatusColor(order.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.food.name} x${item.quantity}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                Text(_formatPrice(item.food.price * item.quantity), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          )).toList(),
                          if (order.instructions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Note: "${order.instructions}"', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Charged Amount:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text(
                                _formatPrice(order.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          
          // Service Requests List
          requests.isEmpty
            ? const Center(child: Text('No service requests submitted yet.', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                req.serviceType,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getServiceStatusColor(req.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  req.status,
                                  style: TextStyle(
                                    color: _getServiceStatusColor(req.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Target Delivery Time:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(req.preferredTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                          if (req.notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Instructions: "${req.notes}"', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Req ID: ${req.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              Text('Submitted: ${req.timestamp}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

// ------------------------------------
// 6. STAFF SIMULATION SCREEN (CONSOLE)
// ------------------------------------

class StaffSimulationScreen extends StatefulWidget {
  final VoidCallback onStatusChanged;
  const StaffSimulationScreen({Key? key, required this.onStatusChanged}) : super(key: key);

  @override
  State<StaffSimulationScreen> createState() => _StaffSimulationScreenState();
}

class _StaffSimulationScreenState extends State<StaffSimulationScreen> {
  void _updateFoodStatus(FoodOrder order, String newStatus) {
    setState(() {
      order.status = newStatus;
    });
    widget.onStatusChanged();
    
    // Simulate real-time notification toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Resort Alert: Order #${order.id} status updated to: $newStatus')),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateServiceStatus(ServiceRequest request, String newStatus) {
    setState(() {
      request.status = newStatus;
    });
    widget.onStatusChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Resort Alert: Request #${request.id} (${request.serviceType}) is: $newStatus')),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodOrders = LodgeServicesData.orders;
    final requests = LodgeServicesData.serviceRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Staff Fulfillment Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Act as Resort Staff: Use this panel to simulatedly change order statuses, send notifications, and test client status tracking.',
                      style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Kitchen Staff section
            const Text('👨‍🍳 Kitchen & Bar Desk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            foodOrders.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('No active kitchen orders.', style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: foodOrders.length,
                  itemBuilder: (context, index) {
                    final order = foodOrders[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #${order.id} • Room 204', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Status: ${order.status}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map((item) => Text('• ${item.food.name} x${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (order.status == 'Received')
                                  ElevatedButton(
                                    onPressed: () => _updateFoodStatus(order, 'Preparing'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, elevation: 0),
                                    child: const Text('Start Preparing', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (order.status == 'Preparing')
                                  ElevatedButton(
                                    onPressed: () => _updateFoodStatus(order, 'Ready'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, elevation: 0),
                                    child: const Text('Mark Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (order.status == 'Ready')
                                  ElevatedButton(
                                    onPressed: () => _updateFoodStatus(order, 'On the Way'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, elevation: 0),
                                    child: const Text('Send for Delivery', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (order.status == 'On the Way')
                                  ElevatedButton(
                                    onPressed: () => _updateFoodStatus(order, 'Delivered'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                                    child: const Text('Confirm Delivered', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  const Text('✅ Order Delivered', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
            const SizedBox(height: 24),
            
            // Housekeeping/Laundry Staff section
            const Text('🧹 Housekeeping & Support Desk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            requests.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('No active service requests.', style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${req.serviceType} • Room 204', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Status: ${req.status}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Delivery Target: ${req.preferredTime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (req.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Notes: "${req.notes}"', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (req.status == 'Pending')
                                  ElevatedButton(
                                    onPressed: () => _updateServiceStatus(req, 'Accepted'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, elevation: 0),
                                    child: const Text('Accept Request', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (req.status == 'Accepted')
                                  ElevatedButton(
                                    onPressed: () => _updateServiceStatus(req, 'In Progress'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, elevation: 0),
                                    child: const Text('Mark In Progress', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (req.status == 'In Progress')
                                  ElevatedButton(
                                    onPressed: () => _updateServiceStatus(req, 'Completed'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                                    child: const Text('Mark Completed', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  const Text('✅ Request Finished', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

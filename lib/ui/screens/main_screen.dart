import 'package:airbnb_ui_clone/ui/screens/explore/explore.dart';
import 'package:airbnb_ui_clone/ui/screens/host/host_dashboard.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/login_signup_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/host_onboarding_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/wishlist/wishlist_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/lodge_services/lodge_services_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/support/support_help_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/profile/settings_screen.dart';
import 'package:airbnb_ui_clone/models/destination.dart';
import 'package:airbnb_ui_clone/providers/bookings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  // Set active tab programmatically
  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const Explore(),
      WishlistScreen(key: ValueKey('wish:${WishlistData.list.map((d) => d.name).join(',')}|view:${RecentlyViewedData.list.map((d) => d.name).join(',')}')),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildBottomNavItem(Icons.favorite_border, Icons.favorite, 'Wishlists', 1),
            _buildBottomNavItem(Icons.person_outline, Icons.person, 'Profile', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    final color = isActive ? Colors.red.shade900 : Colors.grey.shade500;
    final icon = isActive ? filledIcon : outlineIcon;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: isActive ? 12 : 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// 1. SEARCH LIST SCREEN TAB
// ------------------------------------

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsProvider>().bookings;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Bookings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No active bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your reserved rooms will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final b = bookings[index];
                final isConfirmed = b['status'] == 'Confirmed';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Row Info
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(b['imageUrl'], width: 90, height: 75, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isConfirmed ? Colors.green.shade50 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          b['status'].toUpperCase(),
                                          style: TextStyle(
                                            color: isConfirmed ? Colors.green.shade700 : Colors.blue.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Code: ${b['code'].split('-')[1]}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    b['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b['area']}, ${b['city']}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Details row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DATES', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(b['dates'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(_formatPrice(b['price']), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (b['status'] == 'Confirmed' || b['status'] == 'Checked In') ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final dest = destinations.firstWhere(
                                    (d) => b['name'].toString().contains(d.name) || d.name.contains(b['name'].toString().split('-')[0].trim()),
                                    orElse: () => destinations.first,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReceiptScreen(
                                        bookingCode: b['code'] ?? 'TZ-00000-GEN',
                                        lodgeName: b['name'] ?? 'Lodge Stay',
                                        roomNumber: b['name'].toString().contains('Room') 
                                            ? b['name'].toString().split('Room')[1].trim()
                                            : '204',
                                        location: '${b['area']}, ${b['city']}',
                                        dates: b['dates'] ?? 'Jun 12 – 15, 2026',
                                        guestName: UserSession.userName ?? 'Traveler',
                                        guestPhone: UserSession.userPhone ?? '+255 712 345 678',
                                        paymentMethod: 'Vodacom M-Pesa',
                                        numNights: b['nights'] ?? 3,
                                        pricePerNight: dest.price,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long, size: 14),
                                label: const Text('Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (b['status'] == 'Confirmed')
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      b['status'] = 'Checked In';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Successfully Checked In! In-stay services are now active.'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              else if (b['status'] == 'Checked In')
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LodgeServicesDashboard()),
                                    ).then((_) => setState(() {}));
                                  },
                                  icon: const Icon(Icons.room_service, size: 14),
                                  label: const Text('Lodge Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade900,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ------------------------------------
// 3. PROFILE SCREEN TAB
// ------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final bool loggedIn = UserSession.isLoggedIn;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            if (loggedIn)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(UserSession.userAvatar),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      UserSession.userName ?? 'Guest User',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UserSession.userEmail ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your profile',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to start planning your next trip, booking lodges, and listing properties.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink.shade700, Colors.red.shade900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginSignupScreen(),
                              ),
                            );
                            if (success == true) {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Log in or Sign up',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),

            _buildProfileSection('Hosting & Booking', [
              _buildProfileTile(Icons.bookmark_outline, 'My Bookings', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
              }),
              _buildProfileTile(Icons.room_service_outlined, 'Lodge Services', () {
                final hasActiveStay = BookingsData.list.any((b) => b['status'] == 'Checked In');
                if (hasActiveStay) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LodgeServicesDashboard()),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Services Unavailable'),
                        ],
                      ),
                      content: const Text(
                        'Lodge services become available once you have checked into your room.\n\nYou can manage and check in to your bookings in the "My Bookings" section.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                          child: const Text('Go to Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              }),
              _buildProfileTile(Icons.home_work_outlined, 'List your lodge', () {
                if (UserSession.isLoggedIn && UserSession.hasSeenHostOnboarding) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HostDashboard()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HostOnboardingScreen()));
                }
              }),
            ]),
            const SizedBox(height: 20),
            _buildProfileSection('Settings & Support', [
              _buildProfileTile(Icons.settings_outlined, 'Settings', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              _buildProfileTile(Icons.headset_mic_outlined, 'Lodge Support & Help', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportHelpScreen()));
              }),
            ]),
            const SizedBox(height: 30),
            if (loggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      UserSession.logout();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully.')),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileTile(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap ?? () {},
    );
  }
}

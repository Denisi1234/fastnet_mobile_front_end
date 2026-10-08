import 'package:fastnet_mobile_front_end/ui/screens/explore/explore.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/bookings_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/booking_checkout.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/guest_messages.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/profile_tab.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/services/draft_booking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  Map<String, dynamic>? _draftBooking;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab > 3 ? 3 : widget.initialTab;
    _restoreLastTab();
    _checkForDraftBooking();
  }

  void _restoreLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTab = prefs.getInt('last_main_tab_index');
    if (lastTab != null && lastTab != _selectedIndex && mounted) {
      setState(() {
        // Clamp to valid indices (0 to 3) since there are now 4 tabs
        _selectedIndex = lastTab > 3 ? 3 : lastTab;
      });
    }
  }

  void _checkForDraftBooking() async {
    final draft = await DraftBookingService.load();
    if (draft == null) return;
    if (DraftBookingService.isExpired(draft)) {
      await DraftBookingService.clear();
      return;
    }
    if (mounted) {
      setState(() => _draftBooking = draft);
      // Small delay so main screen has built before showing the bottom sheet
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showResumeBanner();
      });
    }
  }

  void _showResumeBanner() {
    if (_draftBooking == null) return;
    final draft = _draftBooking!;
    final destName = draft['destination']['name'] ?? 'your lodge';
    final dates = draft['selectedDatesText'] ?? '';
    final roomNum = draft['selectedRoomNumber'] ?? '';
    final savedAt = DateTime.tryParse(draft['savedAt'] ?? '');
    final timeAgo = savedAt != null
        ? _formatTimeAgo(DateTime.now().difference(savedAt))
        : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Icon row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade800, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.hotel_outlined, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Continue your booking',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            'Started $timeAgo ago',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _draftRow(Icons.home_outlined, destName),
                    const SizedBox(height: 8),
                    _draftRow(Icons.bed_outlined, 'Room $roomNum'),
                    const SizedBox(height: 8),
                    _draftRow(Icons.calendar_today_outlined, dates),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await DraftBookingService.clear();
                        setState(() => _draftBooking = null);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resumeDraftBooking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Continue Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resumeDraftBooking() {
    if (_draftBooking == null) return;
    final draft = _draftBooking!;
    final destination = Destination.fromDraftJson(draft['destination'] as Map<String, dynamic>);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCheckoutScreen(
          destination: destination,
          selectedDatesText: draft['selectedDatesText'] as String,
          numNights: (draft['numNights'] as num).toInt(),
          selectedRoomNumber: draft['selectedRoomNumber'] as String,
          selectedRoomId: (draft['selectedRoomId'] as num).toInt(),
        ),
      ),
    ).then((_) {
      // Recheck draft after returning (may have been cleared)
      _checkForDraftBooking();
    });
  }

  Widget _draftRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(Duration diff) {
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // Set active tab programmatically
  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;

    final List<Widget> screens = [
      const Explore(),
      const BookingsScreen(),
      const GuestMessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: isDesktopWeb
          ? null
          : BubbleBottomNavBar(
              selectedIndex: _selectedIndex,
              onTabSelected: (index) async {
                setState(() => _selectedIndex = index);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('last_main_tab_index', index);
              },
            ),
    );
  }
}

// ------------------------------------
// Custom Bubble Bottom Navigation Bar
// ------------------------------------
class BubbleBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const BubbleBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _BubbleNavItem(
        outlineIcon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _BubbleNavItem(
        outlineIcon: Icons.event_outlined,
        activeIcon: Icons.event,
        label: 'Booking',
      ),
      _BubbleNavItem(
        outlineIcon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        hasNotification: true,
      ),
      _BubbleNavItem(
        outlineIcon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / items.length;
    final activeX = (selectedIndex + 0.5) * itemWidth;

    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // White Arched Bubble background container with shadow
          Positioned.fill(
            top: 16,
            child: CustomPaint(
              painter: BubbleNavBarShadowPainter(
                selectedIndex: selectedIndex,
                itemCount: items.length,
              ),
              child: ClipPath(
                clipper: BubbleNavBarClipper(
                  selectedIndex: selectedIndex,
                  itemCount: items.length,
                ),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Floating Blue Indicator Dot sitting above the active arch peak
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: activeX - 3.5,
            top: 2,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF1B65F2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Bottom Bar Items Row
          Positioned.fill(
            top: 16,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = selectedIndex == index;

                  return GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isActive ? item.activeIcon : item.outlineIcon,
                                color: isActive ? const Color(0xFF1B65F2) : const Color(0xFF64748B),
                                size: 24,
                              ),
                              if (item.hasNotification && !isActive)
                                Positioned(
                                  top: -2,
                                  right: -3,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? const Color(0xFF1B65F2) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------
// Custom Clipper for Bubble Arch
// ------------------------------------
class BubbleNavBarClipper extends CustomClipper<Path> {
  final int selectedIndex;
  final int itemCount;

  BubbleNavBarClipper({required this.selectedIndex, required this.itemCount});

  @override
  Path getClip(Size size) {
    final path = Path();
    final itemWidth = size.width / itemCount;
    final centerX = (selectedIndex + 0.5) * itemWidth;
    const archRadius = 34.0;
    const archHeight = 15.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - archRadius - 8, 0);

    // Smooth Bezier curve arching upwards at active tab position
    path.cubicTo(
      centerX - archRadius + 8,
      0,
      centerX - archRadius + 10,
      -archHeight,
      centerX,
      -archHeight,
    );
    path.cubicTo(
      centerX + archRadius - 10,
      -archHeight,
      centerX + archRadius - 8,
      0,
      centerX + archRadius + 8,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BubbleNavBarClipper oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.itemCount != itemCount;
  }
}

// ------------------------------------
// Custom Painter for Bubble Bar Shadow
// ------------------------------------
class BubbleNavBarShadowPainter extends CustomPainter {
  final int selectedIndex;
  final int itemCount;

  BubbleNavBarShadowPainter({required this.selectedIndex, required this.itemCount});

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = BubbleNavBarClipper(selectedIndex: selectedIndex, itemCount: itemCount);
    final path = clipper.getClip(size);

    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(path.shift(const Offset(0, -3)), paint);
  }

  @override
  bool shouldRepaint(covariant BubbleNavBarShadowPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.itemCount != itemCount;
  }
}

class _BubbleNavItem {
  final IconData outlineIcon;
  final IconData activeIcon;
  final String label;
  final bool hasNotification;

  _BubbleNavItem({
    required this.outlineIcon,
    required this.activeIcon,
    required this.label,
    this.hasNotification = false,
  });
}

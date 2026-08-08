import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/host_onboarding_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/host/host_dashboard.dart';
import 'package:fastnet_mobile_front_end/ui/screens/lodge_services/lodge_services_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/support/support_help_screen.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';

class WebTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const WebTopHeader({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSessionProvider>();
    final isHost = userSession.hasSeenHostOnboarding;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Authentic FASTNETSTAYS.com Logo
          InkWell(
            onTap: () => onTabSelected(0),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'FASTNET',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003580),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'STAYS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD32F2F),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '.com',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    _BrandDot(color: Colors.red),
                    _BrandDot(color: Colors.orange),
                    _BrandDot(color: Colors.yellow),
                    _BrandDot(color: Colors.green),
                    _BrandDot(color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Navigation Links
          Row(
            children: [
              _navButton(context, index: 0, label: 'Explore Stays', icon: Icons.explore_outlined),
              _navButton(context, index: 1, label: 'Wishlists', icon: Icons.favorite_outline),
              _navButton(context, index: 2, label: 'Messages', icon: Icons.chat_bubble_outline),
              _navButton(context, index: 3, label: 'Profile', icon: Icons.person_outline),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LodgeServicesDashboard()),
                  );
                },
                icon: const Icon(Icons.room_service_outlined, size: 16),
                label: const Text('Lodge Services'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF003580),
                  side: const BorderSide(color: Color(0xFF003580)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Right Controls & Actions
          Row(
            children: [
              // Host / Admin Portal Shortcut
              ElevatedButton.icon(
                onPressed: () {
                  if (isHost) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HostDashboard()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HostOnboardingScreen()),
                    );
                  }
                },
                icon: Icon(isHost ? Icons.dashboard_outlined : Icons.house_outlined, size: 18, color: Colors.white),
                label: Text(
                  isHost ? 'Host Portal' : 'Become a Host',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),

              const SizedBox(width: 12),

              // View Mode Switcher Button
              Tooltip(
                message: "Switch to Mobile Phone App Frame",
                child: IconButton(
                  onPressed: () {
                    AppSettings.instance.toggleMobileShellMode();
                  },
                  icon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF64748B)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Support / Help Button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportHelpScreen()),
                  );
                },
                icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, {required int index, required String label, required IconData icon}) {
    final isActive = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: () => onTabSelected(index),
        icon: Icon(
          icon,
          size: 18,
          color: isActive ? const Color(0xFF003580) : const Color(0xFF64748B),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFF003580) : const Color(0xFF64748B),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: isActive ? const Color(0xFF003580).withValues(alpha: 0.08) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class _BrandDot extends StatelessWidget {
  final Color color;
  const _BrandDot({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

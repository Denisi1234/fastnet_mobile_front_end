import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/host/add_property.dart';
import 'package:fastnet_mobile_front_end/ui/screens/host/host_dashboard.dart';
import 'package:fastnet_mobile_front_end/ui/screens/host/manage_listings.dart';
import 'package:fastnet_mobile_front_end/ui/screens/notifications/notifications_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/account_security.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/bookings_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/language_currency.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/personal_info.dart';
import 'package:fastnet_mobile_front_end/ui/screens/support/support_help_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/wishlist/wishlist_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/search_filter_screen.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';

/// Profile tab — mobile layout of the web account sidebar
/// (`templates/element/profile_sidebar.php` + `profile.css`).
///
/// Same item order, same role gating (host items for owner/admin), same
/// active-pill styling (`#e0f2fe` / `#0284c7`), stacked vertically for
/// phones with an identity header on top.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileMenuItem {
  final String id;
  final IconData icon;
  final String label;
  final Widget Function() page;
  final bool hostOnly;

  const _ProfileMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.page,
    this.hostOnly = false,
  });
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Web `.trivago-side-link.active` equivalent.
  String? _activeId;

  static const _ink = Color(0xFF0F172A);
  static const _body = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _activeBg = Color(0xFFE0F2FE);
  static const _activeFg = Color(0xFF0284C7);
  static const _teal = Color(0xFF007FAD);

  static final _items = [
    _ProfileMenuItem(
      id: 'personal-info',
      icon: Icons.person_outline_rounded,
      label: 'Personal info',
      page: PersonalInfoScreen.new,
    ),
    _ProfileMenuItem(
      id: 'security',
      icon: Icons.lock_outline_rounded,
      label: 'Account security',
      page: AccountSecurityScreen.new,
    ),
    _ProfileMenuItem(
      id: 'favourites',
      icon: Icons.favorite_outline_rounded,
      label: 'Favourites',
      page: WishlistScreen.new,
    ),
    _ProfileMenuItem(
      id: 'recently-viewed',
      icon: Icons.history_rounded,
      label: 'Recently viewed',
      page: WishlistScreen.new,
    ),
    _ProfileMenuItem(
      id: 'bookings',
      icon: Icons.luggage_outlined,
      label: 'Bookings',
      page: BookingsScreen.new,
    ),
    _ProfileMenuItem(
      id: 'search-preferences',
      icon: Icons.search_rounded,
      label: 'Search preferences',
      page: SearchFilterScreen.new,
    ),
    _ProfileMenuItem(
      id: 'notifications',
      icon: Icons.notifications_none_rounded,
      label: 'Notifications',
      page: NotificationsScreen.new,
    ),
    _ProfileMenuItem(
      id: 'language-currency',
      icon: Icons.language_outlined,
      label: 'Language and currency',
      page: LanguageCurrencyScreen.new,
    ),
    _ProfileMenuItem(
      id: 'host-dashboard',
      icon: Icons.hotel_outlined,
      label: 'Host Dashboard',
      page: HostDashboard.new,
      hostOnly: true,
    ),
    _ProfileMenuItem(
      id: 'host-listings',
      icon: Icons.list_alt_rounded,
      label: 'My Properties',
      page: ManageListings.new,
      hostOnly: true,
    ),
    _ProfileMenuItem(
      id: 'host-onboarding',
      icon: Icons.add_home_outlined,
      label: 'Onboard Lodge',
      page: AddProperty.new,
      hostOnly: true,
    ),
    _ProfileMenuItem(
      id: 'help-center',
      icon: Icons.help_outline_rounded,
      label: 'Help and support',
      page: SupportHelpScreen.new,
    ),
  ];

  void _open(_ProfileMenuItem item) {
    HapticFeedback.selectionClick();
    setState(() => _activeId = item.id);
    Navigator.push(context, FadeSlidePageRoute(page: item.page()));
  }

  Color _badgeColor(String? hex, Color fallback) {
    try {
      if (hex == null || hex.isEmpty) return fallback;
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionProvider>();
    final loggedIn = session.isLoggedIn;
    final showHost = loggedIn && session.isOwnerOrAdmin;
    final visible = _items.where((i) {
      if (i.hostOnly && !showHost) return false;
      // Logged-out visitors get the account gate + public pages only,
      // mirroring the web redirect-to-login behaviour.
      if (!loggedIn &&
          i.id != 'help-center' &&
          i.id != 'language-currency') {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!loggedIn) ...[
            _loginCard(),
            const SizedBox(height: 20),
          ] else ...[
            _identityHeader(session),
            const SizedBox(height: 16),
          ],
          for (int i = 0; i < visible.length; i++) ...[
            _menuLink(visible[i], _activeId == visible[i].id),
            if (i < visible.length - 1) const SizedBox(height: 6),
          ],
          if (loggedIn) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Provider.of<UserSessionProvider>(context, listen: false)
                      .logout();
                  setState(() => _activeId = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Logged out successfully.')),
                  );
                },
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.red, size: 19),
                label: const Text('Log Out',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: Text(
              'FastNet Stays · v1.0.0',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Identity header — avatar + name + email, opens Personal info.
  Widget _identityHeader(UserSessionProvider session) {
    final name = session.userName ?? 'Traveler';
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'T';
    final hasPhoto = UserSession.profileImagePath != null;
    return InkWell(
      onTap: () => _open(_items.firstWhere((i) => i.id == 'personal-info')),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            hasPhoto
                ? CircleAvatar(
                    radius: 27,
                    backgroundImage: session.profileImage,
                  )
                : Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _badgeColor(
                          session.avatarBg, const Color(0xFFF0F9FF)),
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _badgeColor(
                            session.avatarFg, _activeFg),
                      ),
                    ),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.userEmail ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: _muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your profile',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in to manage your personal info, bookings, favourites and host dashboard.',
            style: TextStyle(
                color: _muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  FadeSlidePageRoute(
                      page: const LoginSignupScreen()),
                ).then((_) => setState(() {}));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Log in or Sign up',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web `.trivago-side-link` (+ `.active`): icon + label pill rows.
  Widget _menuLink(_ProfileMenuItem item, bool active) {
    return InkWell(
      onTap: () => _open(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: active ? _activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Icon(
                item.icon,
                size: 19,
                color: active ? _activeFg : _body,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? _activeFg : _body,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: active ? _activeFg : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

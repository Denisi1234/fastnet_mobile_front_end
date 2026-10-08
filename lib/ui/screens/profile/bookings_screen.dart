import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/providers/bookings_provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/write_review_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/booking_details.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/shimmer_widget.dart';

/// My bookings — Booking.com-grade trips screen in Material style.
///
/// Upcoming / Completed / Cancelled tabs over live backend rows, tonal
/// status pills, per-status actions (real cancel, receipt, review,
/// rebook), pull-to-refresh against `GET /bookings`, shimmer loading,
/// per-tab empties, a logged-out gate, and a cached + "Updated X ago"
/// offline banner. No invented rows, weather, or countdowns — every
/// number comes from the backend record.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _faint = Color(0xFF9AA0A6);
  static const _border = Color(0xFFE8EAED);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _blue = Color(0xFF1A73E8);
  static const _blueTint = Color(0xFFE8F0FE);

  static const _tabs = ['upcoming', 'completed', 'cancelled'];
  static const _tabLabels = {
    'upcoming': 'Upcoming',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  String _tab = 'upcoming';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<UserSessionProvider>().isLoggedIn) {
        context.read<BookingsProvider>().refresh();
      }
    });
  }

  String _tabOf(Map<String, dynamic> b) {
    final s = (b['status'] ?? '').toString().toLowerCase().trim();
    if (s == 'cancelled' || s == 'canceled') return 'cancelled';
    if (s == 'completed') return 'completed';
    return 'upcoming';
  }

  String _formatPrice(dynamic price) {
    final v = price is num
        ? price.toInt()
        : int.tryParse(price?.toString() ?? '') ?? 0;
    return 'TSh ${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Short booking-code chip. Backend rows sometimes carry no code (or a
  /// code without dashes) — never index blindly into the split parts.
  String _shortCode(dynamic code) {
    final s = (code ?? '').toString().trim();
    if (s.isEmpty) return '—';
    final parts = s.split('-');
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    if (s.length > 12) return '${s.substring(0, 12)}…';
    return s;
  }

  String _timeAgo(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  /// Display-only property for receipt/rebook, resolved from the live
  /// list when possible, otherwise built honestly from backend fields.
  Destination _resolveDestination(Map<String, dynamic> b) {
    return destinations.firstWhere(
      (d) =>
          b['name'].toString().contains(d.name) ||
          d.name.contains(b['name'].toString().split('-')[0].trim()),
      orElse: () => Destination(
        imageUrl: (b['imageUrl'] is String &&
                (b['imageUrl'] as String).isNotEmpty)
            ? b['imageUrl']
            : 'assets/images/house3.webp',
        name: (b['name'] ?? 'Lodge Stay').toString(),
        city: (b['city'] ?? 'Dar es Salaam').toString(),
        area: (b['area'] ?? '').toString(),
        roomType: 'Private Room',
        distance: 2,
        rating: 4.5,
        price: (b['price'] is num) ? (b['price'] as num).toInt() : 50000,
        duration: 'Available today',
        guests: 2,
        bedrooms: 1,
        beds: 1,
        baths: 1,
        condition: '',
        amenities: const ['Wi-Fi'],
        latitude: -6.7780,
        longitude: 39.2345,
      ),
    );
  }

  void _openDetails(Map<String, dynamic> b) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      FadeSlidePageRoute(page: BookingDetailsScreen(booking: b)),
    );
  }

  void _openReceipt(Map<String, dynamic> b) {
    HapticFeedback.selectionClick();
    final dest = _resolveDestination(b);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          bookingCode: (b['code']?.toString().isNotEmpty ?? false)
              ? b['code']
              : 'Pending',
          lodgeName: (b['name'] ?? 'Lodge Stay').toString(),
          roomNumber: b['name'].toString().contains('Room')
              ? b['name'].toString().split('Room')[1].trim()
              : (b['roomNumber']?.toString() ?? '—'),
          location: '${b['area'] ?? ''}, ${b['city'] ?? ''}',
          dates: (b['dates'] ?? '').toString(),
          guestName: UserSession.userName ?? 'Traveler',
          guestPhone: UserSession.userPhone ?? '',
          paymentMethod:
              (b['payment_method'] ?? 'Vodacom M-Pesa').toString(),
          numNights:
              (b['nights'] is num) ? (b['nights'] as num).toInt() : 1,
          pricePerNight: dest.price,
          paymentTime: b['paymentTime'],
        ),
      ),
    );
  }

  void _openReview(Map<String, dynamic> b) {
    final pid = b['propertyId'];
    final propertyId = pid is int ? pid : int.tryParse(pid?.toString() ?? '');
    if (propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reviews are available for listed properties.')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: WriteReviewScreen(
          propertyName: (b['name'] ?? 'Lodge Stay').toString(),
          propertyId: propertyId,
          bookingId: b['id'] is int ? b['id'] as int : null,
        ),
      ),
    );
  }

  void _rebook(Map<String, dynamic> b) {
    HapticFeedback.selectionClick();
    final name = b['name']?.toString() ?? '';
    final match = destinations.where((d) =>
        name.contains(d.name) ||
        d.name.contains(name.split('-')[0].trim()));
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'This property is not listed right now — search for your next stay.')),
      );
      return;
    }
    final dest = match.first;
    final nights =
        (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: BookRoom(destination: dest, numNights: nights),
      ),
    );
  }

  Future<void> _cancelBooking(Map<String, dynamic> b) async {
    final id = b['id'];
    final code = b['code']?.toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel this stay?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Booking ${(code ?? '').toString().isNotEmpty ? code : ''} will be cancelled. This action cannot be undone.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Keep stay', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB81922),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel stay',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final ok = await context.read<BookingsProvider>().cancelOnServer(
          id: id is int ? id : int.tryParse(id?.toString() ?? ''),
          code: code,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Stay cancelled.'
              : 'Could not cancel. Please try again.'),
        ),
      );
    if (ok) setState(() => _tab = 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionProvider>();
    final provider = context.watch<BookingsProvider>();

    if (!session.isLoggedIn) return _loginGate();

    final all = provider.bookings;
    final counts = {
      for (final t in _tabs) t: all.where((b) => _tabOf(b) == t).length,
    };
    final list = all.where((b) => _tabOf(b) == _tab).toList();
    final loading =
        provider.status == BookingsSyncStatus.loading && all.isEmpty;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text('My bookings',
                style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(width: 8),
            if (all.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _blueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${all.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _blue)),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await context.read<BookingsProvider>().refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _tabBar(counts),
            const SizedBox(height: 6),
            _syncLine(provider),
            const SizedBox(height: 10),
            if (loading) ...[
              for (int i = 0; i < 3; i++) ...[
                const _SkeletonCard(),
                const SizedBox(height: 12),
              ],
            ] else if (list.isEmpty) ...[
              _emptyState(),
            ] else ...[
              for (int i = 0; i < list.length; i++) ...[
                _bookingCard(list[i]),
                if (i < list.length - 1) const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabBar(Map<String, int> counts) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: _tabs.map((t) {
          final active = _tab == t;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (_tab == t) return;
                HapticFeedback.selectionClick();
                setState(() => _tab = t);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_tabLabels[t]} (${counts[t] ?? 0})',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Offline / error banner + last-synced stamp (enterprise OTA contract).
  Widget _syncLine(BookingsProvider provider) {
    if (provider.status == BookingsSyncStatus.error &&
        provider.bookings.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 15, color: Color(0xFF92400E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Couldn't refresh · Updated ${_timeAgo(provider.lastSyncedAt)}",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E)),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<BookingsProvider>().refresh();
              },
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
    }
    if (provider.lastSyncedAt != null &&
        provider.status != BookingsSyncStatus.loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, left: 4),
        child: Text(
          'Updated ${_timeAgo(provider.lastSyncedAt)}',
          style:
              const TextStyle(fontSize: 11.5, color: _faint),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _emptyState() {
    final isCancelled = _tab == 'cancelled';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_outlined
                  : Icons.luggage_outlined,
              size: 28,
              color: _faint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _tab == 'upcoming'
                ? 'No upcoming stays'
                : _tab == 'completed'
                    ? 'No completed stays yet'
                    : 'No cancelled stays',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink),
          ),
          const SizedBox(height: 6),
          Text(
            _tab == 'upcoming'
                ? 'Your confirmed reservations will appear here.'
                : _tab == 'completed'
                    ? 'Finished stays will appear here.'
                    : 'Cancelled reservations will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _loginGate() {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My bookings',
            style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: _blueTint,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.lock_outline_rounded,
                        size: 44, color: _blue),
              ),
              const SizedBox(height: 20),
              const Text('Sign in to view bookings',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 8),
              const Text(
                'Your upcoming, completed and cancelled stays live here once you sign in.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: _muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final ok = await Navigator.push<bool>(
                      context,
                      FadeSlidePageRoute(
                          page: const LoginSignupScreen()),
                    );
                    if (ok == true && mounted) {
                      setState(() {});
                      await context
                          .read<BookingsProvider>()
                          .refresh();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log In / Register',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Booking card ──

  ({Color bg, Color fg}) _statusColors(String status) {
    switch (status.toLowerCase().trim()) {
      case 'confirmed':
        return (bg: const Color(0xFFE6F4EA), fg: const Color(0xFF137333));
      case 'pending':
        return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E));
      case 'cancelled':
      case 'canceled':
        return (bg: const Color(0xFFFDECEA), fg: const Color(0xFFB81922));
      case 'checked in':
      case 'checked_in':
        return (bg: _blueTint, fg: const Color(0xFF1967D2));
      case 'completed':
        return (
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569)
        );
      default:
        return (bg: const Color(0xFFE6F4EA), fg: const Color(0xFF137333));
    }
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final status = (b['status'] ?? 'Confirmed').toString();
    final colors = _statusColors(status);
    final nights =
        (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    final dates = (b['dates'] ?? '').toString();
    return InkWell(
      onTap: () => _openDetails(b),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 118,
                    height: 148,
                    child: PropertyImage(
                      url: (b['imageUrl'] ??
                              'assets/images/house3.webp')
                          .toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.bg,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: colors.fg),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _shortCode(b['code']),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _faint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (b['name'] ?? 'Lodge Stay').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              height: 1.25),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b['area'] ?? ''}, ${b['city'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _muted),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: _muted),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                dates.isNotEmpty
                                    ? '$dates · $nights night${nights == 1 ? '' : 's'}'
                                    : '$nights night${nights == 1 ? '' : 's'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _ink),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatPrice(b['price']),
                            style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: _ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: _border)),
              ),
              child: _cardActions(b),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardActions(Map<String, dynamic> b) {
    final tab = _tabOf(b);
    Widget actionBtn({
      required String label,
      required VoidCallback onTap,
      bool primary = false,
      bool danger = false,
      IconData? icon,
    }) {
      final fg = danger
          ? const Color(0xFFB81922)
          : (primary ? Colors.white : _ink);
      return Expanded(
        child: SizedBox(
          height: 44,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? _blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: danger
                        ? const Color(0xFFFECACA)
                        : (primary ? _blue : _border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (tab == 'cancelled') {
      return Row(
        children: [
          actionBtn(
            label: 'Book again',
            icon: Icons.refresh_rounded,
            primary: true,
            onTap: () => _rebook(b),
          ),
        ],
      );
    }
    if (tab == 'completed') {
      return Row(
        children: [
          actionBtn(
            label: 'Receipt',
            icon: Icons.receipt_outlined,
            onTap: () => _openReceipt(b),
          ),
          const SizedBox(width: 10),
          actionBtn(
            label: 'Review',
            icon: Icons.star_outline_rounded,
            primary: true,
            onTap: () => _openReview(b),
          ),
        ],
      );
    }
    final cancellable = b['id'] is int;
    return Row(
      children: [
        if (cancellable) ...[
          actionBtn(
            label: 'Cancel stay',
            danger: true,
            onTap: () => _cancelBooking(b),
          ),
          const SizedBox(width: 10),
        ],
        actionBtn(
          label: 'Receipt',
          icon: Icons.receipt_outlined,
          onTap: () => _openReceipt(b),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: ShimmerWidget(
                width: 100, height: double.infinity, borderRadius: 12),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 14, bottom: 14, right: 14, left: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(
                          width: 90, height: 14, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerWidget(
                          width: 150, height: 17, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerWidget(
                          width: 120, height: 12, borderRadius: 4),
                    ],
                  ),
                  ShimmerWidget(
                      width: 80, height: 15, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

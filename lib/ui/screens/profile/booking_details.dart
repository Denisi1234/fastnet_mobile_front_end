import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/guest_messages.dart';
import 'package:fastnet_mobile_front_end/providers/bookings_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/write_review_screen.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';

/// Full details for a single booking row (same map shape as
/// `BookingsData.list` entries produced by `syncFromApi`).
///
/// Reached from [BookingsScreen] via `_openDetails`. Shows the property
/// header, status pill, booking code, stay facts, payment summary, and
/// the same per-status actions as the list card (receipt / review /
/// rebook / server-side cancel).
class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  // Carbon tokens (same system as the web: sharp corners, hairlines,
  // flat fills — matches the bookings list screen).
  static const _ink = Color(0xFF161616);
  static const _muted = Color(0xFF525252);
  static const _faint = Color(0xFF6F6F6F);
  static const _border = Color(0xFFE0E0E0);
  static const _pageBg = Color(0xFFF4F4F4);
  static const _blue = Color(0xFF0F62FE);
  static const _blueTint = Color(0xFFEDF5FF);
  static const _greenBg = Color(0xFFDEFBE6);
  static const _greenFg = Color(0xFF0E6027);
  static const _redBg = Color(0xFFFDE7E9);
  static const _redFg = Color(0xFFA2191F);
  static const _amberBg = Color(0xFFFCF4D6);
  static const _amberFg = Color(0xFF8E6A00);
  static const _infoBg = Color(0xFFD0E2FF);
  static const _infoFg = Color(0xFF0043CE);

  String _formatPrice(dynamic price) {
    final v = price is num
        ? price.toInt()
        : int.tryParse(price?.toString() ?? '') ?? 0;
    return 'TSh ${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  ({Color bg, Color fg}) _statusColors(String status) {
    switch (status.toLowerCase().trim()) {
      case 'confirmed':
        return (bg: _greenBg, fg: _greenFg);
      case 'pending':
        return (bg: _amberBg, fg: _amberFg);
      case 'cancelled':
      case 'canceled':
        return (bg: _redBg, fg: _redFg);
      case 'checked in':
      case 'checked_in':
        return (bg: _infoBg, fg: _infoFg);
      case 'completed':
        return (
          bg: const Color(0xFFE8E8E8),
          fg: const Color(0xFF525252)
        );
      default:
        return (bg: _greenBg, fg: _greenFg);
    }
  }

  String _tabOf(Map<String, dynamic> b) {
    final s = (b['status'] ?? '').toString().toLowerCase().trim();
    if (s == 'cancelled' || s == 'canceled') return 'cancelled';
    if (s == 'completed') return 'completed';
    return 'upcoming';
  }

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

  /// Receipt from server truth: refreshes the booking, registers the
  /// authoritative server receipt record, then renders. Falls back to the
  /// cached row when offline so the receipt still opens.
  Future<void> _openReceipt(
      BuildContext context, Map<String, dynamic> b) async {
    HapticFeedback.selectionClick();
    final rawId = b['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    Map<String, dynamic>? fresh;
    if (id != null) {
      _showWorking(context);
      fresh = await ApiService.fetchBookingDetail(id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }

    final code = (b['code']?.toString().isNotEmpty ?? false)
        ? b['code'].toString()
        : 'Pending';
    final name = (b['name'] ?? 'Lodge Stay').toString();
    final area = (b['area'] ?? '').toString();
    final city = (b['city'] ?? '').toString();
    final price = (b['price'] is num)
        ? (b['price'] as num).toInt()
        : int.tryParse(b['price']?.toString() ?? '') ?? 0;

    // Server-side receipt record (same file per code — safe to refresh).
    try {
      await ApiService.generateReceipt(
        bookingCode: code,
        guestName: UserSession.userName,
        propertyName: name,
        propertyAddress: '$area, $city',
        checkIn: fresh?['check_in']?.toString() ??
            b['check_in']?.toString(),
        checkOut: fresh?['check_out']?.toString() ??
            b['check_out']?.toString(),
        totalPrice: price,
      );
    } catch (_) {
      // Local receipt below still renders from cached/server fields.
    }
    if (!context.mounted) return;

    final dest = _resolveDestination(b);
    final nights =
        (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    final total = (fresh?['total_price'] is num)
        ? (fresh!['total_price'] as num).toInt()
        : (int.tryParse(fresh?['total_price']?.toString() ?? '') ?? price);
    final perNight = nights > 0 ? (total ~/ nights) : total;
    final method = (fresh?['payment_method']?.toString().isNotEmpty ?? false)
        ? fresh!['payment_method'].toString()
        : (b['payment_method'] ?? 'Vodacom M-Pesa').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          bookingCode: code,
          lodgeName: name,
          roomNumber: b['name'].toString().contains('Room')
              ? b['name'].toString().split('Room')[1].trim()
              : (b['roomNumber']?.toString() ?? '—'),
          location: '$area, $city',
          dates: (b['dates'] ?? '').toString(),
          guestName: UserSession.userName ?? 'Traveler',
          guestPhone: UserSession.userPhone ?? '',
          paymentMethod: method,
          numNights: nights,
          pricePerNight: perNight > 0 ? perNight : dest.price,
          paymentTime: b['paymentTime']?.toString(),
          verifyUrl: (b['verify_url']?.toString().isNotEmpty ?? false)
              ? b['verify_url'].toString()
              : null,
        ),
      ),
    );
  }

  void _openReview(BuildContext context, Map<String, dynamic> b) {
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

  void _rebook(BuildContext context, Map<String, dynamic> b) {
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
    final nights = (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: BookRoom(destination: dest, numNights: nights),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final uri = Uri.parse(AppConstants.supportUrl);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not open support page. Please visit ${AppConstants.supportUrlDisplay}.')),
      );
    }
  }

  /// Host contact for guest messaging: one authenticated detail fetch,
  /// resolved on demand so the cached list rows stay lean. Null when
  /// unresolvable (offline, unlisted property) — callers degrade gracefully.
  Future<({int hostId, String hostName, String lodge})?> _resolveHost(
      Map<String, dynamic> b) async {
    final lodge = (b['name'] ?? 'Lodge Stay').toString();
    final rawId = b['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
    if (id == null) return null;
    final detail = await ApiService.fetchBookingDetail(id);
    if (detail == null) return null;
    try {
      final room = detail['room'] is Map
          ? Map<String, dynamic>.from(detail['room'] as Map)
          : null;
      final property = room?['property'] is Map
          ? Map<String, dynamic>.from(room!['property'] as Map)
          : null;
      final host = property?['host'] is Map
          ? Map<String, dynamic>.from(property!['host'] as Map)
          : null;
      final rawHostId = host?['id'] ?? property?['host_id'];
      final hostId = rawHostId is int
          ? rawHostId
          : int.tryParse(rawHostId?.toString() ?? '');
      if (hostId == null) return null;
      final hostName = (host?['name']?.toString().isNotEmpty ?? false)
          ? (host!['name'] as String)
          : 'Your host';
      return (hostId: hostId, hostName: hostName, lodge: lodge);
    } catch (_) {
      return null;
    }
  }

  void _showWorking(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Future<void> _messageHost(
      BuildContext context, Map<String, dynamic> b) async {
    HapticFeedback.selectionClick();
    _showWorking(context);
    final host = await _resolveHost(b);
    if (!context.mounted) return;
    Navigator.pop(context);
    if (host == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not reach the property right now. Try again or contact support.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuestChatDetailScreen(thread: {
          'hostId': host.hostId,
          'hostName': host.hostName,
          'lodgeName': host.lodge,
          'avatar': 'assets/images/man2.jpeg',
          'isOnline': false,
          'isReal': true,
          'unread': false,
          'lastMessage': '',
          'time': '',
        }),
      ),
    );
  }

  /// Guest arrival notice: check-in itself is confirmed by the host
  /// (backend enforces host-only arrival), so this sends a real
  /// "guest has arrived" message the host can act on.
  Future<void> _arrivalNotice(
      BuildContext context, Map<String, dynamic> b) async {
    final code = (b['code']?.toString().isNotEmpty ?? false)
        ? b['code'].toString()
        : 'your booking';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        title: const Text("You've arrived?",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
          'This lets the property know you are here so they can confirm your check-in.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Not yet', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
            ),
            child: const Text('Notify host',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    _showWorking(context);
    final host = await _resolveHost(b);
    if (!context.mounted) return;
    Navigator.pop(context);
    if (host == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not reach the property right now. Please try again.')),
      );
      return;
    }
    final guest = UserSession.userName ?? 'A guest';
    final sent = await ApiService.sendMessage(
      recipientId: host.hostId,
      lodgeName: host.lodge,
      text:
          'Hello! $guest has arrived for booking $code. Please confirm check-in when ready.',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(sent != null
              ? 'Host notified — they will confirm your check-in.'
              : 'Could not reach the property. Please try again.'),
        ),
      );
  }

  /// Real date change (quote → confirm → apply): live availability and
  /// reprice from the backend, applied server-side with host notification.
  Future<void> _requestChange(
      BuildContext context, Map<String, dynamic> b) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Choose new dates',
    );
    if (range == null || !context.mounted) return;

    final rawId = b['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Only confirmed server bookings can be moved. Pull to refresh and try again.')),
      );
      return;
    }

    _showWorking(context);
    final quote = await ApiService.rescheduleQuote(
        id, _isoDay(range.start), _isoDay(range.end));
    if (!context.mounted) return;
    Navigator.pop(context);

    final valid = quote?['valid'] == true;
    if (!valid) {
      final msg = (quote?['message']?.toString().isNotEmpty ?? false)
          ? quote!['message'].toString()
          : (ApiService.lastError ??
              'Those dates are unavailable for this room.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    final nights = (quote!['nights'] is num)
        ? (quote['nights'] as num).toInt()
        : range.end.difference(range.start).inDays;
    final newTotal = (quote['new_total'] is num)
        ? (quote['new_total'] as num).toInt()
        : 0;
    final diff = (quote['diff'] is num)
        ? (quote['diff'] as num).toDouble()
        : 0.0;
    final balanceDue = (quote['balance_due'] is num)
        ? (quote['balance_due'] as num).toDouble()
        : 0.0;
    final diffLine = diff > 0
        ? '+${_formatPrice(diff.abs().toInt())} extra'
            '${balanceDue > 0 ? ' — payable at the property' : ''}'
        : diff < 0
            ? '−${_formatPrice(diff.abs().toInt())} (refunds via support)'
            : 'No price change';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        title: const Text('Confirm date change',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _quoteRow('Current', (b['dates'] ?? '—').toString()),
            _quoteRow('New',
                '${_fmtDay(range.start)} → ${_fmtDay(range.end)}'),
            _quoteRow('Nights', '$nights'),
            _quoteRow('New total', _formatPrice(newTotal)),
            _quoteRow('Difference', diffLine),
            const SizedBox(height: 8),
            Text(
              (quote['message'] ?? '').toString(),
              style: const TextStyle(
                  fontSize: 12.5, color: _muted, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Back', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
            ),
            child: const Text('Move booking',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    _showWorking(context);
    final result = await ApiService.rescheduleApply(
        id, _isoDay(range.start), _isoDay(range.end));
    if (!context.mounted) return;
    Navigator.pop(context);
    if (result != null && result['status'] == 'success') {
      await context.read<BookingsProvider>().refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text((result['message']?.toString().isNotEmpty ??
                        false)
                    ? result['message'].toString()
                    : 'Booking moved to the new dates.'),
          ),
        );
      Navigator.pop(context);
    } else {
      final msg = (result?['message']?.toString().isNotEmpty ?? false)
          ? result!['message'].toString()
          : (ApiService.lastError ?? 'Could not move the booking.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Widget _quoteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label,
                style: const TextStyle(fontSize: 12.5, color: _faint)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
          ),
        ],
      ),
    );
  }

  String _isoDay(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _fmtDay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// True once the stay's check-in day has arrived (cached rows without
  /// dates never qualify).
  bool _arrivalDue(Map<String, dynamic> b) {
    final day = _checkinDay(b);
    if (day == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !day.isAfter(today);
  }

  Future<void> _cancelBooking(
      BuildContext context, Map<String, dynamic> b) async {
    final id = b['id'];
    final code = b['code']?.toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        title: const Text('Cancel this stay?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Booking ${(code ?? '').toString().isNotEmpty ? code : ''} will be cancelled. This action cannot be undone.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep stay', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _redFg,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
            ),
            child: const Text('Cancel stay',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final ok = await context.read<BookingsProvider>().cancelOnServer(
          id: id is int ? id : int.tryParse(id?.toString() ?? ''),
          code: code,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Stay cancelled.' : 'Could not cancel. Please try again.'),
        ),
      );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final status = (b['status'] ?? 'Confirmed').toString();
    final colors = _statusColors(status);
    final tab = _tabOf(b);
    final nights = (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    final dates = (b['dates'] ?? '').toString();
    final code = (b['code']?.toString().isNotEmpty ?? false)
        ? b['code'].toString()
        : 'Pending';
    final paymentStatus =
        (b['payment_status']?.toString().isNotEmpty ?? false)
            ? b['payment_status'].toString()
            : '—';
    final room = b['name'].toString().contains('Room')
        ? b['name'].toString().split('Room')[1].trim()
        : (b['roomNumber']?.toString() ?? '—');

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking details',
            style: TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: PropertyImage(
                      url: (b['imageUrl'] ?? 'assets/images/house3.webp')
                          .toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: colors.fg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (b['name'] ?? 'Lodge Stay').toString(),
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: _muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${b['area'] ?? ''}, ${b['city'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 13, color: _muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: _border, height: 1),
                  const SizedBox(height: 12),
                  _row('Booking code', code, mono: true),
                  _row('Dates',
                      dates.isNotEmpty ? dates : '—'),
                  _row('Nights',
                      '$nights night${nights == 1 ? '' : 's'}'),
                  _row('Room', room.isNotEmpty ? room : '—'),
                  _row('Payment', paymentStatus),
                  if (b['id'] != null)
                    _row('Booking ID', b['id'].toString()),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total paid',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _muted)),
                      Text(
                        _formatPrice(b['price']),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _blueTint,
                borderRadius: BorderRadius.circular(0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: _blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Show this booking code at check-in along with your payment confirmation.',
                      style: TextStyle(
                          fontSize: 12.5, color: _ink, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (tab == 'upcoming') ...[
              _checkinCard(context, b, status),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 4),
            if (tab == 'cancelled')
              _primaryBtn(context,
                  label: 'Book again',
                  icon: Icons.refresh_rounded,
                  onTap: () => _rebook(context, b))
            else if (tab == 'completed')
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionPair([
                    _outlineBtn(context,
                        label: 'Receipt',
                        icon: Icons.receipt_outlined,
                        onTap: () => _openReceipt(context, b)),
                    _primaryBtn(context,
                        label: 'Review',
                        icon: Icons.star_outline_rounded,
                        onTap: () => _openReview(context, b)),
                  ]),
                  const SizedBox(height: 10),
                  _outlineBtn(context,
                      label: 'Message property',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => _messageHost(context, b)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionPair([
                    if (b['id'] is int)
                      _dangerBtn(context,
                          label: 'Cancel stay',
                          onTap: () => _cancelBooking(context, b)),
                    _outlineBtn(context,
                        label: 'Receipt',
                        icon: Icons.receipt_outlined,
                        onTap: () => _openReceipt(context, b)),
                  ]),
                  const SizedBox(height: 10),
                  _actionPair([
                    _outlineBtn(context,
                        label: 'Message property',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => _messageHost(context, b)),
                    _outlineBtn(context,
                        label: 'Change dates',
                        icon: Icons.edit_calendar_outlined,
                        onTap: () => _requestChange(context, b)),
                  ]),
                  if (status.toLowerCase() == 'completed' ||
                      tab == 'completed') ...[
                    const SizedBox(height: 10),
                    _primaryBtn(context,
                        label: 'Write a review',
                        icon: Icons.star_outline_rounded,
                        onTap: () => _openReview(context, b)),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => _openSupport(context),
                child: const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12.5, color: _muted),
                    children: [
                      TextSpan(text: 'Need help with this stay? '),
                      TextSpan(
                        text: 'Visit the help center',
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check-in day (date only) from the synced ISO timestamp, if present.
  DateTime? _checkinDay(Map<String, dynamic> b) {
    final iso = (b['check_in']?.toString() ?? '').trim();
    if (iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Always-visible check-in guide (upcoming stays): first-time guests see
  /// exactly what check-in involves and when it opens; on the day, the
  /// arrival button notifies the host. States: checked-in / open / countdown.
  Widget _checkinCard(
      BuildContext context, Map<String, dynamic> b, String status) {
    final checkedIn = status.toLowerCase().contains('check');
    final due = _arrivalDue(b);
    final inDay = _checkinDay(b);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    late final String title;
    late final String sub;
    late final Color accent;
    late final Color tint;
    late final IconData icon;
    String? chip;
    if (checkedIn) {
      title = 'Checked in — enjoy your stay';
      sub =
          'Your host has confirmed your arrival. For anything during your stay, message the property from the buttons below.';
      accent = _greenFg;
      tint = _greenBg;
      icon = Icons.check_circle_rounded;
    } else if (due) {
      title = 'Check-in is open';
      sub =
          'You can arrive from today. Notify the property, then show your receipt QR code and a photo ID at the front desk.';
      accent = _blue;
      tint = _blueTint;
      icon = Icons.flight_land_rounded;
    } else if (inDay != null) {
      final days = inDay.difference(today).inDays;
      title = 'Check-in opens ${_fmtDay(inDay)}';
      sub =
          'Your stay starts ${days <= 1 ? 'tomorrow' : 'in $days days'}. Come back on the day and notify the property from here.';
      accent = _amberFg;
      tint = _amberBg;
      icon = Icons.schedule_rounded;
      chip = days <= 1 ? 'Opens tomorrow' : '$days days to go';
    } else {
      title = 'Check-in';
      sub =
          'Pull to refresh your bookings to load the check-in date, then notify the property on arrival day.';
      accent = _muted;
      tint = const Color(0xFFE8E8E8);
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.25)),
                    if (chip != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: Text(chip,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: _muted, height: 1.5)),
          if (!checkedIn) ...[
            const SizedBox(height: 12),
            _checkinStep('1',
                'On arrival day, tap “I’ve arrived” to notify the property.'),
            const SizedBox(height: 8),
            _checkinStep('2',
                'Show your receipt QR code and a photo ID at the front desk.'),
            const SizedBox(height: 8),
            _checkinStep(
                '3', 'The host confirms — your stay flips to Checked In.'),
          ],
          if (due && !checkedIn) ...[
            const SizedBox(height: 14),
            _primaryBtn(context,
                label: "I've arrived — notify host",
                icon: Icons.flight_land_rounded,
                onTap: () => _arrivalNotice(context, b)),
          ],
        ],
      ),
    );
  }

  Widget _checkinStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _ink,
            shape: BoxShape.circle,
          ),
          child: Text(number,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: _ink, height: 1.45)),
          ),
        ),
      ],
    );
  }

  /// Two action buttons side by side on normal phones, stacked full-width
  /// on narrow screens (< 360 logical pixels) so labels never clip.
  Widget _actionPair(List<Widget> buttons) {
    assert(buttons.isNotEmpty);
    if (buttons.length == 1) return buttons.first;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buttons[0],
              const SizedBox(height: 10),
              buttons[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 10),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12.5, color: _faint)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _ink,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryBtn(BuildContext context,
      {required String label, IconData? icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn(BuildContext context,
      {required String label, IconData? icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: _ink),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _dangerBtn(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _redFg,
          side: const BorderSide(color: Color(0xFFF4C7C7)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Colors.white,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

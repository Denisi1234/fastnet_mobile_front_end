import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fastnet_mobile_front_end/models/destination.dart';
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

  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _faint = Color(0xFF9AA0A6);
  static const _border = Color(0xFFE8EAED);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _blue = Color(0xFF1A73E8);
  static const _blueTint = Color(0xFFE8F0FE);

  String _formatPrice(dynamic price) {
    final v = price is num
        ? price.toInt()
        : int.tryParse(price?.toString() ?? '') ?? 0;
    return 'TSh ${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

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
        return (bg: const Color(0xFFF1F5F9), fg: const Color(0xFF475569));
      default:
        return (bg: const Color(0xFFE6F4EA), fg: const Color(0xFF137333));
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

  void _openReceipt(BuildContext context, Map<String, dynamic> b) {
    HapticFeedback.selectionClick();
    final dest = _resolveDestination(b);
    final nights = (b['nights'] is num) ? (b['nights'] as num).toInt() : 1;
    final total = (b['price'] is num)
        ? (b['price'] as num).toInt()
        : int.tryParse(b['price']?.toString() ?? '') ?? 0;
    final perNight = nights > 0 ? (total ~/ nights) : total;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          bookingCode: (b['code']?.toString().isNotEmpty ?? false)
              ? b['code'].toString()
              : 'Pending',
          lodgeName: (b['name'] ?? 'Lodge Stay').toString(),
          roomNumber: b['name'].toString().contains('Room')
              ? b['name'].toString().split('Room')[1].trim()
              : (b['roomNumber']?.toString() ?? '—'),
          location: '${b['area'] ?? ''}, ${b['city'] ?? ''}',
          dates: (b['dates'] ?? '').toString(),
          guestName: UserSession.userName ?? 'Traveler',
          guestPhone: UserSession.userPhone ?? '',
          paymentMethod: (b['payment_method'] ?? 'Vodacom M-Pesa').toString(),
          numNights: nights,
          pricePerNight: perNight > 0 ? perNight : dest.price,
          paymentTime: b['paymentTime']?.toString(),
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

  Future<void> _cancelBooking(
      BuildContext context, Map<String, dynamic> b) async {
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
            child: const Text('Keep stay', style: TextStyle(color: _muted)),
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
              borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(16),
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
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),
            if (tab == 'cancelled')
              _primaryBtn(context,
                  label: 'Book again',
                  icon: Icons.refresh_rounded,
                  onTap: () => _rebook(context, b))
            else if (tab == 'completed')
              Row(
                children: [
                  Expanded(
                      child: _outlineBtn(context,
                          label: 'Receipt',
                          icon: Icons.receipt_outlined,
                          onTap: () => _openReceipt(context, b))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _primaryBtn(context,
                          label: 'Review',
                          icon: Icons.star_outline_rounded,
                          onTap: () => _openReview(context, b))),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (b['id'] is int)
                        Expanded(
                            child: _dangerBtn(context,
                                label: 'Cancel stay',
                                onTap: () => _cancelBooking(context, b))),
                      if (b['id'] is int) const SizedBox(width: 10),
                      Expanded(
                          child: _outlineBtn(context,
                              label: 'Receipt',
                              icon: Icons.receipt_outlined,
                              onTap: () => _openReceipt(context, b))),
                    ],
                  ),
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
          ],
        ),
      ),
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
      height: 50,
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB81922),
          side: const BorderSide(color: Color(0xFFFECACA)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

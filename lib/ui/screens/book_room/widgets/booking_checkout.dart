import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/services/draft_booking_service.dart';
import 'package:fastnet_mobile_front_end/services/receipt_pdf_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/reward_animations.dart';

/// Checkout — mobile layout of web `/bookingpage-03`
/// (`bookingpage-03.css`, Agoda style).
///
/// Compact stepper (Step 2 of 3 + Secure), price-guarantee timer bar,
/// stay summary card first, mobile-money payment card, email note, pay
/// card with inline errors, and the Agoda price breakdown:
///
///   N × Room (nights) · Mobile-money processing (1%) ·
///   Taxes & fees Included · dashed Total.
///
/// The backend engine is untouched: room lock/unlock, 10-minute hold,
/// quote via `POST /bookings/calculate`, `POST /bookings/create`,
/// AzamPay `POST /payments/checkout`, e-receipt + bookings sync.
/// No simulation dialogs, no card brands (the backend rejects cards —
/// same rule as the web).
class BookingCheckoutScreen extends StatefulWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;
  final String selectedRoomNumber;
  final int selectedRoomId;

  const BookingCheckoutScreen({
    Key? key,
    required this.destination,
    required this.selectedDatesText,
    required this.numNights,
    required this.selectedRoomNumber,
    required this.selectedRoomId,
  }) : super(key: key);

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  // Web `bookingpage-03.css` tokens.
  static const _ink = Color(0xFF0F172A);
  static const _body = Color(0xFF334155);
  static const _muted = Color(0xFF64748B);
  static const _faint = Color(0xFF94A3B8);
  static const _pageBg = Color(0xFFF4F4F4);
  static const _cardBorder = Color(0xFFCBD5E1);
  static const _hairline = Color(0xFFE2E8F0);
  static const _boxBg = Color(0xFFF8FAFC);
  static const _blue = Color(0xFF0F62FE);
  static const _green = Color(0xFF059669);
  static const _timerBg = Color(0xFFFFFBEB);
  static const _timerBorder = Color(0xFFFEF3C7);
  static const _timerFg = Color(0xFF92400E);
  static const _timerStrong = Color(0xFFB45309);
  static const _dangerBg = Color(0xFFFDECEA);
  static const _dangerBorder = Color(0xFFF5C6CB);
  static const _dangerFg = Color(0xFF7D2E2E);

  // Mobile-money networks (web `cds-pay-tile` set — no card brands).
  static const _methods = [
    {
      'key': 'Vodacom M-Pesa',
      'title': 'M-Pesa',
      'sub': 'Vodacom',
      'asset': 'assets/images/vodacom_logo.png',
    },
    {
      'key': 'Tigo Pesa',
      'title': 'Tigo Pesa',
      'sub': 'Tigo',
      'asset': 'assets/images/mix by yas.jpg',
    },
    {
      'key': 'Airtel Money',
      'title': 'Airtel Money',
      'sub': 'Airtel',
      'asset': 'assets/images/airtel logo.png',
    },
    {
      'key': 'Halotel HaloPesa',
      'title': 'HaloPesa',
      'sub': 'Halotel',
      'asset': 'assets/images/halotel_logo.jpg',
    },
  ];

  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _guestNameCtrl = TextEditingController();
  final _guestEmailCtrl = TextEditingController();

  String _selectedPaymentMethod = 'Vodacom M-Pesa';
  bool _isLoading = false;
  int _loadingStep = 0;
  bool _bookingCompleted = false;
  bool _holdExpired = false;
  Timer? _holdTimer;
  int _remainingSeconds = 600; // 10-minute room lock, like the web guarantee
  String? _formError;

  // Real quote (`POST /bookings/calculate`, web `BookingsQuoteTrait`);
  // null until it lands — local math below is the fallback, never shown
  // as a quote.
  bool _quoteLoading = true;
  double? _qSubtotal;
  double? _qFee;
  double? _qTotal;

  late String _currentDatesText;
  late int _currentNumNights;
  late int _currentGuestsCount;

  bool get _loggedIn => UserSession.isLoggedIn;

  double get _roomPrice =>
      _qSubtotal ??
      (widget.destination.price * _currentNumNights).toDouble();
  double get _fee {
    if (_qFee != null) return _qFee!;
    // Quote gave a total but no itemized fee: derive it so the rows
    // always add up instead of mixing quote and local math.
    final t = _qTotal;
    if (t != null) {
      final derived = t - _roomPrice;
      if (derived >= 0) return derived;
    }
    return (_roomPrice * 0.01).roundToDouble();
  }

  double get _total => _qTotal ?? (_roomPrice + _fee);

  String get _receiptEmail => _loggedIn
      ? (UserSession.userEmail ?? '')
      : _guestEmailCtrl.text.trim();

  @override
  void initState() {
    super.initState();
    _currentDatesText = widget.selectedDatesText;
    _currentNumNights = widget.numNights > 0 ? widget.numNights : 1;
    _currentGuestsCount =
        widget.destination.guests > 0 ? widget.destination.guests : 1;
    _acquireRealTimeLock();
    _startHoldTimer();
    _saveDraft();
    _fetchQuote();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _guestNameCtrl.dispose();
    _guestEmailCtrl.dispose();
    if (!_bookingCompleted) {
      ApiService.unlockRoom(widget.selectedRoomId);
      // Draft stays so user can resume
    } else {
      // Booking completed — clear draft
      DraftBookingService.clear();
    }
    super.dispose();
  }

  void _saveDraft() {
    DraftBookingService.save(
      destinationJson: widget.destination.toJson(),
      selectedDatesText: widget.selectedDatesText,
      numNights: widget.numNights,
      selectedRoomNumber: widget.selectedRoomNumber,
      selectedRoomId: widget.selectedRoomId,
    );
  }

  void _acquireRealTimeLock() async {
    final dates = parseDateRange(widget.selectedDatesText);
    final checkIn = dates.isNotEmpty ? dates[0] : _checkInIso();
    final checkOut = dates.length > 1 ? dates[1] : _checkOutIso();
    final response =
        await ApiService.lockRoom(widget.selectedRoomId, checkIn, checkOut);
    if (response == null) return;

    final status = response['status'] as int;
    if (status == 409) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Room Unavailable',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                response['body']['message'] ??
                    'This room is currently held by another customer. Please choose a different room.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Pop dialog
                    Navigator.pop(context); // Pop checkout screen
                  },
                  child: Text('OK',
                      style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    }
  }

  List<String> parseDateRange(String dateRangeText) {
    try {
      final now = DateTime.now();
      final currentYear = now.year;
      const monthsAbbr = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      final parts =
          dateRangeText.split('–').map((e) => e.trim()).toList();
      if (parts.length != 2) throw Exception("Invalid range parts");

      final startPart = parts[0];
      final endPart = parts[1];

      final startTokens = startPart.split(' ');
      final startMonthStr = startTokens[0];
      final startDayVal = int.parse(startTokens[1]);
      final startMonthVal = monthsAbbr.indexOf(startMonthStr) + 1;

      final startDate =
          DateTime(currentYear, startMonthVal, startDayVal);

      DateTime endDate;
      final endTokens = endPart.split(' ');
      if (endTokens.length == 2) {
        final endMonthStr = endTokens[0];
        final endDayVal = int.parse(endTokens[1]);
        final endMonthVal = monthsAbbr.indexOf(endMonthStr) + 1;
        endDate = DateTime(currentYear, endMonthVal, endDayVal);
      } else {
        final endDayVal = int.parse(endPart);
        endDate = DateTime(currentYear, startMonthVal, endDayVal);
      }

      final startFormatted =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endFormatted =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      return [startFormatted, endFormatted];
    } catch (_) {
      final today = DateTime.now();
      final future = today.add(const Duration(days: 3));
      final startFormatted =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final endFormatted =
          "${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}";
      return [startFormatted, endFormatted];
    }
  }

  /// Check-in / check-out for the API.
  ///
  /// The stay reaches this screen as a display label ("12 Nov 2026 - 15 Nov
  /// 2026"), parsed the same way book_room.dart parses it. Anything
  /// unparseable falls back to today + the selected night count rather than
  /// throwing, so a malformed label can never block a booking.
  ({DateTime start, DateTime end}) _stayDates() {
    final nights = _currentNumNights > 0 ? _currentNumNights : 1;
    final today = DateTime.now();
    final fallbackStart = DateTime(today.year, today.month, today.day);

    try {
      const monthsAbbr = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final text = _currentDatesText
          .replaceAll('–', '-')
          .replaceAll(' - ', '-')
          .trim();
      final yearMatch = RegExp(r'\d{4}').firstMatch(text);
      final year =
          yearMatch != null ? int.parse(yearMatch.group(0)!) : today.year;

      final parts = text
          .split('-')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length < 2) {
        throw const FormatException('missing end date');
      }

      DateTime parse(String part, int fallbackMonth) {
        final cleaned =
            part.replaceAll(RegExp(r',\s*\d{4}'), '').trim();
        final tokens = cleaned.split(RegExp(r'\s+'));
        final month = monthsAbbr.indexOf(tokens.first) + 1;
        if (month <= 0 || tokens.length < 2) {
          throw FormatException('bad date "$part"');
        }
        return DateTime(year, month, int.parse(tokens[1]));
      }

      return (
        start: parse(parts.first, today.month),
        end: parse(parts.last, today.month)
      );
    } catch (_) {
      return (
        start: fallbackStart,
        end: fallbackStart.add(Duration(days: nights)),
      );
    }
  }

  String _checkInIso() {
    final start = _stayDates().start;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  String _checkOutIso() {
    final end = _stayDates().end;
    return '${end.year.toString().padLeft(4, '0')}-'
        '${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
  }

  /// Real price quote (web `BookingsQuoteTrait`). Silent fallback to local
  /// math — a failed quote never blocks checkout.
  Future<void> _fetchQuote() async {
    final pid = widget.destination.id;
    if (pid == null) {
      setState(() => _quoteLoading = false);
      return;
    }
    try {
      final q = await ApiService.calculateBooking(
        propertyId: pid,
        roomId: widget.selectedRoomId,
        checkIn: _checkInIso(),
        checkOut: _checkOutIso(),
        guests: _currentGuestsCount,
      );
      if (!mounted || q == null) return;
      double? asDouble(dynamic v) => v is num
          ? v.toDouble()
          : double.tryParse(v?.toString() ?? '');
      final sub = asDouble(q['subtotal'] ?? q['room_price']);
      final fee = asDouble(
          q['azampay_fee'] ?? q['fee'] ?? q['processing_fee']);
      final tot = asDouble(
          q['total_amount'] ?? q['total'] ?? q['grand_total']);
      if (tot != null && tot > 0) {
        setState(() {
          _qSubtotal = sub;
          _qFee = fee;
          _qTotal = tot;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

  void _startHoldTimer() {
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _holdTimer?.cancel();
        if (mounted && !_holdExpired) {
          setState(() => _holdExpired = true);
          _showHoldExpiredDialog();
        }
      }
    });
  }

  void _showHoldExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hold Time Expired',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Your room lock reservation has expired. To secure this listing, please restart the checkout process.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop checkout screen
              },
              child: Text('OK',
                  style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _formatPrice(num price) {
    final v = price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return 'TSh $v';
  }

  static bool _validEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);

  void _fail(String msg, {bool focusPhone = false}) {
    HapticFeedback.selectionClick();
    setState(() => _formError = msg);
    if (focusPhone) _phoneFocus.requestFocus();
  }

  Future<void> _submitBooking() async {
    if (_holdExpired) {
      _showHoldExpiredDialog();
      return;
    }
    if (!_loggedIn) {
      if (_guestNameCtrl.text.trim().length < 2) {
        _fail('Please enter the guest full name.');
        return;
      }
      if (!_validEmail(_guestEmailCtrl.text.trim())) {
        _fail('Please enter a valid email address.');
        return;
      }
    }
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      _fail(
          'Enter your mobile money phone number to receive the payment prompt.',
          focusPhone: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _formError = null);
    await _executeFinalizeBooking();
  }

  Future<void> _executeFinalizeBooking() async {
    setState(() {
      _isLoading = true;
      _loadingStep = 0;
    });

    // Step 0: the room lock the guest is already holding is settled server-side.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() => _loadingStep = 1);

    // Step 1: create the booking for real via the backend (web parity:
    // BookingsCheckoutTrait → POST /bookings/create). Guest contact is sent
    // so logged-out guests still get an owned booking.
    final created = await ApiService.createBooking(
      widget.selectedRoomId,
      _checkInIso(),
      _checkOutIso(),
      guestName:
          _loggedIn ? UserSession.userName : _guestNameCtrl.text.trim(),
      guestEmail:
          _loggedIn ? UserSession.userEmail : _guestEmailCtrl.text.trim(),
      guestPhone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : UserSession.userPhone,
      paymentMethod: _selectedPaymentMethod,
      paymentPhone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : UserSession.userPhone,
    );

    if (!mounted) return;
    setState(() => _loadingStep = 2);

    // Backend nests the record under `booking:{...}` (BookingCreationService).
    final top = created ?? const <String, dynamic>{};
    final nested = top['booking'] is Map<String, dynamic>
        ? top['booking'] as Map<String, dynamic>
        : (top['data'] is Map<String, dynamic>
            ? top['data'] as Map<String, dynamic>
            : top);
    final serverCode =
        (top['booking_code'] ?? nested['booking_code'] ?? top['code'])
            ?.toString();
    final serverVerifyUrl =
        (top['verify_url'] ?? nested['verify_url'])?.toString();
    final bookingId = int.tryParse(
            (nested['id'] ?? top['booking_id'] ?? '').toString()) ??
        0;

    if (serverCode == null || serverCode.isEmpty) {
      // No server record (offline/validation). Surface the backend message
      // instead of inventing a "Confirmed" booking.
      if (mounted) {
        setState(() => _isLoading = false);
        _fail(ApiService.lastError ??
            'Booking failed. Check connection and try again.');
      }
      return;
    }
    final String bookingCode = serverCode;

    // Step 2: dispatch the mobile-money push (web parity: PaymentService).
    // Only mobile-money methods reach here — no card option exists.
    String payStatus = 'pending';
    final pay = await ApiService.checkoutPayment(
      bookingId,
      _selectedPaymentMethod,
      bookingCode: serverCode,
      phoneNumber: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : UserSession.userPhone,
    );
    if (pay != null) {
      payStatus =
          (pay['payment_status'] ?? pay['status'] ?? 'pending').toString();
    } else if (mounted) {
      _fail(ApiService.lastError ??
          'Payment request failed — booking is saved as pending.');
    }

    // Prefer the totals the server issued.
    final roomTotal = _roomPrice;
    final fee = _fee;
    final grandTotal = _total;

    if (!mounted) return;
    setState(() {
      _loadingStep = 3;
      _isLoading = false;
    });

    final dt = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    var hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final paymentTimeStr = '$month $day, $year - $hourStr:$minuteStr $period';

    final guestName = _loggedIn
        ? (UserSession.userName ?? 'Guest User')
        : _guestNameCtrl.text.trim();
    final guestEmail =
        _loggedIn ? UserSession.userEmail : _guestEmailCtrl.text.trim();

    final bookingData = {
      'id': bookingId,
      'name':
          '${widget.destination.name} - Room ${widget.selectedRoomNumber}',
      'city': widget.destination.city,
      'area': widget.destination.area,
      'dates': _currentDatesText,
      'nights': _currentNumNights,
      'guests': _currentGuestsCount,
      'price': grandTotal,
      'code': bookingCode,
      'imageUrl': widget.destination.imageUrl,
      'status': (nested['status'] ?? top['status'] ?? '').toString().isNotEmpty
          ? (nested['status'] ?? top['status']).toString()
          : 'Pending',
      'payment_status': payStatus,
      'paymentTime': paymentTimeStr,
      'check_in': _checkInIso(),
      'check_out': _checkOutIso(),
      'verify_url': (serverVerifyUrl?.isNotEmpty ?? false)
          ? serverVerifyUrl
          : '',
    };
    BookingsData.list.add(bookingData);
    await BookingsData.save();

    // E-receipt via the backend (shared with web `/booking-receipt`).
    try {
      await ApiService.generateReceipt(
        bookingCode: bookingCode,
        guestName: guestName,
        propertyName: widget.destination.name,
        propertyAddress:
            '${widget.destination.area}, ${widget.destination.city}',
        checkIn: _checkInIso(),
        checkOut: _checkOutIso(),
        totalPrice: grandTotal,
      );
    } catch (_) {}

    if (!mounted) return;
    _bookingCompleted = true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSuccessScreen(
          destination: widget.destination,
          selectedDatesText: _currentDatesText,
          numNights: _currentNumNights,
          guestName: guestName,
          guestPhone: _phoneCtrl.text.trim().isNotEmpty
              ? _phoneCtrl.text.trim()
              : (UserSession.userPhone ?? ''),
          paymentMethod: _selectedPaymentMethod,
          bookingCode: bookingCode,
          selectedRoomNumber: widget.selectedRoomNumber,
          paymentTime: paymentTimeStr,
          total: grandTotal,
          roomTotal: roomTotal,
          fee: fee,
          guestEmail: guestEmail,
          paymentPhone: _phoneCtrl.text.trim(),
          paid: payStatus.toLowerCase() == 'paid',
          paymentStatus: payStatus,
          verifyUrl: serverVerifyUrl,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _selectDates() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: now.add(const Duration(days: 1)),
        end: now.add(Duration(days: 1 + _currentNumNights)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F62FE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final nights = picked.end.difference(picked.start).inDays;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final startMonth = months[picked.start.month - 1];
      final endMonth = months[picked.end.month - 1];
      final formattedDates = picked.start.month == picked.end.month
          ? '$startMonth ${picked.start.day} – ${picked.end.day}'
          : '$startMonth ${picked.start.day} – $endMonth ${picked.end.day}';

      HapticFeedback.selectionClick();
      setState(() {
        _currentNumNights = nights > 0 ? nights : 1;
        _currentDatesText = formattedDates;
      });
      _fetchQuote();
    }
  }

  String _timerText() {
    final s = _remainingSeconds.clamp(0, 359999);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }

  String _fmtFull(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _editGuests() {
    int tempGuests = _currentGuestsCount;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Guests & Occupancy',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Guests',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _ink)),
                          Text('Adults and children',
                              style: TextStyle(
                                  fontSize: 12, color: _muted)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: tempGuests > 1
                                ? () =>
                                    setModalState(() => tempGuests--)
                                : null,
                            icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 28),
                            color: const Color(0xFF0F62FE),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text('$tempGuests',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _ink)),
                          ),
                          IconButton(
                            onPressed: tempGuests < 10
                                ? () =>
                                    setModalState(() => tempGuests++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline,
                                size: 28),
                            color: const Color(0xFF0F62FE),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentGuestsCount = tempGuests;
                        });
                        Navigator.pop(ctx);
                        _fetchQuote();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepper(),
                _timerBar(),
                _summaryCard(d),
                const SizedBox(height: 14),
                _paymentCard(),
                if (_receiptEmail.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _emailNote(),
                ],
                const SizedBox(height: 14),
                _payCard(),
                const SizedBox(height: 12),
                const Center(
                  child: Text.rich(
                    TextSpan(
                      style:
                          TextStyle(fontSize: 12, color: _muted, height: 1.5),
                      children: [
                        TextSpan(
                            text:
                                'By confirming, you agree to FastNet Stays\' '),
                        TextSpan(
                            text: 'Terms of Use',
                            style: TextStyle(color: _blue)),
                        TextSpan(text: ' and '),
                        TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: _blue)),
                        TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _loadingOverlay(),
        ],
      ),
    );
  }

  /// Compact mobile stepper (web `.agoda-checkout-stepper` mobile).
  Widget _stepper() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text('Step 2 of 3',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue)),
          ),
          const SizedBox(width: 10),
          const Text('Payment information',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const Spacer(),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: _green),
              SizedBox(width: 4),
              Text('Secure',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  /// Price-guarantee countdown (web `.agoda-timer-bar`).
  Widget _timerBar() {
    if (_holdExpired) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: _dangerBg,
          border: Border(
              bottom: BorderSide(color: _dangerBorder)),
        ),
        child: const Text(
          'Price guarantee expired — go back to refresh the live price.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _dangerFg),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _timerBg,
        border: Border(
            bottom: BorderSide(color: _timerBorder)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
              fontSize: 13, color: _timerFg, height: 1.4),
          children: [
            const TextSpan(text: 'This price is guaranteed for... '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: _timerStrong),
                  const SizedBox(width: 4),
                  Text(_timerText(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _timerStrong)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stay & price summary (web right column, stacked first on mobile).
  Widget _summaryCard(Destination d) {
    final stars = d.starRating.clamp(0, 5);
    final ci = _stayDates().start;
    final co = _stayDates().end;
    final roomTitle = 'Room ${widget.selectedRoomNumber}';
    final metaBits = [
      if (d.roomType.trim().isNotEmpty) d.roomType.trim(),
      'Max $_currentGuestsCount adult${_currentGuestsCount == 1 ? '' : 's'}',
    ];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel row.
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: PropertyImage(
                        url: d.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.3)),
                      if (stars > 0)
                        Text(
                          '★★★★★'.substring(0, stars) +
                              '☆☆☆☆☆'.substring(0, 5 - stars),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB7791F),
                              letterSpacing: 1),
                        ),
                      if (d.rating > 0)
                        Text(
                          '${d.rating.toStringAsFixed(1)} Excellent · ${d.reviewCount} reviews',
                          style: const TextStyle(
                              fontSize: 12, color: _body),
                        ),
                      Text('${d.area}, ${d.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dates row.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: _boxBg,
              border: Border(
                top: BorderSide(color: _hairline),
                bottom: BorderSide(color: _hairline),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHECK-IN',
                          style: TextStyle(
                              fontSize: 11,
                              color: _muted,
                              letterSpacing: 0.36)),
                      Text(_fmtFull(ci),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_right_alt_rounded,
                    size: 16, color: _faint),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHECK-OUT',
                          style: TextStyle(
                              fontSize: 11,
                              color: _muted,
                              letterSpacing: 0.36)),
                      Text(_fmtFull(co),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_currentNumNights Night${_currentNumNights == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _selectDates();
                      },
                      child: const Text('Change',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _blue,
                              decoration:
                                  TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Room + guests row.
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 × $roomTitle',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(metaBits.join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: _muted)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _editGuests();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: _blue),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentGuestsCount Guest${_currentGuestsCount == 1 ? '' : 's'} · Edit',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Price breakdown.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _hairline)),
            ),
            child: Column(
              children: [
                _priceRow(
                  '1 × Room ($_currentNumNights night${_currentNumNights == 1 ? '' : 's'})',
                  _formatPrice(_roomPrice.round()),
                ),
                const SizedBox(height: 8),
                _priceRow(
                  'Mobile-money processing (1%)',
                  _formatPrice(_fee.round()),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Taxes & fees',
                        style: TextStyle(
                            fontSize: 13, color: _body)),
                    Text('Included',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _green)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: _cardBorder,
                            width: 1.5,
                            style: BorderStyle.solid)),
                  ),
                  child: const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Price',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _quoteLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _blue),
                        )
                      : Text(
                          _formatPrice(_total.round()),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _blue),
                        ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Includes 1% AzamPay mobile fee · Instant confirmation',
                  style: TextStyle(
                      fontSize: 11.5, color: _muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, color: _body)),
        ),
        Text(amount,
            style:
                const TextStyle(fontSize: 13, color: _body)),
      ],
    );
  }

  // ── Payment card (web left column) ──

  Widget _paymentCard() {
    final method = _methods.firstWhere(
      (m) => m['key'] == _selectedPaymentMethod,
      orElse: () => _methods.first,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment method',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: _green),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  '256-bit SSL encrypted & secure mobile payment',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Select your mobile network',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _body)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
            ),
            itemCount: _methods.length,
            itemBuilder: (_, i) {
              final m = _methods[i];
              final selected = m['key'] == _selectedPaymentMethod;
              return _payTile(
                title: m['title']!,
                sub: m['sub']!,
                asset: m['asset']!,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                      () => _selectedPaymentMethod = m['key']!);
                },
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _boxBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay with ${method['title']} (${method['sub']})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                              color: _cardBorder, width: 1.5),
                          left: BorderSide(
                              color: _cardBorder, width: 1.5),
                          bottom: BorderSide(
                              color: _cardBorder, width: 1.5),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: const Text('+255',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _body)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 16, color: _ink),
                        decoration: const InputDecoration(
                          hintText: '712 345 678',
                          hintStyle: TextStyle(
                              fontSize: 14, color: _faint),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            borderSide: BorderSide(
                                color: _cardBorder, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            borderSide: BorderSide(
                                color: _cardBorder, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            borderSide: BorderSide(
                                color: _blue, width: 1.5),
                          ),
                        ),
                        onChanged: (_) {
                          if (_formError != null) {
                            setState(() => _formError = null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: _blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You will receive a USSD prompt on your phone to authorize payment. ${method['title']} selected.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_loggedIn) ...[
            const SizedBox(height: 14),
            const Text('Guest details',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _body)),
            const SizedBox(height: 8),
            _guestField(
              controller: _guestNameCtrl,
              hint: 'Full name',
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 8),
            _guestField(
              controller: _guestEmailCtrl,
              hint: 'Email address',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _boxBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: _muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${UserSession.userName ?? 'Guest'} · ${UserSession.userEmail ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: _body),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _payTile({
    required String title,
    required String sub,
    required String asset,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : _boxBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? _blue : _cardBorder, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: _blue.withValues(alpha: 0.25),
                      blurRadius: 0,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: selected ? _blue : _cardBorder,
                    width: 1.5),
                color:
                    selected ? _blue : Colors.white,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 36,
                height: 24,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.smartphone_rounded,
                      size: 18,
                      color: _muted),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1.2)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _ink),
      onChanged: (v) {
        if (_formError != null) {
          setState(() => _formError = null);
        }
        onChanged?.call(v);
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 14, color: _faint),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: _cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: _cardBorder, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _emailNote() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded,
              size: 16, color: _blue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: _body, height: 1.4),
                children: [
                  const TextSpan(
                      text:
                          "We'll send booking confirmation and digital receipt to "),
                  TextSpan(
                    text: _receiptEmail,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          if (_formError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _dangerBorder),
              ),
              child: Text(_formError!,
                  style: const TextStyle(
                      fontSize: 12.5, color: _dangerFg)),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  (_isLoading || _holdExpired) ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFCBD5E1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _holdExpired
                        ? 'PRICE EXPIRED'
                        : 'Pay ${_formatPrice(_total.round())}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, size: 13, color: _green),
              SizedBox(width: 4),
              Text('Instant payment processing via AzamPay',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    final steps = [
      'Securing your room…',
      'Creating your booking…',
      'Requesting the mobile-money prompt…',
    ];
    final label = steps[_loadingStep.clamp(0, steps.length - 1)];
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: _blue),
            ),
            const SizedBox(height: 16),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink)),
            const SizedBox(height: 6),
            const Text(
              'Keep this screen open and approve the prompt on your phone.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Booking confirmation — mobile layout of web `/bookingpage-success`
/// (22px title, burnt-orange reference, dashed detail grid, pill
/// actions). Paid shows the blue check card; pending shows the amber
/// hourglass card with a nudge to finish payment from My bookings.
class BookingSuccessScreen extends StatefulWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;
  final String guestName;
  final String guestPhone;
  final String paymentMethod;
  final String bookingCode;
  final String selectedRoomNumber;
  final String? paymentTime;

  final double? total;
  final double? roomTotal;
  final double? fee;
  final String? guestEmail;
  final String? paymentPhone;
  final bool paid;
  final String paymentStatus;
  final String? verifyUrl;

  const BookingSuccessScreen({
    Key? key,
    required this.destination,
    required this.selectedDatesText,
    required this.numNights,
    required this.guestName,
    required this.guestPhone,
    required this.paymentMethod,
    required this.bookingCode,
    required this.selectedRoomNumber,
    this.paymentTime,
    this.total,
    this.roomTotal,
    this.fee,
    this.guestEmail,
    this.paymentPhone,
    this.paid = true,
    this.paymentStatus = 'paid',
    this.verifyUrl,
  }) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _pageBg = Color(0xFFF4F4F4);
  static const _border = Color(0xFFE8EAED);
  static const _blue = Color(0xFF0F62FE);
  static const _burnt = Color(0xFFC2410C);
  static const _amberBg = Color(0xFFFEF3C7);
  static const _amberBorder = Color(0xFFFDE68A);
  static const _amberFg = Color(0xFFB45309);
  static const _blueTint = Color(0xFFEBF5FF);
  static const _blueTintBorder = Color(0xFFDBEAFE);

  String _fmt(int v) {
    return 'TSh ${v.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ConfettiOverlay.show(context);

      final email = widget.guestEmail?.trim().isNotEmpty == true
          ? widget.guestEmail!.trim()
          : (UserSession.userEmail ?? 'guest@fastnet.com');
      final grandTotal = (widget.total ??
              (widget.destination.price * widget.numNights))
          .toInt();

      _dispatchConfirmationEmail(
        email: email,
        grandTotal: grandTotal,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirmation email & e-receipt PDF sent to $email',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF008009),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  Future<void> _dispatchConfirmationEmail({
    required String email,
    required int grandTotal,
  }) async {
    try {
      final receiptBytes = await ReceiptPdfService.generate(
        bookingCode: widget.bookingCode,
        lodgeName: widget.destination.name,
        roomNumber: widget.selectedRoomNumber,
        location:
            '${widget.destination.area}, ${widget.destination.city}',
        dates: widget.selectedDatesText,
        guestName: widget.guestName,
        guestPhone: widget.guestPhone,
        numNights: widget.numNights,
        pricePerNight: widget.destination.price,
        paymentTime: widget.paymentTime,
      );

      String? pdfBase64;
      try {
        pdfBase64 = base64Encode(receiptBytes);
      } catch (_) {}

      await ApiService.generateReceipt(
        bookingCode: widget.bookingCode,
        guestName: widget.guestName,
        propertyName: widget.destination.name,
        propertyAddress:
            '${widget.destination.area}, ${widget.destination.city}',
        totalPrice: grandTotal,
        pdfBase64: pdfBase64,
      );
    } catch (e) {
      debugPrint('Dispatch receipt error: $e');
    }
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final paid = widget.paid;
    final total =
        (widget.total ?? (widget.destination.price * widget.numNights))
            .toInt();
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _ink),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: paid ? _blueTint : _amberBg,
                  border: Border.all(
                      color:
                          paid ? _blueTintBorder : _amberBorder),
                ),
                child: Icon(
                  paid
                      ? Icons.check_rounded
                      : Icons.hourglass_bottom_rounded,
                  size: 32,
                  color: paid ? _blue : _amberFg,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                paid
                    ? 'Your Booking Was Confirmed Successfully!'
                    : 'Booking Details',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.25),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style:
                      const TextStyle(fontSize: 14, color: _muted),
                  children: [
                    const TextSpan(text: 'Booking Reference: '),
                    TextSpan(
                      text: widget.bookingCode,
                      style: const TextStyle(
                          color: _burnt,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paid
                    ? 'A confirmation receipt has been generated for your stay.'
                    : 'Payment ${widget.paymentStatus} — this stay is not confirmed yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: paid ? _faintColor() : _amberFg,
                    fontWeight:
                        paid ? FontWeight.w400 : FontWeight.w600),
              ),
              if (!paid) ...[
                const SizedBox(height: 2),
                const Text(
                  'Complete the payment from My bookings to confirm it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _fact('Booking ID',
                                '#${widget.bookingCode}')),
                        Expanded(
                            child: _fact(
                                'Date Issued', _todayLabel())),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _fact('Booking Status',
                                paid ? 'Confirmed' : 'Pending',
                                ok: paid)),
                        Expanded(
                            child: _fact('Total Amount',
                                _fmt(total),
                                highlight: true)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fact('Property & Destination',
                        '${widget.destination.name} (${widget.destination.city})'),
                    const SizedBox(height: 14),
                    _fact('Stay Dates', widget.selectedDatesText),
                    if (widget.guestName.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _fact('Guest Name', widget.guestName.trim()),
                    ],
                    const SizedBox(height: 14),
                    _fact('Payment Method (Local)',
                        '${widget.paymentMethod} (${(widget.paymentPhone ?? widget.guestPhone).trim()})'),
                    const SizedBox(height: 14),
                    _fact(
                        'Guest Contact',
                        [
                          (widget.paymentPhone ?? widget.guestPhone)
                              .trim(),
                          (widget.guestEmail ?? '').trim(),
                        ]
                            .where((s) => s.isNotEmpty)
                            .join(' · ')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _actionBtn(
                    label: 'Browse More Stays',
                    bg: Colors.white,
                    fg: _ink,
                    border: _border,
                    onTap: () => Navigator.popUntil(
                        context, (route) => route.isFirst),
                  ),
                  _actionBtn(
                    label: 'View My Bookings',
                    bg: _blue,
                    fg: Colors.white,
                    border: _blue,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainScreen(
                                initialTab: 1)),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  _actionBtn(
                    label: 'View e-receipt',
                    icon: Icons.receipt_outlined,
                    bg: const Color(0xFFF8FAFC),
                    fg: _blue,
                    border: _border,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptScreen(
                            bookingCode: widget.bookingCode,
                            lodgeName: widget.destination.name,
                            roomNumber:
                                widget.selectedRoomNumber,
                            location:
                                '${widget.destination.area}, ${widget.destination.city}',
                            dates: widget.selectedDatesText,
                            guestName: widget.guestName,
                            guestPhone: widget.guestPhone,
                            paymentMethod:
                                widget.paymentMethod,
                            numNights: widget.numNights,
                            pricePerNight:
                                widget.destination.price,
                            paymentTime: widget.paymentTime,
                            verifyUrl: widget.verifyUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _faintColor() => const Color(0xFF9AA0A6);

  Widget _fact(String label, String value,
      {bool ok = false, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _muted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: highlight ? _burnt : (ok ? _greenOk() : _ink))),
      ],
    );
  }

  Color _greenOk() => const Color(0xFF15803D);

  Widget _actionBtn({
    required String label,
    required Color bg,
    required Color fg,
    required Color border,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

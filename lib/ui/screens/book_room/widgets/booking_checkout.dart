import 'dart:math';
import 'dart:async';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/reviews_screen.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/services/draft_booking_service.dart';
import 'package:fastnet_mobile_front_end/services/supabase_service.dart';
import 'package:fastnet_mobile_front_end/services/receipt_pdf_service.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/reward_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/web_header.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  
  // Payment Details Controllers (for local simulation)
  final _cardNoController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _crdbAccController = TextEditingController();
  final _mobileWalletPhoneController = TextEditingController();

  String _selectedPaymentMethod = 'Vodacom M-Pesa';
  bool _isLoading = false;
  int _loadingStep = 0;
  bool _bookingCompleted = false;
  Timer? _holdTimer;
  int _remainingSeconds = 600; // 10 minutes temporary room lock

  late String _currentDatesText;
  late int _currentNumNights;
  late int _currentGuestsCount;

  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'Vodacom M-Pesa', 'asset': 'assets/images/vodacom_logo.png', 'icon': Icons.phone_android},
    {'name': 'Tigo Pesa', 'asset': 'assets/images/mix by yas.jpg', 'icon': Icons.phone_android},
    {'name': 'Airtel Money', 'asset': 'assets/images/airtel logo.png', 'icon': Icons.phone_android},
    {'name': 'Halotel HaloPesa', 'asset': 'assets/images/halotel_logo.jpg', 'icon': Icons.phone_android},
    {'name': 'Mastercard', 'asset': 'assets/images/mastercard-logo.png', 'icon': Icons.credit_card},
    {'name': 'Visa Card', 'asset': 'assets/images/VISA_LOGO.png', 'icon': Icons.credit_card},
  ];

  @override
  void initState() {
    super.initState();
    _currentDatesText = widget.selectedDatesText;
    _currentNumNights = widget.numNights > 0 ? widget.numNights : 1;
    _currentGuestsCount = widget.destination.guests > 0 ? widget.destination.guests : 1;
    _acquireRealTimeLock();
    _startHoldTimer();
    _saveDraft();
    if (_mobileWalletPhoneController.text.isEmpty) {
      _mobileWalletPhoneController.text = '255';
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _cardNoController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _crdbAccController.dispose();
    _mobileWalletPhoneController.dispose();
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
    final response = await ApiService.lockRoom(widget.selectedRoomId, dates[0], dates[1]);
    if (response == null) return;
    
    final status = response['status'] as int;
    if (status == 409) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Room Unavailable', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                response['body']['message'] ?? 'This room is currently held by another customer. Please choose a different room.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Pop dialog
                    Navigator.pop(context); // Pop checkout screen
                  },
                  child: Text('OK', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
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
      final monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final parts = dateRangeText.split('–').map((e) => e.trim()).toList();
      if (parts.length != 2) throw Exception("Invalid range parts");

      final startPart = parts[0];
      final endPart = parts[1];

      final startTokens = startPart.split(' ');
      final startMonthStr = startTokens[0];
      final startDayVal = int.parse(startTokens[1]);
      final startMonthVal = monthsAbbr.indexOf(startMonthStr) + 1;
      
      final startDate = DateTime(currentYear, startMonthVal, startDayVal);

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

      final startFormatted = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endFormatted = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      return [startFormatted, endFormatted];
    } catch (_) {
      final today = DateTime.now();
      final future = today.add(const Duration(days: 3));
      final startFormatted = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final endFormatted = "${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}";
      return [startFormatted, endFormatted];
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
        if (mounted) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hold Time Expired', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Your room lock reservation has expired. To secure this listing, please restart the checkout process.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop checkout screen
              },
              child: Text('OK', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  IconData _getPaymentIcon(String method) {
    if (method.contains('Mastercard') || method.contains('Visa')) {
      return Icons.credit_card;
    } else if (method.contains('CRDB')) {
      return Icons.account_balance;
    }
    return Icons.phone_android;
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      final roomTotal = widget.destination.price * _currentNumNights;
      final vatTotal = (roomTotal * 0.125).round();
      final grandTotal = roomTotal + vatTotal;

      if (_selectedPaymentMethod.contains('M-Pesa') || 
          _selectedPaymentMethod.contains('Tigo Pesa') || 
          _selectedPaymentMethod.contains('Airtel') ||
          _selectedPaymentMethod.contains('HaloPesa') ||
          _selectedPaymentMethod.contains('CRDB')) {
        _showUSSDPushSimulationDialog(grandTotal);
      } else {
        _showOTPSimulationDialog(grandTotal);
      }
    }
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  void _showUSSDPushSimulationDialog(int amount) {
    final pinController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    final operatorAsset = _getSelectedOperatorAsset();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: operatorAsset != null
                        ? Image.asset(operatorAsset, fit: BoxFit.contain)
                        : const Icon(
                            Icons.lock_person_rounded,
                            color: Color(0xFF1E88E5),
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authorize Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An STK Push has been sent to your mobile phone. Enter your wallet PIN to authorize.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDialogInfoRow('Operator', _selectedPaymentMethod),
                        const SizedBox(height: 8),
                        _buildDialogInfoRow('Merchant', 'LODGE RESERVATION'),
                        const SizedBox(height: 8),
                        _buildDialogInfoRow('Room', 'Room ${widget.selectedRoomNumber}'),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Charge', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                            Text(
                              _formatPrice(amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E88E5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: const TextStyle(fontSize: 22, letterSpacing: 8, color: Colors.grey),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length != 4 || int.tryParse(value) == null) {
                        return 'Please enter your 4-digit PIN';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (dialogFormKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _executeFinalizeBooking();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Authorize', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOTPSimulationDialog(int amount) {
    final otpController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.blue.shade800,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Card Authentication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit one-time verification code (OTP) sent to your registered phone number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDialogInfoRow('Payment Method', _selectedPaymentMethod),
                        const SizedBox(height: 8),
                        _buildDialogInfoRow('Merchant', 'LODGE RESERVATION'),
                        const SizedBox(height: 8),
                        _buildDialogInfoRow('Room', 'Room ${widget.selectedRoomNumber}'),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Charge', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                            Text(
                              _formatPrice(amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E88E5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '123456',
                      hintStyle: const TextStyle(fontSize: 22, letterSpacing: 8, color: Colors.grey),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length != 6 || int.tryParse(value) == null) {
                        return 'Please enter a valid 6-digit OTP';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (dialogFormKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _executeFinalizeBooking();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Verify Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _executeFinalizeBooking() {
    setState(() {
      _isLoading = true;
      _loadingStep = 0;
    });

    // Step 0 -> Step 1 after 1200ms
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _loadingStep = 1;
        });
      }
    });

    // Step 1 -> Step 2 after 2400ms
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _loadingStep = 2;
        });
      }
    });

    // Step 2 -> Finalize after 3600ms
    Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        setState(() {
          _loadingStep = 3;
          _isLoading = false;
        });
        
        final random = Random();
        final bookingCode = 'TZ-${10000 + random.nextInt(90000)}-${widget.destination.city.substring(0, 3).toUpperCase()}';

        final dt = DateTime.now();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[dt.month - 1];
        final day = dt.day.toString().padLeft(2, '0');
        final year = dt.year;
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        var hour = dt.hour % 12;
        if (hour == 0) hour = 12;
        final hourStr = hour.toString().padLeft(2, '0');
        final minuteStr = dt.minute.toString().padLeft(2, '0');
        final paymentTimeStr = '$month $day, $year - $hourStr:$minuteStr $period';

        final roomTotal = widget.destination.price * _currentNumNights;
        final vatTotal = (roomTotal * 0.125).round();
        final grandTotal = roomTotal + vatTotal;
        final bookingData = {
          'name': '${widget.destination.name} - Room ${widget.selectedRoomNumber}',
          'city': widget.destination.city,
          'area': widget.destination.area,
          'dates': _currentDatesText,
          'nights': _currentNumNights,
          'guests': _currentGuestsCount,
          'price': grandTotal,
          'code': bookingCode,
          'imageUrl': widget.destination.imageUrl,
          'status': 'Confirmed',
          'paymentTime': paymentTimeStr,
        };
        BookingsData.list.add(bookingData);

        // Sync with Supabase real-time database
        SupabaseService.createBookingRecord({
          'booking_code': bookingCode,
          'lodge_name': widget.destination.name,
          'room_number': widget.selectedRoomNumber,
          'guest_name': UserSession.userName ?? 'Guest User',
          'guest_phone': UserSession.userPhone ?? '',
          'dates': _currentDatesText,
          'nights': _currentNumNights,
          'total_price': grandTotal,
          'payment_method': _selectedPaymentMethod,
          'status': 'Confirmed',
          'created_at': DateTime.now().toIso8601String(),
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              destination: widget.destination,
              selectedDatesText: _currentDatesText,
              numNights: _currentNumNights,
              guestName: UserSession.userName ?? 'Guest User',
              guestPhone: UserSession.userPhone ?? '+255 712 345 678',
              paymentMethod: _selectedPaymentMethod,
              bookingCode: bookingCode,
              selectedRoomNumber: widget.selectedRoomNumber,
              paymentTime: paymentTimeStr,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  Widget _buildLoadingProgressItem({
    required String text,
    required bool isActive,
    required bool isDone,
  }) {
    Color textColor = Colors.grey.shade400;
    Widget leadingWidget = Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 20);

    if (isDone) {
      textColor = Colors.black87;
      leadingWidget = const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (isActive) {
      textColor = Colors.red.shade900;
      leadingWidget = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade900),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(width: 20, height: 20, child: Center(child: leadingWidget)),
        const SizedBox(width: 14),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isActive || isDone) ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          ),
          child: Text(text),
        ),
      ],
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Choose how to pay',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _paymentOptions.length,
                    itemBuilder: (context, index) {
                      final option = _paymentOptions[index];
                      final name = option['name'] as String;
                      final asset = option['asset'] as String?;
                      final icon = option['icon'] as IconData;
                      final isSelected = _selectedPaymentMethod == name;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        leading: asset != null
                            ? Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.asset(asset, fit: BoxFit.contain),
                                ),
                              )
                            : Icon(icon, color: Colors.black87, size: 24),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? _blue : Colors.grey.shade400,
                          size: 22,
                        ),
                        onTap: () {
                          setModalState(() {
                            _selectedPaymentMethod = name;
                          });
                          setState(() {
                            _selectedPaymentMethod = name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXACT SCREENSHOT MATCH
  // ─────────────────────────────────────────────────────────────────────────
  static const Color _blue = Color(0xFF2979FF);   // bright blue from screenshot

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final roomTotal  = widget.destination.price * _currentNumNights;
    final vatTotal   = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal;

    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;
    if (isDesktopWeb) {
      return _buildDesktopWebView(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F3FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 24, color: Colors.black87),
              ),
            ),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Hotel card ──────────────────────────────────────────
                  _screenshotHotelCard(),
                  const SizedBox(height: 22),

                  // ── Trip Overview ───────────────────────────────────────
                  const Text('Trip Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 10),
                  _screenshotTripCard(),
                  const SizedBox(height: 22),

                  // ── Billing Details ─────────────────────────────────────
                  const Text('Billing Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 10),
                  _screenshotBillingCard(roomTotal, vatTotal, grandTotal),
                  const SizedBox(height: 22),

                  // ── Pay with ────────────────────────────────────────────
                  const Text('Pay with',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('Select your preferred payment method',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 14),
                  // Payment chips row
                  _screenshotPaymentRow(),
                  const SizedBox(height: 20),

                  // Dynamic payment inputs
                  _screenshotInputsCard(),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading) _screenshotLoadingOverlay(),
        ],
      ),
      // ── Confirm and Pay button ──────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: Colors.blue.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'Confirm and Pay • ${_formatPrice(grandTotal)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hotel card ─────────────────────────────────────────────────────────────
  Widget _screenshotHotelCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(widget.destination.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + star rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.destination.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text(
                      widget.destination.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Location in blue
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.blue.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${widget.destination.area}, ${widget.destination.city}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade500, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price + Super Host
                Row(
                  children: [
                    Text(
                      _formatPrice(widget.destination.price),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    Text(
                      '/night',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Super Host',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Trip Overview card ─────────────────────────────────────────────────────
  Widget _screenshotTripCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _screenshotTripRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: '$_currentDatesText ($_currentNumNights night${_currentNumNights > 1 ? 's' : ''})',
            onEdit: _selectDates,
          ),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFF0F0F0)),
          _screenshotTripRow(
            icon: Icons.person_outline,
            label: 'Guests',
            value: '$_currentGuestsCount Guest${_currentGuestsCount > 1 ? 's' : ''}',
            onEdit: _editGuests,
          ),
        ],
      ),
    );
  }

  Widget _screenshotTripRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Text(
              'Edit',
              style: TextStyle(fontSize: 13.5, color: Colors.blue.shade700, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
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
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final nights = picked.end.difference(picked.start).inDays;
      final startMonth = _getMonthAbbr(picked.start.month);
      final endMonth = _getMonthAbbr(picked.end.month);
      final formattedDates = picked.start.month == picked.end.month
          ? '$startMonth ${picked.start.day} – ${picked.end.day}'
          : '$startMonth ${picked.start.day} – $endMonth ${picked.end.day}';

      setState(() {
        _currentNumNights = nights > 0 ? nights : 1;
        _currentDatesText = formattedDates;
      });
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _editGuests() {
    int tempGuests = _currentGuestsCount;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Guests & Occupancy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Guests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                          Text('Adults and children', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: tempGuests > 1 ? () => setModalState(() => tempGuests--) : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: const Color(0xFF1E88E5),
                          ),
                          Text(
                            '$tempGuests',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          IconButton(
                            onPressed: tempGuests < 10 ? () => setModalState(() => tempGuests++) : null,
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: const Color(0xFF1E88E5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentGuestsCount = tempGuests;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Billing Details card ───────────────────────────────────────────────────
  Widget _screenshotBillingCard(int roomTotal, int vatTotal, int grandTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _screenshotBillingRow(
            '$_currentNumNights night${_currentNumNights > 1 ? 's' : ''}',
            _formatPrice(roomTotal),
          ),
          const SizedBox(height: 12),
          _screenshotBillingRow('Vat', _formatPrice(vatTotal)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          // Total row — larger text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              Text(
                _formatPrice(grandTotal),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _screenshotBillingRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  // ── Payment icons row ──────────────────────────────────────────────────────
  Widget _screenshotPaymentRow() {
    final methods = [
      {'name': 'Vodacom M-Pesa', 'asset': 'assets/images/vodacom_logo.png', 'label': 'M-Pesa'},
      {'name': 'Tigo Pesa', 'asset': 'assets/images/mix by yas.jpg', 'label': 'Tigo Pesa'},
      {'name': 'Airtel Money', 'asset': 'assets/images/airtel logo.png', 'label': 'Airtel'},
      {'name': 'Halotel HaloPesa', 'asset': 'assets/images/halotel_logo.jpg', 'label': 'HaloPesa'},
      {'name': 'Mastercard', 'asset': 'assets/images/mastercard-logo.png', 'label': 'Mastercard'},
      {'name': 'Visa Card', 'asset': 'assets/images/VISA_LOGO.png', 'label': 'Visa'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: methods.map((m) {
          final name = m['name']!;
          final asset = m['asset']!;
          final label = m['label']!;
          final isSelected = _selectedPaymentMethod == name;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _screenshotPayChip(
              selected: isSelected,
              onTap: () => setState(() => _selectedPaymentMethod = name),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      asset,
                      height: 22,
                      width: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _screenshotPayChip({required bool selected, required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE0E0E0),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      ),
    );
  }

  // ── Dynamic payment inputs card ────────────────────────────────────────────
  Widget _screenshotInputsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _buildDynamicPaymentInputs(),
    );
  }

  // ── Loading overlay ────────────────────────────────────────────────────────
  Widget _screenshotLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),
                const SizedBox(width: 14),
                const Text('Processing payment…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
              ]),
              const SizedBox(height: 22),
              _buildLoadingProgressItem(text: 'Checking availability', isActive: _loadingStep == 0, isDone: _loadingStep > 0),
              const SizedBox(height: 14),
              _buildLoadingProgressItem(text: 'Confirming payment',    isActive: _loadingStep == 1, isDone: _loadingStep > 1),
              const SizedBox(height: 14),
              _buildLoadingProgressItem(text: 'Preparing confirmation', isActive: _loadingStep == 2, isDone: _loadingStep > 2),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTripDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutStepper(int currentStep) {
    return Row(
      children: List.generate(5, (index) {
        if (index % 2 == 1) {
          return Expanded(
            child: Divider(
              color: index < currentStep * 2 ? Colors.red.shade900 : Colors.grey.shade300,
              thickness: 2,
            ),
          );
        }
        final stepIdx = index ~/ 2;
        final isActive = stepIdx <= currentStep;
        final isCompleted = stepIdx < currentStep;
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.red.shade900 : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.red.shade900 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${stepIdx + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, color: Colors.black54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade900, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildDynamicPaymentInputs() {
    if (_selectedPaymentMethod == 'Mastercard / Visa' || _selectedPaymentMethod == 'Mastercard' || _selectedPaymentMethod == 'Visa Card') {
      final isMastercard = _selectedPaymentMethod == 'Mastercard';
      final cardAsset = isMastercard ? 'assets/images/mastercard-logo.png' : 'assets/images/VISA_LOGO.png';
      final cardName = isMastercard ? 'Mastercard' : 'Visa Card';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Form Input Fields ─────────────────────────────────────────────
          Text('$cardName Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNoController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 1),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '4000 1234 5678 9010',
              counterText: '',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(cardAsset, width: 22, height: 22, fit: BoxFit.contain),
              ),
              suffixIcon: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF10B981)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.length != 16 || int.tryParse(value) == null) {
                return 'Enter a valid 16-digit card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 5 || !value.contains('/')) {
                      return 'Enter MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'CVV / CVC',
                    hintText: '123',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 3 || int.tryParse(value) == null) {
                      return 'Enter 3 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Guaranteed safe & 256-bit SSL encrypted checkout',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      );
    } else if (_selectedPaymentMethod == 'CRDB Bank') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CRDB Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _crdbAccController,
            keyboardType: TextInputType.number,
            maxLength: 15,
            decoration: _buildInputDecoration('CRDB Account Number', 'e.g., 0152345678900', Icons.account_balance_wallet_outlined),
            validator: (value) {
              if (value == null || value.length < 10 || value.length > 15 || int.tryParse(value) == null) {
                return 'Enter a valid CRDB Account Number';
              }
              return null;
            },
          ),
        ],
      );
    } else {
      final operatorAsset = _getSelectedOperatorAsset();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_selectedPaymentMethod Number', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobileWalletPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '2557XXXXXXXX',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: operatorAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(operatorAsset, width: 22, height: 22, fit: BoxFit.contain),
                    )
                  : const Icon(Icons.phone_android_outlined),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              final val = value?.trim() ?? '';
              if (val.isEmpty || val.length < 9) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
        ],
      );
    }
  }

  String? _getSelectedOperatorAsset() {
    final match = _paymentOptions.firstWhere(
      (opt) => opt['name'] == _selectedPaymentMethod,
      orElse: () => <String, dynamic>{},
    );
    return match['asset'] as String?;
  }

  Widget _buildDesktopWebView(BuildContext context) {
    final d = widget.destination;
    final roomTotal = d.price * _currentNumNights;
    final vatTotal = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal;

    final formattedRoomTotal = 'TZS ${roomTotal.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
    final formattedVatTotal = 'TZS ${vatTotal.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
    final formattedGrandTotal = 'TZS ${grandTotal.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timerText = '$minutes:${seconds.toString().padLeft(2, "0")}';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: WebTopHeader(
        selectedIndex: 0,
        onTabSelected: (idx) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(initialTab: idx)),
            (route) => false,
          );
        },
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF003580)),
                  const SizedBox(height: 16),
                  Text(
                    _loadingStep == 0
                        ? 'Verifying room lock status...'
                        : _loadingStep == 1
                            ? 'Processing secure transaction...'
                            : 'Finalizing booking receipt details...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hold Timer Bar
                  Container(
                    color: const Color(0xFFFFB700),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          'We are holding this room for you. Complete checkout in $timerText',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Header Back Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF006CE4)),
                          label: const Text('Back to room selection', style: TextStyle(color: Color(0xFF006CE4), fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        const Text(
                          'Secure Checkout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Constrained Columns Split Layout
                  Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Columns - Guest Details & Payment Inputs
                        Expanded(
                          flex: 3,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step 1: Guest Details
                                const Text('Step 1: Guest Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        initialValue: UserSession.userName ?? '',
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter your name';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        initialValue: UserSession.userEmail ?? '',
                                        decoration: const InputDecoration(
                                          labelText: 'Email Address',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.email_outlined),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter email';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Step 2: Payment Details
                                const Text('Step 2: Choose Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Payment Options Grid Wrap
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: _paymentOptions.map((opt) {
                                          final name = opt['name'] as String;
                                          final isSelected = _selectedPaymentMethod == name;
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedPaymentMethod = name;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF003580).withValues(alpha: 0.05) : Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected ? const Color(0xFF003580) : Colors.grey.shade300,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(opt['icon'] as IconData, size: 16, color: isSelected ? const Color(0xFF003580) : Colors.black54),
                                                  const SizedBox(width: 8),
                                                  Text(name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),

                                      // Mobile money configuration or Visa inputs
                                      if (_selectedPaymentMethod.contains('Visa') || _selectedPaymentMethod.contains('Mastercard')) ...[
                                        TextFormField(
                                          controller: _cardNoController,
                                          decoration: const InputDecoration(
                                            labelText: 'Card Number',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.credit_card),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _expiryController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Expiry Date (MM/YY)',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _cvvController,
                                                decoration: const InputDecoration(
                                                  labelText: 'CVV',
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType: TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        TextFormField(
                                          controller: _mobileWalletPhoneController,
                                          decoration: const InputDecoration(
                                            labelText: 'Mobile Wallet Number',
                                            border: OutlineInputBorder(),
                                            prefixText: '+',
                                            prefixIcon: Icon(Icons.phone_android),
                                          ),
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Enter wallet number (e.g. 25576XXXXXXX). A push notification will be sent to complete payments.',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Right Column: Summary Card
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${d.area}, ${d.city}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 16),
                                _summaryItem('Dates', _currentDatesText),
                                _summaryItem('Stay length', '$_currentNumNights Nights'),
                                _summaryItem('Room Number', 'Room ${widget.selectedRoomNumber}'),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 16),
                                _priceRow('Room Total', formattedRoomTotal, false),
                                _priceRow('VAT (12.5%)', formattedVatTotal, false),
                                const SizedBox(height: 10),
                                _priceRow('Grand Total', formattedGrandTotal, true),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        _submitBooking();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006CE4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Complete Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Center(
                                  child: Text('Secure payment processing', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, bool isGrand) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
              fontSize: isGrand ? 16 : 13,
              color: isGrand ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isGrand ? 18 : 13,
              color: isGrand ? const Color(0xFF003580) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

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
  }) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  static const Color _bookingNavy = Color(0xFF003580);
  static const Color _bookingBlue = Color(0xFF006CE4);
  static const Color _bookingGreen = Color(0xFF008009);
  static const Color _bgGrey = Color(0xFFF5F5F5);

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ConfettiOverlay.show(context);

        final email = UserSession.userEmail ?? 'guest@fastnet.com';
        final roomTotal = widget.destination.price * widget.numNights;
        final vatTotal = (roomTotal * 0.125).round();
        final grandTotal = roomTotal + vatTotal;

        // Generate the exact same e-receipt PDF the user sees on screen,
        // upload it to Supabase Storage, then email it via the edge function.
        _dispatchConfirmationEmail(
          email: email,
          grandTotal: grandTotal,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Confirmation email & e-receipt PDF sent to $email',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF008009),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  Future<void> _dispatchConfirmationEmail({
    required String email,
    required int grandTotal,
  }) async {
    try {
      final pdfBytes = await ReceiptPdfService.generate(
        bookingCode: widget.bookingCode,
        lodgeName: widget.destination.name,
        roomNumber: widget.selectedRoomNumber,
        location: '${widget.destination.area}, ${widget.destination.city}',
        dates: widget.selectedDatesText,
        guestName: widget.guestName,
        guestPhone: widget.guestPhone,
        numNights: widget.numNights,
        pricePerNight: widget.destination.price,
        paymentTime: widget.paymentTime,
      );

      // Upload the phone-generated receipt so the edge function attaches the
      // exact same PDF the guest sees on screen.
      final receiptUrl = await SupabaseService.uploadReceiptPdf(widget.bookingCode, pdfBytes);

      await SupabaseService.triggerConfirmationEmail(
        userEmail: email,
        guestName: widget.guestName,
        guestPhone: widget.guestPhone,
        bookingCode: widget.bookingCode,
        lodgeName: widget.destination.name,
        roomNumber: widget.selectedRoomNumber,
        location: '${widget.destination.area}, ${widget.destination.city}',
        dates: widget.selectedDatesText,
        numNights: widget.numNights,
        pricePerNight: widget.destination.price,
        paymentMethod: widget.paymentMethod,
        paymentTime: widget.paymentTime,
        amount: grandTotal,
        receiptUrl: receiptUrl,
      );
    } catch (e) {
      debugPrint('Dispatch confirmation email error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomTotal = widget.destination.price * widget.numNights;
    final vatTotal = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal;

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'Booking Confirmed',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 2. "Congratulations! Your booking is now confirmed." Card ─
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingSuccessPulse(
                      child: Text(
                        'Congratulations ${widget.guestName.trim().isNotEmpty ? widget.guestName.trim() : ''}! Your booking is now confirmed.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _bookingNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _bookingCheckRow('We\'ve sent the confirmation SMS/email to ', widget.guestPhone),
                    const SizedBox(height: 8),
                    _bookingCheckRow('Your booking at ', widget.destination.name, isBoldEnd: true, postText: ' is already confirmed'),
                    const SizedBox(height: 8),
                    _bookingCheckRow('You can ', 'make changes or cancel your booking', isLink: true, postText: ' at any time'),
                    const SizedBox(height: 8),
                    _bookingCheckRow(
                      'Get paperless confirmation when you ',
                      'download the e-receipt',
                      isLink: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptScreen(
                              bookingCode: widget.bookingCode,
                              lodgeName: widget.destination.name,
                              roomNumber: widget.selectedRoomNumber,
                              location: '${widget.destination.area}, ${widget.destination.city}',
                              dates: widget.selectedDatesText,
                              guestName: widget.guestName,
                              guestPhone: widget.guestPhone,
                              paymentMethod: widget.paymentMethod,
                              numNights: widget.numNights,
                              pricePerNight: widget.destination.price,
                              paymentTime: widget.paymentTime,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Real-Time E-Receipt & Confirmation Email Notice Card ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF166534), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'E-Receipt PDF Dispatched in Real-Time',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sent to ${UserSession.userEmail ?? "your email address"}',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Save confirmation & Print)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReceiptScreen(
                                    bookingCode: widget.bookingCode,
                                    lodgeName: widget.destination.name,
                                    roomNumber: widget.selectedRoomNumber,
                                    location: '${widget.destination.area}, ${widget.destination.city}',
                                    dates: widget.selectedDatesText,
                                    guestName: widget.guestName,
                                    guestPhone: widget.guestPhone,
                                    paymentMethod: widget.paymentMethod,
                                    numNights: widget.numNights,
                                    pricePerNight: widget.destination.price,
                                    paymentTime: widget.paymentTime,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.phone_android_rounded, size: 16, color: Colors.white),
                              label: const Text('Save confirmation', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _bookingBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                            icon: const Icon(Icons.home_outlined, size: 16, color: _bookingBlue),
                            label: const Text('Home', style: TextStyle(color: _bookingBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _bookingBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 3. "Check your details" Card ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check your details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bookingNavy),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.destination.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bookingBlue),
                      ),
                      const SizedBox(height: 12),

                      _detailRow('Booking number', widget.bookingCode),
                      const SizedBox(height: 6),
                      _detailRow('PIN code', '3947 🔒', isLock: true),
                      const SizedBox(height: 6),
                      _detailRow('Booking details', '${widget.numNights} night${widget.numNights > 1 ? 's' : ''}, Room ${widget.selectedRoomNumber}'),
                      const SizedBox(height: 6),
                      _detailRow('Check-in', widget.selectedDatesText.split(' - ').first + ' (14:00 - 20:30)'),
                      const SizedBox(height: 6),
                      _detailRow('Check-out', (widget.selectedDatesText.contains('-') ? widget.selectedDatesText.split('-').last.trim() : 'Next Day') + ' (08:00 - 11:00)'),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                      ),

                      // Price breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 room x ${widget.numNights} night(s)', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          Text(_formatPrice(roomTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT & Taxes', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          Text(_formatPrice(vatTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Price:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Row(
                            children: [
                              Text(
                                _formatPrice(grandTotal),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _bookingNavy),
                              ),
                              const SizedBox(width: 8),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: _bookingGreen, size: 14),
                                  SizedBox(width: 2),
                                  Text(
                                    'Best Price Guaranteed',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _bookingGreen),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 4. "Is everything correct?" Action Box ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5FF),
                    border: Border.all(color: const Color(0xFFCBE0FF)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Is everything correct?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _bookingNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can always view or change your booking online — no registration required.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 12),
                      _bookingLinkAction('💳 Edit payment details', () {}),
                      const SizedBox(height: 8),
                      _bookingLinkAction('📅 Change dates', () {}),
                      const SizedBox(height: 8),
                      _bookingLinkAction('👤 Edit guest details', () {}),
                      const SizedBox(height: 8),
                      _bookingLinkAction('💬 Contact the property', () {}),
                      const SizedBox(height: 8),
                      _bookingLinkAction('⭐ Leave a review', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewsScreen(lodgeName: widget.destination.name),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      _bookingLinkAction('❌ Cancel your booking', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Free cancellation is active for this reservation.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }, isDanger: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 5. Property Details Card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _bookingNavy),
                      ),
                      const SizedBox(height: 12),
                      _detailRow('Address', '${widget.destination.area}, ${widget.destination.city}, Tanzania'),
                      const SizedBox(height: 6),
                      _detailRow('Phone', widget.guestPhone),
                      const SizedBox(height: 6),
                      _detailRow('Room Condition', widget.destination.condition),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCheckRow(String text, String highlight, {bool isLink = false, bool isBoldEnd = false, String postText = '', VoidCallback? onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, color: _bookingGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: highlight,
                    style: TextStyle(
                      fontWeight: (isLink || isBoldEnd) ? FontWeight.bold : FontWeight.w600,
                      color: isLink ? _bookingBlue : Colors.black87,
                      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                  if (postText.isNotEmpty) TextSpan(text: postText),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool isLock = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isLock ? _bookingBlue : Colors.grey.shade800,
              fontWeight: isLock ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookingLinkAction(String title, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDanger ? Colors.red.shade700 : _bookingBlue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NextStepCard — staggered slide-up + fade-in action card
// ─────────────────────────────────────────────────────────────────────────────
class _NextStepCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NextStepCard({
    Key? key,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_NextStepCard> createState() => _NextStepCardState();
}

class _NextStepCardState extends State<_NextStepCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    // Stagger based on index
    Future.delayed(Duration(milliseconds: 120 + widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

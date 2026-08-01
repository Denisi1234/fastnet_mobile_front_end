import 'dart:math';
import 'dart:async';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/reviews_screen.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/services/draft_booking_service.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/reward_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String? _selectedArrivalTime;
  Timer? _holdTimer;
  int _remainingSeconds = 600; // 10 minutes temporary room lock

  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'Vodacom M-Pesa', 'icon': Icons.phone_android},
    {'name': 'Tigo Pesa', 'icon': Icons.phone_android},
    {'name': 'Halotel HaloPesa', 'icon': Icons.phone_android},
    {'name': 'Mastercard / Visa', 'icon': Icons.credit_card},
    {'name': 'CRDB Bank', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _acquireRealTimeLock();
    _startHoldTimer();
    _saveDraft();
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
      final roomTotal = widget.destination.price * widget.numNights;
      final grandTotal = roomTotal + 5000;

      if (_selectedPaymentMethod.contains('M-Pesa') || 
          _selectedPaymentMethod.contains('Tigo Pesa') || 
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
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mobile_friendly_outlined,
                      color: Colors.red.shade900,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authorize Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An STK Push has been sent to your mobile wallet. Enter your wallet PIN to confirm.',
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade900),
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
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.shade900, width: 1.5),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink.shade700, Colors.red.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (dialogFormKey.currentState!.validate()) {
                                Navigator.pop(context);
                                _executeFinalizeBooking();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Authorize', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade900),
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
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade800, width: 1.5),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade700, Colors.indigo.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (dialogFormKey.currentState!.validate()) {
                                Navigator.pop(context);
                                _executeFinalizeBooking();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Verify Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
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

        final roomTotal = widget.destination.price * widget.numNights;
        BookingsData.list.add({
          'name': '${widget.destination.name} - Room ${widget.selectedRoomNumber}',
          'city': widget.destination.city,
          'area': widget.destination.area,
          'dates': widget.selectedDatesText,
          'nights': widget.numNights,
          'price': roomTotal + 5000,
          'code': bookingCode,
          'imageUrl': widget.destination.imageUrl,
          'status': 'Confirmed',
          'paymentTime': paymentTimeStr,
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              destination: widget.destination,
              selectedDatesText: widget.selectedDatesText,
              numNights: widget.numNights,
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
                      final icon = option['icon'] as IconData;
                      final isSelected = _selectedPaymentMethod == name;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: Icon(icon, color: Colors.black87, size: 22),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Colors.black87 : Colors.grey.shade400,
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
    final roomTotal  = widget.destination.price * widget.numNights;
    final vatTotal   = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal;

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pay with',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                          Text('Payment method',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showPaymentBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Payment chips row
                  _screenshotPaymentRow(),
                  const SizedBox(height: 22),

                  // ── Arrival time ────────────────────────────────────────
                  _screenshotArrivalCard(),
                  const SizedBox(height: 14),
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
              child: const Text(
                'Confirm and Pay',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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
          _screenshotTripRow(icon: Icons.calendar_today_outlined, label: 'Dates', value: widget.selectedDatesText),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFF0F0F0)),
          _screenshotTripRow(
            icon: Icons.person_outline,
            label: 'Guests',
            value: '${widget.destination.guests} Guest${widget.destination.guests > 1 ? 's' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _screenshotTripRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
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
            onTap: () {},
            child: Text('Edit', style: TextStyle(fontSize: 13, color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
            '${widget.numNights} night${widget.numNights > 1 ? 's' : ''}',
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
    return Row(
      children: [
        // 1. Mastercard — two overlapping circles
        _screenshotPayChip(
          selected: _selectedPaymentMethod.contains('Mastercard'),
          onTap: () => setState(() => _selectedPaymentMethod = 'Mastercard / Visa'),
          child: SizedBox(
            width: 36, height: 24,
            child: Stack(
              children: [
                Positioned(left: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
                Positioned(right: 0, child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(color: const Color(0xFFF79E1B).withValues(alpha: 0.9), shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 2. PayPal — stylised P
        _screenshotPayChip(
          selected: _selectedPaymentMethod.contains('M-Pesa') || _selectedPaymentMethod.contains('Tigo'),
          onTap: () => setState(() => _selectedPaymentMethod = 'Vodacom M-Pesa'),
          child: const Text(
            'P',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF003087), fontStyle: FontStyle.italic, height: 1),
          ),
        ),
        const SizedBox(width: 10),
        // 3. Apple Pay
        _screenshotPayChip(
          selected: _selectedPaymentMethod == 'Apple Pay',
          onTap: _showPaymentBottomSheet,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apple, size: 18, color: Colors.black87),
              SizedBox(width: 2),
              Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // 4. Google Pay
        _screenshotPayChip(
          selected: _selectedPaymentMethod == 'CRDB Bank',
          onTap: _showPaymentBottomSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('G', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
              const SizedBox(width: 2),
              Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
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

  // ── Arrival time card ──────────────────────────────────────────────────────
  Widget _screenshotArrivalCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Arrival Time',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        initialValue: _selectedArrivalTime,
        style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
        dropdownColor: Colors.white,
        items: const [
          DropdownMenuItem(value: 'Before noon', child: Text('Before noon')),
          DropdownMenuItem(value: '12–3 PM',    child: Text('12–3 PM')),
          DropdownMenuItem(value: '3–6 PM',     child: Text('3–6 PM')),
          DropdownMenuItem(value: '6–9 PM',     child: Text('6–9 PM')),
          DropdownMenuItem(value: 'After 9 PM', child: Text('After 9 PM')),
        ],
        onChanged: (v) => setState(() => _selectedArrivalTime = v),
        validator: (v) => v == null ? 'Please select arrival time' : null,
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
    if (_selectedPaymentMethod == 'Mastercard / Visa') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNoController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            decoration: _buildInputDecoration('Card Number', '16-digit card number', Icons.credit_card),
            validator: (value) {
              if (value == null || value.length != 16 || int.tryParse(value) == null) {
                return 'Enter a valid 16-digit card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.datetime,
                  decoration: _buildInputDecoration('Expiry Date', 'MM/YY', Icons.calendar_today),
                  validator: (value) {
                    if (value == null || value.trim().length != 5 || !value.contains('/')) {
                      return 'Enter MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                  decoration: _buildInputDecoration('CVV', '3 digits', Icons.lock_outline),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_selectedPaymentMethod Wallet Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobileWalletPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration('Mobile Wallet Phone Number', 'e.g., 0712345678', Icons.phone_android),
            validator: (value) {
              if (value == null || value.trim().length < 9) {
                return 'Enter a valid mobile wallet number';
              }
              return null;
            },
          ),
        ],
      );
    }
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
      if (mounted) ConfettiOverlay.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomTotal = widget.destination.price * widget.numNights;
    final vatTotal = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal;

    return Scaffold(
      backgroundColor: _bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Booking.com Header Bar ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: _bookingNavy,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Booking',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              TextSpan(
                                text: '.com',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00B1FF)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('TZS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.guestName.isNotEmpty ? widget.guestName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 2. "Congratulations! Your booking is now confirmed." Card ─
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingSuccessPulse(
                      child: const Text(
                        'Congratulations! Your booking is now confirmed.',
                        style: TextStyle(
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
                    _bookingCheckRow('Get paperless confirmation when you ', 'download the e-receipt', isLink: true),
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

  Widget _bookingCheckRow(String text, String highlight, {bool isLink = false, bool isBoldEnd = false, String postText = ''}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, color: _bookingGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
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

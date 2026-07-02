import 'dart:math';
import 'package:airbnb_ui_clone/models/destination.dart';
import 'package:airbnb_ui_clone/ui/screens/main_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:airbnb_ui_clone/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:flutter/material.dart';

class BookingCheckoutScreen extends StatefulWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;
  final String selectedRoomNumber;

  const BookingCheckoutScreen({
    Key? key,
    required this.destination,
    required this.selectedDatesText,
    required this.numNights,
    required this.selectedRoomNumber,
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

  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'Vodacom M-Pesa', 'icon': Icons.phone_android},
    {'name': 'Tigo Pesa', 'icon': Icons.phone_android},
    {'name': 'Halotel HaloPesa', 'icon': Icons.phone_android},
    {'name': 'Mastercard / Visa', 'icon': Icons.credit_card},
    {'name': 'CRDB Bank', 'icon': Icons.account_balance},
  ];

  @override
  void dispose() {
    _cardNoController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _crdbAccController.dispose();
    _mobileWalletPhoneController.dispose();
    super.dispose();
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
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        final random = Random();
        final bookingCode = 'TZ-${10000 + random.nextInt(90000)}-${widget.destination.city.substring(0, 3).toUpperCase()}';

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
            ),
          ),
          (route) => route.isFirst,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final roomTotal = widget.destination.price * widget.numNights;
    const serviceFee = 5000;
    final grandTotal = roomTotal + serviceFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm and book',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Progress Bar
                  const SizedBox(height: 12),
                  _buildCheckoutStepper(0), // Step 1: Review & Pay details
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Lodge info card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          widget.destination.imageUrl,
                          width: 100,
                          height: 85,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.destination.roomType,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.destination.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(
                                  widget.destination.rating.toString(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.destination.area}, ${widget.destination.city}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Trip Details Section
                  const Text(
                    'Your trip details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Clean trip grid rows
                  _buildTripDetailRow('Dates', widget.selectedDatesText, Icons.calendar_today_outlined),
                  const SizedBox(height: 12),
                  _buildTripDetailRow('Room Number', 'Room ${widget.selectedRoomNumber}', Icons.meeting_room_outlined),
                  const SizedBox(height: 12),
                  _buildTripDetailRow('Guest Profile', UserSession.userName ?? 'Guest User', Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildTripDetailRow('Contact Phone', UserSession.userPhone ?? '', Icons.phone_outlined),
                  const SizedBox(height: 32),

                  // Airbnb-style "Pay with" Row
                  const Text(
                    'Pay with',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_getPaymentIcon(_selectedPaymentMethod), color: Colors.black87, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _selectedPaymentMethod,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showPaymentBottomSheet,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Real Payment Detail Inputs (Changes depending on selected method)
                  _buildDynamicPaymentInputs(),
                  const SizedBox(height: 32),

                  // Price Details
                  const Text(
                    'Price details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatPrice(widget.destination.price)} x ${widget.numNights} night${widget.numNights > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                      ),
                      Text(
                        _formatPrice(roomTotal),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Fee',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                      ),
                      Text(
                        _formatPrice(serviceFee),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total (TZS)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatPrice(grandTotal),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 25.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
                        SizedBox(height: 20),
                        Text(
                          'Securing your booking...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
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
            onPressed: _isLoading ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Confirm Booking • ${_formatPrice(grandTotal)}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
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

class BookingSuccessScreen extends StatelessWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;
  final String guestName;
  final String guestPhone;
  final String paymentMethod;
  final String bookingCode;
  final String selectedRoomNumber;

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
  }) : super(key: key);

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final roomTotal = destination.price * numNights;
    final grandTotal = roomTotal + 5000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lodge Booked Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your room reservation has been confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 35),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESERVATION SUMMARY',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryRow('Booking Code', bookingCode, isHighlight: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Lodge Name', destination.name),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Room Assigned', 'Room $selectedRoomNumber', isHighlight: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Location', '${destination.area}, ${destination.city}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Dates', selectedDatesText),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Guests', guestName),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Payment Option', paymentMethod),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total Amount', _formatPrice(grandTotal), isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Important Room Guidelines',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      destination.condition,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          bookingCode: bookingCode,
                          lodgeName: destination.name,
                          roomNumber: selectedRoomNumber,
                          location: '${destination.area}, ${destination.city}',
                          dates: selectedDatesText,
                          guestName: guestName,
                          guestPhone: guestPhone,
                          paymentMethod: paymentMethod,
                          numNights: numNights,
                          pricePerNight: destination.price,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, color: Colors.black87),
                  label: const Text('View Full Invoice Receipt', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Go Back to Home',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w600,
            color: isHighlight 
                ? Colors.blue.shade700 
                : (isBold ? Colors.red.shade900 : Colors.black87),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:fastnet_mobile_front_end/services/receipt_pdf_service.dart';

class ReceiptScreen extends StatelessWidget {
  final String bookingCode;
  final String lodgeName;
  final String roomNumber;
  final String location;
  final String dates;
  final String guestName;
  final String guestPhone;
  final String paymentMethod;
  final int numNights;
  final int pricePerNight;
  final String? paymentTime;
  final List<Map<String, dynamic>> extraServices;
  /// Signed verification URL from the backend (`verify_url`). When present
  /// the QR encodes it so any camera opens the live verify page; otherwise
  /// it falls back to the legacy booking payload.
  final String? verifyUrl;

  const ReceiptScreen({
    Key? key,
    required this.bookingCode,
    required this.lodgeName,
    required this.roomNumber,
    required this.location,
    required this.dates,
    required this.guestName,
    required this.guestPhone,
    required this.paymentMethod,
    required this.numNights,
    required this.pricePerNight,
    this.paymentTime,
    this.extraServices = const [],
    this.verifyUrl,
  }) : super(key: key);

  String _formatPrice(int price) {
    return ReceiptPdfService.formatPrice(price);
  }

  /// Opens the real web support page in the external browser, with an
  /// offline/unsupported fallback that still shows the address.
  ///
  /// Uses [launchUrl]'s own result instead of gating on [canLaunchUrl]:
  /// on Android 11+ package-visibility rules make `canLaunchUrl` return
  /// false for https even when a browser would open fine (hence the
  /// previous "could not open" dead-end). The manifest `<queries>` block
  /// covers the check anyway; this stays correct with or without it.
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

  // ───────────────────────────────────────────────────────────────────────────
  // PDF GENERATION (DELEGATES TO SHARED ReceiptPdfService)
  // ───────────────────────────────────────────────────────────────────────────
  Future<File> _generatePdf(int grandTotal, int roomTotal, int extraTotal, int serviceFee, String transactionId, String paymentTime) async {
    final bytes = await ReceiptPdfService.generate(
      bookingCode: bookingCode,
      lodgeName: lodgeName,
      roomNumber: roomNumber,
      location: location,
      dates: dates,
      guestName: guestName,
      guestPhone: guestPhone,
      numNights: numNights,
      pricePerNight: pricePerNight,
      paymentTime: paymentTime,
      extraServices: extraServices,
      verifyUrl: verifyUrl,
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/FastNetStays-Booking-Confirmation-$bookingCode.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SCREEN UI BUILD
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _shareReceipt(BuildContext context, int grandTotal, int roomTotal, int extraTotal, int serviceFee, String transactionId, String paymentTime) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final file = await _generatePdf(grandTotal, roomTotal, extraTotal, serviceFee, transactionId, paymentTime);

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles([XFile(file.path)], text: 'FastNetStays Booking Confirmation - $lodgeName');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomTotal = pricePerNight * numNights;
    int extraTotal = 0;
    for (var svc in extraServices) {
      extraTotal += (svc['price'] as int) * (svc['quantity'] as int);
    }
    final vatTotal = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal + extraTotal;
    const serviceFee = 5000;

    final transactionId = 'FNS-${bookingCode.replaceAll('-', '')}';
    final actualPaymentTime = paymentTime ?? '2026-08-01 09:00 AM';

    final arrivalDate = dates.split(' - ').first;
    final departureDate = dates.contains('-') ? dates.split('-').last.trim() : 'Next Day';
    final refNo = '337038${bookingCode.replaceAll('-', '').substring(0, 4)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Booking Confirmation', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Voucher',
            onPressed: () => _shareReceipt(context, grandTotal, roomTotal, extraTotal, serviceFee, transactionId, actualPaymentTime),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Outer Border Container Box (Exact match to reference image)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/fastnet_logo_icon.png',
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF1A73E8),
                                size: 26),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'fastnetstays.com',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202124),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(text: 'Booking ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black)),
                                  TextSpan(text: 'Confirmation', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFFD9251D))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Please present either an electronic or paper copy of your booking confirmation upon check-in.',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 8.5, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Full-width Grey Watermark Band
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                    color: Colors.grey.shade400,
                    child: const Text(
                      'fastnetstays.com    fastnetstays.com    fastnetstays.com    fastnetstays.com    fastnetstays.com',
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Main 2-Column Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 13,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _uiDetailRow('Booking ID :', bookingCode, isBold: true),
                            _uiDetailRow('Booking Reference No :', refNo, isBold: true),
                            _uiDetailRow('Client :', guestName.toUpperCase(), isBold: true),
                            _uiDetailRow('Member ID :', '53370111', isBold: true),
                            _uiDetailRow('Country of Residence :', 'Tanzania', isBold: true),
                            _uiDetailRow('Property Contact :', guestPhone.isNotEmpty ? guestPhone : '+255 700 000 000', isBold: true),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text('Property :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                      color: Colors.white,
                                    ),
                                    child: Text(lodgeName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text('Room Assigned :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                      color: Colors.white,
                                    ),
                                    child: Text('Room $roomNumber', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text('Address :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                      color: Colors.white,
                                    ),
                                    child: Text('$location, Tanzania', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Column Form Box Panel (Grey background container)
                      Expanded(
                        flex: 11,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          color: const Color(0xFFEFEFEF),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _uiFormBox('Number of Rooms :', '1'),
                              _uiFormBox('Number of Extra Beds :', '0'),
                              _uiFormBox('Number of Adults :', '2'),
                              _uiFormBox('Number of Children :', '0'),
                              _uiFormBox('Room Type :', 'Standard King Room', isBold: true),
                              _uiFormBox('Room Number :', 'Room $roomNumber', isBold: true),
                              _uiFormBox('Promotion :', ''),
                              const SizedBox(height: 4),
                              const Text(
                                'For Full Promotion details and conditions see confirmation email',
                                style: TextStyle(fontSize: 8.5, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. Cancellation Policy Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    color: const Color(0xFFEFEFEF),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 9.5, color: Colors.black87, height: 1.3),
                        children: [
                          TextSpan(text: 'Cancellation Policy: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: 'Any cancellation received will incur a charge of 34% of the booking value. Failure to arrive at your hotel or property will be treated as a No-Show and will incur a charge of 100% of the booking value (Hotel policy).',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // 4. Benefits Included Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    color: const Color(0xFFEFEFEF),
                    child: const Text(
                      'Benefits Included: -',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 5. Arrival / Departure & Payment Details Box
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        // Arrival / Departure Row
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('Arrival :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      color: const Color(0xFFD9D9D9),
                                      child: Text(arrivalDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('Departure :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      color: const Color(0xFFD9D9D9),
                                      child: Text(departureDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Payment Details Note & Stamp / QR Box
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Details :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(6),
                                    color: const Color(0xFFEFEFEF),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            style: TextStyle(fontSize: 9, height: 1.3),
                                            children: [
                                              TextSpan(text: 'Please note: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD9251D))),
                                              TextSpan(text: 'Payment for this booking has been processed via FastNetStays. Payment confirmation is verified by property.', style: TextStyle(color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 8, height: 1.3),
                                            children: [
                                              const TextSpan(text: 'Note to property: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD9251D))),
                                              TextSpan(text: 'Reservation was made under FastNetStays booking ID $bookingCode', style: const TextStyle(color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stamp & QR Box
                            Expanded(
                              flex: 9,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    QrImageView(
                                      data: (verifyUrl?.isNotEmpty ?? false)
                                          ? verifyUrl!
                                          : 'FASTNETSTAYS-BOOKING:$bookingCode|LODGE:$lodgeName|ROOM:$roomNumber|GUEST:$guestName',
                                      version: QrVersions.auto,
                                      size: 58.0,
                                      gapless: false,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Colors.black87,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Authorized Stamp & Signature',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. Remarks
                  const Text('Remarks :', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  Text('Included : Taxes and fees ${_formatPrice(vatTotal)}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
                  const Text('NonSmoke', style: TextStyle(fontSize: 9.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'All special requests are subject to availability upon arrival',
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openSupport(context),
                          child: Text.rich(
                            const TextSpan(
                              style: TextStyle(fontSize: 9, color: Colors.black87, height: 1.35),
                              children: [
                                TextSpan(text: 'For any issues or questions, please visit '),
                                TextSpan(
                                  text: AppConstants.supportUrlDisplay,
                                  style: TextStyle(
                                    color: Color(0xFF1A73E8),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 7. Notes Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                      color: const Color(0xFFFDFDFD),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(height: 6),
                        _uiNoteItem('1.', 'At check-in, you must present a valid photo ID with your address confirming the same name as the lead guest on the booking. For bookings paid with a credit card, you may also need to present the card used to make the payment. Failure to do so may result in the hotel requesting additional payment or your reservation not being honored.', isImportant: true),
                        const SizedBox(height: 5),
                        _uiNoteItem('2.', 'All rooms are guaranteed on the day of arrival. In the case of a no-show, your room(s) will be released and you will be subject to the terms and conditions of the Cancellation/No-Show Policy specified at the time you made the booking as well as noted in the Confirmation Email.'),
                        const SizedBox(height: 5),
                        _uiNoteItem('3.', 'The total price for this booking does not include mini-bar items, telephone usage, laundry service, etc. The property will bill you directly.'),
                        const SizedBox(height: 5),
                        _uiNoteItem('4.', 'In cases where Breakfast is included with the room rate, please note that certain properties may charge extra for children travelling with their parents. If applicable, the property will bill you directly. Upon arrival, if you have any questions, please verify with the property.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 8. Calm & Minimal Thank You Banner Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      border: Border.all(color: Colors.grey.shade400, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thank you for choosing FastNetStays.com!',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We wish you a pleasant and comfortable stay.',
                          style: TextStyle(fontSize: 8.5, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _uiDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.w900 : FontWeight.normal, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uiFormBox(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.0),
              ),
              child: Text(
                value,
                style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.w900 : FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uiNoteItem(String number, String text, {bool isImportant = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Text(number, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        Expanded(
          child: isImportant
              ? RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 8.5, color: Colors.black87, height: 1.35),
                    children: [
                      const TextSpan(text: 'IMPORTANT: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD9251D))),
                      TextSpan(text: text),
                    ],
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(fontSize: 7.5, color: Colors.black87, height: 1.35),
                ),
        ),
      ],
    );
  }
}

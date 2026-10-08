import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fastnet_mobile_front_end/config/constants.dart';

/// Builds the exact same booking confirmation e-receipt PDF that users see on
/// screen (used both for in-app sharing and the emailed attachment).
class ReceiptPdfService {
  static String formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  static String toAscii(String input) {
    return String.fromCharCodes(input.runes.map((char) {
      if (char > 127) {
        if (char == 0x2013 || char == 0x2014 || char == 0x2212) return 0x2d;
        if (char == 0x2022) return 0x2d;
        if (char == 0x00A0) return 0x20;
        return 0x20;
      }
      return char;
    }));
  }

  static pw.Widget _pdfDetailRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFormBox(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
              ),
              child: pw.Text(
                value,
                style: pw.TextStyle(fontSize: 8.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfNoteItem(String number, String text, {bool isImportant = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 14,
          child: pw.Text(number, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Expanded(
          child: isImportant
              ? pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black, height: 1.35),
                    children: [
                      pw.TextSpan(text: 'IMPORTANT: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.TextSpan(text: text),
                    ],
                  ),
                )
              : pw.Text(
                  text,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black, height: 1.35),
                ),
        ),
      ],
    );
  }

  /// Generates the confirmation receipt PDF bytes.
  static Future<Uint8List> generate({
    required String bookingCode,
    required String lodgeName,
    required String roomNumber,
    required String location,
    required String dates,
    required String guestName,
    required String guestPhone,
    required int numNights,
    required int pricePerNight,
    String? paymentTime,
    List<Map<String, dynamic>> extraServices = const [],
    String? verifyUrl,
  }) async {
    final pdf = pw.Document();

    final cleanDates = toAscii(dates);
    final cleanLodgeName = toAscii(lodgeName);
    final cleanRoomNumber = toAscii(roomNumber);
    final cleanLocation = toAscii(location);
    final cleanGuestName = toAscii(guestName).toUpperCase();

    final arrivalDate = cleanDates.split(' - ').first;
    final departureDate = cleanDates.contains('-') ? cleanDates.split('-').last.trim() : 'Next Day';
    final refNo = '337038${bookingCode.replaceAll('-', '').substring(0, 4)}';

    // App logo (same mark used across the app: blue pin + plane icon).
    // Loaded from the bundled asset; falls back to a text wordmark if
    // the asset cannot be read (e.g. outside a Flutter binding in tests).
    Uint8List? logoBytes;
    try {
      final data =
          await rootBundle.load('assets/images/fastnet_logo_icon.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }
    final logoImage =
        logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final roomTotal = pricePerNight * numNights;
    int extraTotal = 0;
    for (var svc in extraServices) {
      extraTotal += (svc['price'] as int) * (svc['quantity'] as int);
    }
    final vatTotal = (roomTotal * 0.125).round();
    final grandTotal = roomTotal + vatTotal + extraTotal;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── 1. Top Header ──────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null)
                          pw.Image(logoImage, width: 30, height: 30),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          'fastnetstays.com',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Booking ',
                                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                                ),
                                pw.TextSpan(
                                  text: 'Confirmation',
                                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Please present either an electronic or paper copy of your booking confirmation upon check-in.',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                            textAlign: pw.TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Full-width Grey Watermark Band
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: PdfColors.grey400,
                  child: pw.Text(
                    'fastnetstays.com    fastnetstays.com    fastnetstays.com    fastnetstays.com    fastnetstays.com    fastnetstays.com',
                    style: pw.TextStyle(fontSize: 9.5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 14),

                // ── 2. Top Main Section (2 Columns) ─────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 12,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfDetailRow('Booking ID :', bookingCode, isBold: true),
                          _pdfDetailRow('Booking Reference No :', refNo, isBold: true),
                          _pdfDetailRow('Client :', cleanGuestName, isBold: true),
                          _pdfDetailRow('Member ID :', '53370111', isBold: true),
                          _pdfDetailRow('Country of Residence :', 'Tanzania', isBold: true),
                          _pdfDetailRow('Property Contact :', guestPhone.isNotEmpty ? guestPhone : '+255 700 000 000', isBold: true),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 110,
                                child: pw.Text('Property :', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                              ),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Text(cleanLodgeName, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 110,
                                child: pw.Text('Room Assigned :', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                              ),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Text('Room $cleanRoomNumber', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 110,
                                child: pw.Text('Address :', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                              ),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Text('$cleanLocation, Tanzania', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),

                    pw.Expanded(
                      flex: 11,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        color: PdfColors.grey200,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfFormBox('Number of Rooms :', '1'),
                            _pdfFormBox('Number of Extra Beds :', '0'),
                            _pdfFormBox('Number of Adults :', '2'),
                            _pdfFormBox('Number of Children :', '0'),
                            _pdfFormBox('Room Type :', 'Standard King Room', isBold: true),
                            _pdfFormBox('Room Number :', 'Room $cleanRoomNumber', isBold: true),
                            _pdfFormBox('Promotion :', ''),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'For Full Promotion details and conditions see confirmation email',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // ── 3. Cancellation Policy Box ──────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey200,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                      children: [
                        pw.TextSpan(text: 'Cancellation Policy: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        const pw.TextSpan(
                          text: 'Any cancellation received will incur a charge of 34% of the booking value. Failure to arrive at your hotel or property will be treated as a No-Show and will incur a charge of 100% of the booking value (Hotel policy).',
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                // ── 4. Benefits Included Box ────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    'Benefits Included: -',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 14),

                // ── 5. Arrival / Departure & Payment Details Box ─────────────
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Row(
                              children: [
                                pw.Text('Arrival :', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(width: 6),
                                pw.Expanded(
                                  child: pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    color: PdfColors.grey300,
                                    child: pw.Text(arrivalDate, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 14),
                          pw.Expanded(
                            child: pw.Row(
                              children: [
                                pw.Text('Departure :', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(width: 6),
                                pw.Expanded(
                                  child: pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    color: PdfColors.grey300,
                                    child: pw.Text(departureDate, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),

                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 14,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Payment Details :', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.all(7),
                                  color: PdfColors.grey200,
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          style: const pw.TextStyle(fontSize: 8.5),
                                          children: [
                                            pw.TextSpan(text: 'Please note: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                                            const pw.TextSpan(text: 'Payment for this booking has been processed via FastNetStays. Payment confirmation is verified by property.', style: pw.TextStyle(color: PdfColors.black)),
                                          ],
                                        ),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          style: const pw.TextStyle(fontSize: 8.5),
                                          children: [
                                            pw.TextSpan(text: 'Note to property: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                                            pw.TextSpan(text: 'Reservation was made under FastNetStays booking ID $bookingCode', style: const pw.TextStyle(color: PdfColors.black)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 10),

                          pw.Expanded(
                            flex: 9,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                                color: PdfColors.white,
                              ),
                              child: pw.Column(
                                children: [
                                  pw.BarcodeWidget(
                                    barcode: pw.Barcode.qrCode(),
                                    data: (verifyUrl?.isNotEmpty ?? false)
                                        ? verifyUrl!
                                        : 'FASTNETSTAYS-BOOKING:$bookingCode|LODGE:$cleanLodgeName|ROOM:$cleanRoomNumber|GUEST:$cleanGuestName',
                                    width: 62,
                                    height: 62,
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Authorized Stamp & Signature',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                                    textAlign: pw.TextAlign.center,
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
                pw.SizedBox(height: 14),

                // ── 6. Remarks ──────────────────────────────────────────────
                pw.Text('Remarks :', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('Included : Taxes and fees ${formatPrice(grandTotal - roomTotal)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('NonSmoke', style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('All special requests are subject to availability upon arrival', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.UrlLink(
                        destination: AppConstants.supportUrl,
                        child: pw.RichText(
                          textAlign: pw.TextAlign.end,
                          text: pw.TextSpan(
                            style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColors.grey800),
                            children: [
                              const pw.TextSpan(
                                  text:
                                      'For any issues or questions, please visit '),
                              pw.TextSpan(
                                text: AppConstants.supportUrlDisplay,
                                style: pw.TextStyle(
                                  color: PdfColors.blue,
                                  fontWeight: pw.FontWeight.bold,
                                  decoration: pw.TextDecoration.underline,
                                ),
                              ),
                              const pw.TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // ── 7. Notes Box ────────────────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Notes', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      _pdfNoteItem('1.', 'At check-in, you must present a valid photo ID with your address confirming the same name as the lead guest on the booking. For bookings paid with a credit card, you may also need to present the card used to make the payment. Failure to do so may result in the hotel requesting additional payment or your reservation not being honored.', isImportant: true),
                      pw.SizedBox(height: 5),
                      _pdfNoteItem('2.', 'All rooms are guaranteed on the day of arrival. In the case of a no-show, your room(s) will be released and you will be subject to the terms and conditions of the Cancellation/No-Show Policy specified at the time you made the booking as well as noted in the Confirmation Email.'),
                      pw.SizedBox(height: 5),
                      _pdfNoteItem('3.', 'The total price for this booking does not include mini-bar items, telephone usage, laundry service, etc. The property will bill you directly.'),
                      pw.SizedBox(height: 5),
                      _pdfNoteItem('4.', 'In cases where Breakfast is included with the room rate, please note that certain properties may charge extra for children travelling with their parents. If applicable, the property will bill you directly. Upon arrival, if you have any questions, please verify with the property.'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // ── 8. Calm & Minimal Thank You Banner ──────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.grey400, width: 1.0),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Thank you for choosing FastNetStays.com!',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'We wish you a pleasant and comfortable stay.',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}

import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> extraServices; // ordered food, spa, etc.

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
    this.extraServices = const [],
  }) : super(key: key);

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _simulateDownload(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const DownloadSimulationDialog();
      },
    );
  }

  void _simulateShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing options opened! Link copied to clipboard.'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomTotal = pricePerNight * numNights;
    int extraTotal = 0;
    for (var svc in extraServices) {
      extraTotal += (svc['price'] as int) * (svc['quantity'] as int);
    }
    const serviceFee = 5000;
    final grandTotal = roomTotal + serviceFee + extraTotal;

    // Simulated transaction details
    final transactionId = 'TZS-TXN-${bookingCode.split('-')[1]}';
    const paymentTime = 'Jul 01, 2026 • 07:34 AM';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Invoice Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _simulateShare(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          children: [
            // Receipt Card container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Receipt Header (Merchant Info)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, color: Colors.red.shade900, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PAYMENT SUCCESSFUL',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(grandTotal),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transaction ID: $transactionId',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Dotted line with ticket notches
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.constrainWidth() / 10).floor(),
                                (index) => SizedBox(
                                  width: 5,
                                  height: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Receipt Body (Itemized summary)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('RESERVATION DETAILS'),
                        const SizedBox(height: 12),
                        _buildRow('Merchant', 'LODGE RESERVATIONS Ltd.'),
                        _buildRow('Lodge Name', lodgeName),
                        _buildRow('Room Number', 'Room $roomNumber'),
                        _buildRow('Location', location),
                        _buildRow('Dates', dates),
                        _buildRow('Guest Profile', guestName),
                        _buildRow('Payment Time', paymentTime),
                        _buildRow('Payment Wallet', paymentMethod),

                        const SizedBox(height: 24),
                        _buildSectionHeader('CHARGE BREAKDOWN'),
                        const SizedBox(height: 12),
                        _buildRow('Room Base Charge (${_formatPrice(pricePerNight)} x $numNights nights)', _formatPrice(roomTotal)),
                        _buildRow('Lodge Service Fee', _formatPrice(serviceFee)),
                        
                        // Extra services (food order checkout)
                        for (var svc in extraServices)
                          _buildRow(
                            '${svc['description']} (x${svc['quantity']})',
                            _formatPrice((svc['price'] as int) * (svc['quantity'] as int)),
                          ),

                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL CHARGE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            Text(
                              _formatPrice(grandTotal),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade900),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        // QR Code placeholder using visual containers
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(12, (y) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(12, (x) {
                                        // Generate simulated QR code blocks
                                        final isFilled = (x + y) % 3 == 0 || (x * y) % 5 == 1 || (x < 3 && y < 3) || (x > 8 && y < 3) || (x < 3 && y > 8);
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          color: isFilled ? Colors.black : Colors.white,
                                        );
                                      }),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'SCAN AT RECEPTION FOR FAST CHECK-IN',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _simulateDownload(context),
                    icon: const Icon(Icons.download_outlined, color: Colors.black87),
                    label: const Text('Download Receipt', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadSimulationDialog extends StatefulWidget {
  const DownloadSimulationDialog({Key? key}) : super(key: key);

  @override
  State<DownloadSimulationDialog> createState() => _DownloadSimulationDialogState();
}

class _DownloadSimulationDialogState extends State<DownloadSimulationDialog> {
  double _progress = 0.0;
  String _status = 'Compiling receipt details...';

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    // Simulate compilation steps
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _progress = 0.35;
          _status = 'Generating PDF vector graphics...';
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _progress = 0.70;
          _status = 'Signing invoice with CRDB payment hash...';
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _status = 'Saved PDF to Downloads successfully!';
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt PDF saved to downloads folder.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: _progress,
                color: Colors.red.shade900,
                backgroundColor: Colors.grey.shade200,
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating PDF Invoice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

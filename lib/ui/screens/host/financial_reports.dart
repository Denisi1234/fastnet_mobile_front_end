import 'package:flutter/material.dart';

class FinancialReports extends StatefulWidget {
  const FinancialReports({Key? key}) : super(key: key);

  @override
  State<FinancialReports> createState() => _FinancialReportsState();
}

class _FinancialReportsState extends State<FinancialReports> {
  final List<Map<String, dynamic>> _payouts = [
    {'id': 'PAY-9042', 'date': 'Jun 15, 2026', 'method': 'CRDB Bank', 'amount': 330000, 'status': 'Paid'},
    {'id': 'PAY-8812', 'date': 'Jun 03, 2026', 'method': 'NMB Bank', 'amount': 500000, 'status': 'Paid'},
    {'id': 'PAY-7401', 'date': 'May 20, 2026', 'method': 'Vodacom M-Pesa', 'amount': 150000, 'status': 'Paid'},
  ];

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _requestPayout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Payout'),
          content: const Text('Do you want to initiate an instant payout of your outstanding balance to your linked CRDB bank account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _payouts.insert(0, {
                    'id': 'PAY-${9100 + _payouts.length}',
                    'date': 'Just now',
                    'method': 'CRDB Bank',
                    'amount': 250000,
                    'status': 'Processing',
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payout requested successfully! Fund arrival expected within 2 hours.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
              child: const Text('Confirm Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Financial Reports', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade700, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade900.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OUTSTANDING BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  const Text('TSh 250,000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL EARNED (MTD)', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_formatPrice(1230000), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _requestPayout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text('Instant Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bar Chart Section
            const Text('Monthly Revenue Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Jan', 400000, 0.4),
                      _buildBar('Feb', 650000, 0.65),
                      _buildBar('Mar', 500000, 0.5),
                      _buildBar('Apr', 850000, 0.85),
                      _buildBar('May', 720000, 0.72),
                      _buildBar('Jun', 1230000, 1.0, isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red.shade900, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Total Net Earnings (Excl. 3% service fee)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recent payouts list
            const Text('Recent Payout Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = _payouts[index];
                final isPaid = p['status'] == 'Paid';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                            radius: 20,
                            child: Icon(
                              isPaid ? Icons.arrow_downward : Icons.autorenew,
                              color: isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Paid to ${p['method']} • ${p['date']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatPrice(p['amount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            p['status'],
                            style: TextStyle(
                              color: isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int amount, double ratio, {bool isHighlight = false}) {
    final height = 120 * ratio;
    final color = isHighlight ? Colors.red.shade900 : Colors.grey.shade400;

    return Column(
      children: [
        Text(
          amount >= 1000000 ? '${(amount / 1000000).toStringAsFixed(1)}M' : '${(amount / 1000).round()}k',
          style: TextStyle(fontSize: 10, color: isHighlight ? Colors.red.shade900 : Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: height < 10 ? 10 : height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

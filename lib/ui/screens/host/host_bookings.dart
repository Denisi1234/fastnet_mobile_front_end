import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';

class HostBookings extends StatefulWidget {
  const HostBookings({Key? key}) : super(key: key);

  @override
  State<HostBookings> createState() => _HostBookingsState();
}

class _HostBookingsState extends State<HostBookings> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showStatusDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manage Booking Status'),
          content: const Text('Set the current status of this guest stay reservation:'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  booking['status'] = 'Completed';
                });
                Navigator.pop(context);
              },
              child: const Text('Mark Completed', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  booking['status'] = 'Canceled';
                });
                Navigator.pop(context);
              },
              child: const Text('Cancel Reservation', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _messageGuest(Map<String, dynamic> booking) {
    final msgController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message Guest for stay: ${booking['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your message to the guest here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (msgController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent to guest successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  child: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read directly from client-side bookings list for real-time synchronization!
    final reservations = BookingsData.list;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Guest Bookings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No bookings received yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Received traveler stays will appear here.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final res = reservations[index];
                final status = res['status'] ?? 'Confirmed';

                Color statusBg = Colors.blue.shade50;
                Color statusText = Colors.blue.shade700;
                if (status == 'Completed') {
                  statusBg = Colors.green.shade50;
                  statusText = Colors.green.shade700;
                } else if (status == 'Checked In') {
                  statusBg = Colors.orange.shade50;
                  statusText = Colors.orange.shade800;
                } else if (status == 'Canceled') {
                  statusBg = Colors.red.shade50;
                  statusText = Colors.red.shade700;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Traveler Guest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.home_work_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(res['name'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(res['dates'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Code: ${res['code'] ?? ''}', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Stay Earnings', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(_formatPrice(res['price'] ?? 0), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.black54),
                                onPressed: () => _showStatusDialog(res),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54),
                                onPressed: () => _messageGuest(res),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

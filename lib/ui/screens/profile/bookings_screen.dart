import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/bookings_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/receipt_screen.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/lodge_services/lodge_services_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/guest_messages.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  Widget _buildAnticipationChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'AirbnbCereal',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Completed':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
      case 'Checked In':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        break;
      case 'Confirmed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      default: // Cancelled
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'AirbnbCereal',
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsProvider>().bookings;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontFamily: 'AirbnbCereal',
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_border, size: 56, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No active bookings',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your reserved rooms will appear here.',
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final b = bookings[index];
                final isConfirmed = b['status'] == 'Confirmed';
                final isCheckedIn = b['status'] == 'Checked In';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Top Row Info (Compact Design)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                b['imageUrl'] ?? 'assets/images/house3.webp',
                                width: 95,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatusBadge(b['status']),
                                      Text(
                                        'Code: ${b['code'].split('-')[1]}',
                                        style: TextStyle(
                                          fontFamily: 'AirbnbCereal',
                                          fontSize: 10.5,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b['name'],
                                    style: const TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 13, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${b['area']}, ${b['city']}',
                                          style: TextStyle(
                                            fontFamily: 'AirbnbCereal',
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Details Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DATES',
                                  style: TextStyle(
                                    fontFamily: 'AirbnbCereal',
                                    fontSize: 9.5,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  b['dates'],
                                  style: const TextStyle(
                                    fontFamily: 'AirbnbCereal',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TOTAL PAID',
                                  style: TextStyle(
                                    fontFamily: 'AirbnbCereal',
                                    fontSize: 9.5,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatPrice(b['price']),
                                  style: TextStyle(
                                    fontFamily: 'AirbnbCereal',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Anticipation Panel
                      if (isConfirmed) ...[
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withValues(alpha: 0.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.hourglass_bottom, size: 15, color: Colors.blue.shade800),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Check-in in 2 days',
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.wb_sunny_outlined, size: 15, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '28°C Sunny',
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildAnticipationChip(Icons.map_outlined, 'Local Guide', Colors.teal.shade700),
                                    const SizedBox(width: 8),
                                    _buildAnticipationChip(Icons.checklist_rtl, 'Checklist', Colors.purple.shade700),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        if (!UserSession.isLoggedIn) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please log in first to message the host.')),
                                          );
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GuestChatDetailScreen(
                                              thread: {
                                                'hostId': 1,
                                                'hostName': 'John Doe (Host)',
                                                'lodgeName': b['name'] ?? 'Lodge Stay',
                                                'avatar': 'assets/images/man2.jpeg',
                                                'lastMessage': '',
                                                'time': 'Just now',
                                                'unread': false,
                                                'isOnline': true,
                                                'isReal': true,
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: _buildAnticipationChip(Icons.chat_bubble_outline, 'Message Host', Colors.indigo.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Actions Row
                      if (isConfirmed || isCheckedIn) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final dest = destinations.firstWhere(
                                      (d) => b['name'].toString().contains(d.name) || d.name.contains(b['name'].toString().split('-')[0].trim()),
                                      orElse: () => destinations.first,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReceiptScreen(
                                          bookingCode: b['code'] ?? 'TZ-00000-GEN',
                                          lodgeName: b['name'] ?? 'Lodge Stay',
                                          roomNumber: b['name'].toString().contains('Room') 
                                              ? b['name'].toString().split('Room')[1].trim()
                                              : '204',
                                          location: '${b['area']}, ${b['city']}',
                                          dates: b['dates'] ?? 'Jun 12 – 15, 2026',
                                          guestName: UserSession.userName ?? 'Traveler',
                                          guestPhone: UserSession.userPhone ?? '+255 712 345 678',
                                          paymentMethod: 'Vodacom M-Pesa',
                                          numNights: b['nights'] ?? 3,
                                          pricePerNight: dest.price,
                                          paymentTime: b['paymentTime'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.receipt_long, size: 14),
                                  label: const Text(
                                    'Receipt',
                                    style: TextStyle(fontFamily: 'AirbnbCereal', fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isConfirmed)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.read<BookingsProvider>().updateStatus(index, 'Checked In');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Successfully Checked In! In-stay services are now active.'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text(
                                      'Check In',
                                      style: TextStyle(fontFamily: 'AirbnbCereal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                )
                              else if (isCheckedIn)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LodgeServicesDashboard()),
                                      ).then((_) => setState(() {}));
                                    },
                                    icon: const Icon(Icons.room_service, size: 14, color: Colors.white),
                                    label: const Text(
                                      'Lodge Services',
                                      style: TextStyle(fontFamily: 'AirbnbCereal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade900,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

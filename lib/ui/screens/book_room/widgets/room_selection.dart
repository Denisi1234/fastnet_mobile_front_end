import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/booking_checkout.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/web_header.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;

  const RoomSelectionScreen({
    Key? key,
    required this.destination,
    required this.selectedDatesText,
    required this.numNights,
  }) : super(key: key);

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  late List<Map<String, dynamic>> _rooms;
  String? _selectedRoomNumber;

  @override
  void initState() {
    super.initState();
    _generateRooms();
  }

  void _generateRooms() {
    if (widget.destination.rooms != null && widget.destination.rooms!.isNotEmpty) {
      _rooms = widget.destination.rooms!.map((r) {
        return {
          'id': r['id'] as int,
          'number': r['room_number'] ?? 'Room',
          'isBooked': r['status'] == 'booked',
        };
      }).toList();
      return;
    }

    final nameHash = widget.destination.name.hashCode;
    _rooms = List.generate(16, (index) {
      final roomNo = '${(nameHash % 5 + 1) * 100 + index + 1}';
      final isBooked = (index * 3 + nameHash) % 5 == 0 || index == 2 || index == 7;
      
      return {
        'id': index + 1,
        'number': roomNo,
        'isBooked': isBooked,
      };
    });
  }

  // Get specific photos for a room dynamically to solve "booking pictures" focus
  List<String> _getRoomImages(String roomNum) {
    final lastDigit = int.tryParse(roomNum.substring(roomNum.length - 1)) ?? 0;
    switch (lastDigit % 4) {
      case 0:
        return ['assets/images/room.webp', 'assets/images/home.webp'];
      case 1:
        return ['assets/images/LakeArrowhead.webp', 'assets/images/house2.webp'];
      case 2:
        return ['assets/images/Santorini.webp', 'assets/images/home2.webp'];
      default:
        return ['assets/images/abiansemal.webp', 'assets/images/house3.webp'];
    }
  }

  String _getRoomType(String roomNum) {
    final lastDigit = int.tryParse(roomNum.substring(roomNum.length - 1)) ?? 0;
    if (lastDigit % 3 == 0) return 'Premium Deluxe Room';
    if (lastDigit % 3 == 1) return 'Executive Balcony Suite';
    return 'Comfort Standard Queen';
  }

  List<String> _getRoomFeatures(String roomNum) {
    final lastDigit = int.tryParse(roomNum.substring(roomNum.length - 1)) ?? 0;
    if (lastDigit % 2 == 0) {
      return ['King Bed', 'AC', 'Pool View', 'Private Balcony'];
    } else {
      return ['Queen Bed', 'Wi-Fi', 'Hot Shower', 'Garden View'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;
    if (isDesktopWeb) {
      return _buildDesktopWebView(context);
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5FA),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 22, color: Colors.grey.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    Text(
                      '${widget.selectedDatesText}, ${widget.destination.guests} guest${widget.destination.guests > 1 ? 's' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _rooms.length + 1,
        separatorBuilder: (_, index) => index == 0 ? const SizedBox(height: 14) : const SizedBox(height: 18),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildRoomSelectionIntro();
          }

          return _buildRoomCard(_rooms[index - 1]);
        },
      ),
    );
  }

  Widget _buildRoomSelectionIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.destination.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 4),
            Text(
            widget.selectedDatesText,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            'Choose a room that matches your stay and tap Book to continue.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomNumber = room['number']?.toString() ?? 'N/A';
    final isBooked = room['isBooked'] == true || room['is_booked'] == true;
    final isSelected = _selectedRoomNumber == roomNumber;
    final roomImages = _getRoomImages(roomNumber);
    final roomType = _getRoomType(roomNumber);
    final roomFeatures = _getRoomFeatures(roomNumber);
    final roomPrice = _buildRoomPrice(roomNumber);
    final roomSize = _buildRoomSize(roomNumber);
    final capacity = _buildRoomCapacity(roomNumber);
    final bedLabel = _buildBedLabel(roomNumber);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    roomType,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  roomSize,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.52,
                    child: PageView.builder(
                      itemCount: roomImages.length,
                      itemBuilder: (context, imageIndex) {
                        return Image.asset(
                          roomImages[imageIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: const Color(0xFFF2F5FA),
                              alignment: Alignment.center,
                              child: const Icon(Icons.bed_outlined, color: Colors.grey, size: 42),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPromoChip('Our last 2!', const Color(0xFFE8D4C9), const Color(0xFF9A4B2F)),
                      _buildPromoChip('Free cancellation', const Color(0xFFE7DBF8), const Color(0xFF7B3FE4)),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, size: 24, color: Colors.black87),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      roomImages.length > 1 ? '1/${roomImages.length}' : '1/1',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildStatPill(roomSize, Icons.square_foot_outlined),
                _buildStatPill(capacity, Icons.people_alt_outlined),
                _buildStatPill(bedLabel, Icons.bed_outlined),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roomFeatures.map((feature) => _buildAmenityChip(feature)).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2 adults',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You won\'t be charged yet',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        roomPrice,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow('Cancellation policy', Icons.info_outline),
                  _buildBenefitRow('No credit card needed', Icons.verified_outlined),
                  _buildBenefitRow('Parking', Icons.local_parking_outlined),
                  _buildBenefitRow('Free WiFi', Icons.wifi_outlined),
                  _buildBenefitRow('Only 2 left', Icons.bolt_outlined, color: const Color(0xFFB45309)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedRoomNumber = roomNumber;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text(
                      'See details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.favorite_border, size: 22, color: Colors.black87),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Rooms',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(width: 18),
                      const Text(
                        '1',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_drop_down, size: 22, color: Colors.grey.shade700),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBooked
                        ? null
                        : () => _bookRoom(roomNumber, room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isBooked ? 'Booked' : (isSelected ? 'Book again' : 'Book'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          isBooked ? 'Unavailable' : 'Pay at hotel',
                          style: const TextStyle(fontSize: 12, height: 1.1),
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
    );
  }

  Widget _buildPromoChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildStatPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBenefitRow(String label, IconData icon, {Color? color}) {
    final effectiveColor = color ?? Colors.grey.shade800;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: effectiveColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: effectiveColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _buildRoomSize(String roomNum) {
    final roomNumber = int.tryParse(roomNum) ?? 1;
    final squareMeters = 15 + (roomNumber % 5);
    final squareFeet = (squareMeters * 10.764).round();
    return '$squareMeters m²/$squareFeet ft²';
  }

  String _buildRoomCapacity(String roomNum) {
    final roomNumber = int.tryParse(roomNum) ?? 1;
    final adults = 2 + (roomNumber % 2);
    return '$adults adult${adults > 1 ? 's' : ''}';
  }

  String _buildBedLabel(String roomNum) {
    final roomNumber = int.tryParse(roomNum) ?? 1;
    return roomNumber.isEven ? '1 double bed / 1 sofa bed' : '1 double bed';
  }

  String _buildRoomPrice(String roomNum) {
    final roomNumber = int.tryParse(roomNum) ?? 1;
    final basePrice = widget.destination.price > 0 ? widget.destination.price : 42000;
    final adjusted = basePrice + (roomNumber % 4) * 2500;
    return 'TSh ${adjusted.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Future<void> _bookRoom(String roomNumber, Map<String, dynamic> room) async {
    final navigator = Navigator.of(context);
    if (!UserSession.isLoggedIn) {
      final loggedIn = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => const LoginSignupScreen(),
        ),
      );
      if (loggedIn != true) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedRoomNumber = roomNumber;
    });

    final selectedRoomId = (room['id'] as num).toInt();
    navigator.push(
      MaterialPageRoute(
        builder: (context) => BookingCheckoutScreen(
          destination: widget.destination,
          selectedDatesText: widget.selectedDatesText,
          numNights: widget.numNights,
          selectedRoomNumber: roomNumber,
          selectedRoomId: selectedRoomId,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool hasBorder) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRoomWidget(Map<String, dynamic> room) {
    final number = room['number']?.toString() ?? 'N/A';
    final isBooked = room['isBooked'] == true || room['is_booked'] == true;
    final isSelected = _selectedRoomNumber == number;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    if (isBooked) {
      bgColor = Colors.red.shade400;
      borderColor = Colors.red.shade400;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = Colors.blue.shade600;
      borderColor = Colors.blue.shade600;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedRoomNumber = null;
                } else {
                  _selectedRoomNumber = number;
                }
              });
            },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (!isBooked && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bed, 
                  size: 16, 
                  color: isSelected || isBooked ? Colors.white70 : Colors.black26
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (isBooked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 8, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopWebView(BuildContext context) {
    final d = widget.destination;
    final formattedPrice = '${(d.price).toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}/night';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF006CE4)),
                    label: const Text('Back to lodge details', style: TextStyle(color: Color(0xFF006CE4), fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Stay Dates: ${widget.selectedDatesText}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main constrained body
            Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Rooms',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose from our selection of premium suites, standard rooms, and private options.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Room Cards Grid Layout
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final roomNumber = room['number'] as String;
                      final isBooked = room['isBooked'] as bool;
                      final type = _getRoomType(roomNumber);
                      final features = _getRoomFeatures(roomNumber);
                      final images = _getRoomImages(roomNumber);
                      final isSelected = _selectedRoomNumber == roomNumber;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF006CE4)
                                : isBooked
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Room Image Slider
                            Expanded(
                              flex: 4,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    child: SizedBox.expand(
                                      child: Image.asset(
                                        images[0],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade100,
                                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Selected badge
                                  if (isSelected)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006CE4),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('SELECTED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Room Details
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Room $roomNumber',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const Spacer(),
                                        Text(
                                          isBooked ? 'Unavailable' : 'Available',
                                          style: TextStyle(
                                            color: isBooked ? Colors.red : const Color(0xFF008009),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      type,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: features.map<Widget>((feature) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(feature, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                        );
                                      }).toList(),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TZS $formattedPrice',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        ElevatedButton(
                                          onPressed: isBooked
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _selectedRoomNumber = roomNumber;
                                                  });
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelected
                                                ? Colors.grey.shade200
                                                : const Color(0xFF006CE4),
                                            foregroundColor: isSelected
                                                ? Colors.black87
                                                : Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            isSelected ? 'Selected' : 'Select',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedRoomNumber == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room $_selectedRoomNumber Selected',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TZS $formattedPrice · ${widget.numNights} Nights',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final selectedRoomId = _rooms.firstWhere((r) => r['number'] == _selectedRoomNumber)['id'] as int;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingCheckoutScreen(
                            destination: widget.destination,
                            selectedDatesText: widget.selectedDatesText,
                            numNights: widget.numNights,
                            selectedRoomNumber: _selectedRoomNumber!,
                            selectedRoomId: selectedRoomId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006CE4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}

// Fullscreen room photos gallery screen
class FullscreenRoomGalleryScreen extends StatefulWidget {
  final List<String> images;
  final String roomNumber;

  const FullscreenRoomGalleryScreen({
    Key? key,
    required this.images,
    required this.roomNumber,
  }) : super(key: key);

  @override
  State<FullscreenRoomGalleryScreen> createState() => _FullscreenRoomGalleryScreenState();
}

class _FullscreenRoomGalleryScreenState extends State<FullscreenRoomGalleryScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Room ${widget.roomNumber} - Photos (${_currentIndex + 1}/${widget.images.length})',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.5,
            child: Center(
              child: Image.asset(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

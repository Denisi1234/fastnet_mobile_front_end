import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/booking_checkout.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:flutter/material.dart';

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
    final nameHash = widget.destination.name.hashCode;
    
    _rooms = List.generate(16, (index) {
      final roomNo = '${(nameHash % 5 + 1) * 100 + index + 1}';
      final isBooked = (index * 3 + nameHash) % 5 == 0 || index == 2 || index == 7;
      
      return {
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
    final List<String> selectedRoomImages = _selectedRoomNumber != null ? _getRoomImages(_selectedRoomNumber!) : [];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Room',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              widget.destination.name,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Legend & Info bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem(Colors.white, 'Available', true),
                _buildLegendItem(Colors.red.shade400, 'Booked', false),
                _buildLegendItem(Colors.blue.shade600, 'Selected', false),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'MAIN CORRIDOR LAYOUT',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Room Rows layout
                  for (int i = 0; i < _rooms.length; i += 4) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildRoomWidget(_rooms[i]),
                            const SizedBox(width: 12),
                            _buildRoomWidget(_rooms[i + 1]),
                          ],
                        ),
                        const Expanded(
                          child: Center(
                            child: Icon(Icons.swap_vertical_circle_outlined, color: Colors.black12, size: 20),
                          ),
                        ),
                        Row(
                          children: [
                            _buildRoomWidget(_rooms[i + 2]),
                            const SizedBox(width: 12),
                            _buildRoomWidget(_rooms[i + 3]),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),

          // Dynamic Room Preview Card with tap-to-zoom pictures
          if (_selectedRoomNumber != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room pictures carousel preview (Tapping expands to Fullscreen gallery)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullscreenRoomGalleryScreen(
                                  images: selectedRoomImages,
                                  roomNumber: _selectedRoomNumber!,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 110,
                                  height: 90,
                                  child: PageView.builder(
                                    itemCount: selectedRoomImages.length,
                                    itemBuilder: (context, index) {
                                      return Image.asset(
                                        selectedRoomImages[index],
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room $_selectedRoomNumber',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRoomType(_selectedRoomNumber!),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Features list in small badges
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _getRoomFeatures(_selectedRoomNumber!).map((feat) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      feat,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
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
          ],

          // Selection Checkout Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Nights',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.numNights} night${widget.numNights > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _selectedRoomNumber == null
                        ? null
                        : () async {
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
                            if (mounted) {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => BookingCheckoutScreen(
                                    destination: widget.destination,
                                    selectedDatesText: widget.selectedDatesText,
                                    numNights: widget.numNights,
                                    selectedRoomNumber: _selectedRoomNumber!,
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
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
    final number = room['number'] as String;
    final isBooked = room['isBooked'] as bool;
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

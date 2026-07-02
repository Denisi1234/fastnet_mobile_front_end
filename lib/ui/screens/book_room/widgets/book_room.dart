import 'dart:async';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/reviews_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/room_selection.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BookRoom extends StatefulWidget {
  final Destination destination;
  final String selectedDatesText;
  final int numNights;

  const BookRoom({
    Key? key,
    required this.destination,
    required this.selectedDatesText,
    required this.numNights,
  }) : super(key: key);

  @override
  State<BookRoom> createState() => _BookRoomState();
}

class _BookRoomState extends State<BookRoom> with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late final PageController _pageController;
  Timer? _carouselTimer;
  final ScrollController _scrollController = ScrollController();
  bool _showSolidTitle = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    RecentlyViewedData.add(widget.destination);
    _pageController = PageController();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(_pulseController);

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentImageIndex + 1) % _lodgeImages.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final offset = _scrollController.offset;
        if (offset > 240 && !_showSolidTitle) {
          setState(() {
            _showSolidTitle = true;
          });
        } else if (offset <= 240 && _showSolidTitle) {
          setState(() {
            _showSolidTitle = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  List<String> get _lodgeImages {
    final original = widget.destination.imageUrl;
    return [
      original,
      'assets/images/LakeArrowhead.webp',
      'assets/images/Santorini.webp',
      'assets/images/abiansemal.webp',
    ];
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wi-fi') || lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('air conditioning') || lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('breakfast')) return Icons.free_breakfast_outlined;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('fan')) return Icons.air;
    if (lower.contains('bathroom') || lower.contains('shower')) return Icons.bathtub_outlined;
    if (lower.contains('reception') || lower.contains('service')) return Icons.room_service_outlined;
    if (lower.contains('workspace') || lower.contains('work')) return Icons.laptop;
    if (lower.contains('bed') || lower.contains('beds')) return Icons.bed_outlined;
    if (lower.contains('security')) return Icons.security;
    if (lower.contains('garden')) return Icons.yard_outlined;
    if (lower.contains('pool')) return Icons.pool_outlined;
    return Icons.check_circle_outline;
  }

  String _getHostName(String city) {
    if (city.toLowerCase().contains('dodoma')) {
      return 'Elias';
    } else if (city.toLowerCase().contains('dar es salaam')) {
      return 'Mariam';
    } else {
      return 'Thomas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostName = _getHostName(widget.destination.city);
    final images = _lodgeImages;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        height: 85,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatPrice(widget.destination.price),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' / night', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedDatesText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    color: Colors.black87,
                  ),
                )
              ],
            ),
            Container(
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomSelectionScreen(
                        destination: widget.destination,
                        selectedDatesText: widget.selectedDatesText,
                        numNights: widget.numNights,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Reserve Room',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: _showSolidTitle ? 1.0 : 0.0,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: _showSolidTitle ? Colors.black87 : Colors.white),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showSolidTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 20, color: _showSolidTitle ? Colors.black87 : Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              title: AnimatedOpacity(
                opacity: _showSolidTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.destination.name,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _showSolidTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, size: 20, color: _showSolidTitle ? Colors.black87 : Colors.white),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _showSolidTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      WishlistData.contains(widget.destination) ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: WishlistData.contains(widget.destination)
                          ? Colors.red
                          : (_showSolidTitle ? Colors.black87 : Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        WishlistData.toggle(widget.destination);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            WishlistData.contains(widget.destination)
                                ? '${widget.destination.name} added to Wishlist'
                                : '${widget.destination.name} removed from Wishlist',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                            }
                            return Center(
                              child: SizedBox(
                                height: Curves.easeInOut.transform(value) * 320,
                                width: double.infinity,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
// Indicator Count pill
                   Positioned(
                     bottom: 16,
                     right: 16,
                     child: GestureDetector(
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => FullscreenGalleryScreen(
                               images: images,
                               initialIndex: _currentImageIndex,
                             ),
                           ),
                         );
                       },
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.black.withValues(alpha: 0.7),
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                             const SizedBox(width: 6),
                             Text(
                               '${_currentImageIndex + 1} / ${images.length}',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 11,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 8 : 5,
                            height: _currentImageIndex == index ? 8 : 5,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index ? Colors.white : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.destination.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.6),
              ),
              const SizedBox(height: 12),
              
              // Rating / Review Counts / Location line (Clickable reviews to view/submit reviews)
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    widget.destination.rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
const SizedBox(width: 6),
                   const Text('·', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                   const SizedBox(width: 6),
                   GestureDetector(
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => ReviewsScreen(lodgeName: widget.destination.name),
                         ),
                       );
                     },
                     child: const Text(
                       '148 reviews',
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         decoration: TextDecoration.underline,
                       ),
                     ),
                   ),
                  const SizedBox(width: 6),
                  const Text('·', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 6),
                  Text(
                    'Superhost',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Host detail block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entire lodge hosted by $hostName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.destination.guests} guest${widget.destination.guests > 1 ? 's' : ''} • ${widget.destination.bedrooms} bedroom${widget.destination.bedrooms > 1 ? 's' : ''} • ${widget.destination.beds} bed${widget.destination.beds > 1 ? 's' : ''} • ${widget.destination.baths} bath${widget.destination.baths > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(
                      widget.destination.city.toLowerCase().contains('dodoma')
                          ? "assets/images/man.jpeg"
                          : "assets/images/man2.jpeg",
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Highlights
              _buildHighlightTile(
                Icons.workspace_premium,
                '$hostName is a Superhost',
                'Superhosts are experienced, highly rated hosts committed to providing outstanding stays.',
              ),
              const SizedBox(height: 20),
              _buildHighlightTile(
                Icons.vpn_key_outlined,
                'Self check-in',
                'Easily access the lodge via electronic keypad lock instructions.',
              ),
              const SizedBox(height: 20),
              _buildHighlightTile(
                Icons.calendar_today_outlined,
                'Free cancellation for 48 hours',
                'Cancel your booking within 48 hours of reservation for a full refund.',
              ),
              const SizedBox(height: 32),

              // Description
              const Text('About this lodge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                widget.destination.condition,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5, letterSpacing: -0.1),
              ),
              const SizedBox(height: 32),

              // Amenities
              const Text('What this place offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.destination.amenities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final amenity = widget.destination.amenities[index];
                  return Row(
                    children: [
                      Icon(_getAmenityIcon(amenity), size: 24, color: Colors.black87),
                      const SizedBox(width: 16),
                      Text(
                        amenity,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Date Availability Card
              _buildDateAvailabilityCard(),
              const SizedBox(height: 24),

              // Pricing Breakdown Card
              _buildPricingBreakdownCard(),
              const SizedBox(height: 32),

              // Map Section
              const Text('Where you\'ll be', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildMockMap(),
              const SizedBox(height: 10),
              Text(
                '${widget.destination.area}, ${widget.destination.city}, Tanzania',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Located in a clean and peaceful area with convenient access to nearby points of interest.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 32),

              // Host detail card
              const Text('Meet your Host', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(
                            widget.destination.city.toLowerCase().contains('dodoma')
                                ? "assets/images/man.jpeg"
                                : "assets/images/man2.jpeg",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Superhost • 2 years hosting',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildHostDetailRow(Icons.reviews_outlined, '148 reviews (4.8 Rating)'),
                    const SizedBox(height: 8),
                    _buildHostDetailRow(Icons.verified_user_outlined, 'Identity Verified (Government ID uploaded)', iconColor: Colors.green.shade700),
                    const SizedBox(height: 8),
                    _buildHostDetailRow(Icons.chat_bubble_outline, 'Response rate: 100% (Within an hour)'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Colors.black87),
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Contact Host', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightTile(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: Colors.black87),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHostDetailRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
      ],
    );
  }

  Widget _buildPricingBreakdownCard() {
    final pricePerNight = widget.destination.price;
    final roomTotal = pricePerNight * widget.numNights;
    const serviceFee = 5000;
    final vat = (roomTotal * 0.18).toInt();
    final grandTotal = roomTotal + serviceFee + vat;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pricing details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.green.shade800, size: 12),
                    const SizedBox(width: 4),
                    Text('INSTANT BOOK', style: TextStyle(color: Colors.green.shade800, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceItemRow('${_formatPrice(pricePerNight)} x ${widget.numNights} nights', _formatPrice(roomTotal)),
          const SizedBox(height: 10),
          _buildPriceItemRow('OTA Service fee', _formatPrice(serviceFee)),
          const SizedBox(height: 10),
          _buildPriceItemRow('VAT & local taxes (18%)', _formatPrice(vat)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              Text(_formatPrice(grandTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItemRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDateAvailabilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Availability & Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(
                'Dates Confirmed',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHECK-IN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(widget.selectedDatesText.split('–')[0].trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHECK-OUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(widget.selectedDatesText.split('–')[1].trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.green.shade800),
              const SizedBox(width: 8),
              Text(
                'Lodge is fully available for these ${widget.numNights} nights.',
                style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Custom Availability Calendar Widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.chevron_left, color: Colors.black54),
                    Text(
                      'July 2026', // Mock month for display
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black87),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                      .map((day) => SizedBox(
                            width: 30,
                            child: Center(
                              child: Text(day, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 0,
                    childAspectRatio: 1,
                  ),
                  itemCount: 31 + 3, // 3 days offset + 31 days
                  itemBuilder: (context, index) {
                    if (index < 3) return const SizedBox(); // Empty slots for month start offset
                    final day = index - 2;
                    final isSelected = day >= 14 && day <= (14 + widget.numNights);
                    final isStart = day == 14;
                    final isEnd = day == (14 + widget.numNights);
                    final isPast = day < 14;

                    return Container(
                      decoration: BoxDecoration(
                        color: isStart || isEnd
                            ? Colors.black
                            : isSelected
                                ? Colors.grey.shade200
                                : Colors.transparent,
                        borderRadius: isStart
                            ? const BorderRadius.horizontal(left: Radius.circular(20))
                            : isEnd
                                ? const BorderRadius.horizontal(right: Radius.circular(20))
                                : BorderRadius.circular(0),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isStart || isEnd
                                ? Colors.white
                                : isPast
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                            fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.w500,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getCityCoordinates(String city) {
    final lower = city.toLowerCase();
    if (lower.contains('dodoma')) {
      return {'lat': -6.179, 'lon': 35.748};
    } else if (lower.contains('dar es salaam') || lower.contains('kariakoo')) {
      return {'lat': -6.816, 'lon': 39.280};
    } else if (lower.contains('zanzibar')) {
      return {'lat': -6.166, 'lon': 39.199};
    } else if (lower.contains('arusha')) {
      return {'lat': -3.387, 'lon': 36.683};
    }
    return {'lat': -6.792, 'lon': 39.208}; // Default Dar es Salaam center
  }

  String _getStaticMapUrl() {
    final coords = _getCityCoordinates(widget.destination.city);
    final lat = coords['lat'];
    final lon = coords['lon'];
    return 'https://static-maps.yandex.ru/1.x/?ll=$lon,$lat&z=15&size=500,220&l=map&pt=$lon,$lat,pm2rdm';
  }

  Widget _buildCustomVectorMap() {
    final isDar = widget.destination.city.toLowerCase().contains('dar es salaam') || 
                 widget.destination.city.toLowerCase().contains('kariakoo');
    return Container(
      color: const Color(0xFFF4F3F0),
      child: Stack(
        children: [
          if (isDar)
            Positioned(
              right: -30, top: -20, bottom: -20,
              child: Container(
                width: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFC4E3FC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(80),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
                child: const Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'INDIAN OCEAN',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6DA5D8),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20, top: 40,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 90, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFD3EAD2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC2E2C0), width: 1),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'City Park',
                  style: TextStyle(fontSize: 9, color: Color(0xFF558252), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100, left: -20, right: -20,
            child: Container(
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEB9C),
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFFEAD09E), width: 1.5),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 101, left: 40,
            child: Text(
              'Morogoro Rd / Highway',
              style: TextStyle(fontSize: 8, color: Color(0xFF8C7355), fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            left: 150, top: -20, bottom: -20,
            child: Container(
              width: 10,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: 250, top: -20, bottom: -20,
            child: Container(
              width: 8,
              color: Colors.white,
            ),
          ),
          const Positioned(
            left: 155, top: 25,
            child: Text(
              'Samora Ave',
              style: TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            left: -20, right: -20, top: 150,
            child: Container(
              height: 8,
              color: Colors.white,
            ),
          ),
          const Positioned(
            left: 60, top: 151,
            child: Text(
              'Maktaba St',
              style: TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            left: 80, top: 20,
            child: Row(
              children: [
                Icon(Icons.storefront, color: Colors.orange.shade800, size: 12),
                const SizedBox(width: 4),
                const Text(
                  'Shopping Center',
                  style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockMap() {
    final coords = _getCityCoordinates(widget.destination.city);
    final lat = coords['lat']!;
    final lon = coords['lon']!;
    
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lon),
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fastnet.ota',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lon),
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: _pulseAnimation.value * 2,
                            height: _pulseAnimation.value * 2,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: (1.0 - _pulseController.value).clamp(0.0, 1.0)),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.location_on, color: Colors.red, size: 40),
                      Positioned(
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.black87),
    );
  }
}

// Fullscreen interactive gallery viewer with zoomable image support
class FullscreenGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenGalleryScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullscreenGalleryScreen> createState() => _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<FullscreenGalleryScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
          '${_currentIndex + 1} / ${widget.images.length}',
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

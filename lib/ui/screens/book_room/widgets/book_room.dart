import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show ByteData, Uint8List;
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/wishlist_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/reviews_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/room_selection.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/reward_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/fullscreen_map.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/web_header.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';

class BookRoom extends StatefulWidget {
  final Destination destination;
  final String? selectedDatesText;
  final int? numNights;

  const BookRoom({
    Key? key,
    required this.destination,
    this.selectedDatesText,
    this.numNights,
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
  bool _overviewExpanded = false;
  late DateTimeRange _selectedRange;

  // ── Computed helpers ──────────────────────────────────────────────────────
  int get _numNights => _selectedRange.duration.inDays;

  String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  String get _datesText => '${_fmt(_selectedRange.start)} – ${_fmt(_selectedRange.end)}';

  DateTimeRange _parseDates(String? text) {
    final today = DateTime.now();
    final defaultStart = DateTime(today.year, today.month, today.day);
    final defaultEnd = defaultStart.add(const Duration(days: 1));
    
    if (text == null || text.isEmpty) {
      return DateTimeRange(start: defaultStart, end: defaultEnd);
    }
    
    try {
      final cleanText = text.replaceAll('–', '-').replaceAll(' - ', '-');
      final parts = cleanText.split('-');
      if (parts.length != 2) {
        return DateTimeRange(start: defaultStart, end: defaultEnd);
      }
      
      final startPart = parts[0].trim();
      var endPart = parts[1].trim();
      
      final yearReg = RegExp(r'\d{4}');
      final yearMatch = yearReg.firstMatch(text);
      final year = yearMatch != null ? int.parse(yearMatch.group(0)!) : today.year;
      
      endPart = endPart.replaceAll(RegExp(r',\s*\d{4}'), '').trim();
      
      final monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      final startTokens = startPart.split(' ');
      final startMonthStr = startTokens[0];
      final startDayVal = int.parse(startTokens[1]);
      final startMonthVal = monthsAbbr.indexOf(startMonthStr) + 1;
      final startDate = DateTime(year, startMonthVal, startDayVal);
      
      final endTokens = endPart.split(' ');
      int endMonthVal = startMonthVal;
      int endDayVal;
      if (endTokens.length == 2) {
        final endMonthStr = endTokens[0];
        endMonthVal = monthsAbbr.indexOf(endMonthStr) + 1;
        endDayVal = int.parse(endTokens[1]);
      } else {
        endDayVal = int.parse(endTokens[0]);
      }
      final endDate = DateTime(year, endMonthVal, endDayVal);
      
      return DateTimeRange(start: startDate, end: endDate);
    } catch (_) {
      return DateTimeRange(start: defaultStart, end: defaultEnd);
    }
  }

  @override
  void initState() {
    super.initState();
    RecentlyViewedData.add(widget.destination);
    _pageController = PageController();

    _selectedRange = _parseDates(widget.selectedDatesText);
    if (widget.selectedDatesText == null && widget.numNights != null && widget.numNights! > 0) {
      final start = _selectedRange.start;
      _selectedRange = DateTimeRange(
        start: start,
        end: start.add(Duration(days: widget.numNights!)),
      );
    }

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
          setState(() { _showSolidTitle = true; });
        } else if (offset <= 240 && _showSolidTitle) {
          setState(() { _showSolidTitle = false; });
        }
      }
    });
  }

  Future<void> _openDatePicker() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: _selectedRange,
      helpText: 'Select your stay dates',
      saveText: 'CONFIRM',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB71C1C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFFB71C1C)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  void _shareLodge() {
    final d = widget.destination;
    final price = _formatPrice(d.price);
    final text = '''
🏡 ${d.name}
⭐ ${d.rating} · 148 reviews
📍 ${d.area}, ${d.city}, Tanzania
💰 $price / night

Book this lodge on FastNet:
https://fastnet.app/lodges/${Uri.encodeComponent(d.name)}
    '''.trim();

    Share.share(text, subject: 'Check out ${d.name} on FastNet');
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
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


  @override
  Widget build(BuildContext context) {
    final images = _lodgeImages;
    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;
    if (isDesktopWeb) {
      return _buildDesktopWebView(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(widget.destination.price),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const Text('/night', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomSelectionScreen(
                            destination: widget.destination,
                            selectedDatesText: _datesText,
                            numNights: _numNights,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // Prominent Blue
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Select Room',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Animated Image Carousel ────────────────────────────────────
            SizedBox(
              height: 380,
              child: Stack(
                children: [
                  // PageView with animated image transitions
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 1.08, end: 1.0)
                                    .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            images[index],
                            key: ValueKey(images[index]),
                            width: double.infinity,
                            height: 380,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top navigation buttons
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircularButton(
                            icon: Icons.arrow_back_ios_new,
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildCircularButton(
                            icon: Icons.tune,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom text, animated dots, counter
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.destination.area}, ${widget.destination.city}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Animated dot indicators
                            Row(
                              children: List.generate(images.length, (index) {
                                final isActive = _currentImageIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.only(right: 6),
                                  width: isActive ? 22 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            // Counter badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top-Rated Facilities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFacilityIcon(Icons.restaurant, 'Restaurant'),
                      _buildFacilityIcon(Icons.local_cafe_outlined, 'Cafe'),
                      _buildFacilityIcon(Icons.wifi, 'Free Wifi'),
                      _buildFacilityIcon(Icons.local_parking_outlined, 'Parking'),
                      _buildFacilityIcon(Icons.business_center_outlined, 'Business'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewText(),
                  const SizedBox(height: 30),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildRealMap(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildOverviewText() {
    const int previewLength = 150;
    final String fullText = widget.destination.condition.isNotEmpty
        ? widget.destination.condition
        : 'Experience the perfect blend of comfort and luxury with our top-rated facilities designed to elevate your stay. From world-class dining and a refreshing pool to high-speed Wi-Fi and a fully equipped business centre, every detail has been thoughtfully curated for your comfort. Whether you\'re here for leisure or business, enjoy seamless service, modern amenities, and an ambience that makes you feel right at home.';

    final bool isTruncatable = fullText.length > previewLength;
    final String previewText = isTruncatable && !_overviewExpanded
        ? '${fullText.substring(0, previewLength)}… '
        : '$fullText ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
            children: [
              TextSpan(text: previewText),
              if (isTruncatable)
                TextSpan(
                  text: _overviewExpanded ? 'Read Less' : 'Read More',
                  style: TextStyle(
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _overviewExpanded = !_overviewExpanded;
                      });
                    },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: Colors.black87, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
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

  Widget _buildPricingBreakdownCard() {
    final pricePerNight = widget.destination.price;
    final roomTotal = pricePerNight * _numNights;
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
          const Text('Pricing details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          _buildPriceItemRow('${_formatPrice(pricePerNight)} x $_numNights nights', _formatPrice(roomTotal)),
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final start = _selectedRange.start;
    final end   = _selectedRange.end;

    String fullDate(DateTime d) =>
        '${months[d.month - 1]} ${d.day}, ${d.year}';

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
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Availability & Dates',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              GestureDetector(
                onTap: _openDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 13, color: Colors.red.shade900),
                      const SizedBox(width: 4),
                      Text('Change dates',
                          style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Check-in / Check-out cards ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200, width: 1.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.login_rounded, size: 11, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text('CHECK-IN',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(fullDate(start),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200, width: 1.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 11, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text('CHECK-OUT',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(fullDate(end),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.nights_stay_outlined, size: 14, color: Colors.green.shade800),
              const SizedBox(width: 8),
              Text(
                '$_numNights ${_numNights == 1 ? 'night' : 'nights'} selected.',
                style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Tap-to-change banner ──────────────────────────────────────────
          GestureDetector(
            onTap: _openDatePicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade900, Colors.pink.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pick dates on calendar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCustomMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hotel, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.destination.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _TrianglePainter(color: const Color(0xFFB71C1C)),
        ),
      ],
    );
  }

  Future<Uint8List> _getTeardropPinBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 120.0;
    const double height = 150.0;

    final Paint pinPaint = Paint()
      ..color = const Color(0xFF003580) // Dark Navy Blue
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path();
    const Offset center = Offset(60, 55);
    path.addOval(Rect.fromCircle(center: center, radius: 44));
    path.moveTo(20, 70);
    path.lineTo(60, 142);
    path.lineTo(100, 70);
    path.close();

    canvas.drawPath(path, pinPaint);
    canvas.drawPath(path, borderPaint);
    canvas.drawCircle(center, 16.0, dotPaint);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Widget _buildRealMap() {
    final lat = widget.destination.latitude;
    final lon = widget.destination.longitude;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullscreenMapScreen(destination: widget.destination),
          ),
        );
      },
      child: Container(
        height: 215,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IgnorePointer(
            child: MapWidget(
              key: const ValueKey("bookRoomMap"),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(lon, lat)),
                zoom: 15.0,
                pitch: 30,
                bearing: 0,
              ),
              onMapCreated: (mapboxMap) async {
                final pinBytes = await _getTeardropPinBytes();
                mapboxMap.annotations.createPointAnnotationManager().then((manager) {
                  manager.create(PointAnnotationOptions(
                    geometry: Point(coordinates: Position(lon, lat)),
                    image: pinBytes,
                    iconSize: 0.9,
                    textField: widget.destination.name,
                    textSize: 11.5,
                    textColor: const Color(0xFF0F172A).toARGB32(),
                    textHaloColor: Colors.white.toARGB32(),
                    textHaloWidth: 2.0,
                    textOffset: const [0.0, 1.0],
                    textAnchor: TextAnchor.TOP,
                  ));
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopWebView(BuildContext context) {
    final d = widget.destination;
    final images = _lodgeImages;
    final formattedPrice = _formatPrice(d.price);
    final formattedOriginal = _formatPrice((d.price * 1.1).toInt());
    final reviewScore = (d.rating * 2).clamp(0, 10).toStringAsFixed(1);
    final reviewLabel = d.rating >= 4.5 ? 'Superb' : d.rating >= 4.0 ? 'Very Good' : 'Good';
    final stars = d.rating.round().clamp(1, 5);

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
            // Breadcrumbs and Action buttons bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF006CE4)),
                    label: const Text('Back to search results', style: TextStyle(color: Color(0xFF006CE4), fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _shareLodge,
                    icon: const Icon(Icons.share, size: 20, color: Color(0xFF006CE4)),
                    tooltip: 'Share',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final wishlist = Provider.of<WishlistProvider>(context, listen: false);
                      wishlist.toggle(d);
                    },
                    icon: Icon(
                      Provider.of<WishlistProvider>(context).contains(d)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'Save to Wishlist',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Web Layout Constrained Container
            Container(
              constraints: const BoxConstraints(maxWidth: 1150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Stars Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Lodge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(stars, (_) => const Icon(Icons.star, size: 16, color: Color(0xFFF5A623))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d.name,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Color(0xFF006CE4)),
                                const SizedBox(width: 4),
                                Text(
                                  '${d.area}, ${d.city}, Tanzania',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Reviews Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003580),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              reviewScore,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reviewLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image Grid (1 Big Left + 4 Small Grid Right)
                  if (images.isNotEmpty)
                    SizedBox(
                      height: 420,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Large image
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              child: Image.asset(images[0], fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Small grid images
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.zero,
                                          child: Image.asset(images.length > 1 ? images[1] : images[0], fit: BoxFit.cover, height: double.infinity),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
                                          child: Image.asset(images.length > 2 ? images[2] : images[0], fit: BoxFit.cover, height: double.infinity),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.zero,
                                          child: Image.asset(images.length > 3 ? images[3] : images[0], fit: BoxFit.cover, height: double.infinity),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8)),
                                          child: Image.asset(images.length > 4 ? images[4] : images[0], fit: BoxFit.cover, height: double.infinity),
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
                  const SizedBox(height: 32),

                  // Content Columns Split Layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Content Panel
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Facilities wrap
                            const Text('Popular facilities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: d.amenities.map((facility) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF008009)),
                                      const SizedBox(width: 8),
                                      Text(facility, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),

                            // Overview Section
                            const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                d.condition,
                                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Map Preview Section
                            const Text('Location Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildRealMap(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Right Booking Panel (Sticky sidebar simulation)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Text(_datesText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.nightlight_round, size: 16, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Text('Duration of stay: $_numNights nights', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Rate per night', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text(formattedPrice, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Original value', style: TextStyle(color: Colors.red, fontSize: 13, decoration: TextDecoration.lineThrough)),
                                  Text(formattedOriginal, style: const TextStyle(fontSize: 13, color: Colors.red, decoration: TextDecoration.lineThrough)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RoomSelectionScreen(
                                        destination: widget.destination,
                                        selectedDatesText: _datesText,
                                        numNights: _numNights,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006CE4),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  elevation: 0,
                                ),
                                child: const Text('Reserve Your Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  'Standard booking steps apply',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
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

class _TrustPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final bool pulse;

  const _TrustPill({
    Key? key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.pulse = false,
  }) : super(key: key);

  @override
  State<_TrustPill> createState() => _TrustPillState();
}

class _TrustPillState extends State<_TrustPill>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;
  Animation<double>? _scaleAnim;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _scaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.iconColor.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 13, color: widget.iconColor),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.iconColor.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );

    if (widget.pulse && _scaleAnim != null) {
      return AnimatedBuilder(
        animation: _scaleAnim!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim!.value,
            child: child,
          );
        },
        child: pill,
      );
    }

    return pill;
  }
}



class PulseMarker extends StatefulWidget {
  const PulseMarker({Key? key}) : super(key: key);

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }
}

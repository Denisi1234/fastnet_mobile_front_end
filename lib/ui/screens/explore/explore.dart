// create nav bar properly later

import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/models/destination.dart';
import 'package:airbnb_ui_clone/ui/screens/explore/widgets/search_results.dart';
import 'package:airbnb_ui_clone/ui/screens/book_room/widgets/book_room.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:airbnb_ui_clone/ui/screens/explore/widgets/tabs.dart';
import 'package:airbnb_ui_clone/ui/widgets/interactive_card.dart';
import 'package:airbnb_ui_clone/ui/widgets/fade_slide_page_route.dart';



class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  String _searchQuery = 'Dodoma'; // Default popular destination to look focused
  DateTimeRange? _selectedDateRange;
  int _guestsCount = 2;

  final List<Map<String, String>> _destinationsList = [
    {'city': 'Dar es Salaam', 'display': 'Dar es Salaam (All)'},
    {'city': 'Dodoma', 'display': 'Dodoma (All)'},
    {'city': 'Mtumba', 'display': 'Mtumba, Dodoma'},
    {'city': 'Sabasaba', 'display': 'Sabasaba, Dodoma'},
    {'city': 'Kariakoo', 'display': 'Kariakoo, Dar es Salaam'},
    {'city': 'Kisasa', 'display': 'Kisasa, Dodoma'},
    {'city': 'Arusha', 'display': 'Arusha (All)'},
  ];



  @override
  void initState() {
    super.initState();
    // Default date range: today to 3 days from now
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 3)),
    );
  }

  String get _dateRangeText {
    if (_selectedDateRange == null) {
      return 'Choose Dates';
    }
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day} – ${end.day}';
    } else {
      return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
    }
  }

  int get _numNights {
    if (_selectedDateRange == null) return 1;
    final diff = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays;
    return diff <= 0 ? 1 : diff;
  }

  List<Destination> get _filteredDestinations {
    if (_searchQuery.isEmpty) {
      return destinations;
    }
    return destinations.where((d) => d.matches(_searchQuery)).toList();
  }

  void _triggerSearch() {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: SearchResultsScreen(
          searchQuery: _searchQuery,
          dateRange: _selectedDateRange,
          guestsCount: _guestsCount,
          filteredDestinations: _filteredDestinations,
          selectedDatesText: _dateRangeText,
          numNights: _numNights,
        ),
      ),
    );
  }


  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade900,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _destinationsList.length,
                  itemBuilder: (context, index) {
                    final dest = _destinationsList[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.grey),
                      title: Text(
                        dest['display']!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        setState(() {
                          _searchQuery = dest['city']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGuestsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Guests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Number of occupants',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          Text('Adults, kids or infants',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _guestsCount > 1
                                ? () {
                                    setModalState(() => _guestsCount--);
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: _guestsCount > 1 ? Colors.red.shade900 : Colors.grey,
                          ),
                          Text('$_guestsCount',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _guestsCount < 10
                                ? () {
                                    setModalState(() => _guestsCount++);
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: _guestsCount < 10 ? Colors.red.shade900 : Colors.grey,
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Section: Expedia/Trip.com style
              Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/house.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LODGE BOOKING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Find your next stay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Search lodges, private rooms, and apartments.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Search Card
              Transform.translate(
                offset: const Offset(0, -35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Destination Select
                        _buildSearchFieldItem(
                          icon: Icons.location_on_outlined,
                          label: 'Where to?',
                          value: _searchQuery.isEmpty ? 'Search destination' : _searchQuery,
                          onTap: _showDestinationPicker,
                        ),
                        const SizedBox(height: 12),
                        // Dates Select
                        _buildSearchFieldItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Dates',
                          value: '$_dateRangeText ($_numNights night${_numNights > 1 ? 's' : ''})',
                          onTap: _selectDateRange,
                        ),
                        const SizedBox(height: 12),
                        // Guests Select
                        _buildSearchFieldItem(
                          icon: Icons.people_outline_outlined,
                          label: 'Guests',
                          value: '$_guestsCount guest${_guestsCount > 1 ? 's' : ''}',
                          onTap: _showGuestsPicker,
                        ),
                        const SizedBox(height: 16),
                        // Search Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink.shade700, Colors.red.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade900.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _triggerSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Search Lodges',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Tabs(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Featured Lodges',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: Text(
                  'Top-rated stays near your location',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: destinations.where((d) => d.rating >= 4.6).length,
                  itemBuilder: (context, index) {
                    final featured = destinations.where((d) => d.rating >= 4.6).toList();
                    final item = featured[index];
                    return _buildHomeFeaturedCard(context, item);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }

  Widget _buildSearchFieldItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red.shade900, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeFeaturedCard(BuildContext context, Destination item) {
    return InteractiveCard(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: BookRoom(
              destination: item,
              selectedDatesText: 'Jun 25 – 28',
              numNights: 3,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    item.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '15% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: WishlistHeartButton(
                    item: item,
                    onToggled: () {
                      setState(() {
                        WishlistData.toggle(item);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            WishlistData.contains(item)
                                ? '${item.name} added to Wishlist'
                                : '${item.name} removed from Wishlist',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.area}, ${item.city}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'TSh ${(item.price * 1.15).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TSh ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / night',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistHeartButton extends StatefulWidget {
  final Destination item;
  final VoidCallback onToggled;
  const WishlistHeartButton({Key? key, required this.item, required this.onToggled}) : super(key: key);

  @override
  State<WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends State<WishlistHeartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWishlisted = WishlistData.contains(widget.item);
    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0.0);
        widget.onToggled();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            Icons.favorite,
            color: isWishlisted ? Colors.red : Colors.grey.shade400,
            size: 16,
          ),
        ),
      ),
    );
  }
}


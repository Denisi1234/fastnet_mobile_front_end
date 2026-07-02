import 'dart:math';
import 'package:airbnb_ui_clone/models/destination.dart';
import 'package:airbnb_ui_clone/ui/screens/book_room/widgets/book_room.dart';
import 'package:flutter/material.dart';
import 'filter_bottom_sheet.dart';
import 'package:airbnb_ui_clone/ui/widgets/interactive_card.dart';
import 'package:airbnb_ui_clone/ui/widgets/fade_slide_page_route.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final int guestsCount;
  final List<Destination> filteredDestinations;
  final String selectedDatesText;
  final int numNights;

  const SearchResultsScreen({
    Key? key,
    required this.searchQuery,
    this.dateRange,
    required this.guestsCount,
    required this.filteredDestinations,
    required this.selectedDatesText,
    required this.numNights,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  bool _isMapView = false;
  String _selectedSort = 'Best Match';
  late ScrollController _scrollController;
  int _loadedItemsCount = 4;
  bool _isLoadingMore = false;
  int _selectedMapLodgeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      final totalDestinations = _getSortedDestinations().length;
      if (!_isLoadingMore && _loadedItemsCount < totalDestinations) {
        setState(() {
          _isLoadingMore = true;
        });
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _loadedItemsCount = _loadedItemsCount + 3;
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  List<Destination> _getSortedDestinations() {
    final list = List<Destination>.from(widget.filteredDestinations);
    if (_selectedSort == 'Price: low to high') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: high to low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'Top Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'Distance: closest') {
      list.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return list;
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ...['Best Match', 'Price: low to high', 'Price: high to low', 'Top Rated', 'Distance: closest'].map((option) {
                  final isSelected = _selectedSort == option;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.red.shade900 : Colors.black87,
                      ),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: Colors.red.shade900) : null,
                    onTap: () {
                      setState(() {
                        _selectedSort = option;
                        _loadedItemsCount = 4; // reset pagination limit
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(List<Destination> sortedList) {
    if (sortedList.isEmpty) {
      return const Center(child: Text('No lodges available to show on map'));
    }
    final activeLodge = sortedList[_selectedMapLodgeIndex % sortedList.length];

    return Stack(
      children: [
        // Mock Map Canvas background
        Container(
          color: const Color(0xFFF1F8E9),
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: MapGridPainter(),
          ),
        ),
        // Pins overlay
        ...List.generate(sortedList.length, (index) {
          final lodge = sortedList[index];
          final randX = ((lodge.name.hashCode & 0xFFFF) % 100) / 100.0;
          final randY = (((lodge.name.hashCode >> 8) & 0xFFFF) % 100) / 100.0;
          
          final left = 40.0 + randX * 240.0;
          final top = 60.0 + randY * 260.0;
          
          final isSelected = _selectedMapLodgeIndex == index;

          return Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMapLodgeIndex = index;
                });
              },
              child: AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.white : Colors.red.shade900, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    'TSh ${(lodge.price ~/ 1000)}k',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        // Floating bottom listing preview card in map view
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.asset(
                    activeLodge.imageUrl,
                    width: 120,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeLodge.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${activeLodge.area}, ${activeLodge.city}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(activeLodge.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TSh ${activeLodge.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  FadeSlidePageRoute(
                                    page: BookRoom(
                                      destination: activeLodge,
                                      selectedDatesText: widget.selectedDatesText,
                                      numNights: widget.numNights,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _buildTagChip(Destination destination) {
    String tagText = 'Popular Choice';
    IconData tagIcon = Icons.thumb_up_alt_outlined;
    Color chipBg = Colors.blue.shade50;
    Color chipFg = Colors.blue.shade800;

    if (destination.rating >= 4.7) {
      tagText = 'Top Rated';
      tagIcon = Icons.star;
      chipBg = Colors.green.shade50;
      chipFg = Colors.green.shade800;
    } else if (destination.price <= 50000) {
      tagText = 'Best Value';
      tagIcon = Icons.local_offer_outlined;
      chipBg = Colors.orange.shade50;
      chipFg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tagIcon, size: 12, color: chipFg),
          const SizedBox(width: 4),
          Text(
            tagText,
            style: TextStyle(
              color: chipFg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.searchQuery.isEmpty ? 'All Areas' : widget.searchQuery;
    final sortedList = _getSortedDestinations();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Back button, Title, Subtitle, Filter & Sort
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 20, top: 10, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sortedList.length} Lodges found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Filter and Sort buttons
                        Row(
                          children: [
                            _buildHeaderButton(Icons.tune_outlined, 'Filter', () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const FilterBottomSheet(),
                              );
                            }),
                            const SizedBox(width: 8),
                            _buildHeaderButton(Icons.swap_vert_outlined, 'Sort: $_selectedSort', _showSortBottomSheet),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable list or Map view of lodge cards
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: 3,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildSkeletonCard(),
                    )
                  : sortedList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No Lodges Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try looking for Dodoma, Mtumba, or Sabasaba.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : _isMapView
                          ? _buildMapView(sortedList)
                          : ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: min(_loadedItemsCount, sortedList.length) + (_loadedItemsCount < sortedList.length ? 1 : 1),
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                if (index >= min(_loadedItemsCount, sortedList.length)) {
                                  // Shimmer loaders or end message
                                  if (_loadedItemsCount < sortedList.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          "You've viewed all matching properties.",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                final lodge = sortedList[index];
                                return _buildLodgeCard(context, lodge);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
          });
        },
        backgroundColor: Colors.black87,
        label: Text(
          _isMapView ? 'List' : 'Map',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        icon: Icon(_isMapView ? Icons.list : Icons.map, color: Colors.white, size: 18),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeaderButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLodgeCard(BuildContext context, Destination lodge) {
    // Custom rating count generation for screenshot accuracy
    final int reviewsCount = (lodge.rating * 17).floor();

    return InteractiveCard(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: BookRoom(
              destination: lodge,
              selectedDatesText: widget.selectedDatesText,
              numNights: widget.numNights,
            ),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Left Image: Rounded corners with carousel
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: CardImageCarousel(
                    imageUrls: [
                      lodge.imageUrl,
                      'assets/images/house1.webp',
                      'assets/images/house2.webp',
                    ],
                    width: 140,
                  ),
                ),
              ),
            ),

            // Right details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12.0, right: 12.0, left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag chip (Top Rated / Best Value etc.)
                        _buildTagChip(lodge),
                        const SizedBox(height: 6),
                        // Lodge Title
                        Text(
                          lodge.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Distance / Center
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${lodge.distance} km from center (${lodge.area})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Rating & Reviews
                        Row(
                          children: [
                            const Icon(Icons.star, size: 13, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              lodge.rating.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($reviewsCount Reviews)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price per night & Arrow icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(lodge.price),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20), // Premium Dark Green for pricing
                              ),
                            ),
                            Text(
                              ' / night',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: ShimmerWidget(
              width: 140,
              height: double.infinity,
              borderRadius: 12,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 12.0, right: 12.0, left: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(width: 80, height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerWidget(width: 120, height: 18, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerWidget(width: 140, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerWidget(width: 90, height: 12, borderRadius: 4),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerWidget(width: 100, height: 16, borderRadius: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade200,
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
  }
}

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class CardImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double width;
  const CardImageCarousel({
    Key? key,
    required this.imageUrls,
    required this.width,
  }) : super(key: key);

  @override
  State<CardImageCarousel> createState() => _CardImageCarouselState();
}

class _CardImageCarouselState extends State<CardImageCarousel> {
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
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.asset(
              widget.imageUrls[index],
              width: widget.width,
              height: double.infinity,
              fit: BoxFit.cover,
            );
          },
        ),
        // Dots indicator
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (index) {
              final isSelected = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isSelected ? 6.0 : 4.0,
                height: isSelected ? 6.0 : 4.0,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..style = PaintingStyle.fill;

    // Draw mock water body
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.65, size.width * 0.6, size.height * 0.95)
      ..lineTo(size.width, size.height * 0.9)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, waterPaint);

    // Draw some mock road grids
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), paint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

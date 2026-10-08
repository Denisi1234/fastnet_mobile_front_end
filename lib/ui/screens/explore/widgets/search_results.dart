import 'dart:async';
import 'dart:math' hide Point;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show ByteData, Uint8List;
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'filter_bottom_sheet.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/interactive_card.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/shimmer_widget.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final int guestsCount;
  final List<Destination> filteredDestinations;
  final String selectedDatesText;
  final int numNights;

  /// Web parity: home (`Explore`) opens this screen straight into the map
  /// pane via its Map FAB (web desktop shows list + map side by side).
  final bool initialMapView;

  const SearchResultsScreen({
    Key? key,
    required this.searchQuery,
    this.dateRange,
    required this.guestsCount,
    required this.filteredDestinations,
    required this.selectedDatesText,
    required this.numNights,
    this.initialMapView = false,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  bool _isMapView = false;
  String _selectedSort = 'Best Match';
  late ScrollController _scrollController;
  late PageController _pageController;
  int _loadedItemsCount = 12;

  int _selectedMapLodgeIndex = 0;

  MapboxMap? _mapController;
  PointAnnotationManager? _pointAnnotationManager;
  final Map<String, int> _symbolToLodgeIndex = {};
  Cancelable? _tapSubscription;
  bool _styleLoaded = false;
  List<Destination>? _previousList;
  int? _previousSelectedLodgeIndex;
 
  LodgeFilterOptions _filterOptions = const LodgeFilterOptions(
    priceRange: RangeValues(0, 200000),
    minRating: 0,
    freeCancellation: false,
    selectedAmenities: {},
    selectedNeighborhoods: {},
  );

  final Set<String> _activeFilters = {};

  void _zoomIn() {
    _mapController?.getCameraState().then((state) {
      _mapController?.setCamera(CameraOptions(zoom: state.zoom + 1));
    });
  }

  void _zoomOut() {
    _mapController?.getCameraState().then((state) {
      _mapController?.setCamera(CameraOptions(zoom: state.zoom - 1));
    });
  }

  void _reCenter(List<Destination> sortedList) {
    if (sortedList.isEmpty) return;
    final activeLodge = sortedList[_selectedMapLodgeIndex % sortedList.length];
    _mapController?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(activeLodge.longitude, activeLodge.latitude)),
        zoom: 13.0,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  void _animateToLodge(int index, List<Destination> sortedList) {
    if (index >= 0 && index < sortedList.length) {
      final lodge = sortedList[index];
      _mapController?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lodge.longitude, lodge.latitude)),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  final Map<int, Uint8List> _pinCache = {};

  final List<Color> _markerColors = const [
    Color(0xFFE53935), // Crimson Red
    Color(0xFF1565C0), // Royal Blue
    Color(0xFF2E7D32), // Emerald Green
    Color(0xFF6A1B9A), // Rich Purple
    Color(0xFFEF6C00), // Vibrant Amber
    Color(0xFF00838F), // Deep Teal
    Color(0xFFC2185B), // Berry Magenta
    Color(0xFF283593), // Indigo
  ];

  Future<Uint8List> _getTeardropPinBytes({required Color pinColor}) async {
    final int key = pinColor.toARGB32();
    if (_pinCache.containsKey(key)) return _pinCache[key]!;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 120.0;
    const double height = 150.0;

    final Paint pinPaint = Paint()
      ..color = pinColor
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
    final Uint8List result = byteData!.buffer.asUint8List();

    _pinCache[key] = result;
    return result;
  }

  void _updateMapMarkers(List<Destination> sortedList) async {
    if (_mapController == null || _pointAnnotationManager == null) return;
    try {
      await _pointAnnotationManager!.deleteAll();
      _symbolToLodgeIndex.clear();

      for (int i = 0; i < sortedList.length; i++) {
        final lodge = sortedList[i];
        final isSelected = _selectedMapLodgeIndex == i;
        final Color pinColor = isSelected ? const Color(0xFFFF385C) : _markerColors[i % _markerColors.length];
        final pinBytes = await _getTeardropPinBytes(pinColor: pinColor);

        final annotation = await _pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(lodge.longitude, lodge.latitude)),
            image: pinBytes,
            iconSize: isSelected ? 1.25 : 0.9,
            textField: lodge.name,
            textSize: isSelected ? 11.5 : 10.0,
            textColor: isSelected ? const Color(0xFFFF385C).toARGB32() : const Color(0xFF0F172A).toARGB32(),
            textHaloColor: Colors.white.toARGB32(),
            textHaloWidth: 2.0,
            textOffset: const [0.0, 1.0],
            textAnchor: TextAnchor.TOP,
          ),
        );
        _symbolToLodgeIndex[annotation.id] = i;
      }
    } catch (e) {
      // Ignore map exceptions on fast UI rebuilds
    }
  }

  void _showFilterFeedback(int count) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Filters Updated • $count lodges match',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isMapView = widget.initialMapView;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _pageController = PageController(viewportFraction: 0.88, initialPage: _selectedMapLodgeIndex);
    // The result set is already in memory, so there is nothing to wait for.
    // This used to hold the skeleton on screen for a fixed 350ms regardless
    // of how fast the data arrived.
    _isLoading = false;
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Items added per scroll-near-end event.
  static const int _pageSize = 12;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final totalDestinations = _getSortedDestinations().length;
      final next = min(_loadedItemsCount + _pageSize, totalDestinations);
      if (next > _loadedItemsCount) {
        // No artificial 1s-per-3-items delay: the list is local, so extend it
        // immediately rather than trickling rows onto the screen.
        setState(() {
          _loadedItemsCount = next;
        });
      }
    }
  }

  List<Destination> _getSortedDestinations() {
    var list = List<Destination>.from(widget.filteredDestinations);

    // Apply quick filters dynamically
    if (_activeFilters.contains('Top Rated (4.7+)')) {
      list = list.where((d) => d.rating >= 4.7).toList();
    }
    if (_activeFilters.contains('Budget (≤ 80k)')) {
      list = list.where((d) => d.price <= 80000).toList();
    }
    if (_activeFilters.contains('AC')) {
      list = list.where((d) => d.amenities.any((a) => a.toLowerCase().contains('air conditioning') || a.toLowerCase().contains('ac'))).toList();
    }
    if (_activeFilters.contains('Pool')) {
      list = list.where((d) => d.amenities.any((a) => a.toLowerCase().contains('pool'))).toList();
    }
    if (_activeFilters.contains('Breakfast')) {
      list = list.where((d) => d.amenities.any((a) => a.toLowerCase().contains('breakfast'))).toList();
    }

    // Apply advanced bottom sheet filters
    list = list.where((d) {
      if (d.price < _filterOptions.priceRange.start || d.price > _filterOptions.priceRange.end) {
        return false;
      }
      if (_filterOptions.minRating > 0 && d.rating < _filterOptions.minRating) {
        return false;
      }
      if (_filterOptions.selectedAmenities.isNotEmpty) {
        final matchesAll = _filterOptions.selectedAmenities.every((amenity) {
          return d.amenities.any((a) => a.toLowerCase().trim() == amenity.toLowerCase().trim());
        });
        if (!matchesAll) return false;
      }
      if (_filterOptions.selectedNeighborhoods.isNotEmpty) {
        final matchesAny = _filterOptions.selectedNeighborhoods.any((area) {
          return d.area.toLowerCase().trim() == area.toLowerCase().trim() || d.city.toLowerCase().trim() == area.toLowerCase().trim();
        });
        if (!matchesAny) return false;
      }
      return true;
    }).toList();

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
                        _loadedItemsCount = 12; // reset pagination limit
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
    if (_selectedMapLodgeIndex >= sortedList.length) {
      _selectedMapLodgeIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
    final activeLodge = sortedList[_selectedMapLodgeIndex];

    // Trigger update of map markers in post frame callback if list or selection changed
    if (_styleLoaded && (_previousList != sortedList || _previousSelectedLodgeIndex != _selectedMapLodgeIndex)) {
      _previousList = sortedList;
      _previousSelectedLodgeIndex = _selectedMapLodgeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMapMarkers(sortedList);
      });
    }

    return Stack(
      children: [
        // Real Mapbox Map background
        Container(
          width: double.infinity,
          height: double.infinity,
          child: MapWidget(
            key: const ValueKey("searchResultsMapWidget"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(activeLodge.longitude, activeLodge.latitude)),
              zoom: 13.0,
            ),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            onMapCreated: (mapboxMap) {
              _mapController = mapboxMap;
              mapboxMap.annotations.createPointAnnotationManager().then((manager) {
                _pointAnnotationManager = manager;
                _styleLoaded = true;
                _updateMapMarkers(sortedList);
                
                _tapSubscription?.cancel();
                _tapSubscription = manager.tapEvents(onTap: (annotation) {
                  final index = _symbolToLodgeIndex[annotation.id];
                  if (index != null) {
                    setState(() {
                      _selectedMapLodgeIndex = index;
                    });
                    _animateToLodge(index, sortedList);
                    _updateMapMarkers(sortedList);
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                });
              });
            },
          ),
        ),
        
        // Polished unified map controls on right side
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                  splashRadius: 20,
                  tooltip: 'Zoom In',
                ),
                Container(
                  width: 24,
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                IconButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.remove, color: Colors.black87, size: 20),
                  splashRadius: 20,
                  tooltip: 'Zoom Out',
                ),
                Container(
                  width: 24,
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                IconButton(
                  onPressed: () => _reCenter(sortedList),
                  icon: const Icon(Icons.my_location_rounded, color: Colors.black87, size: 18),
                  splashRadius: 20,
                  tooltip: 'Re-Center',
                ),
              ],
            ),
          ),
        ),

        // Floating bottom listing preview card in map view
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Container(
            height: 125,
            child: PageView.builder(
              controller: _pageController,
              itemCount: sortedList.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedMapLodgeIndex = index;
                });
                _animateToLodge(index, sortedList);
                _updateMapMarkers(sortedList);
              },
              itemBuilder: (context, index) {
                final lodge = sortedList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          child: PropertyImage(
                            url: lodge.imageUrl,
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
                                      lodge.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${lodge.area}, ${lodge.city}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 12, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(lodge.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TSh ${lodge.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    InkWell(
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade900,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Book',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
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
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.searchQuery.isEmpty ? 'All Areas' : widget.searchQuery;
    final sortedList = _getSortedDestinations();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Royal Blue Header Banner with Floating Search Box Pill
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF003580), // Signature Royal Deep Blue
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFB700), width: 2), // Golden Accent Border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.selectedDatesText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 3 Action Toolbar (Trier / Filtrer / Carte)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _showSortBottomSheet,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.black87),
                                const SizedBox(width: 6),
                                const Text(
                                  'Sort',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final result = await showModalBottomSheet<LodgeFilterOptions>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => FilterBottomSheet(initialOptions: _filterOptions),
                            );
                            if (result != null) {
                              setState(() {
                                _filterOptions = result;
                                _loadedItemsCount = 12;
                              });
                              _showFilterFeedback(_getSortedDestinations().length);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.tune_rounded, size: 20, color: Colors.black87),
                                const SizedBox(width: 6),
                                const Text(
                                  'Filter',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isMapView = !_isMapView;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.location_on_rounded, size: 20, color: Colors.black87),
                                const SizedBox(width: 6),
                                Text(
                                  _isMapView ? 'List' : 'Map',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results Counter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '${sortedList.length} stays found',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          // Cards List / Map View
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
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
                              'No Stays Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try looking for Dar es Salaam, Masaki, or Arusha.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _isMapView
                        ? _buildMapView(sortedList)
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: min(_loadedItemsCount, sortedList.length) + (_loadedItemsCount < sortedList.length ? 1 : 1),
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              if (index >= min(_loadedItemsCount, sortedList.length)) {
                                if (_loadedItemsCount < sortedList.length) {
                                  return _buildSkeletonCard();
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
    );
  }

  Widget _buildLodgeCard(BuildContext context, Destination lodge) {
    final int reviewsCount = (lodge.rating * 42).floor();
    final bool isWishlisted = WishlistData.contains(lodge);

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
        height: 225,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image Thumbnail with Green Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 135,
                    height: double.infinity,
                    child: CardImageCarousel(
                      imageUrls: [
                        lodge.imageUrl,
                        'assets/images/house1.webp',
                        'assets/images/house2.webp',
                      ],
                      width: 135,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00875A), // Green Badge
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Breakfast included',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            // Right Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Heart Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                lodge.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  WishlistData.toggle(lodge);
                                });
                              },
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                                color: isWishlisted ? const Color(0xFFEF4444) : Colors.grey.shade500,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Stars + Genius Badge
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (index) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB700)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003580),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Genius',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Pay Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003580),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Pay with Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Score Box + Review Count
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003580),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lodge.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lodge.rating >= 4.7 ? 'Exceptional' : 'Superb',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              ' · $reviewsCount reviews',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Location & Distance
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${lodge.distance} km from center · ${lodge.area}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Room Type & Pricing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${lodge.roomType} : ${lodge.beds} bed',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${widget.numNights} nights : ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'TSh ${(lodge.price * 1.25 ~/ 1000)}k ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatPrice(lodge.price),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Taxes and fees included',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Only 1 left at this price!',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
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
            return PropertyImage(
              url: widget.imageUrls[index],
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

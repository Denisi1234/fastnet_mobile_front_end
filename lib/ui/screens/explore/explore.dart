import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/views/full_website_view.dart';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/search_results.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/interactive_card.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';
import 'package:fastnet_mobile_front_end/ui/screens/notifications/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  String _currentLocation = 'Mikocheni, Dar es Salaam';
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  int _guestsCount = 1;
  int _roomsCount = 1;

  final List<Map<String, String>> _destinationsList = [
    {'display': 'Dar es Salaam (Masaki, Mikocheni)', 'city': 'Dar es Salaam'},
    {'display': 'Zanzibar (Nungwi, Stone Town)', 'city': 'Zanzibar'},
    {'display': 'Arusha (Sakina, Njiro)', 'city': 'Arusha'},
    {'display': 'Dodoma (Capital District)', 'city': 'Dodoma'},
    {'display': 'Mwanza (Rock City Lake View)', 'city': 'Mwanza'},
  ];

  @override
  void initState() {
    super.initState();
    // Default date range: today to 3 days from now
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 3)),
    );
    _restoreSearchState();
    _fetchMapboxCurrentLocation();
  }

  void _restoreSearchState() async {
    final prefs = await SharedPreferences.getInstance();
    final loc = prefs.getString('explore_current_location');
    final query = prefs.getString('explore_search_query');
    final guests = prefs.getInt('explore_guests_count');
    final rooms = prefs.getInt('explore_rooms_count');

    if (mounted) {
      setState(() {
        if (loc != null) _currentLocation = loc;
        if (query != null) _searchQuery = query;
        if (guests != null) _guestsCount = guests;
        if (rooms != null) _roomsCount = rooms;
      });
    }
  }

  void _saveSearchState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('explore_current_location', _currentLocation);
    await prefs.setString('explore_search_query', _searchQuery);
    await prefs.setInt('explore_guests_count', _guestsCount);
    await prefs.setInt('explore_rooms_count', _roomsCount);
  }

  String get _dateRangeText {
    if (_selectedDateRange == null) {
      return 'Check-in date — Check-out date';
    }
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

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





  Future<void> _fetchMapboxCurrentLocation() async {
    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
        geo.Position position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
        );

        final url =
            'https://api.mapbox.com/geocoding/v5/mapbox.places/${position.longitude},${position.latitude}.json?access_token=${AppConstants.mapboxApiKey}&types=neighborhood,locality,place,district';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List?;
          if (features != null && features.isNotEmpty) {
            final placeName = features[0]['text'] ?? features[0]['place_name'];
            String city = 'Dar es Salaam';
            final contextList = features[0]['context'] as List?;
            if (contextList != null) {
              for (var c in contextList) {
                if (c['id'].toString().startsWith('place') || c['id'].toString().startsWith('district')) {
                  city = c['text'] ?? city;
                }
              }
            }
            final displayLoc = '$placeName, $city';
            if (mounted) {
              setState(() {
                _currentLocation = displayLoc;
                _saveSearchState();
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Mapbox geocoding error: $e');
    }

    if (mounted) {
      setState(() {
        _currentLocation = 'Mikocheni, Dar es Salaam';
        _saveSearchState();
      });
    }
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE55325),
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
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String filterText = '';
        bool isLocating = false;
        bool isSearching = false;
        List<Map<String, dynamic>> suggestions = [];
        Timer? debounceTimer;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void fetchSuggestions(String query) async {
              if (query.trim().length < 3) {
                setModalState(() {
                  suggestions = [];
                  isSearching = false;
                });
                return;
              }
              setModalState(() {
                isSearching = true;
              });
              try {
                final url =
                    'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=tz';
                final response = await http.get(Uri.parse(url), headers: {
                  'User-Agent': 'FastNetMobileTravelApp/1.0',
                });
                if (response.statusCode == 200) {
                  final List data = jsonDecode(response.body);
                  setModalState(() {
                    suggestions = data
                        .map((item) => {
                              'display': item['display_name'].toString(),
                              'city': item['name'].toString(),
                              'lat': double.tryParse(item['lat'].toString()) ?? -6.7780,
                              'lng': double.tryParse(item['lon'].toString()) ?? 39.2730,
                            })
                        .toList();
                    isSearching = false;
                  });
                } else {
                  setModalState(() {
                    isSearching = false;
                  });
                }
              } catch (_) {
                setModalState(() {
                  isSearching = false;
                });
              }
            }

            final localFiltered = _destinationsList.where((d) {
              final term = filterText.toLowerCase().trim();
              if (term.isEmpty) return true;
              return d['display']!.toLowerCase().contains(term) ||
                  d['city']!.toLowerCase().contains(term);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where are you going?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search destinations or stays...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE55325)),
                                ),
                              ),
                            )
                          : (filterText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setModalState(() {
                                      filterText = '';
                                      suggestions = [];
                                    });
                                  },
                                )
                              : null),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE55325)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filterText = val;
                        if (val.trim().length >= 3) {
                          isSearching = true;
                        } else {
                          isSearching = false;
                        }
                      });
                      if (debounceTimer?.isActive ?? false) debounceTimer?.cancel();
                      debounceTimer = Timer(const Duration(milliseconds: 200), () {
                        fetchSuggestions(val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocating ? Icons.hourglass_empty : Icons.my_location,
                        color: const Color(0xFFE55325),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isLocating ? 'Locating...' : 'Use Current Location',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE55325),
                      ),
                    ),
                    onTap: isLocating
                        ? null
                        : () async {
                            setModalState(() {
                              isLocating = true;
                            });
                            await _fetchMapboxCurrentLocation();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Located: ${_searchQuery.isEmpty ? "Dar es Salaam" : _searchQuery}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: filterText.trim().length >= 3 && suggestions.isNotEmpty
                        ? ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final dest = suggestions[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on, color: Color(0xFFE55325), size: 18),
                                ),
                                title: Text(
                                  dest['city']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  dest['display']!,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  setState(() {
                                    _searchQuery = dest['city']!;
                                    _saveSearchState();
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Selected: ${dest['city']}'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : (localFiltered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching destinations found.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                itemCount: localFiltered.length,
                                itemBuilder: (context, index) {
                                  final dest = localFiltered[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                    title: Text(
                                      dest['display']!,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = dest['city']!;
                                        _saveSearchState();
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              )),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGuestsAndRoomsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guests & Rooms',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 20),
                  // Guests Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guests',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                          Text('Adults, kids or infants',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _guestsCount > 1
                                ? () {
                                    setModalState(() {
                                      _guestsCount--;
                                      _saveSearchState();
                                    });
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: _guestsCount > 1 ? const Color(0xFFE55325) : Colors.grey.shade400,
                          ),
                          Text('$_guestsCount',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _guestsCount < 10
                                ? () {
                                    setModalState(() {
                                      _guestsCount++;
                                      _saveSearchState();
                                    });
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: _guestsCount < 10 ? const Color(0xFFE55325) : Colors.grey.shade400,
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  // Rooms Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rooms',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                          Text('Number of rooms required',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _roomsCount > 1
                                ? () {
                                    setModalState(() {
                                      _roomsCount--;
                                      _saveSearchState();
                                    });
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: _roomsCount > 1 ? const Color(0xFFE55325) : Colors.grey.shade400,
                          ),
                          Text('$_roomsCount',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _roomsCount < 5
                                ? () {
                                    setModalState(() {
                                      _roomsCount++;
                                      _saveSearchState();
                                    });
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: _roomsCount < 5 ? const Color(0xFFE55325) : Colors.grey.shade400,
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE55325),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
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
    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;

    if (isDesktopWeb) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: FullWebsiteView(
          destinations: _filteredDestinations,
          currentLocation: _currentLocation,
          onDestinationTap: (destination) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookRoom(destination: destination),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // -------------------------------------------------------------
          // Fixed Top Location Header Bar (Non-scrollable)
          // -------------------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B65F2),
                  Color(0xFF144EC9),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: FastNetStays.com Logo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontWeight: FontWeight.w900,
                            ),
                            children: [
                              TextSpan(
                                text: 'FASTNET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  letterSpacing: 0.8,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 2,
                                ),
                              ),
                              TextSpan(
                                text: 'STAYS',
                                style: TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 22,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: '.com',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _logoDot(Colors.redAccent),
                            _logoDot(Colors.orangeAccent),
                            _logoDot(Colors.amber),
                            _logoDot(Colors.lightGreenAccent),
                            _logoDot(Colors.lightBlueAccent),
                          ],
                        ),
                      ],
                    ),

                    // Right: Notification Bell Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(page: const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
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

          // -------------------------------------------------------------
          // Scrollable Body Content Below Fixed Header
          // -------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Royal Blue Header Banner with Custom World Map Pattern
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF144EC9),
                          Color(0xFF0F3EAF),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      child: CustomPaint(
                        painter: WorldMapPainter(),
                      ),
                    ),
                  ),

            // -------------------------------------------------------------
            // 2. Floating Search Card ("Where do you want to stay?")
            // -------------------------------------------------------------
            Transform.translate(
              offset: const Offset(0, -120),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.08),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title inside card
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Where do you ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontFamily: 'AirbnbCereal',
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: 'want to stay?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFE55325),
                                fontFamily: 'serif',
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Input 1: Search Hotel / Location
                      _buildPillInputField(
                        icon: Icons.location_on_outlined,
                        value: _searchQuery.isEmpty ? 'Search Stays..' : _searchQuery,
                        onTap: _showDestinationPicker,
                      ),
                      const SizedBox(height: 12),

                      // Input 2: Dates (Check-in - Check-out)
                      _buildPillInputField(
                        icon: Icons.calendar_month_outlined,
                        value: _dateRangeText,
                        onTap: _selectDateRange,
                      ),
                      const SizedBox(height: 12),

                      // Input 3: Guests & Rooms (2 side-by-side equal pills)
                      Row(
                        children: [
                          Expanded(
                            child: _buildPillInputField(
                              icon: Icons.person_outline_rounded,
                              value: '$_guestsCount Guest${_guestsCount > 1 ? 's' : ''}',
                              onTap: _showGuestsAndRoomsPicker,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPillInputField(
                              icon: Icons.single_bed_outlined,
                              value: '$_roomsCount Room${_roomsCount > 1 ? 's' : ''}',
                              onTap: _showGuestsAndRoomsPicker,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Large Orange Search Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _triggerSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE55325),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------------
            // 3. Recommended Hotel Section
            // -------------------------------------------------------------
            Transform.translate(
              offset: const Offset(0, -90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended Stays',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: _triggerSearch,
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE55325),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 272,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final item = destinations[index];
                        return _buildRecommendedStayCard(context, item);
                      },
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildHomeFeedSections(context),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  void _openDestination(Destination item) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: BookRoom(
          destination: item,
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        );
  }

  // -------------------------------------------------------------------------
  // Helper Widget: Pill Input Field
  // -------------------------------------------------------------------------
  Widget _buildPillInputField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF475569),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper Widget: Recommended Hotel Card
  // -------------------------------------------------------------------------
  Widget _buildRecommendedStayCard(BuildContext context, Destination item) {
    return InteractiveCard(
      onTap: () => _openDestination(item),
      child: Container(
        width: 230,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    item.imageUrl,
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // 25% OFF Green Badge Pill (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '25% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Circular White Heart Button (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: WishlistHeartButton(
                    item: item,
                    onToggled: () {
                      setState(() {
                        WishlistData.toggle(item);
                      });
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${item.area}, ${item.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _buildRoomSizeLabel(item),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'TSh ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFE55325),
                        ),
                      ),
                      const Text(
                        ' / night',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildHomeFeedSections(BuildContext context) {
    final popularRooms = _buildPopularRoomCards();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rooms',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: _triggerSearch,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE55325),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: List.generate(popularRooms.length, (index) {
                  final room = popularRooms[index];
                  return SizedBox(
                    width: cardWidth,
                    child: _buildPopularRoomCard(
                      context,
                      room,
                      isTall: index.isEven,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: InkWell(
        onTap: _triggerSearch,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 98,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFE55325), size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(Destination item) {
    return InteractiveCard(
      onTap: () => _openDestination(item),
      child: Container(
        width: 246,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD8C8)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(item.imageUrl, width: 88, height: 112, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE55325),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Last minute',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.area}, ${item.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TSh ${_formatPrice(item.price)}',
                    style: const TextStyle(color: Color(0xFFE55325), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRoomSizeLabel(Destination item) {
    final bedrooms = item.bedrooms > 0 ? item.bedrooms : 1;
    final estimatedSquareMeters = 15 + ((bedrooms - 1) * 5) + (item.beds > 1 ? 2 : 0);
    final estimatedSquareFeet = (estimatedSquareMeters * 10.764).round();
    return '$estimatedSquareMeters m²/$estimatedSquareFeet ft²';
  }

  List<PopularRoomCardData> _buildPopularRoomCards() {
    final List<PopularRoomCardData> cards = [];

    for (final lodge in destinations) {
      final rooms = lodge.rooms;
      if (rooms != null && rooms.isNotEmpty) {
        for (final room in rooms) {
          cards.add(
            PopularRoomCardData(
              lodge: lodge,
              roomLabel: lodge.roomType.isNotEmpty ? lodge.roomType : 'Popular room',
              subtitle: '${lodge.area}, ${lodge.city}',
              imageUrl: lodge.imageUrl,
              price: lodge.price + (cards.length % 4) * 2500,
              rating: lodge.rating,
              badge: room['status']?.toString() == 'booked' ? 'Booked' : 'Available',
              views: 20 + cards.length * 3,
            ),
          );
        }
      } else {
        cards.add(
          PopularRoomCardData(
            lodge: lodge,
            roomLabel: lodge.roomType.isNotEmpty ? lodge.roomType : 'Popular room',
            subtitle: '${lodge.area}, ${lodge.city}',
            imageUrl: lodge.imageUrl,
            price: lodge.price + (cards.length % 4) * 2500,
            rating: lodge.rating,
            badge: lodge.duration.toLowerCase().contains('few') ? 'Few left' : 'Popular',
            views: 20 + cards.length * 3,
          ),
        );
      }
    }

    return cards.take(4).toList();
  }

  Widget _buildPopularRoomCard(
    BuildContext context,
    PopularRoomCardData room, {
    required bool isTall,
  }) {
    final cardImageHeight = isTall ? 146.0 : 132.0;
    final priceText = 'TSh ${room.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    return InteractiveCard(
      onTap: () => _openDestination(room.lodge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.asset(
                    room.imageUrl,
                    height: cardImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: cardImageHeight,
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: const Icon(Icons.bed_outlined, color: Colors.grey, size: 42),
                      );
                    },
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: room.badge == 'Booked' ? const Color(0xFFD97706) : const Color(0xFFDB2777),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                      child: Text(
                        room.badge,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 18, color: Colors.black87),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Popular room',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.lodge.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          room.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          '${room.views}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE55325),
                            ),
                          ),
                        ),
                        Text(
                          '/ night',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3EAF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3EAF).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FastNet care on every stay',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Verified rooms, secure booking, and support when plans change.',
                  style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStayTile(Destination item) {
    return InteractiveCard(
      onTap: () => _openDestination(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(item.imageUrl, width: 76, height: 76, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${item.distance} km away in ${item.area}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        item.rating.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      Text(
                        'TSh ${_formatPrice(item.price)}',
                        style: const TextStyle(color: Color(0xFFE55325), fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _logoDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painter for World Map Background Pattern in Header
// -----------------------------------------------------------------------------
class WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    // Draw subtle grid dot matrix representing world continents
    const rows = 16;
    const cols = 28;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Pseudo world shape filter logic to form subtle continent clusters
        final normX = c / cols;
        final normY = r / rows;
        bool isLand = (normX > 0.15 && normX < 0.35 && normY > 0.2 && normY < 0.7) ||
            (normX > 0.45 && normX < 0.65 && normY > 0.25 && normY < 0.8) ||
            (normX > 0.70 && normX < 0.92 && normY > 0.15 && normY < 0.65);

        if (isLand && random.nextDouble() > 0.25) {
          final x = c * cellWidth + cellWidth / 2;
          final y = r * cellHeight + cellHeight / 2;
          canvas.drawCircle(Offset(x, y), 1.8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PopularRoomCardData {
  final Destination lodge;
  final String roomLabel;
  final String subtitle;
  final String imageUrl;
  final int price;
  final double rating;
  final String badge;
  final int views;

  const PopularRoomCardData({
    required this.lodge,
    required this.roomLabel,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.badge,
    required this.views,
  });
}

// -----------------------------------------------------------------------------
// Heart Button for Wishlist
// -----------------------------------------------------------------------------
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
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: isWishlisted ? const Color(0xFFEF4444) : Colors.grey.shade400,
            size: 18,
          ),
        ),
      ),
    );
  }
}

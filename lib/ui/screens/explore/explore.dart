import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/settings_screen.dart';
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
    final sessionProvider = context.watch<UserSessionProvider>();
    final profileImage = sessionProvider.profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 1. Royal Blue Header Banner with Custom World Map Pattern
            // -------------------------------------------------------------
            Stack(
              children: [
                Container(
                  height: 330,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1B65F2),
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Profile Avatar + Location Info
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  FadeSlidePageRoute(page: const SettingsScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundImage: profileImage,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showDestinationPicker,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'My Current Location',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _currentLocation.isEmpty ? 'Mikocheni, Dar es Salaam' : _currentLocation,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Right: Notification Bell Button with Red Dot Badge
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(page: const NotificationsScreen()),
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Color(0xFF1E293B),
                                  size: 25,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 13,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    height: 260,
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: BookRoom(
              destination: item,
            ),
          ),
        );
      },
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

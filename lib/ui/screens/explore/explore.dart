import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/filter_bottom_sheet.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/search_results.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/web_home_filter_chips.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/web_home_hotel_card.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/web_home_results_header.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/web_home_search_bar.dart';
import 'package:fastnet_mobile_front_end/ui/screens/explore/widgets/web_home_search_sheet.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/shimmer_widget.dart';

/// Home tab — mobile parity of web `/` (`templates/Pages/index.php`).
///
/// Web structure mirrored here:
///   search bar (`gh-search-bar.php` mobile block) →
///   filter chips (`gh-filter-chips.php`) →
///   results header (`gh-results-header.php`: "near X · N results" + sort) →
///   hotel cards (`gh-cards-list.php`: photo, name+price, stay total,
///   location, `4.2 ★ Excellent (66)` rating, amenity grid, View prices).
class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  // ── Search state (web `gh-search-bar.php` defaults) ──
  String _city = '';
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 8));
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;

  // ── Filter state (web `gh-filter-chips.php` URL keys) ──
  String _sort = 'recommended';
  double? _priceMin;
  double? _priceMax;
  String _propertyType = '';
  double _minRating = 0;
  bool _freeCancel = false;
  final Set<String> _amenities = {};
  final Set<String> _areas = {};
  final List<String> _recents = [];
  final ScrollController _listCtrl = ScrollController();

  bool _isLoading = true;

  static const _sortLabels = {
    'recommended': 'Recommended',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
    'rating': 'Highest rating',
  };

  static const _popularEmpty = [
    'Arusha',
    'Zanzibar',
    'Dar es Salaam',
    'Kilimanjaro',
    'Serengeti',
    'Mwanza',
  ];

  @override
  void initState() {
    super.initState();
    _restoreState().then((_) => _refresh());
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  /// Native scroll-to-top (logo tap / fresh search): eases back when the
  /// list is already mounted, jumps when it is still (re)building.
  void _scrollToTop({bool animate = true}) {
    if (!_listCtrl.hasClients) return;
    if (animate && _listCtrl.offset > 0) {
      _listCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _listCtrl.jumpTo(0);
    }
  }

  // ───────────────────────── persistence ─────────────────────────

  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day);
      final ci = DateTime.tryParse(prefs.getString('explore_checkin') ?? '');
      final co =
          DateTime.tryParse(prefs.getString('explore_checkout') ?? '');
      if (!mounted) return;
      setState(() {
        _city = prefs.getString('explore_city') ?? '';
        if (ci != null && !ci.isBefore(today)) {
          _checkIn = ci;
        }
        if (co != null && co.isAfter(_checkIn)) {
          _checkOut = co;
        } else {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
        _adults = (prefs.getInt('explore_adults') ?? 2).clamp(1, 10);
        _children = (prefs.getInt('explore_children') ?? 0).clamp(0, 6);
        _rooms = (prefs.getInt('explore_rooms') ?? 1).clamp(1, 5);
        final sort = prefs.getString('explore_sort') ?? 'recommended';
        if (_sortLabels.containsKey(sort)) _sort = sort;
        _recents
          ..clear()
          ..addAll((prefs.getStringList('explore_recent_cities') ?? [])
              .where((c) => c.trim().isNotEmpty)
              .take(5));
      });
    } catch (_) {
      // Defaults above already match the web search bar.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('explore_city', _city);
      await prefs.setString(
          'explore_checkin', _checkIn.toIso8601String());
      await prefs.setString(
          'explore_checkout', _checkOut.toIso8601String());
      await prefs.setInt('explore_adults', _adults);
      await prefs.setInt('explore_children', _children);
      await prefs.setInt('explore_rooms', _rooms);
      await prefs.setString('explore_sort', _sort);
      await prefs.setStringList('explore_recent_cities', _recents);
    } catch (_) {}
  }

  // ───────────────────────── data ─────────────────────────

  /// Web parity: home search always hits the backend (`GET /properties`).
  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final rows = await ApiService.fetchProperties(
        city: _city.isEmpty ? null : _city,
      );
      destinations
        ..clear()
        ..addAll(rows.map(
            (p) => Destination.fromJson(Map<String, dynamic>.from(p as Map))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _persist();
    }
  }

  List<Destination> get _visible {
    var list = List<Destination>.from(destinations);
    if (_city.isNotEmpty) {
      list = list.where((d) => d.matches(_city)).toList();
    }
    if (_priceMin != null) {
      list = list.where((d) => d.price >= _priceMin!).toList();
    }
    if (_priceMax != null) {
      list = list.where((d) => d.price <= _priceMax!).toList();
    }
    if (_propertyType.isNotEmpty) {
      list = list.where(_matchesPropertyType).toList();
    }
    if (_minRating > 0) {
      list = list.where((d) => d.rating >= _minRating).toList();
    }
    if (_freeCancel) {
      list = list.where((d) => d.freeCancellation).toList();
    }
    if (_amenities.isNotEmpty) {
      list = list.where(
          (d) => _amenities.every((a) => _hasAmenity(d, a))).toList();
    }
    if (_areas.isNotEmpty) {
      list = list.where((d) {
        final area = d.area.toLowerCase().trim();
        final city = d.city.toLowerCase().trim();
        return _areas.any((a) {
          final want = a.toLowerCase().trim();
          return area == want || city == want;
        });
      }).toList();
    }
    switch (_sort) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        list.sort((a, b) {
          final c = b.rating.compareTo(a.rating);
          return c != 0 ? c : b.reviewCount.compareTo(a.reviewCount);
        });
        break;
      case 'recommended':
      default:
        // Web: "Recommended sorts highest rated first".
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  bool _matchesPropertyType(Destination d) {
    final want = _propertyType.toLowerCase();
    final have = d.propertyType.toLowerCase();
    if (have.isNotEmpty) {
      if (have.contains(want) || want.contains(have)) return true;
      if (want == 'safari lodge' &&
          (have.contains('lodge') ||
              have.contains('safari') ||
              have.contains('camp'))) {
        return true;
      }
      return false;
    }
    final room = d.roomType.toLowerCase();
    final name = d.name.toLowerCase();
    if (want == 'safari lodge') {
      return room.contains('lodge') ||
          room.contains('safari') ||
          name.contains('lodge') ||
          name.contains('safari') ||
          name.contains('camp');
    }
    if (want == 'apartment') {
      return room.contains('apartment') || name.contains('apartment');
    }
    return true; // Untyped rows read as hotel-like (never empty by default).
  }

  bool _hasAmenity(Destination d, String key) {
    final hay = '${d.amenities.join(' ')} ${d.condition}'.toLowerCase();
    switch (key.toLowerCase()) {
      case 'wi-fi':
        return hay.contains('wi-fi') ||
            hay.contains('wifi') ||
            hay.contains('wireless');
      case 'swimming pool':
        return hay.contains('swimming pool') ||
            hay.contains('swim pool') ||
            (hay.contains('pool') &&
                !hay.contains('pool table') &&
                !hay.contains('snooker') &&
                !hay.contains('billiard'));
      case 'breakfast':
        return hay.contains('breakfast');
      default:
        return hay.contains(key.toLowerCase());
    }
  }

  int get _filterCount {
    var n = 0;
    if (_priceMin != null || _priceMax != null) n++;
    if (_propertyType.isNotEmpty) n++;
    if (_minRating > 0) n++;
    if (_freeCancel) n++;
    return n + _amenities.length + _areas.length;
  }

  int get _nights {
    final diff = _checkOut.difference(_checkIn).inDays;
    return diff <= 0 ? 1 : diff;
  }

  int get _guestTotal => _adults + _children;

  String get _priceChipLabel {
    String fmt(double v) => v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    if (_priceMin != null && _priceMax != null) {
      return 'TZS ${fmt(_priceMin!)} – ${fmt(_priceMax!)}';
    }
    if (_priceMin != null) return 'TZS ${fmt(_priceMin!)}+';
    if (_priceMax != null) return 'Up to TZS ${fmt(_priceMax!)}';
    return 'Price';
  }

  // ───────────────────────── formatting ─────────────────────────

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _dayLabel(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

  String get _staySummary =>
      '${_dayLabel(_checkIn)} – ${_dayLabel(_checkOut)} · $_guestTotal guest${_guestTotal == 1 ? '' : 's'}';

  void _openDestination(Destination item) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: BookRoom(
          destination: item,
          selectedDatesText: _staySummary,
          numNights: _nights,
        ),
      ),
    );
  }

  void _openMap(List<Destination> list) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: SearchResultsScreen(
          searchQuery: _city,
          dateRange: DateTimeRange(start: _checkIn, end: _checkOut),
          guestsCount: _guestTotal,
          filteredDestinations: list,
          selectedDatesText: _staySummary,
          numNights: _nights,
          initialMapView: true,
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _priceMin = null;
      _priceMax = null;
      _propertyType = '';
      _minRating = 0;
      _freeCancel = false;
      _amenities.clear();
      _areas.clear();
    });
    _persist();
  }

  void _resetSearch() {
    final now = DateTime.now();
    setState(() {
      _city = '';
      _checkIn = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 7));
      _checkOut = _checkIn.add(const Duration(days: 1));
      _adults = 2;
      _children = 0;
      _rooms = 1;
      _sort = 'recommended';
      _clearFilters();
    });
    _refresh();
  }

  // ───────────────────────── search sheet ─────────────────────────
  // Unified full-screen sheet (web `fns_mobile_sheet`): the collapsed bar
  // opens it at the tapped step; picks apply live, the footer submits.

  Future<void> _showSearchSheet(String step) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.transparent, // web mobile: no backdrop
      builder: (context) {
        // Scaffold keeps the footer above the keyboard when the
        // Where input focuses (native resize instead of overlap).
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: WebHomeSearchSheet(
            initialCity: _city,
            initialCheckIn: _checkIn,
            initialCheckOut: _checkOut,
            initialAdults: _adults,
            initialChildren: _children,
            initialRooms: _rooms,
            initialStep: step,
            initialRecentCities: List.of(_recents),
            onCityChanged: (v) {
              setState(() => _city = v);
              _persist();
            },
            onCityPicked: (v) {
              // Real picks (not keystrokes) feed recent searches.
              setState(() {
                _city = v;
                _recents.remove(v);
                _recents.insert(0, v);
                if (_recents.length > 5) {
                  _recents.removeRange(5, _recents.length);
                }
              });
              _persist();
            },
            onClearRecents: () {
              setState(() => _recents.clear());
              _persist();
            },
            onDatesChanged: (ci, co) {
              setState(() {
                _checkIn = ci;
                _checkOut = co;
              });
              _persist();
            },
            onGuestsChanged: (ad, ch, rm) {
              setState(() {
                _adults = ad;
                _children = ch;
                _rooms = rm;
              });
              _persist();
            },
            onClearAll: () {
              // Web fnsClearAllMobile: blank city, today → tomorrow, 2/0/1.
              final now = DateTime.now();
              final today =
                  DateTime(now.year, now.month, now.day);
              setState(() {
                _city = '';
                _checkIn = today;
                _checkOut = today.add(const Duration(days: 1));
                _adults = 2;
                _children = 0;
                _rooms = 1;
              });
              _persist();
            },
            onSearch: () {
              Navigator.pop(context);
              _refresh();
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToTop(animate: false));
            },
            countMatches: (city) {
              if (city.isEmpty) return destinations.length;
              return destinations
                  .where((d) => d.matches(city))
                  .length;
            },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSortSheet() {
    const options = [
      ('recommended', 'Recommended · top rated'),
      ('price_asc', 'Price: low to high'),
      ('price_desc', 'Price: high to low'),
      ('rating', 'Highest rating'),
    ];
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sort by',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final (key, label) in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label,
                        style: TextStyle(
                          fontWeight: _sort == key
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _sort == key
                              ? const Color(0xFF1967D2)
                              : Colors.black87,
                        )),
                    trailing: _sort == key
                        ? const Icon(Icons.check,
                            color: Color(0xFF1967D2))
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sort = key);
                      _persist();
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPriceSheet() {
    double min = (_priceMin ?? 0).clamp(0, 500000).toDouble();
    double max = (_priceMax ?? 500000).clamp(0, 500000).toDouble();
    if (min > max) min = max;
    final minCtrl = TextEditingController(
        text: _priceMin == null ? '' : _priceMin!.toInt().toString());
    final maxCtrl = TextEditingController(
        text: _priceMax == null ? '' : _priceMax!.toInt().toString());
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price per night',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Histogram shows price distribution',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min (TZS)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (v) {
                            final p = double.tryParse(v);
                            if (p != null && p >= 0 && p <= max) {
                              setModalState(() => min = p);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max (TZS)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (v) {
                            final p = double.tryParse(v);
                            if (p != null && p >= min && p <= 1000000) {
                              setModalState(
                                  () => max = p.clamp(0, 500000).toDouble());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    values: RangeValues(min, max),
                    activeColor: const Color(0xFF1A73E8),
                    onChanged: (r) => setModalState(() {
                      min = r.start;
                      max = r.end;
                      minCtrl.text = min.toInt().toString();
                      maxCtrl.text = max.toInt().toString();
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _priceMin = null;
                            _priceMax = null;
                          });
                          _persist();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Color(0xFF5F6368))),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _priceMin = min <= 0 ? null : min;
                            _priceMax = max >= 500000 ? null : max;
                          });
                          _persist();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Apply',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      minCtrl.dispose();
      maxCtrl.dispose();
    });
  }

  Future<void> _showAllFilters() {
    return showModalBottomSheet<LodgeFilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(
        initialOptions: LodgeFilterOptions(
          priceRange: RangeValues(
            (_priceMin ?? 0).clamp(0, 500000).toDouble(),
            (_priceMax ?? 500000).clamp(0, 500000).toDouble(),
          ),
          minRating: _minRating,
          freeCancellation: _freeCancel,
          selectedAmenities: Set.of(_amenities),
          selectedNeighborhoods: Set.of(_areas),
        ),
      ),
    ).then((result) {
      if (result == null) return;
      setState(() {
        _priceMin =
            result.priceRange.start <= 0 ? null : result.priceRange.start;
        _priceMax = result.priceRange.end >= 500000
            ? null
            : result.priceRange.end;
        _minRating = result.minRating;
        _freeCancel = result.freeCancellation;
        _amenities
          ..clear()
          ..addAll(result.selectedAmenities);
        _areas
          ..clear()
          ..addAll(result.selectedNeighborhoods);
      });
      _persist();
    });
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    final destName = _city.isEmpty ? 'Tanzania' : _city;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── White top block: header + stacked search + chips ──
            // (web `.fns-search-wrap` + `.fns-chips-wrap`, mobile rules:
            // white bg, hairline bottom border, 12px gutters).
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _scrollToTop();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/fastnet_logo_icon.png',
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.bolt_rounded,
                                        color: Color(0xFF1A73E8),
                                        size: 26),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'fastnetstays.com',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF202124),
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        12, 10, 12, 0),
                    child: WebHomeSearchBar(
                      destinationText: _city,
                      hasDestination: _city.isNotEmpty,
                      checkInLabel: _dayLabel(_checkIn),
                      checkOutLabel: _dayLabel(_checkOut),
                      guestsCount: _guestTotal,
                      onWhereTap: () => _showSearchSheet('where'),
                      onWhenTap: () => _showSearchSheet('when'),
                      onWhoTap: () => _showSearchSheet('who'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        12, 10, 12, 0),
                    child: WebHomeFilterChips(
                      filterCount: _filterCount,
                      priceActive: _priceMin != null ||
                          _priceMax != null,
                      priceLabel: _priceChipLabel,
                      ratingActive: _minRating >= 4.0,
                      onAllFilters: _showAllFilters,
                      onPriceTap: _showPriceSheet,
                      onRatingToggle: () {
                        setState(() => _minRating =
                            _minRating >= 4.0 ? 0 : 4.0);
                        _persist();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Results header (web `gh-results-header.php`, mobile:
            // borderless, sits on the grey list background).
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: WebHomeResultsHeader(
                destination: destName,
                count: list.length,
                sortLabel: _sortLabels[_sort] ?? 'Recommended',
                isFiltered: _filterCount > 0,
                onSortTap: _showSortSheet,
              ),
            ),
            // Scrolling cards list (web `.gh-left-scroll`).
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1A73E8),
                onRefresh: _refresh,
                // Soft crossfade between loading / empty / results —
                // same pixels, calmer transitions.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isLoading
                      ? ListView.separated(
                          key: const ValueKey('home-loading'),
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              12, 8, 12, 96),
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, __) =>
                              const SkeletonCard(height: 300),
                        )
                      : list.isEmpty
                          ? KeyedSubtree(
                              key:
                                  const ValueKey('home-empty'),
                              child: _emptyState(destName),
                            )
                          : ListView.separated(
                              key: const ValueKey('home-list'),
                              controller: _listCtrl,
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  12, 4, 12, 96),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final d = list[i];
                                return WebHomeHotelCard(
                                  destination: d,
                                  isWishlisted:
                                      WishlistData.contains(d),
                                  onTap: () =>
                                      _openDestination(d),
                                  onWishlistToggle: () {
                                    HapticFeedback.selectionClick();
                                    setState(() =>
                                        WishlistData.toggle(d));
                                  },
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openMap(list),
              backgroundColor: const Color(0xFF202124),
              icon: const Icon(Icons.map_outlined,
                  color: Colors.white, size: 18),
              label: const Text('Map',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
    );
  }

  /// Web empty state (`.gh-empty`): white card, grey icon disc,
  /// Clear-filters / Reset-search pills, popular destination links.
  Widget _emptyState(String destName) {
    final title = _city.isNotEmpty
        ? 'No stays found for "$_city"'
        : 'No stays found in Tanzania';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143C4043),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    size: 26, color: Color(0xFF9AA0A6)),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202124))),
              const SizedBox(height: 6),
              Text(
                'Try widening your search, changing dates, or clearing filters in $destName.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF5F6368),
                    height: 18 / 13.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(
                        Icons.filter_alt_off_outlined,
                        size: 15),
                    label: const Text('Clear filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(
                          color: Color(0xFFDADCE0)),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetSearch,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 15),
                    label: const Text('Reset search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Popular destinations',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5F6368))),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _popularEmpty
              .map((c) => InkWell(
                    onTap: () {
                      setState(() => _city = c);
                      _refresh();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFDADCE0)),
                      ),
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.w500)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

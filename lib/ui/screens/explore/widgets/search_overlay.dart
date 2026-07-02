import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';

class SearchFilters {
  final String query;
  final DateTimeRange? dateRange;
  final int guests;

  SearchFilters({
    required this.query,
    this.dateRange,
    required this.guests,
  });
}

class SearchOverlayScreen extends StatefulWidget {
  final String initialQuery;
  final DateTimeRange? initialDateRange;
  final int initialGuests;

  const SearchOverlayScreen({
    Key? key,
    required this.initialQuery,
    this.initialDateRange,
    required this.initialGuests,
  }) : super(key: key);

  @override
  State<SearchOverlayScreen> createState() => _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends State<SearchOverlayScreen> {
  late TextEditingController _searchController;
  DateTimeRange? _selectedDateRange;
  late int _guestsCount;
  List<Map<String, String>> _filteredSuggestions = [];

  final List<Map<String, String>> _popularDestinations = [
    {'city': 'Dar es Salaam', 'area': 'Mikocheni', 'display': 'Mikocheni, Dar es Salaam'},
    {'city': 'Dodoma', 'area': 'Mtumba', 'display': 'Mtumba, Dodoma'},
    {'city': 'Dodoma', 'area': 'Sabasaba', 'display': 'Sabasaba, Dodoma'},
    {'city': 'Dar es Salaam', 'area': 'Kariakoo', 'display': 'Kariakoo, Dar es Salaam'},
    {'city': 'Dodoma', 'area': 'Kisasa', 'display': 'Kisasa, Dodoma'},
    {'city': 'Arusha', 'area': 'Njiro', 'display': 'Njiro, Arusha'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedDateRange = widget.initialDateRange;
    _guestsCount = widget.initialGuests;
    _searchController.addListener(_onSearchChanged);
    _onSearchChanged();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = [];
      } else {
        final List<Map<String, String>> matches = [];
        final Set<String> seen = {};

        // Match areas
        for (final dest in destinations) {
          if (dest.area.toLowerCase().contains(query) ||
              dest.name.toLowerCase().contains(query)) {
            final key = '${dest.area}, ${dest.city}';
            if (!seen.contains(key)) {
              seen.add(key);
              matches.add({
                'title': dest.area,
                'subtitle': dest.city,
                'type': 'Area',
              });
            }
          }
        }
        
        // Match cities directly
        for (final dest in destinations) {
          if (dest.city.toLowerCase().contains(query)) {
            final key = dest.city;
            if (!seen.contains(key)) {
              seen.add(key);
              matches.add({
                'title': dest.city,
                'subtitle': 'City in Tanzania',
                'type': 'City',
              });
            }
          }
        }

        _filteredSuggestions = matches;
      }
    });
  }

  String get _dateRangeText {
    if (_selectedDateRange == null) {
      return 'Select dates';
    }
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final days = _selectedDateRange!.duration.inDays;
    final nightsStr = ' ($days night${days > 1 ? 's' : ''})';
    
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day} – ${end.day}$nightsStr';
    } else {
      return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}$nightsStr';
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 3)),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Lodges & Rooms',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination Search input
                  const Text(
                    'Where to?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.black54),
                        hintText: 'Search city or area (e.g. Dodoma, Mtumba...)',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_searchController.text.trim().isNotEmpty) ...[
                    const Text(
                      'Suggestions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    if (_filteredSuggestions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'No matching locations found',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredSuggestions.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final suggestion = _filteredSuggestions[index];
                          final isCity = suggestion['type'] == 'City';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCity ? Icons.location_city_outlined : Icons.location_on_outlined,
                                color: Colors.red.shade900,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              suggestion['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              suggestion['subtitle']!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black54),
                            onTap: () {
                              setState(() {
                                _searchController.text = suggestion['title']!;
                              });
                            },
                          );
                        },
                      ),
                  ] else ...[
                    // Quick Suggestion list
                    const Text(
                      'Popular areas & cities',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularDestinations.map((dest) {
                        final isSelected = _searchController.text.toLowerCase() == dest['area']!.toLowerCase() ||
                                           _searchController.text.toLowerCase() == dest['city']!.toLowerCase() ||
                                           _searchController.text.toLowerCase() == dest['display']!.toLowerCase();
                        return ChoiceChip(
                          label: Text(dest['display']!),
                          selected: isSelected,
                          selectedColor: Colors.red.shade900.withValues(alpha: 0.15),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.red.shade900 : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.red.shade900 : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _searchController.text = dest['area']!; // Search by specific area
                              } else {
                                _searchController.clear();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 15),

                  // Trip Date picker
                  const Text(
                    "When's your trip?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.red.shade900),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDateRange == null ? 'Choose Dates' : 'Selected Dates',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateRangeText,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 15),

                  // Who's coming / Guests selection
                  const Text(
                    "Who's coming?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guests',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              'Number of occupants',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _guestsCount > 1
                                  ? () => setState(() => _guestsCount--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline, size: 28),
                              color: _guestsCount > 1 ? Colors.red.shade900 : Colors.grey,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_guestsCount',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: _guestsCount < 10
                                  ? () => setState(() => _guestsCount++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline, size: 28),
                              color: _guestsCount < 10 ? Colors.red.shade900 : Colors.grey,
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

          // Bottom Bar for searching
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedDateRange = null;
                      _guestsCount = 1;
                    });
                  },
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      SearchFilters(
                        query: _searchController.text,
                        dateRange: _selectedDateRange,
                        guests: _guestsCount,
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Search',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

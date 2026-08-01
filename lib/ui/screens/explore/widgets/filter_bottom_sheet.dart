import 'package:flutter/material.dart';

class LodgeFilterOptions {
  final RangeValues priceRange;
  final double minRating;
  final bool freeCancellation;
  final Set<String> selectedAmenities;
  final Set<String> selectedNeighborhoods;

  const LodgeFilterOptions({
    required this.priceRange,
    required this.minRating,
    required this.freeCancellation,
    required this.selectedAmenities,
    required this.selectedNeighborhoods,
  });
}

class FilterBottomSheet extends StatefulWidget {
  final LodgeFilterOptions initialOptions;
  const FilterBottomSheet({Key? key, required this.initialOptions}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late double _minRating;
  late bool _freeCancellation;
  final Set<String> _selectedAmenities = {};
  final Set<String> _selectedNeighborhoods = {};

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialOptions.priceRange;
    _minRating = widget.initialOptions.minRating;
    _freeCancellation = widget.initialOptions.freeCancellation;
    _selectedAmenities.addAll(widget.initialOptions.selectedAmenities);
    _selectedNeighborhoods.addAll(widget.initialOptions.selectedNeighborhoods);
  }

  static const List<String> _amenities = [
    'Wi-Fi',
    'Air Conditioning',
    'Breakfast',
    'Parking',
    'Pool',
    'Private Bathroom',
  ];

  static const List<String> _neighborhoods = [
    'Mikocheni',
    'Kariakoo',
    'Sabasaba',
    'Kisasa',
    'Njiro',
  ];

  String _formatPrice(double value) {
    final intVal = value.toInt();
    return intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _priceRange = const RangeValues(0, 200000);
                          _minRating = 0;
                          _freeCancellation = false;
                          _selectedAmenities.clear();
                          _selectedNeighborhoods.clear();
                        });
                      },
                      child: Text(
                        'Reset All',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Price Range
                    _buildSectionTitle('Price Range (per night)'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TSh ${_formatPrice(_priceRange.start)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'TSh ${_formatPrice(_priceRange.end)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPriceHistogram(),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.red.shade900,
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.red.shade900,
                        overlayColor: Colors.red.shade100.withValues(alpha: 0.3),
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: RangeSlider(
                        min: 0,
                        max: 200000,
                        divisions: 20,
                        values: _priceRange,
                        onChanged: (range) => setState(() => _priceRange = range),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Minimum Rating
                    _buildSectionTitle('Minimum Guest Rating'),
                    const SizedBox(height: 8),
                    _buildRatingChips(),
                    const SizedBox(height: 20),

                    // Free Cancellation
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Free Cancellation',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Only show properties with free cancellation',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: Colors.red.shade900,
                        value: _freeCancellation,
                        onChanged: (val) => setState(() => _freeCancellation = val),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amenities
                    _buildSectionTitle('Amenities'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amenities.map((amenity) {
                        final selected = _selectedAmenities.contains(amenity);
                        return AnimatedFilterChip(
                          label: amenity,
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Neighborhoods
                    _buildSectionTitle('Neighborhoods'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _neighborhoods.map((area) {
                        final selected = _selectedNeighborhoods.contains(area);
                        return AnimatedFilterChip(
                          label: area,
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedNeighborhoods.add(area);
                              } else {
                                _selectedNeighborhoods.remove(area);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                     onPressed: () {
                      Navigator.pop(
                        context,
                        LodgeFilterOptions(
                          priceRange: _priceRange,
                          minRating: _minRating,
                          freeCancellation: _freeCancellation,
                          selectedAmenities: _selectedAmenities,
                          selectedNeighborhoods: _selectedNeighborhoods,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRatingChips() {
    final ratings = [
      {'value': 4.5, 'label': '4.5+ Exceptional'},
      {'value': 4.0, 'label': '4.0+ Very Good'},
      {'value': 3.5, 'label': '3.5+ Good'},
      {'value': 3.0, 'label': '3.0+ Pleasant'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratings.map((r) {
        final ratingVal = r['value'] as double;
        final selected = _minRating == ratingVal;
        return AnimatedChoiceChip(
          selected: selected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 14, color: selected ? Colors.amber : Colors.grey),
              const SizedBox(width: 6),
              Text(
                r['label'] as String,
                style: TextStyle(
                  color: selected ? Colors.amber.shade900 : Colors.black87,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          onSelected: (val) {
            setState(() {
              _minRating = val ? ratingVal : 0;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriceHistogram() {
    final List<int> frequencies = [
      4, 8, 15, 30, 52, 78, 95, 115, 108, 90, 75, 58, 42, 32, 22, 15, 10, 6, 3, 1
    ];
    final double maxFreq = frequencies.reduce((a, b) => a > b ? a : b).toDouble();
    final double step = 200000 / frequencies.length;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(frequencies.length, (index) {
          final double barMin = index * step;
          final double barMax = (index + 1) * step;
          
          final bool isActive = barMax >= _priceRange.start && barMin <= _priceRange.end;
          final double normalizedHeight = frequencies[index] / maxFreq;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              height: 50 * normalizedHeight,
              decoration: BoxDecoration(
                color: isActive ? Colors.red.shade900 : Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const AnimatedFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<AnimatedFilterChip> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color selectedBg = Color(0xFFFFEBEE);
    const Color unselectedBg = Color(0xFFF5F5F5);
    const Color selectedBorder = Color(0xFFB71C1C);
    const Color unselectedBorder = Color(0xFFE0E0E0);
    const Color selectedText = Color(0xFFB71C1C);
    const Color unselectedText = Colors.black87;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onSelected(!widget.selected);
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: widget.selected ? selectedBorder : unselectedBorder,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: widget.selected
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: selectedBorder),
                            SizedBox(width: 6),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected ? selectedText : unselectedText,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedChoiceChip extends StatefulWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const AnimatedChoiceChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<AnimatedChoiceChip> createState() => _AnimatedChoiceChipState();
}

class _AnimatedChoiceChipState extends State<AnimatedChoiceChip> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedBg = Colors.amber.shade50;
    final Color unselectedBg = Colors.grey.shade100;
    final Color selectedBorder = Colors.amber.shade700;
    final Color unselectedBorder = Colors.grey.shade300;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onSelected(!widget.selected);
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: widget.selected ? selectedBorder : unselectedBorder,
                width: 1.2,
              ),
            ),
            child: widget.label,
          ),
        ),
      ),
    );
  }
}

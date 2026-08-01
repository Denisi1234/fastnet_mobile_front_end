import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';

class SearchFilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const SearchFilterScreen({Key? key, this.initialFilters}) : super(key: key);

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  RangeValues _priceRange = const RangeValues(0, 1000000);
  int _minRating = 0; // 0 means no filter
  String? _propertyType;
  final Set<String> _amenities = {};

  static const _propertyTypes = [
    'Lodge',
    'Villa',
    'Hotel',
    'Apartment',
    'Beach Resort',
  ];

  static const _amenityOptions = [
    'Pool',
    'WiFi',
    'Parking',
    'Gym',
    'Restaurant',
    'Spa',
    'Beach Access',
    'Breakfast Included',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    if (f != null) {
      _cityController.text = f['city'] ?? '';
      final pMin = (f['priceMin'] as double?) ?? 0;
      final pMax = (f['priceMax'] as double?) ?? 1000000;
      _priceRange = RangeValues(pMin, pMax);
      _minRating = ((f['minRating'] as double?) ?? 0).toInt();
      _propertyType = f['propertyType'] as String?;
      final ams = f['amenities'];
      if (ams is List) _amenities.addAll(ams.cast<String>());
      if (pMin > 0) _minPriceController.text = pMin.toInt().toString();
      if (pMax < 1000000) _maxPriceController.text = pMax.toInt().toString();
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _cityController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _priceRange = const RangeValues(0, 1000000);
      _minRating = 0;
      _propertyType = null;
      _amenities.clear();
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'priceMin':
          _priceRange.start <= 0 ? null : _priceRange.start,
      'priceMax':
          _priceRange.end >= 1000000 ? null : _priceRange.end,
      'minRating': _minRating == 0 ? null : _minRating.toDouble(),
      'amenities': _amenities.toList(),
      'propertyType': _propertyType,
    };
    Navigator.pop(context, filters);
  }

  String _formatPrice(double v) {
    if (v >= 1000000) return 'TSh 1M+';
    if (v >= 1000) {
      return 'TSh ${(v / 1000).toStringAsFixed(0)}k';
    }
    return 'TSh ${v.toInt()}';
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Location / City ─────────────────────────────
                  _sectionTitle('Location / City'),
                  _card(
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Dar es Salaam, Zanzibar...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.location_on_outlined,
                            color: Colors.red.shade900),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.red.shade900, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),

                  // ── Price Range ─────────────────────────────────
                  _sectionTitle('Price Range (TSh / night)'),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatPrice(_priceRange.start),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatPrice(_priceRange.end),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.red.shade900,
                            thumbColor: Colors.red.shade900,
                            overlayColor:
                                Colors.red.shade900.withValues(alpha: 0.12),
                            inactiveTrackColor: Colors.grey.shade200,
                            valueIndicatorColor: Colors.red.shade900,
                            valueIndicatorTextStyle:
                                const TextStyle(color: Colors.white),
                          ),
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000000,
                            divisions: 40,
                            labels: RangeLabels(
                              _formatPrice(_priceRange.start),
                              _formatPrice(_priceRange.end),
                            ),
                            onChanged: (vals) {
                              setState(() => _priceRange = vals);
                              _minPriceController.text =
                                  vals.start.toInt().toString();
                              _maxPriceController.text =
                                  vals.end.toInt().toString();
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPriceField(
                                  _minPriceController, 'Min Price'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPriceField(
                                  _maxPriceController, 'Max Price'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Star Rating ─────────────────────────────────
                  _sectionTitle('Minimum Star Rating'),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final starVal = i + 1;
                            final active = starVal <= _minRating;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _minRating =
                                    _minRating == starVal ? 0 : starVal;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: AnimatedScale(
                                  scale: active ? 1.2 : 1.0,
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    active
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: active
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                    size: 38,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _minRating == 0
                                  ? 'Any rating'
                                  : '$_minRating star${_minRating > 1 ? 's' : ''} & above',
                              key: ValueKey(_minRating),
                              style: TextStyle(
                                color: _minRating == 0
                                    ? Colors.grey.shade500
                                    : Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Property Type ───────────────────────────────
                  _sectionTitle('Property Type'),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _propertyTypes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final t = _propertyTypes[i];
                        final selected = _propertyType == t;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _propertyType = selected ? null : t;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.red.shade900
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected
                                    ? Colors.red.shade900
                                    : Colors.grey.shade300,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.shade900
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Amenities ───────────────────────────────────
                  _sectionTitle('Amenities'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _amenityOptions.map((a) {
                      final selected = _amenities.contains(a);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _amenities.remove(a);
                          } else {
                            _amenities.add(a);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.red.shade900
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? Colors.red.shade900
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.red.shade900
                                          .withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected)
                                const Icon(Icons.check,
                                    size: 14, color: Colors.white),
                              if (selected) const SizedBox(width: 5),
                              Text(
                                a,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Sticky bottom Apply button ──────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  shadowColor:
                      Colors.red.shade900.withValues(alpha: 0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Show Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(
      TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        final d = double.tryParse(val);
        if (d != null) {
          setState(() {
            if (label.contains('Min')) {
              _priceRange = RangeValues(
                d.clamp(0, _priceRange.end),
                _priceRange.end,
              );
            } else {
              _priceRange = RangeValues(
                _priceRange.start,
                d.clamp(_priceRange.start, 1000000),
              );
            }
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixText: 'TSh ',
        prefixStyle: TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.red.shade900, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

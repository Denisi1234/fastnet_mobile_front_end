import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/models/destination.dart';

class CalendarPricingEditorScreen extends StatefulWidget {
  final Destination destination;
  const CalendarPricingEditorScreen({Key? key, required this.destination}) : super(key: key);

  @override
  State<CalendarPricingEditorScreen> createState() => _CalendarPricingEditorScreenState();
}

class _CalendarPricingEditorScreenState extends State<CalendarPricingEditorScreen> {
  final Set<int> _blockedDays = {5, 6, 12, 13, 20}; // Sample pre-blocked days in the month
  final Map<int, int> _customPrices = {}; // Day number to custom price
  int _selectedDay = 15;
  late int _basePrice;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _basePrice = widget.destination.price;
    _priceController.text = _basePrice.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _updatePriceForSelectedDay() {
    final newPrice = int.tryParse(_priceController.text.trim());
    if (newPrice != null && newPrice > 0) {
      setState(() {
        _customPrices[_selectedDay] = newPrice;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated price for July $_selectedDay to ${_formatPrice(newPrice)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleBlockedSelectedDay() {
    setState(() {
      if (_blockedDays.contains(_selectedDay)) {
        _blockedDays.remove(_selectedDay);
      } else {
        _blockedDays.add(_selectedDay);
      }
    });
    final isBlocked = _blockedDays.contains(_selectedDay);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBlocked ? 'Blocked July $_selectedDay' : 'Unblocked July $_selectedDay'),
        backgroundColor: isBlocked ? Colors.red.shade800 : Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = _blockedDays.contains(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text('${widget.destination.name} Calendar', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Month Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'July 2026',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weekdays Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Su', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('Mo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('Tu', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('We', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('Th', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('Fr', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('Sa', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            // Days Grid View (Standard 31 Days starting on Wednesday)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 34, // 3 empty padding slots + 31 days
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < 3) return const SizedBox.shrink(); // July starts on Wednesday (offset 3)
                final dayNumber = index - 2;
                final isDaySelected = _selectedDay == dayNumber;
                final isDayBlocked = _blockedDays.contains(dayNumber);
                final hasCustomPrice = _customPrices.containsKey(dayNumber);
                final dayPrice = _customPrices[dayNumber] ?? _basePrice;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = dayNumber;
                      _priceController.text = dayPrice.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isDaySelected
                          ? Colors.red.shade900
                          : (isDayBlocked ? Colors.red.shade50 : Colors.green.shade50),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDaySelected
                            ? Colors.red.shade900
                            : (hasCustomPrice ? Colors.orange : Colors.grey.shade200),
                        width: hasCustomPrice ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDaySelected
                                ? Colors.white
                                : (isDayBlocked ? Colors.red.shade900 : Colors.green.shade900),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(dayPrice / 1000).toInt()}k',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDaySelected
                                ? Colors.white70
                                : (isDayBlocked ? Colors.red.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Selected Day Settings Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'July $_selectedDay, 2026',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBlocked ? 'BLOCKED' : 'AVAILABLE',
                          style: TextStyle(
                            color: isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Edit pricing row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nightly Rate (TSh)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixText: 'TSh ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _updatePriceForSelectedDay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle availability button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _toggleBlockedSelectedDay,
                      icon: Icon(isBlocked ? Icons.check_circle_outline : Icons.block, color: isBlocked ? Colors.green : Colors.red.shade800),
                      label: Text(
                        isBlocked ? 'Make Day Available' : 'Block Out Day',
                        style: TextStyle(color: isBlocked ? Colors.green : Colors.red.shade800, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isBlocked ? Colors.green : Colors.red.shade800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bulk actions section
            const Text('Smart Pricing Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildRuleTile('Weekend Markup', 'Auto-add +15% pricing on Friday and Saturday stays.', true),
            _buildRuleTile('Early Bird Discount', 'Apply 10% off for reservations made 30 days in advance.', false),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(String title, String desc, bool value) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      value: value,
      activeThumbColor: Colors.red.shade900,
      onChanged: (val) {},
    );
  }
}

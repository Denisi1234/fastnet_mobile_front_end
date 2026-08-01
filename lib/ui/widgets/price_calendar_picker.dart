import 'package:flutter/material.dart';

class PriceCalendarPicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  const PriceCalendarPicker({Key? key, this.initialRange}) : super(key: key);

  @override
  State<PriceCalendarPicker> createState() => _PriceCalendarPickerState();
}

class _PriceCalendarPickerState extends State<PriceCalendarPicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    }
    _currentMonth = DateTime.now();
  }

  // Helper to generate mock daily price rates (TSh) based on day index & weekends
  int _getDayPrice(DateTime date) {
    const basePrice = 60000;
    final dayOfWeek = date.weekday;
    final nameHash = date.day * 17;
    
    // Weekends (Friday, Saturday) are peak pricing
    if (dayOfWeek == 5 || dayOfWeek == 6) {
      return basePrice + 35000 + (nameHash % 4) * 5000; // Peak weekends
    }
    // Middle of the month has dynamic rates
    if (date.day > 10 && date.day < 20) {
      return basePrice + 15000 + (nameHash % 3) * 5000; // Mid rates
    }
    return basePrice + (nameHash % 3) * 5000; // Low budget rates
  }

  Color _getPriceColor(int price) {
    if (price < 75000) return Colors.green.shade600;
    if (price < 95000) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _formatPriceAbbr(int price) {
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  void _onDayTap(DateTime date) {
    if (_startDate == null || (_startDate != null && _endDate != null)) {
      setState(() {
        _startDate = date;
        _endDate = null;
      });
    } else if (_startDate != null && _endDate == null) {
      if (date.isBefore(_startDate!)) {
        setState(() {
          _startDate = date;
          _endDate = null;
        });
      } else {
        setState(() {
          _endDate = date;
        });
      }
    }
  }

  bool _isDaySelected(DateTime date) {
    if (_startDate != null && _startDate!.year == date.year && _startDate!.month == date.month && _startDate!.day == date.day) {
      return true;
    }
    if (_endDate != null && _endDate!.year == date.year && _endDate!.month == date.month && _endDate!.day == date.day) {
      return true;
    }
    return false;
  }

  bool _isDayInRange(DateTime date) {
    if (_startDate != null && _endDate != null) {
      return date.isAfter(_startDate!) && date.isBefore(_endDate!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Indicator
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          
          // Title area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Dates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Days color-coded by dynamic season rates', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pricing legend helper
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.green.shade600, 'Low Rate (TSh <75k)'),
                _buildLegendItem(Colors.orange.shade700, 'Mid Rate (75k-95k)'),
                _buildLegendItem(Colors.red.shade700, 'Peak Rate (>95k)'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weekday label headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
                return SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black45)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Months views
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4, // Next 4 months
              itemBuilder: (context, index) {
                final monthDate = DateTime(_currentMonth.year, _currentMonth.month + index, 1);
                return _buildMonthGrid(monthDate, months);
              },
            ),
          ),

          // Bottom Action bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selected Stay', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        _startDate == null
                            ? 'Select Dates'
                            : _endDate == null
                                ? 'Choose end date'
                                : '${_startDate!.day} ${_startDate!.month == _endDate!.month ? '' : months[_startDate!.month - 1].substring(0, 3)} – ${_endDate!.day} ${months[_endDate!.month - 1].substring(0, 3)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _startDate == null || _endDate == null
                      ? null
                      : () {
                          Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate!));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }

  Widget _buildMonthGrid(DateTime monthDate, List<String> months) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday % 7;
    
    final gridItems = firstWeekday + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10, left: 8),
          child: Text(
            '${months[monthDate.month - 1]} ${monthDate.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: 0.9,
          ),
          itemCount: gridItems,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }
            
            final day = index - firstWeekday + 1;
            final date = DateTime(monthDate.year, monthDate.month, day);
            final price = _getDayPrice(date);
            final isSelected = _isDaySelected(date);
            final isInRange = _isDayInRange(date);
            final isBeforeToday = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

            Color cellBg = Colors.transparent;
            Color textCol = isBeforeToday ? Colors.grey.shade300 : Colors.black87;
            
            if (isSelected) {
              cellBg = Colors.red.shade900;
              textCol = Colors.white;
            } else if (isInRange) {
              cellBg = Colors.red.shade50;
              textCol = Colors.red.shade900;
            }

            return GestureDetector(
              onTap: isBeforeToday ? null : () => _onDayTap(date),
              child: Container(
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: textCol,
                        fontSize: 14,
                      ),
                    ),
                    if (!isBeforeToday) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatPriceAbbr(price),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white70
                              : isInRange
                                  ? Colors.red.shade800
                                  : _getPriceColor(price),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

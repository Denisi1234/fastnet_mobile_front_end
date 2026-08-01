import 'package:flutter/material.dart';

class RoomMapScreen extends StatefulWidget {
  const RoomMapScreen({Key? key}) : super(key: key);

  @override
  State<RoomMapScreen> createState() => _RoomMapScreenState();
}

class _RoomMapScreenState extends State<RoomMapScreen> {
  // Mock data for rooms (true = booked/red, false = available/white)
  // Let's create 30 rooms for this floor.
  // We'll mimic the layout from the reference: left side and right side of a corridor.
  final List<Map<String, dynamic>> _rooms = List.generate(40, (index) {
    return {
      'number': '${101 + index}',
      // randomly set some as booked for demonstration
      'isBooked': [0, 1, 3, 4, 7, 10, 14, 15, 18, 22, 29, 32, 35].contains(index),
      'isSelected': false,
    };
  });

  int get _bookedCount => _rooms.where((room) => room['isBooked'] == true).length;
  int get _selectedCount => _rooms.where((room) => room['isSelected'] == true).length;
  int get _availableCount => _rooms.length - _bookedCount;

  void _clearSelection() {
    setState(() {
      for (final room in _rooms) {
        room['isSelected'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Room Booking Map', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Header info & Legend
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Floor 1 - Main Wing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _buildLegendItem(Colors.white, 'Available', true),
                        const SizedBox(width: 12),
                        _buildLegendItem(Colors.redAccent, 'Booked', false),
                        const SizedBox(width: 12),
                        _buildLegendItem(Colors.blue.shade600, 'Selected', false),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildStatChip('Rooms', _rooms.length, Colors.red.shade900),
                    _buildStatChip('Available', _availableCount, Colors.green.shade700),
                    _buildStatChip('Booked', _bookedCount, Colors.red.shade700),
                    _buildStatChip('Selected', _selectedCount, Colors.blue.shade700),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // The visual map (Corridor style)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildCorridorMap(),
              ),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearSelection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Clear Selection'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       final selected = _rooms.where((r) => r['isSelected'] == true).toList();
                       if(selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an available room first.')));
                          return;
                       }
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Proceeding to book ${selected.map((e) => e['number']).join(", ")}')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Book Selected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool hasBorder) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorMap() {
    // We will build rows of 4 rooms: 2 on the left, an aisle, and 2 on the right.
    List<Widget> rows = [];
    
    // Front desk / Entry visualization
    rows.add(
      Container(
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Text('ENTRANCE / RECEPTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
      ),
    );

    for (int i = 0; i < _rooms.length; i += 4) {
      if (i + 3 >= _rooms.length) break;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side rooms
              Row(
                children: [
                  _buildRoomBox(_rooms[i]),
                  const SizedBox(width: 8),
                  _buildRoomBox(_rooms[i + 1]),
                ],
              ),
              
              // Corridor / Aisle indicator
              const Expanded(
                child: Center(
                  child: Icon(Icons.arrow_downward, color: Colors.black12, size: 20),
                ),
              ),

              // Right side rooms
              Row(
                children: [
                  _buildRoomBox(_rooms[i + 2]),
                  const SizedBox(width: 8),
                  _buildRoomBox(_rooms[i + 3]),
                ],
              ),
            ],
          ),
        )
      );
    }

    return Column(children: rows);
  }

  Widget _buildRoomBox(Map<String, dynamic> room) {
    final bool isBooked = room['isBooked'] == true;
    final bool isSelected = room['isSelected'] == true;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade400;
    Color textColor = Colors.black87;

    if (isBooked) {
      bgColor = Colors.red.shade400;
      borderColor = Colors.red.shade400;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = Colors.blue.shade600;
      borderColor = Colors.blue.shade600;
      textColor = Colors.white;
    }

    return Semantics(
      button: true,
      label: 'Room ${room['number']} ${isBooked ? 'booked' : isSelected ? 'selected' : 'available'}',
      child: GestureDetector(
        onTap: () {
          if (isBooked) return;
          setState(() {
            room['isSelected'] = !room['isSelected'];
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (!isBooked && !isSelected)
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  room['number'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              if (isBooked)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.block, size: 12, color: Colors.white70),
                )
            ],
          ),
        ),
      ),
    );
  }
}

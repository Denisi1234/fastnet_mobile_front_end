import 'package:flutter/material.dart';

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _categories = const [
    {'text': 'Rooms', 'imageUrl': 'assets/images/rooms.jpeg'},
    {'text': 'Pools', 'imageUrl': 'assets/images/pool.jpeg'},
    {'text': 'Beachfront', 'imageUrl': 'assets/images/beachfront.jpeg'},
    {'text': 'Lakes', 'imageUrl': 'assets/images/lakes.jpeg'},
    {'text': 'Amazing views', 'imageUrl': 'assets/images/views.jpeg'},
    {'text': 'Islands', 'imageUrl': 'assets/images/palm-tree.png'},
    {'text': 'Caves', 'imageUrl': 'assets/images/cave.png'},
    {'text': 'Deserts', 'imageUrl': 'assets/images/cactus.png'},
    {'text': 'Tropical', 'imageUrl': 'assets/images/island.png'},
    {'text': 'Creative spaces', 'imageUrl': 'assets/images/art.png'},
    {'text': 'Mansions', 'imageUrl': 'assets/images/villa.png'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.black87,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2.5,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.grey.shade500,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _tabController.index == index;

          return Tab(
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 0.95,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    item['imageUrl']!,
                    height: 20,
                    width: 20,
                    color: isSelected ? Colors.black87 : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['text']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

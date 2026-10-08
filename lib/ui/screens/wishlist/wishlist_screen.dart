import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/providers/wishlist_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/web_header.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _selectedGroupIndex = 0;

  @override
  void initState() {
    super.initState();
    // Live sync with web `/my-wishlists`: same backend rows.
    Future.microtask(() {
      if (mounted) context.read<WishlistProvider>().syncFromApi();
    });
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showCreateWishlistDialog() {
    final textController = TextEditingController();
    bool isPrivate = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Beach Getaways',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Private List', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Only visible to you', style: TextStyle(fontSize: 11)),
                    value: isPrivate,
                    activeThumbColor: Colors.red.shade900,
                    onChanged: (val) {
                      setDialogState(() {
                        isPrivate = val;
                      });
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = textController.text.trim();
                    if (name.isNotEmpty) {
                      final provider = context.read<WishlistProvider>();
                      provider.createGroup(name, isPrivate: isPrivate);
                      setState(() {
                        _selectedGroupIndex = provider.groups.length - 1;
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameWishlistDialog(int index) {
    final textController = TextEditingController(text: context.read<WishlistProvider>().groups[index].name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rename Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  context.read<WishlistProvider>().renameGroup(index, name);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              child: const Text('Rename', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final groups = wishlistProvider.groups;
    if (_selectedGroupIndex >= groups.length) {
      _selectedGroupIndex = 0;
    }
    final activeGroup = groups.isNotEmpty ? groups[_selectedGroupIndex] : WishlistGroup(name: 'Favorites', items: []);
    final savedList = activeGroup.items;
    final visitedList = RecentlyViewedData.list;

    // Collect cities user has interacted with
    final Set<String> savedCities = {
      ...savedList.map((d) => d.city),
      ...visitedList.map((d) => d.city),
    };

    // Build suggestions dynamically
    List<Destination> suggestionsList = [];
    if (savedCities.isNotEmpty) {
      suggestionsList = destinations.where((d) => 
        savedCities.contains(d.city) && !wishlistProvider.contains(d)
      ).toList();
    }
    
    if (suggestionsList.length < 4) {
      final fallbackDestinations = destinations.where((d) => 
        !wishlistProvider.contains(d) && !suggestionsList.any((s) => s.name == d.name)
      ).toList();
      fallbackDestinations.sort((a, b) => b.rating.compareTo(a.rating));
      suggestionsList.addAll(fallbackDestinations);
    }

    final String suggestionTitle = savedCities.isNotEmpty ? 'Suggested Near Your Visits' : 'Featured Lodges';
    final String suggestionSubtitle = savedCities.isNotEmpty 
        ? 'Based on stays you visited in ${savedCities.join(', ')}' 
        : 'Top-rated stays near your location';
    final isDesktopWeb = kIsWeb && !AppSettings.instance.isMobileShellMode;
    if (isDesktopWeb) {
      return _buildDesktopWebView(context, groups, activeGroup, savedList, visitedList, suggestionsList, suggestionTitle, suggestionSubtitle);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title
            const Padding(
              padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Text(
                'Wishlists',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [




              if (visitedList.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recently Viewed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stays you recently inspected',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: visitedList.length,
                    itemBuilder: (context, index) {
                      final item = visitedList[index];
                      return _buildSuggestionCard(item);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestionTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestionSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: suggestionsList.length,
                  itemBuilder: (context, index) {
                    final item = suggestionsList[index];
                    return _buildSuggestionCard(item);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
  }



  Widget _buildSuggestionCard(Destination item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookRoom(
              destination: item,
            ),
          ),
        );
      },
      child: Container(
        width: 190,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: PropertyImage(
                    url: item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87),
                        ),
                      ],
                    ),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.area}, ${item.city}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrice(item.price),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87),
                          ),
                        ],
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

  Widget _buildDesktopWebView(
    BuildContext context,
    List<WishlistGroup> groups,
    WishlistGroup activeGroup,
    List<Destination> savedList,
    List<Destination> visitedList,
    List<Destination> suggestionsList,
    String suggestionTitle,
    String suggestionSubtitle,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: WebTopHeader(
        selectedIndex: 1,
        onTabSelected: (idx) {
          if (idx != 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen(initialTab: idx)),
              (route) => false,
            );
          }
        },
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and create list button
                Row(
                  children: [
                    const Text(
                      'Wishlists',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showCreateWishlistDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create list', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006CE4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar Wishlist Folders List
                    SizedBox(
                      width: 260,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('My folders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            ...List.generate(groups.length, (idx) {
                              final gp = groups[idx];
                              final isSelected = _selectedGroupIndex == idx;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(0xFF003580).withValues(alpha: 0.05),
                                leading: Icon(
                                  gp.isPrivate ? Icons.lock_outline : Icons.folder_open_outlined,
                                  color: isSelected ? const Color(0xFF003580) : Colors.black54,
                                ),
                                title: Text(
                                  gp.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF003580) : Colors.black87,
                                  ),
                                ),
                                trailing: Text(
                                  '${gp.items.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF003580) : Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedGroupIndex = idx;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Active Wishlist Properties Grid
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeGroup.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activeGroup.isPrivate ? 'Only me' : 'Shared',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (savedList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(48),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text('No saved properties yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text('Stays you save will appear here in folders.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: savedList.length,
                              itemBuilder: (context, index) {
                                final item = savedList[index];
                                final stars = item.rating.round().clamp(1, 5);
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookRoom(destination: item),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                                          child: PropertyImage(url: item.imageUrl, width: 140, height: double.infinity, fit: BoxFit.cover),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: List.generate(stars, (_) => const Icon(Icons.star, size: 12, color: Color(0xFFF5A623))),
                                                ),
                                                const Spacer(),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatPrice(item.price),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003580)),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.favorite, color: Colors.red, size: 18),
                                                      onPressed: () {
                                                        context.read<WishlistProvider>().toggle(item);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 48),

                          // Suggestions section
                          Text(suggestionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(suggestionSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: suggestionsList.length,
                              itemBuilder: (context, index) {
                                final item = suggestionsList[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildSuggestionCard(item),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





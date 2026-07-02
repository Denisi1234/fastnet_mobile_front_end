import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/book_room.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/providers/wishlist_provider.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/destination.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _selectedGroupIndex = 0;

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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title and Create Wishlist Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wishlists',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.8,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateWishlistDialog,
                      icon: Icon(Icons.add, color: Colors.red.shade900, size: 18),
                      label: Text(
                        'New List',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wishlist groups horizontal switcher
              SizedBox(
                height: 135, // Increased to 135 to fix RenderFlex overflow
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isSelected = _selectedGroupIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGroupIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 155,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.red.shade900 : Colors.grey.shade200,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.red.shade900.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  group.isPrivate ? Icons.lock_outline : Icons.public_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert, size: 14, color: Colors.black54),
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _showRenameWishlistDialog(index);
                                    } else if (value == 'privacy') {
                                      wishlistProvider.toggleGroupPrivacy(index);
                                    } else if (value == 'delete') {
                                      wishlistProvider.deleteGroup(index);
                                      setState(() {
                                        if (_selectedGroupIndex >= groups.length) {
                                          _selectedGroupIndex = 0;
                                        }
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Text('Rename', style: TextStyle(fontSize: 13)),
                                    ),
                                    PopupMenuItem(
                                      value: 'privacy',
                                      child: Text(
                                        group.isPrivate ? 'Make Public' : 'Make Private',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    if (index > 0) // Cannot delete default Favorites folder
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${group.items.length} stay${group.items.length == 1 ? '' : 's'}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Active selected group items listing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Saved in ${activeGroup.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (savedList.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    final item = savedList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: DestinationWidget(
                        destination: item,
                        index: index,
                        numNights: 3,
                        selectedDatesText: 'Jun 25 – 28',
                      ),
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: EmptyStateWidget(
                    icon: Icons.bookmark_border_outlined,
                    title: 'No stays in this wishlist',
                    description: 'Keep exploring and tap the heart icon to save listings to "${activeGroup.name}".',
                    buttonText: 'Find Lodges',
                    onButtonPressed: () {
                      // Navigate or toggle tab focus back
                    },
                  ),
                ),

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
              selectedDatesText: 'Jun 25 – 28',
              numNights: 3,
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
                  child: Image.asset(
                    item.imageUrl,
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
}





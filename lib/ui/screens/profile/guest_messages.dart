import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/services/notification_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/shimmer_widget.dart';
import 'package:fastnet_mobile_front_end/ui/screens/notifications/notifications_screen.dart';

class GuestMessagesScreen extends StatefulWidget {
  const GuestMessagesScreen({Key? key}) : super(key: key);

  @override
  State<GuestMessagesScreen> createState() => _GuestMessagesScreenState();
}

class _GuestMessagesScreenState extends State<GuestMessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _displayThreads = [];
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Unread'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadThreads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiThreads = await ApiService.fetchMessageThreads();
      if (mounted) {
        setState(() {
          _displayThreads = apiThreads.map((t) => {
            'hostId': t['partner_id'] ?? 0,
            'hostName': t['partner_name'] ?? 'Unknown',
            'lodgeName': t['lodge_name'] ?? '',
            'avatar': t['partner_role'] == 'owner' ? 'assets/images/man2.jpeg' : 'assets/images/man.jpeg',
            'lastMessage': t['last_message'] ?? '',
            'time': t['time'] ?? 'Just now',
            'unread': t['unread'] ?? false,
            'isOnline': true,
            'isReal': true,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load API threads: $e');
      if (mounted) {
        setState(() {
          _displayThreads = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredThreads {
    return _displayThreads.where((thread) {
      final matchesSearch = thread['hostName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          thread['lodgeName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          thread['lastMessage'].toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_activeFilter == 'Unread') {
        return thread['unread'] == true;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Inbox',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade900,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.red.shade900,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'Notifications'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.black87),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadThreads();
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              // Search and Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // Modern Search Field
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter Tabs
                    Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Unread'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              
              // Threads List
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        itemCount: 3,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: SkeletonCard(height: 130),
                        ),
                      )
                    : _filteredThreads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_outline_rounded, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'No messages found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredThreads.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final thread = _filteredThreads[index];
                              return _buildThreadTile(thread);
                            },
                          ),
              ),
            ],
          ),
          const NotificationsScreen(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = _activeFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade900 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filterName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildThreadTile(Map<String, dynamic> thread) {
    final bool hasUnread = thread['unread'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              setState(() {
                thread['unread'] = false;
              });
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuestChatDetailScreen(thread: thread),
                ),
              );
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar with Online Status
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(thread['avatar']),
                        radius: 26,
                      ),
                      if (thread['isOnline'] == true)
                        Positioned(
                          bottom: 0,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Thread Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              thread['hostName'],
                              style: TextStyle(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              thread['time'],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          thread['lodgeName'],
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          thread['lastMessage'],
                          style: TextStyle(
                            color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GuestChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  const GuestChatDetailScreen({Key? key, required this.thread}) : super(key: key);

  @override
  State<GuestChatDetailScreen> createState() => _GuestChatDetailScreenState();
}

class _GuestChatDetailScreenState extends State<GuestChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;
  bool _isHostTyping = false;

  // New professional variables
  bool _isTripBarExpanded = false;
  bool _isSafetyBannerDismissed = false;

  final List<Map<String, String>> _quickReplies = [
    {'text': '📶 Wi-Fi Passcode', 'query': 'What is the Wi-Fi password?'},
    {'text': '🔑 Early Check-in', 'query': 'Do you offer early check-in?'},
    {'text': '🍳 Breakfast Options', 'query': 'Is breakfast included in the booking?'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRealMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _loadRealMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadRealMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final hostId = widget.thread['hostId'] as int;
      final apiMsgs = await ApiService.fetchMessages(hostId);
      if (mounted) {
        final previousCount = _messages.length;
        setState(() {
          _messages = apiMsgs.map((m) => {
            'sender': m['sender_id'] == UserSession.userId ? 'guest' : 'host',
            'text': m['text'].toString(),
            'time': m['created_at'] != null ? _formatTime(m['created_at']) : 'Just now',
            'type': m['type'] ?? 'text',
            'attachmentUrl': m['attachment_url'],
            'isRead': m['is_read'] ?? true,
            'status': 'sent',
          }).toList();
          _isLoading = false;
        });

        if (apiMsgs.isNotEmpty && _messages.length > previousCount) {
          final lastMsg = _messages.last;
          if (lastMsg['sender'] == 'host') {
            NotificationService.showInAppNotification(
              title: 'Message from ${widget.thread['hostName']}',
              body: lastMsg['text']!,
              icon: Icons.chat_bubble_outline,
            );
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      debugPrint('Failed to load API messages: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String rawTime) {
    try {
      final parsed = DateTime.parse(rawTime).toLocal();
      final hours = parsed.hour.toString().padLeft(2, '0');
      final mins = parsed.minute.toString().padLeft(2, '0');
      return '$hours:$mins';
    } catch (_) {
      return 'Just now';
    }
  }

  void _sendMessage({String? customText, String type = 'text', String? attachmentUrl}) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty && attachmentUrl == null) return;

    if (customText == null) {
      _controller.clear();
    }

    final newMsgIndex = _messages.length;
    setState(() {
      _messages.add({
        'sender': 'guest',
        'text': text,
        'time': 'Just now',
        'type': type,
        'attachmentUrl': attachmentUrl,
        'isRead': false,
        'status': 'sending',
      });
    });
    _scrollToBottom();

    try {
      final hostId = widget.thread['hostId'] as int;
      await ApiService.sendMessage(
        recipientId: hostId,
        lodgeName: widget.thread['lodgeName'] ?? '',
        text: text,
      );
      if (mounted) {
        setState(() {
          _messages[newMsgIndex]['status'] = 'sent';
        });
        _loadRealMessages(silent: true);
      }
    } catch (e) {
      debugPrint('Failed to send API message: $e');
      if (mounted) {
        setState(() {
          _messages[newMsgIndex]['status'] = 'failed';
        });
      }
    }
  }

  void _retryMessage(int index) {
    if (index < 0 || index >= _messages.length) return;
    final text = _messages[index]['text'] as String;
    
    setState(() {
      _messages[index]['status'] = 'sending';
    });
    
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _messages[index]['status'] = 'sent';
        _simulateHostResponse(text);
      });
    });
  }

  void _simulateHostResponse(String text) {
    setState(() {
      _isHostTyping = true;
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        String replyText = 'Thanks for your message! We will get back to you shortly.';
        if (text.toLowerCase().contains('wi-fi') || text.toLowerCase().contains('wifi')) {
          replyText = 'Karibu! The Wi-Fi network is \'${widget.thread['lodgeName']}_Guest\' and the passcode is \'welcome2026\'. Enjoy high-speed access!';
        } else if (text.toLowerCase().contains('early check-in') || text.toLowerCase().contains('check-in')) {
          replyText = 'Yes, standard check-in is at 2:00 PM, but we can arrange early check-in from 11:00 AM free of charge if the room is vacated. Please let us know your arrival time!';
        } else if (text.toLowerCase().contains('breakfast')) {
          replyText = 'Yes! A complimentary English & Swahili breakfast buffet is served daily from 6:30 AM to 10:00 AM in our dining hall.';
        }

        setState(() {
          _isHostTyping = false;
          // Mark previous guest messages as read
          for (var m in _messages) {
            if (m['sender'] == 'guest') {
              m['isRead'] = true;
            }
          }
          _messages.add({
            'sender': 'host',
            'text': replyText,
            'time': 'Just now',
            'type': 'text',
            'isRead': true,
            'status': 'sent',
          });
          widget.thread['lastMessage'] = replyText;
          widget.thread['messages'] = _messages;
        });
        _scrollToBottom();

        NotificationService.showInAppNotification(
          title: 'Message from ${widget.thread['hostName']}',
          body: replyText,
          icon: Icons.chat_bubble_outline,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share Attachment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachItem(
                    icon: Icons.image,
                    label: 'Photo',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        customText: 'Shared a photo',
                        type: 'image',
                        attachmentUrl: 'assets/images/room.webp',
                      );
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        customText: 'Shared location: Mikocheni, Dar es Salaam',
                        type: 'location',
                        attachmentUrl: '-6.7780,39.2730',
                      );
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.receipt_long,
                    label: 'Invoice',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        customText: 'Shared Booking Invoice: ${widget.thread['lodgeName']}',
                        type: 'voucher',
                        attachmentUrl: 'FN-BOOK-9481',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTripSummaryBar() {
    final destName = widget.thread['lodgeName'] ?? 'Lodge Stay';

    // Find the real user booking for this lodge (case-insensitive contains check)
    final booking = BookingsData.list.firstWhere(
      (b) => b['name'].toString().toLowerCase().contains(destName.toLowerCase()) || 
             destName.toLowerCase().contains(b['name'].toString().toLowerCase()),
      orElse: () => <String, dynamic>{},
    );

    // Dynamic strings or fallback defaults
    final dates = booking.isNotEmpty ? (booking['dates'] ?? 'Jul 20 – 23') : 'Jul 20 – 23';
    final roomNum = booking.isNotEmpty ? (booking['roomNumber'] ?? '101') : '101';
    final code = booking.isNotEmpty ? (booking['code'] ?? 'TZ-82914-MSK') : 'TZ-82914-MSK';
    final nights = booking.isNotEmpty ? (booking['nights'] ?? 3) : 3;
    final price = booking.isNotEmpty ? (booking['price'] ?? 260000) : 260000;
    
    // Status text mapping
    String statusText = 'Upcoming stay';
    if (booking.isNotEmpty) {
      if (booking['status'] == 'Checked In') statusText = 'Active stay';
      if (booking['status'] == 'Completed') statusText = 'Past stay';
      if (booking['status'] == 'Cancelled') statusText = 'Cancelled stay';
    }

    final priceFormatted = 'TSh ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _isTripBarExpanded = !_isTripBarExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, color: Colors.red.shade900, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🗓️ $dates  •  🔑 Room $roomNum  •  $statusText',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    _isTripBarExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: booking.isNotEmpty && booking['imageUrl'] != null
                            ? (booking['imageUrl'].toString().startsWith('assets/')
                                ? Image.asset(
                                    booking['imageUrl'] as String,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.red.shade50,
                                      child: Icon(Icons.hotel_rounded, color: Colors.red.shade900),
                                    ),
                                  )
                                : Image.network(
                                    booking['imageUrl'] as String,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.red.shade50,
                                      child: Icon(Icons.hotel_rounded, color: Colors.red.shade900),
                                    ),
                                  ))
                            : Image.asset(
                                widget.thread['avatar'].contains('man') ? 'assets/images/room.webp' : widget.thread['avatar'],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.red.shade50,
                                  child: Icon(Icons.hotel_rounded, color: Colors.red.shade900),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reservation Code: $code',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$nights Night${nights > 1 ? "s" : ""}  •  2 Guests  •  $priceFormatted Total',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Directions & Map'),
                                content: Text('Directions to $destName:\n\nProceed along Bagamoyo Road, turn right at Mikocheni B and follow the signs for 200m.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  )
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.map_rounded, size: 16, color: Colors.red.shade900),
                          label: const Text('Directions', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade900,
                            side: BorderSide(color: Colors.red.shade900),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _sendMessage(
                              customText: 'Shared Invoice Voucher: $code',
                              type: 'voucher',
                              attachmentUrl: code,
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                          label: const Text('Share Voucher', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            alignment: Alignment.center,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            sizeCurve: Curves.easeInOut,
            crossFadeState: _isTripBarExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    if (_isSafetyBannerDismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠️ Communicating or paying off-platform bypasses FASTNET safety shields. Never wire money directly.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSafetyBannerDismissed = true;
              });
            },
            child: Icon(Icons.close_rounded, color: Colors.amber.shade900, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.thread['avatar']),
                  radius: 18,
                ),
                if (widget.thread['isOnline'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread['hostName'],
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    widget.thread['lodgeName'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                // Collapsible Reservation Summary Details Bar
                _buildTripSummaryBar(),
                // Safety off-platform payment Warning banner
                _buildSafetyBanner(),
                
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isHostTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isHostTyping) {
                        return _buildTypingIndicator();
                      }

                      final m = _messages[index];
                      final isGuest = m['sender'] == 'guest';
                      final type = m['type'] ?? 'text';
                      final status = m['status'] ?? 'sent';

                      return Align(
                        alignment: isGuest ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isGuest
                                ? LinearGradient(
                                    colors: [Colors.red.shade900, Colors.pink.shade800],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isGuest ? null : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isGuest ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isGuest ? Radius.zero : const Radius.circular(16),
                            ),
                            border: isGuest ? null : Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              if (!isGuest)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Column(
                            crossAxisAlignment: isGuest ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              _buildBubbleContent(m, isGuest, type),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    m['time']!,
                                    style: TextStyle(
                                      color: isGuest ? Colors.white70 : Colors.grey.shade500,
                                      fontSize: 9,
                                    ),
                                  ),
                                  if (isGuest) ...[
                                    const SizedBox(width: 4),
                                    if (status == 'sending')
                                      const SizedBox(
                                        width: 8,
                                        height: 8,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                        ),
                                      )
                                    else if (status == 'failed')
                                      GestureDetector(
                                        onTap: () => _retryMessage(index),
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          size: 13,
                                          color: Colors.yellowAccent,
                                        ),
                                      )
                                    else
                                      Icon(
                                        m['isRead'] == true ? Icons.done_all : Icons.done,
                                        size: 11,
                                        color: m['isRead'] == true ? const Color(0xFF60A5FA) : Colors.white60,
                                      ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Horizontal Quick Replies bar
                if (widget.thread['isReal'] != true)
                  Container(
                    height: 48,
                    color: Colors.transparent,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final reply = _quickReplies[index];
                        return ActionChip(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          label: Text(
                            reply['text']!,
                            style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _sendMessage(customText: reply['query']!),
                        );
                      },
                    ),
                  ),

                // Text entry bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.red.shade900),
                        onPressed: _showAttachmentOptions,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: () => _sendMessage(),
                        backgroundColor: Colors.red.shade900,
                        mini: true,
                        elevation: 1,
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBubbleContent(Map<String, dynamic> message, bool isGuest, String type) {
    if (type == 'image' && message['attachmentUrl'] != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              message['attachmentUrl'] as String,
              width: 200,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message['text'] as String,
            style: TextStyle(color: isGuest ? Colors.white : Colors.black87, fontSize: 13),
          )
        ],
      );
    }

    if (type == 'location' && message['attachmentUrl'] != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGuest ? Colors.white.withValues(alpha: 0.15) : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_outlined, color: isGuest ? Colors.white : Colors.red.shade900, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location shared',
                  style: TextStyle(color: isGuest ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  message['text'] as String,
                  style: TextStyle(color: isGuest ? Colors.white70 : Colors.grey.shade600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      );
    }

    if (type == 'voucher' && message['attachmentUrl'] != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isGuest ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, color: isGuest ? Colors.white : Colors.red.shade900, size: 32),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Booking Code',
                  style: TextStyle(color: isGuest ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  message['attachmentUrl'] as String,
                  style: TextStyle(color: isGuest ? Colors.white70 : Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            )
          ],
        ),
      );
    }

    return Text(
      message['text']!,
      style: TextStyle(
        color: isGuest ? Colors.white : Colors.black87,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.zero,
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.thread['hostName'].split(' ')[0]} is typing',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(width: 8),
            const _BouncingDots(),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots({Key? key}) : super(key: key);

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The typing indicator still needs to show *something* under reduced
    // motion, so freeze it at a representative point in the cycle.
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _animController
        ..stop()
        ..value = 0.25;
    } else if (!_animController.isAnimating) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final delay = index * 0.2;
            final position = (math.sin((_animController.value * 2 * math.pi) - delay) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              transform: Matrix4.translationValues(0, -position * 4, 0),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

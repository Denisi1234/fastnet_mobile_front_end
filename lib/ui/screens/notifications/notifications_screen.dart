import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

// ── Data model ───────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = data.map((n) => AppNotification(
          id: n['id'] ?? 0,
          type: n['type'] ?? 'info',
          title: n['title'] ?? 'Notification',
          body: n['message'] ?? n['body'] ?? '',
          createdAt: n['created_at'] != null ? DateTime.parse(n['created_at']).toLocal() : DateTime.now(),
          isRead: n['is_read'] ?? n['read'] ?? false,
        )).toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() => n.isRead = true);
    final success = await ApiService.markNotificationAsRead(n.id);
    if (!success) {
      if (mounted) setState(() => n.isRead = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    
    setState(() {
      for (var n in unread) n.isRead = true;
    });

    for (var n in unread) {
      await ApiService.markNotificationAsRead(n.id);
    }
  }

  // ── Type config ────────────────────────────────────────────────────────────

  static const _typeConfig = {
    'booking_confirmed': (
      icon: Icons.check_circle_rounded,
      color: Color(0xFF1B9D5A),
      bgColor: Color(0xFFE8F7F0),
    ),
    'booking_cancelled': (
      icon: Icons.cancel_rounded,
      color: Color(0xFFB91C1C),
      bgColor: Color(0xFFFFEDED),
    ),
    'message_received': (
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFEFF6FF),
    ),
    'payment_success': (
      icon: Icons.payments_rounded,
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFF5F0FF),
    ),
    'lodge_service_update': (
      icon: Icons.room_service_rounded,
      color: Color(0xFFB45309),
      bgColor: Color(0xFFFFF7ED),
    ),
  };

  // ── Time ago helper ────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Notification item ──────────────────────────────────────────────────────

  Widget _buildNotificationItem(AppNotification n) {
    final cfg = _typeConfig[n.type] ??
        (
          icon: Icons.notifications_rounded,
          color: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF3F4F6),
        );

    return GestureDetector(
      onTap: () => _markAsRead(n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : Colors.red.shade50.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: n.isRead ? Colors.grey.shade200 : Colors.red.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: n.isRead ? 0.03 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 24),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread dot
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(n.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: n.isRead
                            ? Colors.grey.shade400
                            : Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade50,
                    Colors.pink.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 52,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'You have no notifications at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final unread = _notifications.where((n) => !n.isRead).toList();
    final read = _notifications.where((n) => n.isRead).toList();
    final hasAny = _notifications.isNotEmpty;
    final hasUnread = unread.isNotEmpty;

    return Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All notifications marked as read'),
                        backgroundColor: Colors.red.shade900,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: Icon(Icons.done_all, size: 16, color: Colors.red.shade900),
                  label: Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: !hasAny
                ? _emptyState()
                : ListView(
                    padding: const EdgeInsets.only(top: 4, bottom: 40),
                    children: [
                      // Unread section
                      if (unread.isNotEmpty) ...[
                        _buildSectionHeader('New'),
                        ...unread.map(_buildNotificationItem),
                      ],

                      // Read section
                      if (read.isNotEmpty) ...[
                        _buildSectionHeader('Earlier'),
                        ...read.map(_buildNotificationItem),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

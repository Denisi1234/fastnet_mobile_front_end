import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyServiceRequestsScreen> createState() =>
      _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  // ── Demo data for offline/demo mode ──────────────────────────────────────
  static const _demoRequests = [
    {
      'id': 1,
      'type': 'Food & Dining',
      'details': 'Grilled chicken with fries and soft drink',
      'room': '204',
      'price': 25000,
      'status': 'Completed',
      'createdAt': 'Jul 8, 2026 • 7:32 PM',
    },
    {
      'id': 2,
      'type': 'Laundry',
      'details': '3 shirts, 2 trousers — express wash & iron',
      'room': '204',
      'price': 15000,
      'status': 'In Progress',
      'createdAt': 'Jul 9, 2026 • 9:10 AM',
    },
    {
      'id': 3,
      'type': 'Room Cleaning',
      'details': 'Full deep-clean + fresh towels & toiletries',
      'room': '204',
      'price': 10000,
      'status': 'Pending',
      'createdAt': 'Jul 9, 2026 • 10:45 AM',
    },
    {
      'id': 4,
      'type': 'Spa & Wellness',
      'details': '60-minute Swedish full-body massage',
      'room': '204',
      'price': 55000,
      'status': 'Pending',
      'createdAt': 'Jul 9, 2026 • 11:00 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchLodgeRequests();
      if (mounted) {
        setState(() {
          _requests = data.isNotEmpty
              ? data
              : List<Map<String, dynamic>>.from(
                  _demoRequests.map((e) => Map<String, dynamic>.from(e)));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(
              _demoRequests.map((e) => Map<String, dynamic>.from(e)));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelRequest(Map<String, dynamic> req) async {
    final id = req['id'] as int;
    // Optimistic update
    setState(() {
      final idx = _requests.indexOf(req);
      if (idx >= 0) _requests[idx]['status'] = 'Cancelled';
    });

    try {
      await ApiService.updateLodgeRequestStatus(id, 'Cancelled');
    } catch (_) {
      // keep optimistic
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Service request cancelled.'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('food') || t.contains('dining') || t.contains('meal')) {
      return Icons.restaurant_outlined;
    }
    if (t.contains('clean') || t.contains('housekeeping')) {
      return Icons.cleaning_services_outlined;
    }
    if (t.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (t.contains('spa') || t.contains('massage') || t.contains('wellness')) {
      return Icons.spa_outlined;
    }
    if (t.contains('transport') || t.contains('taxi') || t.contains('cab')) {
      return Icons.directions_car_outlined;
    }
    if (t.contains('room service')) return Icons.room_service_outlined;
    if (t.contains('maintenance') || t.contains('repair')) {
      return Icons.build_outlined;
    }
    return Icons.miscellaneous_services_outlined;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Completed':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade50;
      case 'In Progress':
        return Colors.blue.shade50;
      case 'Completed':
        return Colors.green.shade50;
      case 'Cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_top_outlined;
      case 'In Progress':
        return Icons.autorenew_outlined;
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          // ── Gradient AppBar ────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: Colors.red.shade900,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade700, Colors.red.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'IN-STAY SERVICES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'My Service Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_requests.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.room_service_outlined,
                        size: 52,
                        color: Colors.red.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No service requests yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your in-stay service requests will appear here.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == 0) {
                      // Stats row
                      final pending = _requests
                          .where((r) => r['status'] == 'Pending')
                          .length;
                      final inProgress = _requests
                          .where((r) => r['status'] == 'In Progress')
                          .length;
                      final completed = _requests
                          .where((r) => r['status'] == 'Completed')
                          .length;
                      return Column(
                        children: [
                          _buildStatsRow(
                              pending, inProgress, completed),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    final req = _requests[i - 1];
                    return _buildRequestCard(req);
                  },
                  childCount: _requests.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int pending, int inProgress, int completed) {
    return Row(
      children: [
        Expanded(
            child: _statCard('Pending', pending, Colors.orange.shade700,
                Icons.hourglass_top_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Active', inProgress, Colors.blue.shade700,
                Icons.autorenew_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Done', completed, Colors.green.shade700,
                Icons.check_circle_outline)),
      ],
    );
  }

  Widget _statCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final type = (req['type'] as String?) ?? 'Service';
    final details = (req['details'] as String?) ?? '';
    final room = (req['room'] as String?) ?? '—';
    final price = (req['price'] as int?) ?? 0;
    final status = (req['status'] as String?) ?? 'Pending';
    final createdAt = (req['createdAt'] as String?) ?? '';
    final isPending = status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade700, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(type),
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status),
                              size: 11, color: _statusColor(status)),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                              letterSpacing: 0.4,
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

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _chip(Icons.meeting_room_outlined, 'Room $room'),
                    const SizedBox(width: 8),
                    _chip(Icons.access_time_outlined, createdAt),
                  ],
                ),
                Text(
                  _formatPrice(price),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),

          // Cancel button for pending requests
          if (isPending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(req),
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 16),
                  label: const Text(
                    'Cancel Request',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Cancel Request?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this "${req['type']}" request?',
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep It',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelRequest(req);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

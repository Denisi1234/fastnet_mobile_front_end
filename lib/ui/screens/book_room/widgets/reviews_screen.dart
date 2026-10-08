import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/write_review_screen.dart';

/// Guest reviews — real backend rows only (`GET /properties/{id}/reviews`).
/// An empty backend renders an honest empty state, never sample reviews.
class ReviewsScreen extends StatefulWidget {
  final String lodgeName;
  final int? propertyId;

  const ReviewsScreen({super.key, required this.lodgeName, this.propertyId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _faint = Color(0xFF9AA0A6);
  static const _border = Color(0xFFE8EAED);
  static const _blue = Color(0xFF1A73E8);

  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pid = widget.propertyId;
    if (pid == null) {
      setState(() => _loading = false);
      return;
    }
    final rows = await ApiService.fetchReviews(pid);
    if (!mounted) return;
    setState(() {
      _reviews = rows
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
      _loading = false;
    });
  }

  double get _average {
    final rated = _reviews
        .map((r) => double.tryParse((r['rating'] ?? '').toString()) ?? 0)
        .where((v) => v > 0)
        .toList();
    if (rated.isEmpty) return 0;
    return rated.reduce((a, b) => a + b) / rated.length;
  }

  static String _label(double rating) {
    if (rating >= 4.5) return 'Exceptional';
    if (rating >= 4.0) return 'Excellent';
    if (rating >= 3.5) return 'Very good';
    if (rating >= 3.0) return 'Good';
    return 'Pleasant';
  }

  String _dateOf(Map<String, dynamic> r) {
    final raw = (r['created_at'] ?? r['date'] ?? '').toString();
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _openWriteReview() {
    final pid = widget.propertyId;
    if (pid == null) return;
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          propertyName: widget.lodgeName,
          propertyId: pid,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final avg = _average;
    final hasRating = avg > 0;
    final visible = _reviews.where((r) {
      final author = (r['user_name'] ?? r['guest_name'] ?? r['name'] ?? '')
          .toString()
          .trim();
      final comment = (r['comment'] ?? '').toString().trim();
      return author.isNotEmpty || comment.isNotEmpty;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guest Reviews',
                style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            Text(widget.lodgeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: 3,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
              itemBuilder: (_, __) => Container(
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : visible.isEmpty
              ? _emptyState()
              : ListView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            hasRating
                                ? avg.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: _ink),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasRating
                                    ? _label(avg)
                                    : 'No reviews yet',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _ink),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(
                                          Icons.star_rounded,
                                          color: hasRating &&
                                                  i <
                                                      avg.round()
                                              ? const Color(
                                                  0xFFF59E0B)
                                              : const Color(
                                                  0xFFE2E8F0),
                                          size: 16,
                                        )),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on ${visible.length} guest review${visible.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: _muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('All Reviews (${visible.length})',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 12),
                    for (final rev in visible)
                      _reviewRow(rev),
                    if (widget.propertyId != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _openWriteReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          child: const Text('Write a review',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review_outlined,
                    size: 26, color: _faint),
              ),
              const SizedBox(height: 16),
              const Text('No reviews yet',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const SizedBox(height: 6),
              const Text(
                'Be the first verified guest to stay here and leave a review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: _muted, height: 1.45),
              ),
              if (widget.propertyId != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _openWriteReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: const Text('Write a review',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(Map<String, dynamic> rev) {
    final author =
        (rev['user_name'] ?? rev['guest_name'] ?? rev['name'] ?? '')
            .toString()
            .trim();
    final comment = (rev['comment'] ?? '').toString().trim();
    final rating =
        double.tryParse((rev['rating'] ?? '').toString()) ?? 0;
    final initial = author.isNotEmpty
        ? author.substring(0, 1).toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F0FE),
                ),
                child: Text(initial,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1967D2))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.isNotEmpty ? author : 'Guest',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _ink),
                    ),
                    const SizedBox(height: 2),
                    Text(_dateOf(rev),
                        style: const TextStyle(
                            color: _faint, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          Icons.star_rounded,
                          color: i < rating.round()
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                          size: 15,
                        )),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: const TextStyle(
                    fontSize: 13.5, color: _ink, height: 1.5)),
          ],
          if (rev['is_verified'] == true || rev['is_verified'] == 1)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('| Verified stay',
                  style: TextStyle(fontSize: 11, color: _faint)),
            ),
        ],
      ),
    );
  }
}

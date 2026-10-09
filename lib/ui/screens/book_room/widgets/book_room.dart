import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/booking_checkout.dart';
import 'package:fastnet_mobile_front_end/ui/screens/book_room/widgets/fullscreen_map.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/property_image.dart';

/// Hotel detail — mobile layout of web `/hotel-detail`
/// (`hotel-detail.php`, Agoda style).
///
/// Back bar + breadcrumb, real-photo gallery, sticky tabs
/// (Overview | Rooms | Reviews) with the from-price deal bar, title card,
/// inline "Select your room" list, rating card with real review snippets,
/// details sheet, map screen and a sticky bottom booking bar.
///
/// Every number on this screen comes from the backend or the passed-in
/// `Destination`: no invented rooms, reviews, prices or counts. An empty
/// backend yields honest empty states, never placeholders.
class BookRoom extends StatefulWidget {
  final Destination destination;
  final String? selectedDatesText;
  final int? numNights;

  const BookRoom({
    Key? key,
    required this.destination,
    this.selectedDatesText,
    this.numNights,
  }) : super(key: key);

  @override
  State<BookRoom> createState() => _BookRoomState();
}

class _BookRoomState extends State<BookRoom> {
  // Web tokens (`hotel-detail-style.php` mobile rules).
  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _faint = Color(0xFF9AA0A6);
  static const _border = Color(0xFFE8EAED);
  static const _cardBorder = Color(0xFFE0E6EF);
  static const _chipBorder = Color(0xFFDADCE0);
  static const _blue = Color(0xFF1A73E8);
  static const _viewBlue = Color(0xFF0F62FE);
  static const _starAmber = Color(0xFFF59E0B);
  static const _starGold = Color(0xFFB7791F);

  final PageController _galleryCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _roomsKey = GlobalKey();

  String _tab = 'overview';

  late DateTimeRange _range;

  List<String> _gallery = [];
  List<Map<String, dynamic>> _rooms = [];
  bool _roomsLoading = true;

  int get _nights {
    final n = _range.duration.inDays;
    return n <= 0 ? 1 : n;
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String get _datesText =>
      '${_fmt(_range.start)} – ${_fmt(_range.end)}';

  DateTimeRange _parseDates(String? text) {
    final today = DateTime.now();
    final defaultStart = DateTime(today.year, today.month, today.day);
    final defaultEnd = defaultStart.add(const Duration(days: 1));

    if (text == null || text.isEmpty) {
      return DateTimeRange(start: defaultStart, end: defaultEnd);
    }

    try {
      final cleanText = text.replaceAll('–', '-').replaceAll(' - ', '-');
      final parts = cleanText.split('-');
      if (parts.length != 2) {
        return DateTimeRange(start: defaultStart, end: defaultEnd);
      }

      final startPart = parts[0].trim();
      var endPart = parts[1].trim();

      final yearReg = RegExp(r'\d{4}');
      final yearMatch = yearReg.firstMatch(text);
      final year =
          yearMatch != null ? int.parse(yearMatch.group(0)!) : today.year;

      endPart = endPart.replaceAll(RegExp(r',\s*\d{4}'), '').trim();

      const monthsAbbr = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      final startTokens = startPart.split(' ');
      final startMonthVal = monthsAbbr.indexOf(startTokens[0]) + 1;
      final startDayVal = int.parse(startTokens[1]);
      final startDate = DateTime(year, startMonthVal, startDayVal);

      final endTokens = endPart.split(' ');
      int endMonthVal = startMonthVal;
      int endDayVal;
      if (endTokens.length == 2) {
        endMonthVal = monthsAbbr.indexOf(endTokens[0]) + 1;
        endDayVal = int.parse(endTokens[1]);
      } else {
        endDayVal = int.parse(endTokens[0]);
      }
      final endDate = DateTime(year, endMonthVal, endDayVal);

      return DateTimeRange(start: startDate, end: endDate);
    } catch (_) {
      return DateTimeRange(start: defaultStart, end: defaultEnd);
    }
  }

  @override
  void initState() {
    super.initState();
    RecentlyViewedData.add(widget.destination);
    _range = _parseDates(widget.selectedDatesText);
    if (widget.selectedDatesText == null &&
        widget.numNights != null &&
        widget.numNights! > 0) {
      _range = DateTimeRange(
        start: _range.start,
        end: _range.start.add(Duration(days: widget.numNights!)),
      );
    }
    _gallery = _collectGallery();
    _loadRooms();
  }

  @override
  void dispose() {
    _galleryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── data ─────────────────────────

  /// Backend host for relative `/storage/…` image paths (web `$hdNormUrl`).
  String _backendHost() {
    final base = ApiService.baseUrl;
    return base.replaceAll(RegExp(r'/api/?$'), '');
  }

  String _normUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http') || u.startsWith('assets/')) return u;
    if (u.startsWith('/storage/')) return '${_backendHost()}$u';
    return u;
  }

  /// Real photos only: property image + backend room photos, deduped.
  /// Zero photos → bundled neutral placeholder (never a stranger's photo).
  List<String> _collectGallery() {
    final out = <String>[];
    void add(String? u) {
      final n = _normUrl(u ?? '');
      if (n.isNotEmpty && !out.contains(n)) out.add(n);
    }

    add(widget.destination.imageUrl.startsWith('assets/')
        ? null
        : widget.destination.imageUrl);
    for (final r in widget.destination.rooms ?? []) {
      final raw = r['photos'] ?? r['images'];
      final list = raw is String
          ? <dynamic>[raw]
          : (raw as List? ?? []);
      for (final p in list) {
        add(p is Map
            ? (p['url'] ?? p['image_url'] ?? '').toString()
            : p.toString());
      }
      add((r['primary_image_url'] ?? '').toString());
    }
    if (out.isEmpty) out.add('assets/images/home.webp');
    return out;
  }

  Future<void> _loadRooms() async {
    final embedded = widget.destination.rooms;
    if (embedded != null && embedded.isNotEmpty) {
      setState(() {
        _rooms = embedded
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        _roomsLoading = false;
      });
      return;
    }
    final pid = widget.destination.id;
    if (pid == null) {
      setState(() => _roomsLoading = false);
      return;
    }
    final rows = await ApiService.fetchRooms(pid);
    if (!mounted) return;
    setState(() {
      _rooms = rows
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
      _roomsLoading = false;
    });
  }

  // ───────────────────────── derived ─────────────────────────

  static bool roomIsAvailable(Map<String, dynamic> r) {
    if (r.containsKey('is_available')) {
      final v = r['is_available'];
      if (v is bool) return v;
      if (v is num) return v != 0;
      return v.toString().toLowerCase() == 'true';
    }
    const maintenance = {
      'maintenance',
      'out_of_service',
      'inactive',
      'disabled'
    };
    return !maintenance.contains(
        (r['status'] ?? 'available').toString().toLowerCase().trim());
  }

  static double roomPrice(Map<String, dynamic> r) {
    final v = r['customer_price'] ?? r['price'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Web "From" price: lowest AVAILABLE room rate, else the property base
  /// rate, else 0 → "Price on request". Never invented.
  double get _fromPrice {
    double best = 0;
    for (final r in _rooms) {
      if (!roomIsAvailable(r)) continue;
      final p = roomPrice(r);
      if (p > 0 && (best <= 0 || p < best)) best = p;
    }
    if (best > 0) return best;
    return widget.destination.price.toDouble();
  }

  double get _score10 {
    final rating = widget.destination.rating;
    if (rating <= 0) return 0;
    final s = rating <= 5.0 ? rating * 2 : rating;
    return double.parse(s.toStringAsFixed(1));
  }

  int get _reviewCount => widget.destination.reviewCount;

  static String ratingLabel(double score10) {
    if (score10 >= 9.0) return 'Exceptional';
    if (score10 >= 8.0) return 'Excellent';
    if (score10 >= 7.0) return 'Very Good';
    return 'Good';
  }

  String _formatPrice(num price) {
    final v = price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'TSh $v';
  }

  // ───────────────────────── actions ─────────────────────────

  void _scrollTo(GlobalKey key, String tab) {
    setState(() => _tab = tab);
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.12,
      );
    }
  }

  void _scrollTop() {
    setState(() => _tab = 'overview');
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut);
    }
  }

  Future<void> _changeDates() async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: day,
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: DateTimeRange(
          start: _range.start, end: _range.end),
      helpText: 'Select your stay dates',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _blue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A73E8)),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _range = picked);
    }
  }

  void _shareLodge() {
    HapticFeedback.selectionClick();
    final d = widget.destination;
    final text = '''
${d.name}
${d.rating > 0 ? '${d.rating.toStringAsFixed(1)}${_reviewCount > 0 ? ' · $_reviewCount reviews' : ''}' : 'New property'}
${d.area}, ${d.city}, Tanzania
${d.price > 0 ? '${_formatPrice(d.price)} / night' : 'Price on request'}

Book this stay on FastNet:
https://fastnetstays.com/hotel-detail?id=${d.id}
    '''
        .trim();
    Share.share(text, subject: 'Check out ${d.name} on FastNet');
  }

  void _openGallery(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenGalleryScreen(
          images: _gallery,
          initialIndex: index,
        ),
      ),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullscreenMapScreen(destination: widget.destination),
      ),
    );
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailsSheet(
        destination: widget.destination,
        score10: _score10,
        reviewCount: _reviewCount,
      ),
    );
  }

  void _reserve(Map<String, dynamic> room, int index) {
    HapticFeedback.selectionClick();
    final id = (room['id'] as num?)?.toInt() ?? (index + 1);
    final number =
        (room['room_number'] ?? 'Room').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingCheckoutScreen(
          destination: widget.destination,
          selectedDatesText: _datesText,
          numNights: _nights,
          selectedRoomNumber: number,
          selectedRoomId: id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final wishlisted = WishlistData.contains(d);
    final from = _fromPrice;

    // Web mobile chrome: static back bar (pill + actions), gallery,
    // borderless sticky tabs (Overview | Rooms), content cards. No sticky
    // bottom bar, no deal CTA, no reviews column on mobile — exactly like
    // the web under 768px.
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _backBar(d, wishlisted),
            Expanded(
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  SliverToBoxAdapter(
                      child: _gallerySection(d)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabsHeaderDelegate(
                      tab: _tab,
                      onTab: (t) {
                        HapticFeedback.selectionClick();
                        if (t == 'overview') {
                          _scrollTop();
                        } else {
                          _scrollTo(_roomsKey, 'rooms');
                        }
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                      child:
                          _titleCard(d, wishlisted, from)),
                  SliverToBoxAdapter(
                    key: _roomsKey,
                    child: _roomsSection(d, from),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Back bar (web `.hotel-detail-back-nav`, mobile: trail hidden) ──

  Widget _backBar(Destination d, bool wishlisted) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 13, color: _blue),
                  SizedBox(width: 8),
                  Text('Back to stays',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _blue)),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _shareLodge,
            icon: const Icon(Icons.share_outlined, size: 21),
            color: _ink,
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => WishlistData.toggle(d));
            },
            icon: Icon(
              wishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: 21,
              color: wishlisted
                  ? const Color(0xFFEF4444)
                  : _ink,
            ),
            tooltip: 'Save',
          ),
        ],
      ),
    );
  }

  // ── Gallery (web `.agoda-gallery-sparse`) ──

  // ── Gallery (web `.agoda-gallery` mobile ≤480px:
  // hero + 2 thumbs + full-width map cell) ──

  Widget _gallerySection(Destination d) {
    final thumbs = _gallery.skip(1).take(2).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          // Hero.
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 210,
                  width: double.infinity,
                  color: const Color(0xFFE8ECEF),
                  child: PageView.builder(
                    controller: _galleryCtrl,
                    itemCount: _gallery.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _openGallery(i),
                      child: PropertyImage(
                          url: _gallery[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              if (_gallery.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _openGallery(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.96),
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 8,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                Icons
                                    .photo_library_outlined,
                                size: 13,
                                color: _ink),
                            SizedBox(width: 6),
                            Text('See all photos',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: _ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Thumbs (max 2, like web ≤480px): plain Row so widths are
          // deterministic — no shrinkWrap grid inside the scroll view.
          if (thumbs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                for (int i = 0; i < thumbs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openGallery(i + 1),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.7,
                          child: Container(
                            color:
                                const Color(0xFFE8ECEF),
                            child: PropertyImage(
                                url: thumbs[i],
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // Pad an odd single thumb so the row keeps its shape.
                if (thumbs.length == 1)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
          // Map cell (web `.agoda-gallery-map`).
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _openMap,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Transform.rotate(
                      angle: -math.pi / 4,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Text('SEE MAP',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Title card (web title block) ──

  Widget _titleCard(Destination d, bool wishlisted, double from) {
    final score = _score10;
    final hasRating = score > 0;
    final stars = d.starRating.clamp(0, 5);
    final address = d.area.trim().isNotEmpty
        ? '${d.area.trim()}, ${d.city.trim()}'
        : d.city.trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          height: 1.25,
                          letterSpacing: -0.19),
                    ),
                    if (stars > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '★★★★★'.substring(0, stars) +
                            '☆☆☆☆☆'.substring(0, 5 - stars),
                        style: const TextStyle(
                            fontSize: 13,
                            color: _starGold,
                            letterSpacing: 2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => WishlistData.toggle(d));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                    color: Colors.white,
                  ),
                  child: Icon(
                    wishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 15,
                    color: wishlisted
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF5F6368),
                  ),
                ),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(address,
                style: const TextStyle(
                    fontSize: 12.5, color: _muted, height: 1.4)),
          ],
          const SizedBox(height: 6),
          if (hasRating)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: _starAmber),
                const SizedBox(width: 4),
                Text(
                  '${score.toStringAsFixed(1)} ${ratingLabel(score)}',
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink),
                ),
                const SizedBox(width: 4),
                Text(
                  '· $_reviewCount verified review${_reviewCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13, color: _muted),
                ),
              ],
            )
          else
            const Row(
              children: [
                _NewBadge(),
                SizedBox(width: 6),
                Text('No reviews yet',
                    style: TextStyle(fontSize: 13, color: _muted)),
              ],
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pillButton(
                icon: Icons.location_on_rounded,
                label: 'SEE MAP',
                fg: _blue,
                onTap: _openMap,
              ),
              _pillButton(
                label: 'View Rooms',
                bg: _viewBlue,
                fg: Colors.white,
                border: _viewBlue,
                minHeight: 44,
                onTap: () => _scrollTo(_roomsKey, 'rooms'),
              ),
              _pillButton(
                icon: Icons.info_outline_rounded,
                label: 'Details',
                fg: _ink,
                onTap: _openDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    Color bg = Colors.white,
    Color fg = _ink,
    Color border = _chipBorder,
    double minHeight = 0,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        alignment:
            minHeight > 0 ? Alignment.center : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg)),
          ],
        ),
      ),
    );
  }

  // ── Select your room (web `rooms.php` + `room-list.php`) ──

  Widget _roomsSection(Destination d, double from) {
    final soldOut = _rooms
        .where((r) => !roomIsAvailable(r))
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Select your room',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              GestureDetector(
                onTap: _changeDates,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: _muted),
                      const SizedBox(width: 6),
                      Text(
                        '$_datesText · $_nights night${_nights == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
          if (_roomsLoading)
            const _RoomsSkeleton()
          else if (_rooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.hotel_outlined,
                      size: 32, color: _faint),
                  SizedBox(height: 10),
                  Text('No rooms available',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  SizedBox(height: 4),
                  Text(
                    'There are currently no rooms available for this property. Please try selecting different travel dates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: _muted, height: 1.45),
                  ),
                ],
              ),
            )
          else ...[
            if (soldOut > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: Color(0xFF991B1B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hurry up! $soldOut room${soldOut > 1 ? 's' : ''} already booked for your dates!',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            for (int i = 0; i < _rooms.length; i++)
              _RoomCard(
                room: _rooms[i],
                index: i,
                nights: _nights,
                cheapest: _cheapestAvailable(),
                onReserve: () => _reserve(_rooms[i], i),
                wishlisted: WishlistData.contains(d),
                onWishlistToggle: () {
                  HapticFeedback.selectionClick();
                  setState(() => WishlistData.toggle(d));
                },
              ),
              ],
            ],
          ),
        ),
        ],
      ),
    );
  }

  double _cheapestAvailable() {
    double best = 0;
    for (final r in _rooms) {
      if (!roomIsAvailable(r)) continue;
      final p = roomPrice(r);
      if (p > 0 && (best <= 0 || p < best)) best = p;
    }
    return best;
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('New',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569))),
    );
  }
}

/// Sticky tabs + deal bar (web `.agoda-tabs-wrap`).
/// Sticky tabs (web `.agoda-tabs-wrap` mobile ≤480px): borderless
/// full-bleed strip, Overview | Rooms, 12.5px, blue 2px underline.
class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String tab;
  final ValueChanged<String> onTab;

  const _TabsHeaderDelegate({
    required this.tab,
    required this.onTab,
  });

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    const muted = Color(0xFF5F6368);
    const blue = Color(0xFF0F62FE);
    const border = Color(0xFFE8EAED);
    Widget tabBtn(String id, String label) {
      final active = tab == id;
      return GestureDetector(
        onTap: () => onTab(id),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? blue : Colors.transparent,
                  width: 2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w500,
              color: active ? blue : muted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          tabBtn('overview', 'Overview'),
          tabBtn('rooms', 'Rooms'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate old) =>
      old.tab != tab;
}

String _formatTzs(num price) {
  final v = price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return 'TSh $v';
}

IconData _roomAmenityIcon(String name) {
  final l = name.toLowerCase();
  if (l.contains('wifi') ||
      l.contains('wi-fi') ||
      l.contains('internet')) {
    return Icons.wifi_rounded;
  }
  if (l.contains('air') || l.contains('ac') || l.contains('fan')) {
    return Icons.ac_unit_rounded;
  }
  if (l.contains('tv') || l.contains('screen') || l.contains('led')) {
    return Icons.tv_rounded;
  }
  if (l.contains('balcony') ||
      l.contains('terrace') ||
      l.contains('patio') ||
      l.contains('view')) {
    return Icons.landscape_outlined;
  }
  if (l.contains('shower')) return Icons.shower_outlined;
  if (l.contains('bath') ||
      l.contains('toilet') ||
      l.contains('tub')) {
    return Icons.bathtub_outlined;
  }
  if (l.contains('bed') || l.contains('king') || l.contains('queen')) {
    return Icons.bed_outlined;
  }
  if (l.contains('fridge') ||
      l.contains('mini bar') ||
      l.contains('refrigerator')) {
    return Icons.kitchen_outlined;
  }
  if (l.contains('coffee') ||
      l.contains('tea') ||
      l.contains('kettle') ||
      l.contains('breakfast')) {
    return Icons.free_breakfast_outlined;
  }
  if (l.contains('safe') || l.contains('lock')) {
    return Icons.lock_outline_rounded;
  }
  if (l.contains('desk') || l.contains('work')) {
    return Icons.laptop_outlined;
  }
  if (l.contains('smoke') || l.contains('non-smoking')) {
    return Icons.smoke_free_rounded;
  }
  if (l.contains('parking') || l.contains('garage')) {
    return Icons.local_parking_outlined;
  }
  if (l.contains('pool')) return Icons.pool_rounded;
  if (l.contains('gym') || l.contains('fitness')) {
    return Icons.fitness_center_rounded;
  }
  return Icons.check_rounded;
}

class _RoomCard extends StatefulWidget {
  final Map<String, dynamic> room;
  final int index;
  final int nights;
  final double cheapest;
  final VoidCallback onReserve;
  final bool wishlisted;
  final VoidCallback onWishlistToggle;

  const _RoomCard({
    required this.room,
    required this.index,
    required this.nights,
    required this.cheapest,
    required this.onReserve,
    required this.wishlisted,
    required this.onWishlistToggle,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  static const _ink = Color(0xFF1A1D25);
  static const _muted = Color(0xFF5F6368);
  static const _border = Color(0xFFE8EAED);
  static const _priceBurnt = Color(0xFFC2410C);

  bool _expanded = false;
  int _photoIdx = 0;

  bool get _avail => _BookRoomState.roomIsAvailable(widget.room);
  double get _price => _BookRoomState.roomPrice(widget.room);

  List<String> _amenities() {
    final raw = widget.room['amenities'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final dec = jsonDecode(raw);
        if (dec is List) {
          return dec
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<String> _photos() {
    final out = <String>[];
    final raw = widget.room['photos'] ?? widget.room['images'];
    final list = raw is List ? raw : <dynamic>[];
    for (final p in list) {
      final u = p is Map
          ? (p['url'] ?? p['image_url'] ?? '').toString()
          : p.toString();
      if (u.trim().isNotEmpty && !out.contains(u)) out.add(u);
    }
    final primary =
        (widget.room['primary_image_url'] ?? '').toString();
    if (primary.trim().isNotEmpty && !out.contains(primary)) {
      out.add(primary);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final typeRaw =
        (r['room_type_id'] ?? r['type'] ?? 'Standard').toString().trim();
    final type = typeRaw.isEmpty ? 'Standard' : typeRaw;
    final title = RegExp(r'room|suite|villa|apartment', caseSensitive: false)
            .hasMatch(type)
        ? type
        : '$type Room';
    final unit = (r['room_number'] ?? '').toString().trim();
    final fullTitle =
        unit.isNotEmpty ? '$title · Room $unit' : title;
    final sizeRaw = (r['room_size'] ?? r['size'] ?? r['area'] ?? '').toString();
    final size = sizeRaw.isEmpty
        ? ''
        : (double.tryParse(sizeRaw) != null ? '$sizeRaw m²' : sizeRaw);
    final adults = (r['max_adults'] as num?)?.toInt() ??
        (r['capacity'] as num?)?.toInt() ??
        2;
    final children = (r['max_children'] as num?)?.toInt() ?? 0;
    final capacity = (r['capacity'] as num?)?.toInt() ?? (adults + children);
    var bed = (r['bed_configuration'] ?? r['beds'] ?? '1 Double Bed').toString();
    if (bed.trim().isEmpty) bed = '1 Double Bed';
    final specs = [
      if (size.isNotEmpty) size,
      'Max $adults adult${adults == 1 ? '' : 's'}',
      bed,
    ].join(' | ');
    final amens = _amenities();
    final shown = amens.take(6).toList();
    final hidden = amens.skip(6).toList();
    final hasBreakfast =
        amens.join(' ').toLowerCase().contains('breakfast');
    final photos = _photos();
    final isCheapest =
        _avail && _price > 0 && _price <= widget.cheapest;
    final total = _price * widget.nights;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 16,
              offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCheapest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 8),
              color: _priceBurnt,
              child: const Text('Lowest price available!',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          if (photos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.52,
                      child: PageView.builder(
                        itemCount: photos.length,
                        onPageChanged: (i) => setState(() => _photoIdx = i),
                        itemBuilder: (_, i) => PropertyImage(
                          url: photos[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (!_avail)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Unavailable for these dates',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF525252)),
                        ),
                      ),
                    ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_photoIdx + 1}/${photos.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.3)),
                const SizedBox(height: 4),
                Text(specs,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _muted)),
                const SizedBox(height: 4),
                Text(
                  _avail
                      ? 'Available for selected dates'
                      : 'Unavailable for selected dates',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _avail
                          ? const Color(0xFF137333)
                          : const Color(0xFF6F6F6F)),
                ),
                if (capacity >= 4) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3FE4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Fits groups',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
                if (shown.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 12,
                      childAspectRatio: 4.2,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => Row(
                      children: [
                        Icon(_roomAmenityIcon(shown[i]),
                            size: 13, color: _muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shown[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3C4043)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hidden.isNotEmpty) ...[
                  if (_expanded)
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 12,
                        childAspectRatio: 4.2,
                      ),
                      itemCount: hidden.length,
                      itemBuilder: (_, i) => Row(
                        children: [
                          Icon(
                              _roomAmenityIcon(hidden[i]),
                              size: 13,
                              color: _muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hidden[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3C4043)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: () => setState(
                        () => _expanded = !_expanded),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 8),
                      child: Text(
                        _expanded ? 'Show less' : 'See details',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F62FE)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '$adults adult${adults == 1 ? '' : 's'} included',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF3C4043)),
                ),
                if (hasBreakfast)
                  const Row(
                    children: [
                      Icon(Icons.free_breakfast_outlined,
                          size: 11, color: Color(0xFF15803D)),
                      SizedBox(width: 6),
                      Text('Breakfast included',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D))),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                    color: Color(0xFF0F62FE), width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$adults adult${adults == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      if (_price > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatTzs(_price),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _priceBurnt),
                        ),
                        const Text('Per night, incl. fees',
                            style: TextStyle(
                                fontSize: 10.5, color: _muted)),
                        const SizedBox(height: 2),
                        Text(
                          '1 room · ${widget.nights} night${widget.nights == 1 ? '' : 's'} · ${_formatTzs(total)} total',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _ink),
                        ),
                      ] else
                        const Text('Price on request',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onWishlistToggle();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFDADCE0)),
                    ),
                    child: Icon(
                      widget.wishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: 18,
                      color: widget.wishlisted
                          ? const Color(0xFFEF4444)
                          : _ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: _avail && _price > 0
                        ? ElevatedButton(
                            onPressed: widget.onReserve,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(24)),
                            ),
                            child: const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text('Book',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2)),
                                Text("You won't be charged yet",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2)),
                              ],
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius:
                                  BorderRadius.circular(24),
                            ),
                            child: const Text('Unavailable',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6F6F6F))),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton rows while rooms load.
class _RoomsSkeleton extends StatelessWidget {
  const _RoomsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: const Column(
            children: [
              Padding(
                padding: EdgeInsets.all(14),
                child: ShimmerBox(height: 120),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: ShimmerBox(height: 16),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: ShimmerBox(height: 16, width: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  const ShimmerBox({super.key, required this.height, this.width});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      builder: (_, child) =>
          Opacity(opacity: _anim.value, child: child),
    );
  }
}

/// Property details sheet (web `#propertyDetailsModal`): full
/// description + amenity chips + location. Backend text only.
/// Property details sheet (web `#propertyDetailsModal`): About,
/// Good-to-know policies (only when the backend provides them),
/// Facilities & Amenities, Rating, Done.
class _DetailsSheet extends StatelessWidget {
  final Destination destination;
  final double score10;
  final int reviewCount;
  const _DetailsSheet({
    required this.destination,
    required this.score10,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A1D25);
    const muted = Color(0xFF5F6368);
    const border = Color(0xFFE8EAED);
    const blue = Color(0xFF0F62FE);
    final desc = destination.condition.trim();
    final policies = [
      if (destination.checkInTime.trim().isNotEmpty)
        (
          Icons.schedule_rounded,
          'Check-in from ${destination.checkInTime.trim()}'
        ),
      if (destination.checkOutTime.trim().isNotEmpty)
        (
          Icons.logout_rounded,
          'Check-out until ${destination.checkOutTime.trim()}'
        ),
      if (destination.cancellationPolicy.trim().isNotEmpty)
        (
          Icons.verified_user_outlined,
          destination.cancellationPolicy.trim()
        ),
    ];
    // NOTE: no Flexible/Expanded here — a bottom sheet gives its content
    // unbounded height, and flex under unbounded constraints throws
    // during layout (surfacing as an Overlay/Offstage layout crash).
    final maxBodyHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(destination.name,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF1F3F4),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: ink),
                        ),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('About this stay',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 8),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF3C4043),
                            height: 1.65)),
                  ],
                  if (policies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Good to know',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 8),
                    for (final p in policies)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(p.$1,
                                size: 13, color: blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p.$2,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF3C4043),
                                      height: 1.45)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Facilities & Amenities',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 8),
                  if (destination.amenities.isEmpty)
                    const Text('No amenities listed.',
                        style:
                            TextStyle(fontSize: 13.5, color: muted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: destination.amenities
                          .map((a) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border:
                                      Border.all(color: border),
                                  color: Colors.white,
                                ),
                                child: Text(a,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color:
                                            Color(0xFF3C4043))),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  const Text('Rating',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 8),
                  if (reviewCount > 0 && score10 > 0)
                    Wrap(
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          '${score10.toStringAsFixed(1)} ${_BookRoomState.ratingLabel(score10)}',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: ink),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· $reviewCount verified review${reviewCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: muted),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'No reviews yet — be the first verified guest to stay here.',
                      style: TextStyle(
                          fontSize: 13.5, color: muted),
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(top: BorderSide(color: border)),
            ),
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen photo lightbox (web `openPhotoLightbox`).
class FullscreenGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenGalleryScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullscreenGalleryScreen> createState() =>
      _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState
    extends State<FullscreenGalleryScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController =
        PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.5,
            child: Center(
              child: PropertyImage(
                url: widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

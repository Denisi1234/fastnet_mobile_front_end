import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';

/// Pixel parity: `gh-cards-list.php` + `google-travel-cards.css`
/// **mobile** rules (`max-width:767px`).
///
/// Column card (radius 12, 1px #dadce0): full-width 168h photo with
/// dark bookmark circle + top-left counter + bottom dots; body with
/// 15px name (2-line clamp), location with blue pin, `4.2 ★ Excellent
/// (66)` rating line; bottom view-map row (hairline top border) with
/// nightly price + blue `View prices` CTA. No amenity grid and no
/// header price block on mobile — exactly like the web.
class WebHomeHotelCard extends StatefulWidget {
  final Destination destination;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlistToggle;

  const WebHomeHotelCard({
    super.key,
    required this.destination,
    required this.isWishlisted,
    required this.onTap,
    required this.onWishlistToggle,
  });

  /// Booking-style word label — same thresholds as web.
  static String ratingWord(double rating) {
    if (rating >= 4.5) return 'Exceptional';
    if (rating >= 4.0) return 'Excellent';
    if (rating >= 3.5) return 'Very good';
    if (rating >= 3.0) return 'Good';
    return 'Pleasant';
  }

  static String formatTzs(int value) {
    return 'TSh ${value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  @override
  State<WebHomeHotelCard> createState() => _WebHomeHotelCardState();
}

class _WebHomeHotelCardState extends State<WebHomeHotelCard> {
  final PageController _photos = PageController();
  int _photoIndex = 0;
  bool _pressed = false;
  Offset? _downPos;

  static const _ink = Color(0xFF202124);
  static const _muted = Color(0xFF5F6368);
  static const _blue = Color(0xFF1A73E8);
  static const _border = Color(0xFFDADCE0);
  static const _borderLight = Color(0xFFE8EAED);

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  List<String> get _images => [widget.destination.imageUrl];

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final hasPrice = d.price > 0;
    final locText = _location(d.area, d.city);
    final starLabel = d.starRating > 0
        ? '${d.starRating}-star hotel'
        : (d.propertyType.isNotEmpty ? d.propertyType : '');

    // Tactile press physics (visual look unchanged): subtle shrink on
    // touch-down, released on lift/cancel or once the finger drags
    // (so photo-carousel swipes never stick scaled).
    return Listener(
      onPointerDown: (e) {
        _downPos = e.position;
        if (!_pressed) setState(() => _pressed = true);
      },
      onPointerMove: (e) {
        if (_pressed &&
            _downPos != null &&
            (e.position - _downPos!).distance > 12) {
          setState(() => _pressed = false);
        }
      },
      onPointerUp: (_) {
        _downPos = null;
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        _downPos = null;
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1E3C4043),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: SizedBox(
                    height: 168,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _photos,
                      itemCount: _images.length,
                      onPageChanged: (i) =>
                          setState(() => _photoIndex = i),
                      itemBuilder: (_, i) =>
                          _photo(_images[i], d.name),
                    ),
                  ),
                ),
                if (_images.length > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${_photoIndex + 1} / ${_images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onWishlistToggle,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                      child: Icon(
                        widget.isWishlisted
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _images.length > 1 ? _images.length : 5,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (i ==
                                  (_images.length > 1
                                      ? _photoIndex
                                      : 0))
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                      height: 20 / 15,
                    ),
                  ),
                  if (locText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 10, color: Color(0xFF0F62FE)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            locText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  _RatingLine(
                      destination: d, starLabel: starLabel),
                  // ── View-map row: price + CTA ──
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding:
                        const EdgeInsets.fromLTRB(0, 10, 0, 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: _borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (hasPrice)
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        WebHomeHotelCard.formatTzs(
                                            d.price),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '/night',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        SizedBox(
                          height: 36,
                          child: hasPrice
                              ? ElevatedButton(
                                  onPressed: widget.onTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets
                                        .symmetric(horizontal: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'View prices',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  onPressed: widget.onTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _blue,
                                    side: const BorderSide(
                                        color: _border),
                                    padding: const EdgeInsets
                                        .symmetric(horizontal: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'View details',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(String url, String name) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null
                ? child
                : Container(
                    color: const Color(0xFFF8F9FA),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    ),
                  ),
        errorBuilder: (_, __, ___) => _photoFallback(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _photoFallback(),
    );
  }

  Widget _photoFallback() {
    return Container(
      color: const Color(0xFFF8F9FA),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined,
              size: 26, color: Color(0xFF9AA0A6)),
          SizedBox(height: 4),
          Text('No photo',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF9AA0A6))),
        ],
      ),
    );
  }

  /// `Area, City` — mirrors `TextFormatter::formatLocation`.
  static String _location(String area, String city) {
    final a = area.trim();
    final c = city.trim();
    if (a.isNotEmpty && c.isNotEmpty) {
      return a.toLowerCase() == c.toLowerCase() ? c : '$a, $c';
    }
    return a.isNotEmpty ? a : c;
  }
}

class _RatingLine extends StatelessWidget {
  final Destination destination;
  final String starLabel;
  const _RatingLine(
      {required this.destination, required this.starLabel});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF202124);
    const muted = Color(0xFF5F6368);
    final d = destination;
    final hasRating = d.rating > 0;
    if (!hasRating && starLabel.isEmpty) {
      return const Text(
        'New property',
        style: TextStyle(fontSize: 13, color: muted),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasRating) ...[
          Text(
            d.rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
          const SizedBox(width: 3),
          const Text('★',
              style:
                  TextStyle(fontSize: 13, color: Color(0xFFFBBC04))),
          const SizedBox(width: 3),
          Text(
            WebHomeHotelCard.ratingWord(d.rating),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ink),
          ),
          const SizedBox(width: 3),
          if (d.reviewCount > 0)
            Text(
              '(${d.reviewCount})',
              style:
                  const TextStyle(fontSize: 13, color: muted),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'New',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF137333)),
              ),
            ),
        ],
        if (hasRating && starLabel.isNotEmpty)
          const Text(' · ',
              style: TextStyle(fontSize: 13, color: muted)),
        if (starLabel.isNotEmpty)
          Text(
            starLabel,
            style:
                const TextStyle(fontSize: 13, color: muted),
          ),
      ],
    );
  }
}

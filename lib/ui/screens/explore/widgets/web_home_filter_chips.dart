import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pixel parity: `gh-filter-chips.php` mobile bar (`max-width:991px`).
///
/// Screenshot parity: only **All filters · Price · Offers ·
/// Guest rating** are shown on mobile — everything else lives in the
/// All-filters sheet. Chips are 46h, radius 12, 15px Roboto #202124;
/// active = 1px #1a73e8 + #e8f0fe + blue text. The desktop-only
/// "Track prices" toggle is hidden, exactly like the web.
class WebHomeFilterChips extends StatelessWidget {
  final int filterCount;
  final bool priceActive;
  final String priceLabel;
  final bool ratingActive;
  final VoidCallback onAllFilters;
  final VoidCallback onPriceTap;
  final VoidCallback onRatingToggle;

  const WebHomeFilterChips({
    super.key,
    required this.filterCount,
    required this.priceActive,
    required this.priceLabel,
    required this.ratingActive,
    required this.onAllFilters,
    required this.onPriceTap,
    required this.onRatingToggle,
  });

  static const _blue = Color(0xFF1A73E8);
  static const _blueLight = Color(0xFFE8F0FE);
  static const _border = Color(0xFFDADCE0);
  static const _ink = Color(0xFF202124);
  static const _muted = Color(0xFF5F6368);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 12),
      child: Row(
        children: [
          // All filters — borderless blue link w/ badge.
          _AllFiltersLink(
            filterCount: filterCount,
            onTap: onAllFilters,
          ),
          const SizedBox(width: 10),
          _chip(
            icon: Icons.payments_outlined,
            label: priceActive ? priceLabel : 'Price',
            active: priceActive,
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: onPriceTap,
          ),
          const SizedBox(width: 10),
          _chip(
            icon: Icons.local_offer_outlined,
            label: 'Offers',
            active: false,
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: onAllFilters,
          ),
          const SizedBox(width: 10),
          _chip(
            star: true,
            label: 'Guest rating',
            active: ratingActive,
            onTap: onRatingToggle,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    IconData? icon,
    bool star = false,
    required String label,
    required bool active,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    final fg = active ? _blue : _ink;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? _blueLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _blue : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 17, color: fg),
            if (star)
              Text('★',
                  style: TextStyle(fontSize: 16, color: fg)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: fg,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(trailing,
                  size: 11,
                  color: active ? _blue : _muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Borderless blue "All filters" link — web `.fns-chip-filters` mobile.
class _AllFiltersLink extends StatelessWidget {
  final int filterCount;
  final VoidCallback onTap;
  const _AllFiltersLink(
      {required this.filterCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A73E8);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 4, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 17, color: blue),
            const SizedBox(width: 8),
            const Text(
              'All filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: blue,
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$filterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

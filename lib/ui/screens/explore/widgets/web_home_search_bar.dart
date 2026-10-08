import 'package:flutter/material.dart';

/// Pixel parity: `gh-search-bar.php` mobile block (`.fns-m-google`).
///
/// Row 1: destination search box (56h, white, 1px #dadce0, radius 12,
/// blue icon, 16px text). Row 2: dates box (52h, white,
/// **2px #1a73e8** border, blue icon + blue dates, hairline divider)
/// + guests box (96w, 1px #dadce0, blue icon, dark count).
class WebHomeSearchBar extends StatelessWidget {
  final String destinationText;
  final bool hasDestination;
  final String checkInLabel;
  final String checkOutLabel;
  final int guestsCount;
  final VoidCallback onWhereTap;
  final VoidCallback onWhenTap;
  final VoidCallback onWhoTap;

  const WebHomeSearchBar({
    super.key,
    required this.destinationText,
    required this.hasDestination,
    required this.checkInLabel,
    required this.checkOutLabel,
    required this.guestsCount,
    required this.onWhereTap,
    required this.onWhenTap,
    required this.onWhoTap,
  });

  static const _blue = Color(0xFF1A73E8);
  static const _border = Color(0xFFDADCE0);
  static const _ink = Color(0xFF202124);
  static const _placeholder = Color(0xFF5F6368);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;
    final dateSize = narrow ? 13.5 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: destination search box.
        InkWell(
          onTap: onWhereTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: _blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDestination
                        ? destinationText
                        : 'Search for places, hotels and more',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 20 / 16,
                      color:
                          hasDestination ? _ink : _placeholder,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Row 2: dates + guests.
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onWhenTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding:
                      const EdgeInsets.only(left: 12, right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 19, color: _blue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          checkInLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: dateSize,
                            fontWeight: FontWeight.w500,
                            color: _blue,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: _border,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10),
                      ),
                      Expanded(
                        child: Text(
                          checkOutLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: dateSize,
                            fontWeight: FontWeight.w500,
                            color: _blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onWhoTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: narrow ? 84 : 96,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 19, color: _blue),
                    const SizedBox(width: 8),
                    Text(
                      '$guestsCount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

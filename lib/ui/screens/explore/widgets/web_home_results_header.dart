import 'package:flutter/material.dart';

/// Web parity: `templates/element/Home/gh-results-header.php`.
/// "near {destination} · N results" + sort control.
class WebHomeResultsHeader extends StatelessWidget {
  final String destination;
  final int count;
  final int? totalHits;
  final String sortLabel;
  final bool isFiltered;
  final VoidCallback onSortTap;

  const WebHomeResultsHeader({
    super.key,
    required this.destination,
    required this.count,
    this.totalHits,
    required this.sortLabel,
    required this.isFiltered,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = (totalHits != null && totalHits! > count)
        ? '$count of $totalHits stays'
        : '$count results';
    // Web mobile: no bottom border, 4px bottom padding.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF161616),
                ),
                children: [
                  TextSpan(text: 'near $destination · '),
                  TextSpan(
                    text: countLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (isFiltered)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _FilteredBadge(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onSortTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: const Color(0xFFDADCE0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 13, color: Color(0xFF5F6368)),
                  const SizedBox(width: 4),
                  Text(
                    sortLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3C4043),
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
}

class _FilteredBadge extends StatelessWidget {
  const _FilteredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Filtered',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1967D2),
        ),
      ),
    );
  }
}

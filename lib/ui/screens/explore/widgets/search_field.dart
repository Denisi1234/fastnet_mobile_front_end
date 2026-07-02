import 'package:flutter/material.dart';

class SearchfField extends StatelessWidget {
  final VoidCallback onTap;
  final String titleHint;
  final String subtitleHint;

  const SearchfField({
    Key? key,
    required this.onTap,
    required this.titleHint,
    required this.subtitleHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Material(
        elevation: 5.0,
        shadowColor: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 26,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleHint,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleHint,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


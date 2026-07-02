import 'package:flutter/material.dart';

class TabItem extends StatelessWidget {
  final String text;
  final String imageUrl;
  const TabItem({
    Key? key,
    required this.text,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imageUrl,
            height: 20,
            width: 20,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

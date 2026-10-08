import 'package:flutter/material.dart';

/// Network-aware property photo.
///
/// Backend rows now carry real URLs (`https://…/storage/…`) in
/// `Destination.imageUrl`, while bundled placeholders live under
/// `assets/`. Calling `Image.asset` with a URL throws
/// "Unable to load asset", so every *dynamic* image must go through
/// this widget: http(s) → `Image.network` (spinner + grey fallback),
/// anything else → `Image.asset` (with error fallback), empty → fallback.
class PropertyImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  const PropertyImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  static bool isNetworkUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    if (isNetworkUrl(url)) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: const Color(0xFFF8F9FA),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F3F4),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined,
              size: 26, color: Color(0xFF9AA0A6)),
          SizedBox(height: 4),
          Text('No photo',
              style:
                  TextStyle(fontSize: 12, color: Color(0xFF9AA0A6))),
        ],
      ),
    );
  }
}

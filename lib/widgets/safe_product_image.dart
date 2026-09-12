import 'package:flutter/material.dart';

import '../core/utils/image_url_policy.dart';

class SafeProductImage extends StatelessWidget {
  const SafeProductImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.filterQuality = FilterQuality.low,
    this.color,
    this.colorBlendMode,
    this.width,
    this.height,
    this.semanticLabel,
    this.fallback,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final int? cacheWidth;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final Widget? fallback;

  Widget get _fallback => fallback ?? const Icon(Icons.image_outlined);

  @override
  Widget build(BuildContext context) {
    final safeUrl = safeProductImageUrl(url);
    if (safeUrl == null) return _fallback;

    return Image.network(
      safeUrl,
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}

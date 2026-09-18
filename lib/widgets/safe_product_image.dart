import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/utils/image_url_policy.dart';

class SafeProductImage extends StatelessWidget {
  const SafeProductImage({
    required this.url,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
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
  final String? fallbackUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final Widget? fallback;

  Widget get _fallback {
    final fallbackWidget = fallback ?? const Icon(Icons.image_outlined);
    final label = semanticLabel?.trim();
    if (label == null || label.isEmpty) return fallbackWidget;
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: fallbackWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = safeProductImageUrl(url);
    final safeFallbackUrl = safeProductImageUrl(fallbackUrl);
    if (safeUrl == null) {
      return safeFallbackUrl == null
          ? _fallback
          : _networkImage(safeFallbackUrl);
    }

    return _networkImage(
      safeUrl,
      fallbackUrl: safeFallbackUrl == safeUrl ? null : safeFallbackUrl,
    );
  }

  Widget _networkImage(String safeUrl, {String? fallbackUrl}) {
    return Image.network(
      safeUrl,
      fit: fit,
      cacheWidth: kIsWeb ? null : cacheWidth,
      cacheHeight: kIsWeb ? null : cacheHeight,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) =>
          fallbackUrl == null ? _fallback : _networkImage(fallbackUrl),
    );
  }
}

import 'package:flutter/material.dart';

/// A physical left-pointing arrow that is intentionally not mirrored in RTL.
class StorefrontLeftArrowIcon extends StatelessWidget {
  const StorefrontLeftArrowIcon({this.size, this.color, super.key});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_back,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}

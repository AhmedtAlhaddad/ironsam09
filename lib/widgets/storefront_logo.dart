import 'package:flutter/material.dart';

class IronSamLogo extends StatelessWidget {
  const IronSamLogo({
    this.width = 96,
    this.height = 58,
    this.onPressed,
    this.tooltip = 'العودة إلى الصفحة الرئيسية',
    super.key,
  });

  final double width;
  final double height;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/iron_sam_logo.png',
      semanticLabel: onPressed == null ? 'آيرون سام' : null,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    final content = SizedBox(
      width: width,
      height: height,
      child: Center(child: image),
    );
    final callback = onPressed;
    if (callback == null) return content;

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: callback,
            borderRadius: BorderRadius.circular(8),
            child: ExcludeSemantics(child: content),
          ),
        ),
      ),
    );
  }
}

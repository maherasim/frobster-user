import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? label;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.elevation = 6,
    this.padding,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label != null) const SizedBox(width: 8),
        if (label != null)
          Text(
            label!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: appPrimaryGradient,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: label != null ? 16 : 12,
                  vertical: 12,
                ),
            child: content,
          ),
        ),
      ),
    );
  }
}


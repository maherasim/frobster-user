import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: appPrimaryGradient,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


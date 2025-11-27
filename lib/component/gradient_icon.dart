import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientIcon extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double? width;
  final double? height;

  const GradientIcon({
    super.key,
    required this.child,
    this.gradient = appPrimaryGradient,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, width ?? bounds.width, height ?? bounds.height),
        );
      },
      child: child,
    );
  }
}


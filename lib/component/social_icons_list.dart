import 'package:flutter/material.dart';

class SocialIconsList extends StatelessWidget {
  final double spacing;
  final double size;
  final MainAxisAlignment mainAxisAlignment;
  const SocialIconsList(
      {super.key,
      this.spacing = 2,
      this.mainAxisAlignment = MainAxisAlignment.center,
      this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      spacing: spacing,
      children: [
        Image.asset(
          'assets/images/facebook.png',
          width: size,
          height: size,
        ),
        Image.asset(
          'assets/images/instagram.png',
          width: size,
          height: size,
        ),
        Image.asset(
          'assets/images/twitter.png',
          width: size,
          height: size,
        ),
        Image.asset(
          'assets/images/linkedin.png',
          width: size,
          height: size,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class SocialIconsList extends StatelessWidget {
  final double spacing;
  final double size;
  final MainAxisAlignment mainAxisAlignment;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onInstagramTap;
  final VoidCallback? onTwitterTap;
  final VoidCallback? onLinkedInTap;
  
  const SocialIconsList({
    super.key,
    this.spacing = 2,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.size = 15,
    this.onFacebookTap,
    this.onInstagramTap,
    this.onTwitterTap,
    this.onLinkedInTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      spacing: spacing,
      children: [
        GestureDetector(
          onTap: onFacebookTap,
          child: Image.asset(
            'assets/images/facebook.png',
            width: size,
            height: size,
          ),
        ),
        GestureDetector(
          onTap: onInstagramTap,
          child: Image.asset(
            'assets/images/instagram.png',
            width: size,
            height: size,
          ),
        ),
        GestureDetector(
          onTap: onTwitterTap,
          child: Image.asset(
            'assets/images/twitter.png',
            width: size,
            height: size,
          ),
        ),
        GestureDetector(
          onTap: onLinkedInTap,
          child: Image.asset(
            'assets/images/linkedin.png',
            width: size,
            height: size,
          ),
        ),
      ],
    );
  }
}

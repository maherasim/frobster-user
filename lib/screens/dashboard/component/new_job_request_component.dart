import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:ui';

import '../../../main.dart';
import '../../../utils/colors.dart';
import '../../auth/sign_in_screen.dart';
import '../../jobRequest/create_post_request_screen.dart';
import '../../jobRequest/my_post_request_list_screen.dart';

enum NewJobBannerStyle { card, gradient, glass }

class NewJobRequestComponent extends StatelessWidget {
  final NewJobBannerStyle style;

  const NewJobRequestComponent({Key? key, this.style = NewJobBannerStyle.card})
      : super(key: key);

  void _handleCtaTap(BuildContext context) async {
    if (appStore.isLoggedIn) {
      CreatePostRequestScreen().launch(context);
    } else {
      setStatusBarColor(Colors.white, statusBarIconBrightness: Brightness.dark);
      bool? res = await SignInScreen(returnExpected: true).launch(context);
      if (res ?? false) {
        MyPostRequestListScreen().launch(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case NewJobBannerStyle.gradient:
        return _buildGradient(context);
      case NewJobBannerStyle.glass:
        return _buildGlass(context);
      case NewJobBannerStyle.card:
        return _buildCard(context);
    }
  }

  Widget _buildCard(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: context.width(),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultRadius),
            topRight: Radius.circular(defaultRadius),
          ),
          border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.post_add_rounded, color: context.primaryColor),
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.canTFindYourServices,
                        style: boldTextStyle(size: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      6.height,
                      Text(
                        language.jobRequestSubtitle,
                        style: secondaryTextStyle(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            14.height,
            AppButton(
              width: context.width(),
              elevation: 0,
              shapeBorder: RoundedRectangleBorder(borderRadius: radius(12)),
              color: context.primaryColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  8.width,
                  Text(language.newPostJobRequest, style: boldTextStyle(color: Colors.white)),
                ],
              ),
              onTap: () => _handleCtaTap(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradient(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: context.width(),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.primaryColor, brandAccentColor],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultRadius),
            topRight: Radius.circular(defaultRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(Icons.post_add_rounded, color: Colors.white),
                ),
                12.width,
                Flexible(
                  child: Text(
                    language.canTFindYourServices,
                    style: boldTextStyle(color: Colors.white, size: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            10.height,
            Text(
              language.jobRequestSubtitle,
              style: primaryTextStyle(color: Colors.white.withOpacity(0.9), size: 14),
              textAlign: TextAlign.center,
            ),
            16.height,
            AppButton(
              width: context.width(),
              elevation: 0,
              shapeBorder: RoundedRectangleBorder(borderRadius: radius(12)),
              color: Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: context.primaryColor),
                  8.width,
                  Text(language.newPostJobRequest, style: boldTextStyle(color: context.primaryColor)),
                ],
              ),
              onTap: () => _handleCtaTap(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlass(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: context.width(),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(defaultRadius),
                topRight: Radius.circular(defaultRadius),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.post_add_rounded, color: context.primaryColor),
                    8.width,
                    Flexible(
                      child: Text(
                        language.canTFindYourServices,
                        style: boldTextStyle(size: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                10.height,
                Text(
                  language.jobRequestSubtitle,
                  style: secondaryTextStyle(),
                  textAlign: TextAlign.center,
                ),
                16.height,
                AppButton(
                  width: context.width(),
                  elevation: 0,
                  shapeBorder: RoundedRectangleBorder(borderRadius: radius(12)),
                  color: context.primaryColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                      8.width,
                      Text(language.newPostJobRequest, style: boldTextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () => _handleCtaTap(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

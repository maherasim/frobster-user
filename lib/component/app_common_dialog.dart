import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../utils/colors.dart';

class AppCommonDialog extends StatelessWidget {
  final String title;
  final Widget child;

  AppCommonDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 8, 12),
            width: context.width(),
            decoration: BoxDecoration(
              gradient: appPrimaryGradient,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(defaultRadius),
                topLeft: Radius.circular(defaultRadius),
              ),
            ),
            child: Row(
              children: [
                Text(title, style: boldTextStyle(color: Colors.white)).expand(),
                CloseButton(color: Colors.white),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

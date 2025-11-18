import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class AppScaffold extends StatelessWidget {
  final String? appBarTitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  final Widget child;
  final Color? scaffoldBackgroundColor;
  final Widget? bottomNavigationBar;
  final bool showLoader;
  final Widget? floatingActionButton;

  AppScaffold({
    this.appBarTitle,
    required this.child,
    this.actions,
    this.bottom,
    this.scaffoldBackgroundColor,
    this.bottomNavigationBar,
    this.showLoader = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarTitle != null
          ? AppBar(
              title: Text(appBarTitle.validate(),
                  style: boldTextStyle(
                      color: Colors.white, size: APP_BAR_TEXT_SIZE)),
              elevation: 0.0,
              backgroundColor: context.primaryColor,
              leading: context.canPop ? BackWidget() : null,
              actions: actions,
              bottom: bottom,
            )
          : null,
      backgroundColor: scaffoldBackgroundColor,
      body: Body(child: child, showLoader: showLoader),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

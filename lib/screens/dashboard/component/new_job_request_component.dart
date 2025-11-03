import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../auth/sign_in_screen.dart';
import '../../jobRequest/create_post_request_screen.dart';
import '../../jobRequest/my_post_request_list_screen.dart';

class NewJobRequestComponent extends StatelessWidget {
  const NewJobRequestComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.primaryColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultRadius),
            topRight: Radius.circular(defaultRadius)),
      ),
      width: context.width(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          16.height,
          Material(
              color: Colors.transparent,
              child: Text(language.jobRequestSubtitle,
                  style: primaryTextStyle(color: white, size: 16),
                  textAlign: TextAlign.center)),
          20.height,
          // Container(
          //   width: 200,
          //   decoration: BoxDecoration(
          //       image: DecorationImage(
          //     image: AssetImage('assets/images/button.jpg'),
          //   )),
          // ),
          GestureDetector(
            onTap: () async {
              if (appStore.isLoggedIn) {
                CreatePostRequestScreen().launch(context);
              } else {
                setStatusBarColor(Colors.white,
                    statusBarIconBrightness: Brightness.dark);
                bool? res =
                    await SignInScreen(returnExpected: true).launch(context);

                if (res ?? false) {
                  MyPostRequestListScreen().launch(context);
                }
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/button.jpg',
                  width: 200,
                ),
                Text(
                  language.newPostJobRequest,
                  style: boldTextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          // AppButton(
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Icon(Icons.add,
          //           color: appStore.isDarkMode
          //               ? Colors.white
          //               : context.primaryColor),
          //       4.width,
          //       Text(language.newPostJobRequest,
          //           style: boldTextStyle(
          //               color: appStore.isDarkMode
          //                   ? Colors.white
          //                   : context.primaryColor)),
          //     ],
          //   ),
          //   textStyle: primaryTextStyle(
          //       color: appStore.isDarkMode
          //           ? textPrimaryColorGlobal
          //           : context.primaryColor),
          //   onTap: () async {
          //     if (appStore.isLoggedIn) {
          //       CreatePostRequestScreen().launch(context);
          //     } else {
          //       setStatusBarColor(Colors.white,
          //           statusBarIconBrightness: Brightness.dark);
          //       bool? res =
          //           await SignInScreen(returnExpected: true).launch(context);

          //       if (res ?? false) {
          //         MyPostRequestListScreen().launch(context);
          //       }
          //     }
          //   },
          // ),
          16.height,
        ],
      ),
    );
  }
}

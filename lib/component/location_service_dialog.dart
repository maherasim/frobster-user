import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class LocationServiceDialog extends StatefulWidget {
  final Function()? onAccept;

  LocationServiceDialog({this.onAccept});

  @override
  State<LocationServiceDialog> createState() => _LocationServiceDialogState();
}

class _LocationServiceDialogState extends State<LocationServiceDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
                  appStore.isCurrentLocation
                      ? language.msgForLocationOn
                      : language.msgForLocationOff,
                  style: primaryTextStyle())
              .paddingAll(16),
          16.height,
          GradientButton(
            onPressed: () async {
              finish(context, true);
            },
            child: Text(
              appStore.isCurrentLocation ? language.turnOff : language.turnOn,
              style: boldTextStyle(color: Colors.white),
            ),
          )
              .withWidth(context.width())
              .paddingAll(16),
          8.height,
        ],
      ),
    );
  }
}

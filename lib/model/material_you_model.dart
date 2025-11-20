import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:flutter/material.dart';

Future<Color> getMaterialYouData() async {
  // Enforce a consistent brand color across the app (ignore OS-derived colors).
  primaryColor = defaultPrimaryColor;
  return primaryColor;
}

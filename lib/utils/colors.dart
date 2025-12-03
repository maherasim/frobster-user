import 'package:flutter/material.dart';

var primaryColor = const Color(0xFFE53935);
// Brand neutrals/tints aligned with teal/emerald palette (non-blue)
const secondaryPrimaryColor = Color(0xFFECFDF5); // emerald-50
const lightPrimaryColor = Color(0xFFE6FFFA); // teal-50
const primaryLightColor = Color(0xFFF0FDFA); // teal-50 slightly different

//Text Color
const appTextPrimaryColor = Color(0xff1C1F34);
const appTextSecondaryColor = Color(0xFF6C757D);
const cardColor = Color(0xFFF6F7F9);
const borderColor = Color(0xFFEBEBEB);

const scaffoldColorDark = Color(0xFF0E1116);
const scaffoldSecondaryDark = Color(0xFF1C1F26);
const appButtonColorDark = Color(0xFF282828);

const ratingBarColor = Color(0xfff5c609);
const verifyAcColor = brandAccentColor; // use brand accent, avoid blue
const favouriteColor = Colors.red;
const unFavouriteColor = Colors.grey;
const lineTextColor = Color(0xFF6C757D);

const primaryColorWithOpacity = Color(0xFFBCBCC7);

//Status Color
const pending = Color(0xFFEA2F2F);
const accept = Color(0xFF00968A);
const on_going = Color(0xFFFD6922);
const in_progress = Color(0xFFB953C0);
const hold = Color(0xFFFFBD49);
const cancelled = Color(0xffFF0303);
const rejected = Color(0xFF8D0E06);
const failed = Color(0xFFC41520);
const completed = Color(0xFF3CAE5C);
const defaultStatus = Color(0xFF3CAE5C);
const pendingApprovalColor = Color(0xFF690AD3);
const waiting = Color(0xFF2CAFAF);

const add_booking = Color(0xFFEA2F2F);
const assigned_booking = Color(0xFFFD6922);
const transfer_booking = Color(0xFF00968A);
const update_booking_status = Color(0xFF3CAE5C);
const cancel_booking = Color(0xFFC41520);
const payment_message_status = Color(0xFFFFBD49);
const defaultActivityStatus = Color(0xFF3CAE5C);

const walletCardColor = Color(0xFF1C1E33);
const showRedForZeroRatingColor = Color(0xFFFA6565);

//Dashboard 3
const jobRequestComponentColor = Color(0xFFE4BB97);
const dashboard3CardColor = Color(0xFFF6F7F9);
const cancellationsBgColor = Color(0xFFFFE5E5);

// Brand accent and gradient
const brandAccentColor = Color.fromARGB(255, 62, 65, 241);

// Red–Blue primary gradient requested by client
const Color gradientRed = Color(0xFFE53935); // vivid red
const Color gradientBlue = Color(0xFF1E88E5); // strong blue
const LinearGradient appPrimaryGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: <Color>[gradientRed, gradientBlue],
);
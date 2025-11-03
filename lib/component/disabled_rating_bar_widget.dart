import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class DisabledRatingBarWidget extends StatelessWidget {
  final num rating;
  final double? size;
  final MainAxisAlignment mainAxisAlignment;

  DisabledRatingBarWidget(
      {required this.rating,
      this.size,
      this.mainAxisAlignment = MainAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        RatingBarWidget(
          onRatingChanged: null,
          itemCount: 5,
          size: size ?? 18,
          disable: true,
          rating: rating.validate().toDouble(),
          // activeColor: ratingBarColor,
          activeColor: getRatingBarColor(rating.toInt()),
        ),
      ],
    );
  }
}

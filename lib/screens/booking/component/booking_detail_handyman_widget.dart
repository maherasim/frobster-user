import 'package:booking_system_flutter/component/add_review_dialog.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class BookingDetailHandymanWidget extends StatefulWidget {
  final UserData handymanData;
  final ServiceData serviceDetail;
  final BookingData bookingDetail;
  final Function() onUpdate;

  BookingDetailHandymanWidget(
      {required this.handymanData,
      required this.serviceDetail,
      required this.bookingDetail,
      required this.onUpdate});

  @override
  BookingDetailHandymanWidgetState createState() =>
      BookingDetailHandymanWidgetState();
}

class BookingDetailHandymanWidgetState
    extends State<BookingDetailHandymanWidget> {
  int? flag;

  bool isChattingAllow = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
          backgroundColor: context.cardColor, borderRadius: radius()),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.handymanData.profileImage.validate().isEmpty
                  ? Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: radius(60),
                      ),
                      child: Text('N/A', style: secondaryTextStyle()),
                    )
                  : ImageBorder(
                      src: widget.handymanData.profileImage.validate(),
                      height: 60,
                    ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/verified_badge.jpg',
                        width: 15,
                        height: 15,
                      ),
                      SizedBox(width: 6),
                      Image.asset(
                        'assets/icons/free-membership.jpg',
                        width: 15,
                        height: 15,
                      ),
                    ],
                  ),
                  5.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                              widget.handymanData.displayName
                                      .validate()
                                      .isNotEmpty
                                  ? widget.handymanData.displayName.validate()
                                  : 'N/A',
                              style: boldTextStyle())
                          .flexible(),
                          16.width,
                          Image.asset(ic_verified, height: 16, color: Colors.green)
                              .visible(widget.handymanData.isVerifyHandyman == 1),
                        ],
                      ).expand(),
                    ],
                  ),
                  4.height,
                  Row(
                    children: [
                      Image.asset(
                        ic_star_fill,
                        height: 14,
                        fit: BoxFit.fitWidth,
                        color: getRatingBarColor(widget
                            .handymanData.handymanRating
                            .validate()
                            .toInt()),
                      ),
                      4.width,
                      Text(
                        widget.handymanData.handymanRating
                            .validate()
                            .toStringAsFixed(1)
                            .toString(),
                        style:
                            boldTextStyle(color: textSecondaryColor, size: 14),
                      ),
                    ],
                  ),
                  4.height,
                  Builder(builder: (context) {
                    final city = widget.handymanData.cityName.validate();
                    final country = widget.handymanData.countryName.validate();
                    final label = (city.isEmpty && country.isEmpty)
                        ? 'N/A'
                        : "${city}${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}${country}";
                    return Text(
                      label,
                      style:
                          secondaryTextStyle(size: 12, color: textSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ],
              ).expand()
            ],
          ),
          8.height,
          Divider(color: context.dividerColor),
          8.height,
          8.height,
          if (widget.bookingDetail.status == BookingStatusKeys.complete)
            TextButton(
              onPressed: () {
                _handleHandymanRatingClick();
              },
              child: Text(
                  widget.handymanData.handymanReview != null
                      ? language.lblEditYourReview
                      : language.lblRateHandyman,
                  style: boldTextStyle(color: primaryColor)),
            ).center()
        ],
      ),
    );
  }

  void _handleHandymanRatingClick() {
    if (widget.handymanData.handymanReview == null) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        backgroundColor: context.scaffoldBackgroundColor,
        dialogAnimation: DialogAnimation.SCALE,
        builder: (p0) {
          return AddReviewDialog(
            serviceId: widget.serviceDetail.id.validate(),
            bookingId: widget.bookingDetail.id.validate(),
            handymanId: widget.handymanData.id,
          );
        },
      ).then((value) {
        if (value ?? false) {
          widget.onUpdate.call();
        }
      }).catchError((e) {
        log(e.toString());
      });
    } else {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        backgroundColor: context.scaffoldBackgroundColor,
        dialogAnimation: DialogAnimation.SCALE,
        builder: (p0) {
          return AddReviewDialog(
            serviceId: widget.serviceDetail.id.validate(),
            bookingId: widget.bookingDetail.id.validate(),
            handymanId: widget.handymanData.id,
            customerReview: RatingData(
              bookingId: widget.handymanData.handymanReview!.bookingId,
              createdAt: widget.handymanData.handymanReview!.createdAt,
              customerName: widget.handymanData.handymanReview!.customerName,
              id: widget.handymanData.handymanReview!.id,
              rating: widget.handymanData.handymanReview!.rating,
              customerId: widget.handymanData.handymanReview!.customerId,
              review: widget.handymanData.handymanReview!.review,
              serviceId: widget.handymanData.handymanReview!.serviceId,
            ),
          );
        },
      ).then((value) {
        if (value ?? false) {
          widget.onUpdate.call();
        }
      }).catchError((e) {
        log(e.toString());
      });
    }
  }
}

import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/booking/component/report_review_dialog.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/images.dart';

class ReviewWidget extends StatelessWidget {
  final RatingData data;
  final bool isCustomer;
  /// When set, show report-review flag next to the reviewer name (e.g. booking `customer_rating`).
  final int? reportReviewId;
  final String reportReviewType;

  ReviewWidget({
    required this.data,
    this.isCustomer = false,
    this.reportReviewId,
    this.reportReviewType = 'booking_rating',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      width: context.width(),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageBorder(
                src: isCustomer
                    ? data.customerProfileImage.validate()
                    : data.profileImage.validate(),
                height: 50,
              ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(data.customerName.validate(),
                                  style: boldTextStyle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (reportReviewId != null &&
                                reportReviewId.validate() > 0)
                              Observer(
                                builder: (_) {
                                  final rid = reportReviewId;
                                  if (!appStore.isLoggedIn ||
                                      rid == null ||
                                      rid.validate() <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    tooltip: language.ugcReportReviewTitle,
                                    icon: Icon(
                                      Icons.flag_outlined,
                                      color: context.primaryColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (ctx) => ReportReviewDialog(
                                          reviewId: rid.validate(),
                                          reviewType: reportReviewType,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: appStore.isDarkMode
                                ? Colors.black
                                : Colors.white,
                            borderRadius: radius(5)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3),
                          child: Row(
                            children: [
                              Image.asset(ic_star_fill,
                                  height: 12,
                                  fit: BoxFit.fitWidth,
                                  color: getRatingBarColor(
                                      data.rating.validate().toInt())),
                              4.width,
                              Text(
                                  data.rating
                                      .validate()
                                      .toStringAsFixed(1)
                                      .toString(),
                                  style: boldTextStyle(
                                      color: getRatingBarColor(
                                          data.rating.validate().toInt()),
                                      size: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  4.height,
                  data.createdAt.validate().isNotEmpty
                      ? Text(formatDate(data.createdAt.validate()),
                          style: secondaryTextStyle())
                      : SizedBox(),
                ],
              ).flexible(),
            ],
          ),
          if (data.review.validate().isNotEmpty)
            ReadMoreText(
              data.review.validate(),
              style: secondaryTextStyle(),
              trimLength: 100,
              colorClickableText: context.primaryColor,
            ).paddingTop(8),
        ],
      ),
    );
  }
}

import 'package:booking_system_flutter/component/dotted_line.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/price_widget.dart';
import '../../../main.dart';
import '../../../utils/app_configuration.dart';
import '../../../utils/booking_calculations_logic.dart';
import '../../../utils/colors.dart';
import '../../../utils/constant.dart';

class CouponCardWidget extends StatelessWidget {
  final CouponData data;
  final num? servicePrice;

  CouponCardWidget({required this.data, this.servicePrice});

  final double sideDotsSize = 9;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          width: context.width(),
          height: context.height() * 0.16,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: appPrimaryGradient,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.center,
                child: data.discountType == SERVICE_TYPE_FIXED
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PriceWidget(
                              price: data.discount.validate(),
                              decimalPoint: 0,
                              color: hold,
                              size: 26),
                          Text("${language.lblDiscount.toUpperCase()}",
                              style: boldTextStyle(color: white, size: 12)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${data.discount.validate()}%",
                              textAlign: TextAlign.center,
                              style: boldTextStyle(color: hold, size: 26)),
                          Text("${language.lblDiscount.toUpperCase()}",
                              style: boldTextStyle(color: white, size: 12)),
                        ],
                      ),
              ).paddingRight(4).expand(flex: 1),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${data.code.validate()}",
                      style: boldTextStyle(color: white, size: 14)),
                  6.height,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${language.useThisCodeToGet} ',
                          style: primaryTextStyle(
                              color: white, size: 11, weight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: calculateCouponDiscount(
                                  couponData: data,
                                  price: servicePrice.validate())
                              .toPriceFormat(),
                          style: primaryTextStyle(
                              color: hold, size: 11, weight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' ${language.off}',
                          style: primaryTextStyle(
                              color: white, size: 11, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  6.height,
                  data.isApplied
                      ? Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14, color: completed),
                            4.width,
                            Text(language.applied,
                                style: boldTextStyle(color: white, size: 12)),
                            4.width,
                          ],
                        ).paddingBottom(4)
                      : AppButton(
                          padding: EdgeInsets.zero,
                          width: context.width() * 0.30,
                          child: TextIcon(
                            text: data.isApplied
                                ? language.applied
                                : language.lblApply,
                            textStyle: boldTextStyle(
                                color: appStore.isDarkMode
                                    ? white
                                    : context.primaryColor),
                            prefix: data.isApplied
                                ? Icon(Icons.check_circle_outline,
                                    size: 16, color: completed)
                                : Offstage(),
                          ),
                          color: appStore.isDarkMode
                              ? context.scaffoldBackgroundColor
                              : white,
                          onTap: () {
                            data.isApplied = true;
                            finish(context, data);
                          },
                        ),
                  Text(
                    "${language.lblExpiryDate} ${DateFormat(getStringAsync(DATE_FORMAT)).format(DateTime.parse(data.expireDate.validate()))}",
                    style: primaryTextStyle(
                      color: hold,
                      size: 10,
                      fontStyle: FontStyle.italic,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ).paddingLeft(32).expand(flex: 2),
            ],
          ),
        ),
        Positioned(
          left: -sideDotsSize,
          child: Column(
            children: List.generate(
              countOfSideCuts(context),
              (index) => CircleAvatar(
                radius: sideDotsSize,
                backgroundColor: context.scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
        Positioned(
          right: -sideDotsSize,
          child: Column(
            children: List.generate(
              countOfSideCuts(context),
              (index) => CircleAvatar(
                radius: sideDotsSize,
                backgroundColor: context.scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
        Positioned(
          top: -sideDotsSize * 1.8,
          child: SizedBox(
            width: context.width(),
            height: context.height() * 0.16 + (sideDotsSize * 2 * 1.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.center,
                ).expand(flex: 1),
                Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: sideDotsSize * 1.5,
                          backgroundColor: context.scaffoldBackgroundColor,
                        ),
                        DottedLine(
                          direction: Axis.vertical,
                          dashColor: white.withValues(alpha: 0.12),
                          dashGapLength: 8,
                          dashLength: 10,
                        ).expand(),
                        CircleAvatar(
                          radius: sideDotsSize * 1.5,
                          backgroundColor: context.scaffoldBackgroundColor,
                        ),
                      ],
                    ).paddingSymmetric(horizontal: 8)
                  ],
                ),
                Container(
                  alignment: Alignment.center,
                ).expand(flex: 2),
              ],
            ),
          ),
        )
      ],
    );
  }

  int countOfSideCuts(BuildContext context) {
    num dotCount = 0;
    dotCount = (context.height() * 0.16) / sideDotsSize;
    return dotCount.round();
  }
}

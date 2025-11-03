import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class BankTransferDetailDialog extends StatelessWidget {
  final int? bookingId;
  final String? bookingAmount;
  const BankTransferDetailDialog({super.key,  this.bookingId,  this.bookingAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Bank Transfer Details',
              style: boldTextStyle(size: 16),
            ),
            GestureDetector(
              onTap: () {
                finish(context);
              },
              child: Image.asset(
                Assets.iconsIcClose,
                height: 20.0,
                color: context.iconColor,
              ),
            ),
          ],
        ),
        Divider(),
        10.height,
        if(bookingAmount != null && bookingAmount!.isNotEmpty) RichTextWidget(
          list: [
            TextSpan(
              text: 'Please pay the amount of',
              style: primaryTextStyle(
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' $bookingAmount ',
              style: boldTextStyle(size: 14, color: context.primaryColor),
            ),
            TextSpan(
              text: 'via bank transfer using the details below:',
              style: primaryTextStyle(
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        16.height,
        Container(
          padding: EdgeInsets.all(14),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: BorderRadius.circular(8),
            backgroundColor: appStore.isDarkMode ? context.dividerColor : dashboard3CardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bank Information',
                style: boldTextStyle(size: 14),
              ),
              Divider(),
              10.height,
              bankDetailsWidget("Bank Name:","Norisbank",false),
              bankDetailsWidget("Country:","Germany",false),
              bankDetailsWidget("Account Number:","4776167",false),
              bankDetailsWidget("IBAN:","DE57760260000477616700",false),
              bankDetailsWidget("BIC/Swift:","NORDSDE71XXX",false),
            ],
          ),
        ),
        16.height,
        Container(
          padding: EdgeInsets.all(14),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: BorderRadius.circular(8),
            backgroundColor: appStore.isDarkMode ? context.dividerColor : dashboard3CardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Instructions',
                style: boldTextStyle(size: 14),
              ),
              Divider(),
              10.height,
              if(bookingId != null) RichTextWidget(
                list: [
                  TextSpan(
                    text: 'Mention your Booking ID',
                    style: primaryTextStyle(
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ' #$bookingId ',
                    style: boldTextStyle(size: 14, color: context.primaryColor),
                  ),
                  TextSpan(
                    text: 'in the transfer reference.',
                    style: primaryTextStyle(
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              RichTextWidget(
                list: [
                  TextSpan(
                    text: 'Send Proof of Payment (screenshot or pdf Document) to:',
                    style: primaryTextStyle(
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ' billing@frobster.com',
                    style: boldTextStyle(size: 14, color: context.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget bankDetailsWidget(String title, String value, bool isPrice) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: secondaryTextStyle(
          size: 10,
          color:
          appStore.isDarkMode ? darkGray : appTextSecondaryColor,
        ),
      ).expand(flex: 2),
      Text(
        isPrice ? num.parse(value.toString()).toPriceFormat() : value,
        style: boldTextStyle(size: 10),
      ).expand(flex: 3),
    ],
  ).paddingBottom(6.0);
}
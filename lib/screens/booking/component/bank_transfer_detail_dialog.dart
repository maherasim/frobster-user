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
              language.bankTransferDetailsTitle,
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
              text: language.bankTransferPayAmountPrefix,
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
              text: language.bankTransferPayAmountSuffix,
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
                language.bankTransferLocalInternationalTitle,
                style: boldTextStyle(size: 14),
              ),
              Divider(),
              10.height,
              bankDetailsWidget(language.bankTransferRecipientLabel,"Persotel International",false),
              bankDetailsWidget(language.bankTransferIbanLabel,"DE02 1001 0178 1361 6331 79",false),
              bankDetailsWidget(language.bankTransferBicLabel,"REVODEB2",false),
              bankDetailsWidget(language.bankTransferBankNameAddressLabel,"Revolut Bank UAB, Zweigniederlassung Deutschland\nFORA Linden Palais, Unter den Linden 40\n10117, Berlin, Germany",false),
              bankDetailsWidget(language.bankTransferSenderBankBicLabel,"CHASDEFX",false),
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
                language.bankTransferInstructionsTitle,
                style: boldTextStyle(size: 14),
              ),
              Divider(),
              10.height,
              if(bookingId != null) RichTextWidget(
                list: [
                  TextSpan(
                    text: language.bankTransferMentionBookingIdPrefix,
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
                    text: language.bankTransferMentionBookingIdSuffix,
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
                    text: language.bankTransferSendProofPrefix,
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
      Flexible(
        flex: 3,
        child: Text(
          isPrice ? num.parse(value.toString()).toPriceFormat() : value,
          style: boldTextStyle(size: 10),
          maxLines: null,
          overflow: TextOverflow.visible,
        ),
      ),
    ],
  ).paddingBottom(6.0);
}
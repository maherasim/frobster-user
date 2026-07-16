import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/bank_transfer_settings_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class BankTransferDetailDialog extends StatefulWidget {
  final int? bookingId;
  final String? bookingAmount;

  const BankTransferDetailDialog({super.key, this.bookingId, this.bookingAmount});

  @override
  State<BankTransferDetailDialog> createState() => _BankTransferDetailDialogState();
}

class _BankTransferDetailDialogState extends State<BankTransferDetailDialog> {
  BankTransferSettings? _settings;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await getBankTransferSettings();
      if (mounted) setState(() { _settings = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(language.bankTransferDetailsTitle, style: boldTextStyle(size: 16)),
            GestureDetector(
              onTap: () => finish(context),
              child: Image.asset(Assets.iconsIcClose, height: 20.0, color: context.iconColor),
            ),
          ],
        ),
        Divider(),
        10.height,
        if (widget.bookingAmount != null && widget.bookingAmount!.isNotEmpty)
          RichTextWidget(
            list: [
              TextSpan(text: language.bankTransferPayAmountPrefix, style: primaryTextStyle(size: 12, weight: FontWeight.w600)),
              TextSpan(text: ' ${widget.bookingAmount} ', style: boldTextStyle(size: 14, color: context.primaryColor)),
              TextSpan(text: language.bankTransferPayAmountSuffix, style: primaryTextStyle(size: 12, weight: FontWeight.w600)),
            ],
          ),
        16.height,
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasError || _settings == null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(language.somethingWentWrong, style: secondaryTextStyle(), textAlign: TextAlign.center),
          )
        else
          _buildContent(context, _settings!),
      ],
    );
  }

  Widget _buildContent(BuildContext context, BankTransferSettings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: BorderRadius.circular(8),
            backgroundColor: appStore.isDarkMode ? context.dividerColor : dashboard3CardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language.bankTransferLocalInternationalTitle, style: boldTextStyle(size: 14)),
              Divider(),
              10.height,
              bankDetailsWidget(language.accountHolderName, s.recipient.validate().isNotEmpty ? s.recipient! : 'N/A', false),
              bankDetailsWidget(language.ibanNumber, s.iban.validate().isNotEmpty ? s.iban! : 'N/A', false),
              bankDetailsWidget(language.bicSwiftCode, s.bic.validate().isNotEmpty ? s.bic! : 'N/A', false),
              bankDetailsWidget(language.bankName, s.bankName.validate().isNotEmpty ? s.bankName! : 'N/A', false),
              bankDetailsWidget(language.lblBankAddress, s.bankAddress.validate().isNotEmpty ? s.bankAddress! : 'N/A', false),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language.bankTransferInstructionsTitle, style: boldTextStyle(size: 14)),
              Divider(),
              10.height,
              if (widget.bookingId != null)
                RichTextWidget(
                  list: [
                    TextSpan(text: language.bankTransferMentionBookingIdPrefix, style: primaryTextStyle(size: 12, weight: FontWeight.w500)),
                    TextSpan(text: ' #${widget.bookingId} ', style: boldTextStyle(size: 14, color: context.primaryColor)),
                    TextSpan(text: language.bankTransferMentionBookingIdSuffix, style: primaryTextStyle(size: 12, weight: FontWeight.w500)),
                  ],
                ),
              if (s.email.validate().isNotEmpty)
                RichTextWidget(
                  list: [
                    TextSpan(text: language.bankTransferSendProofPrefix, style: primaryTextStyle(size: 12, weight: FontWeight.w500)),
                    TextSpan(text: ' ${s.email}', style: boldTextStyle(size: 14, color: context.primaryColor)),
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
        style: secondaryTextStyle(size: 10, color: appStore.isDarkMode ? darkGray : appTextSecondaryColor),
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

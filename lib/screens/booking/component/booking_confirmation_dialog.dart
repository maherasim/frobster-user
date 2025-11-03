import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/time_slots_model.dart';
import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:booking_system_flutter/utils/extensions/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/price_widget.dart';
import '../../../main.dart';
import '../../../model/booking_detail_model.dart';
import '../../../model/service_detail_response.dart';
import '../../../utils/colors.dart';
import '../../../utils/constant.dart';
import '../../dashboard/dashboard_screen.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final ServiceDetailResponse data;
  final List<TimeSlotModel> timeSlots;
  final int? bookingId;
  final num? bookingPrice;
  final BookingPackage? selectedPackage;
  final BookingDetailResponse? bookingDetailResponse;

  BookingConfirmationDialog({
    required this.data,
    required this.bookingId,
    this.bookingPrice,
    this.selectedPackage,
    this.bookingDetailResponse,
    required this.timeSlots,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  Widget buildDateWidget(DateTime date) {
    return Text(date.formatDateTime(formate: DATE_FORMAT_2),
        style: boldTextStyle());
  }

  Widget buildTimeWidget(String startTime, String endTime) {
    return Text(
      '${startTime}\n${endTime}',
      style: boldTextStyle(size: 12),
      textAlign: TextAlign.end,
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(),
            ),
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(top: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                30.height,
                Text(language.thankYou, style: boldTextStyle(size: 20)),
                8.height,
                Text(language.bookingConfirmedMsg, style: secondaryTextStyle()),
                24.height,
                DottedBorderWidget(
                  color: primaryColor.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  gap: 6,
                  padding: EdgeInsets.all(16),
                  radius: 12,
                  child: Column(
                    children: List.generate(widget.timeSlots.length, (index) {
                      final timeSlot = widget.timeSlots[index];
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(language.lblDate,
                                  style: secondaryTextStyle()),
                              Text(
                                  '${language.lblStart} & End ${language.lblTime}',
                                  style: secondaryTextStyle()),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildDateWidget(timeSlot.selectedDate)
                                  .expand(flex: 2),
                              buildTimeWidget(
                                      timeSlot.startTime, timeSlot.endTime)
                                  .expand(flex: 1),
                            ],
                          ),
                        ],
                      );
                    }),
                    // [

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(language.lblDate, style: secondaryTextStyle()),
                    //     Text(language.lblTime, style: secondaryTextStyle()),
                    //   ],
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children:  [
                    //     buildDateWidget().expand(flex: 2),
                    //     buildTimeWidget().expand(flex: 1),
                    //   ],
                    // ),
                    // ],
                  ).center(),
                ),
                16.height,
                if (!widget.data.serviceDetail!.isFreeService)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(language.totalAmount,
                              style: secondaryTextStyle(size: 14)),
                          8.height,
                          PriceWidget(
                            price: widget.bookingPrice.validate(),
                            color: textPrimaryColorGlobal,
                          ),
                        ],
                      ),
                    ],
                  ),
                16.height,
                Row(
                  children: [
                    AppButton(
                      padding: EdgeInsets.zero,
                      text: language.goToHome,
                      textStyle: boldTextStyle(size: 14, color: Colors.white),
                      color: context.primaryColor,
                      onTap: () {
                        DashboardScreen().launch(context, isNewTask: true);
                      },
                    ).expand(),
                    16.width,
                    AppButton(
                      padding: EdgeInsets.zero,
                      text: language.goToReview,
                      textStyle: boldTextStyle(size: 12),
                      shapeBorder: RoundedRectangleBorder(
                          borderRadius: radius(),
                          side: BorderSide(color: primaryColor)),
                      color: context.scaffoldBackgroundColor,
                      onTap: () {
                        DashboardScreen(redirectToBooking: true).launch(context,
                            isNewTask: true,
                            pageRouteAnimation: PageRouteAnimation.Fade);
                        BookingDetailScreen(
                                bookingId: widget.bookingId.validate())
                            .launch(context);
                      },
                    ).expand(),
                  ],
                ),
                16.height,
              ],
            ),
          ),
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor,
              border: Border.all(
                  width: 5,
                  color: context.cardColor,
                  style: BorderStyle.solid,
                  strokeAlign: BorderSide.strokeAlignOutside),
            ),
            child: Icon(Icons.check, color: context.cardColor, size: 40),
          ),
        ],
      ),
    );
  }
}

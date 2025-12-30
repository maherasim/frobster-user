import 'package:booking_system_flutter/app_theme.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/time_slots_model.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ServiceBookingSlot extends StatefulWidget {
  final ServiceDetailResponse? data;
  final BookingData? bookingData;
  final bool isHourlyService;
  final bool isDailyService;
  final bool isFixedService;
  final bool showAppbar;
  final ScrollController scrollController;
  final void Function(TimeSlotModel selectedSlot) onApplyClick;

  ServiceBookingSlot(
      {this.showAppbar = false,
      this.bookingData,
      required this.scrollController,
      required this.onApplyClick,
      required this.isHourlyService,
      required this.isDailyService,
      required this.isFixedService,
      this.data});

  @override
  _ServiceBookingSlotState createState() => _ServiceBookingSlotState();
}

class _ServiceBookingSlotState extends State<ServiceBookingSlot> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController selDateCont = TextEditingController();
  TextEditingController startTimeCont = TextEditingController();
  TextEditingController endTimeCont = TextEditingController();
  TextEditingController totalDaysCont = TextEditingController();
  TextEditingController totalHoursCont = TextEditingController();

  DateTime? selDate;
  DateTime? selStartTime;
  DateTime? selEndTime;

  int totalDays = 0;
  int totalHours = 0;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme().copyWith(
            colorScheme: AppTheme.lightTheme().colorScheme.copyWith(
              primary: gradientRed,
              onPrimary: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      // Use selected date if available, otherwise use today
      final baseDate = selDate ?? DateTime.now();
      final selectedDateTime = DateTime(
          baseDate.year, baseDate.month, baseDate.day, pickedTime.hour, pickedTime.minute);

      setState(() {
        if (isStartTime) {
          selStartTime = selectedDateTime;
          startTimeCont.text = selStartTime!.formatDateTime(formate: 'HH:mm');
          if (widget.isFixedService) {
            selEndTime = selStartTime?.add(
                parseDuration(widget.data!.serviceDetail!.duration.validate()));
            endTimeCont.text = selEndTime!.formatDateTime(formate: 'HH:mm');
          } else if (widget.isDailyService) {
            selEndTime = selStartTime?.add(Duration(hours: 8));
            endTimeCont.text = selEndTime!.formatDateTime(formate: 'HH:mm');
          }
        } else {
          // Allow end time to be less than start time (overnight booking)
          // In 24-hour system, if end time < start time, it means next day
          // Check if end time is before start time - if so, add 1 day
          int startTimeMinutes = selStartTime != null 
              ? selStartTime!.hour * 60 + selStartTime!.minute 
              : 0;
          int endTimeMinutes = pickedTime.hour * 60 + pickedTime.minute;
          
          DateTime endDateTime;
          if (selStartTime != null && endTimeMinutes < startTimeMinutes) {
            // Overnight booking: end time is next day
            endDateTime = selectedDateTime.add(Duration(days: 1));
          } else {
            endDateTime = selectedDateTime;
          }
          
          selEndTime = endDateTime;
          endTimeCont.text = selEndTime!.formatDateTime(formate: 'HH:mm');
        }

        if (selStartTime != null && selEndTime != null) {
          // Calculate duration - this will correctly handle overnight bookings
          // since selEndTime will be on the next day if end time < start time
          final duration = selEndTime!.difference(selStartTime!);
          
          totalHours = duration.inHours;
          // If there are remaining minutes, round up to next hour
          if (duration.inMinutes % 60 > 0) {
            totalHours += 1;
          }
          
          // Calculate days based on service type
          if (widget.isHourlyService) {
            // For hourly services: calculate actual calendar days
            // Count the number of calendar days the booking spans
            DateTime startDate = DateTime(selStartTime!.year, selStartTime!.month, selStartTime!.day);
            DateTime endDate = DateTime(selEndTime!.year, selEndTime!.month, selEndTime!.day);
            
            // Calculate difference in calendar days
            int daysDifference = endDate.difference(startDate).inDays;
            
            // If booking spans multiple calendar days, add 1 (to include both start and end days)
            // If same day, it's 1 day
            totalDays = daysDifference + 1;
          } else if (widget.isDailyService) {
            // For daily services: calculate based on 8-hour blocks
            totalDays = (totalHours / 8).ceil();
          } else {
            // For fixed services: calculate based on 8-hour blocks or actual days
            totalDays = (totalHours / 8).ceil();
          }
          
          totalDaysCont.text = '$totalDays Days';
          totalHoursCont.text = '$totalHours Hours';
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = selDate ?? DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (_, child) {
        return Theme(
          data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme().copyWith(
            colorScheme: AppTheme.lightTheme().colorScheme.copyWith(
              primary: gradientRed,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selDate = pickedDate;
        selDateCont.text = selDate!.formatDateTime(formate: 'yyyy-MM-dd');
      });
    }
  }

  Duration parseDuration(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    return Duration(hours: hours, minutes: minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // margin: EdgeInsets.only(top: context.height() * 0.04),
            decoration: boxDecorationWithRoundedCorners(
                borderRadius:
                    radiusOnly(topLeft: defaultRadius, topRight: defaultRadius),
                backgroundColor: context.cardColor),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      8.height,
                      Text(language.lblSelectDate,
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      16.height,
                      AppTextField(
                        textFieldType: TextFieldType.OTHER,
                        controller: selDateCont,
                        readOnly: true,
                        onTap: () => _selectDate(context, false),
                        errorThisFieldRequired: language.requiredText,
                        decoration: inputDecoration(
                          context,
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                          hintText: 'Select Date',
                          fillColor: context.scaffoldBackgroundColor,
                        ),
                      ),
                      16.height,
                      Row(
                        children: [
                          Flexible(
                            child: AppTextField(
                              textFieldType: TextFieldType.OTHER,
                              controller: startTimeCont,
                              readOnly: true,
                              onTap: () => _selectTime(context, true),
                              errorThisFieldRequired: language.requiredText,
                              decoration: inputDecoration(
                                context,
                                prefixIcon: Icon(Icons.access_time_rounded),
                                hintText: 'Start Time',
                                fillColor: context.scaffoldBackgroundColor,
                              ),
                            ),
                          ),
                          8.width,
                          Flexible(
                            child: AbsorbPointer(
                              absorbing: widget.isFixedService ||
                                  widget.isDailyService,
                              child: AppTextField(
                                textFieldType: TextFieldType.OTHER,
                                controller: endTimeCont,
                                readOnly: true,
                                onTap: () => _selectTime(context, false),
                                errorThisFieldRequired: language.requiredText,
                                decoration: inputDecoration(
                                  context,
                                  prefixIcon: Icon(Icons.access_time_rounded),
                                  hintText: 'End Time',
                                  fillColor: context.scaffoldBackgroundColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      16.height,
                      AbsorbPointer(
                        absorbing: true,
                        child: Row(
                          children: [
                            Flexible(
                              child: AppTextField(
                                textFieldType: TextFieldType.NUMBER,
                                controller: totalDaysCont,
                                errorThisFieldRequired: language.requiredText,
                                decoration: inputDecoration(
                                  context,
                                  prefixIcon: Icon(Icons.timelapse_rounded),
                                  hintText: 'Total Days',
                                  fillColor: context.scaffoldBackgroundColor,
                                ),
                              ),
                            ),
                            8.width,
                            Flexible(
                              child: AppTextField(
                                textFieldType: TextFieldType.NUMBER,
                                controller: totalHoursCont,
                                errorThisFieldRequired: language.requiredText,
                                decoration: inputDecoration(
                                  context,
                                  prefixIcon: Icon(Icons.timer_outlined),
                                  hintText: 'Total Hours',
                                  fillColor: context.scaffoldBackgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).expand(),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      text: language.lblCancel,
                      color: appStore.isDarkMode
                          ? context.scaffoldBackgroundColor
                          : white,
                      textColor:
                          appStore.isDarkMode ? white : context.primaryColor,
                      onTap: () {
                        finish(context);
                      },
                    ).expand(),
                    16.width,
                    GradientButton(
                      onPressed: () {
                          final timeSlotModel = TimeSlotModel(
                            startTime: selStartTime!
                                .formatDateTime(formate: 'HH:mm:ss'),
                            selectedDate: selDate!,
                            endTime:
                                selEndTime!.formatDateTime(formate: 'HH:mm:ss'),
                            totalDays: totalDays,
                            totalHours: totalHours,
                          );
                          widget.onApplyClick(timeSlotModel);
                      },
                      child: Text(
                        language.lblApply,
                        style: boldTextStyle(color: white),
                      ),
                    ).expand(),
                  ],
                ).paddingOnly(bottom: 8),
              ],
            ),
          ).expand(),
        ],
      ),
    );
  }
}

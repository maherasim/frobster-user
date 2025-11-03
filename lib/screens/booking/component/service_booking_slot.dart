import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/time_slots_model.dart';
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
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);

      setState(() {
        if (isStartTime) {
          // Prevent setting start time after end time
          if (selEndTime != null && selectedDateTime.isAfter(selEndTime!)) {
            toast('Start time must be before end time');
            return;
          }
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
          // Prevent setting end time before start time
          if (selStartTime != null &&
              selectedDateTime.isBefore(selStartTime!)) {
            toast('End time must be after start time');
            return;
          }

          selEndTime = selectedDateTime;
          endTimeCont.text = selEndTime!.formatDateTime(formate: 'HH:mm');
        }

        if (selStartTime != null && selEndTime != null) {
          final duration = selEndTime!.difference(selStartTime!);
          totalHours = duration.inHours;
          int customDays = (totalHours / 8).ceil();
          totalDays = customDays;
          totalDaysCont.text = '$customDays Days';
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
                    AppButton(
                        text: language.lblApply,
                        color: context.primaryColor,
                        textColor: white,
                        onTap: () {
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
                        }).expand(),
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

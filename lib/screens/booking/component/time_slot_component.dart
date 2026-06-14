import 'package:booking_system_flutter/model/time_slots_model.dart';
import 'package:booking_system_flutter/utils/extensions/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class TimeSlotComponent extends StatelessWidget {
  final TimeSlotModel timeSlotModel;
  final VoidCallback? onClose;

  const TimeSlotComponent({
    super.key,
    required this.timeSlotModel,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              text(
                  'Date',
                  timeSlotModel.selectedDate
                      .formatDateTime(formate: 'yyyy-MM-dd')),
              text('Start Time', timeSlotModel.startTime),
              text('End Time', timeSlotModel.endTime),
              text('Total Days', timeSlotModel.totalDays.toString()),
              text('Total Hours', timeSlotModel.totalHours.toString()),
            ],
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                )),
          ),
        ),
      ],
    );
  }
}

Widget text(String label, String text) {
  return Text.rich(
    TextSpan(
      text: '$label: ',
      style: secondaryTextStyle(),
      children: [
        TextSpan(
          text: text,
          style: primaryTextStyle(),
        ),
      ],
    ),
  );
}

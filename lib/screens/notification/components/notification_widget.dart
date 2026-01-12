import 'dart:developer';

import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/model/notification_model.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../../utils/common.dart';

class NotificationWidget extends StatelessWidget {
  final NotificationData data;

  NotificationWidget({required this.data});

  /*static String getTime(String inputString, String time) {
    List<String> wordList = inputString.split(" ");
    if (wordList.isNotEmpty) {
      return wordList[0] + ' ' + time;
    } else {
      return ' ';
    }
  }*/

  Color _getBGColor(BuildContext context) {
    if (data.readAt != null) {
      return context.scaffoldBackgroundColor;
    } else {
      return context.cardColor;
    }
  }

  String _formatNotificationTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '';
    }

    try {
      // Parse the timestamp - handle both UTC and local time formats
      DateTime notificationDate;
      
      // Check if the string contains timezone info (Z or +HH:MM or -HH:MM)
      final hasTimezone = createdAt.contains('Z') || 
                          createdAt.contains('+') || 
                          (createdAt.length > 19 && (createdAt[19] == '+' || createdAt[19] == '-'));
      
      if (hasTimezone) {
        notificationDate = DateTime.parse(createdAt).toLocal();
      } else {
        try {
          String isoString = createdAt.trim();
          if (isoString.contains(' ') && !isoString.contains('T')) {
            isoString = isoString.replaceFirst(' ', 'T');
          }
          notificationDate = DateTime.parse(isoString + 'Z').toLocal();
        } catch (e) {
          notificationDate = DateTime.parse(createdAt);
        }
      }
      
      // OPTIONAL: Compensate for server time being ~1 hour behind
      // Based on logs: Server 16:28Z vs Real 17:46Z (~1h 18m diff)
      // Adding 1 hour likely corrects a timezone misconfiguration 
      notificationDate = notificationDate.add(Duration(hours: 1));
      
      DateTime now = DateTime.now();
      Duration difference = now.difference(notificationDate);
      
      /*
      // Debug logging - uncomment to troubleshoot timestamp issues
      log('🔔 Notification timestamp: "$createdAt"');
      log('   Has timezone: $hasTimezone');
      log('   Parsed UTC: ${DateTime.tryParse(createdAt)}');
      log('   Converted to local: $notificationDate');
      log('   Current time (local): $now');
      log('   Current time (UTC): ${now.toUtc()}');
      log('   Difference: ${difference.inMinutes} minutes (${difference.inHours} hours)');
      log('   Will display: "${difference.inMinutes < 1 ? 'Just now' : (difference.inMinutes < 60 ? '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago' : '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago')}"');
      */

      // If less than 1 minute ago
      if (difference.inMinutes < 1) {
        return 'Just now';
      }
      // If less than 1 hour ago
      else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      // If less than 24 hours ago
      else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      }
      // If yesterday
      else if (difference.inDays == 1) {
        return language.yesterday;
      }
      // If less than 7 days ago
      else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      }
      // Otherwise show formatted date
      else {
        return formatDate(createdAt, showDateWithTime: false);
      }
    } catch (e) {
      // If parsing fails, try to format as is or return empty
      try {
        return formatDate(createdAt, showDateWithTime: false);
      } catch (e2) {
        return createdAt;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: boxDecorationDefault(
        color: _getBGColor(context),
        borderRadius: radius(0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          data.profileImage.validate().isNotEmpty
              ? ImageBorder(
                  src: data.profileImage.validate(),
                  height: 40,
                )
              : ImageBorder(
                  src: ic_notification_user,
                  height: 40,
                ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.data?.type.validate().isNotEmpty == true
                        ? data.data!.type.validate().split('_').join(' ').capitalizeFirstLetter()
                        : 'Notification',
                    style: boldTextStyle(size: 12),
                  ).expand(),
                  Text(_formatNotificationTime(data.createdAt), style: secondaryTextStyle()),
                ],
              ),
              4.height,
              Text(
                parseHtmlString(data.data?.message.validate() ?? ''),
                  style: secondaryTextStyle(),
                  maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ).expand(),
        ],
      ),
    );
  }
}

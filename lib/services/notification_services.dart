import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/firebase_details_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../model/user_data_model.dart';

class NotificationService {
  Future<void> sendPushNotifications(String title, String content,
      {String? image,
      required UserData receiverUser,
      required UserData senderUserData}) async {
    try {
      await getFirebaseTokenAndId().then((value) async {
        if (value.data != null && value.data!.firebaseToken != null && value.data!.projectId != null) {
          Map<String, dynamic> data = {
            "created_at": senderUserData.createdAt,
            "email": senderUserData.email,
            "first_name": senderUserData.firstName,
            "id": senderUserData.id.toString(),
            "last_name": senderUserData.lastName,
            "updated_at": senderUserData.updatedAt,
            "profile_image": senderUserData.profileImage,
            "uid": senderUserData.uid,
          };
          data.putIfAbsent("is_chat", () => "1");
          if (image != null && image.isNotEmpty)
            data.putIfAbsent("image_url", () => image.validate());

          Map req = {
            "message": {
              "topic": "user_${receiverUser.id.validate()}",
              "notification": {
                "body": content,
                "title": "$title ${language.sentYouAMessage}",
                "image": image.validate(),
              },
              "data": data,
            }
          };

          var header = {
            HttpHeaders.authorizationHeader:
                'Bearer ${value.data!.firebaseToken}',
            HttpHeaders.contentTypeHeader: 'application/json',
          };
          log("Send Notification request: ${req}");
          log("Firebase Project ID: ${value.data!.projectId}");
          log("Firebase Token (first 20 chars): ${value.data!.firebaseToken?.substring(0, 20)}...");

          Response res = await post(
            Uri.parse(
                'https://fcm.googleapis.com/v1/projects/${value.data!.projectId}/messages:send'),
            body: jsonEncode(req),
            headers: header,
          );

          log("FCM Response Status: ${res.statusCode}");
          log("FCM Response Body: ${res.body}");

          if (res.statusCode.isSuccessful()) {
            log("Notification sent successfully");
          } else {
            log("FCM API Error: ${res.statusCode} - ${res.body}");
            if (res.statusCode == 401) {
              log("ERROR: Firebase token expired or invalid. Please check backend Firebase configuration.");
              throw "Firebase token expired. Please contact support.";
            } else if (res.statusCode == 403) {
              log("ERROR: Firebase project access denied. Check Firebase project permissions.");
              throw "Firebase access denied. Please contact support.";
            } else {
              throw errorSomethingWentWrong;
            }
          }
        } else {
          log("ERROR: Firebase token or project ID is null");
          throw "Firebase configuration missing. Please contact support.";
        }
      }).catchError((e) {
        log("ERROR in getFirebaseTokenAndId: $e");
        throw e;
      });
    } catch (e) {
      log("ERROR sending push notification: $e");
      rethrow;
    }
  }

  Future<FirebaseDetailsModel> getFirebaseTokenAndId({Map? request}) async {
    return FirebaseDetailsModel.fromJson(await handleResponse(
        await buildHttpResponse('firebase-detail',
            request: request, method: HttpMethodType.GET)));
  }
}

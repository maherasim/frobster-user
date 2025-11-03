import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';

import 'booking_data_model.dart';
import 'service_data_model.dart';

class DashboardResponse {
  List<SliderModel>? slider;
  List<CategoryData>? category;
  List<ServiceData>? service;
  List<ServiceData>? featuredServices;
  List<UserData>? provider;
  List<DashboardCustomerReview>? dashboardCustomerReview;
  BookingData? upcomingData;
  int? notificationUnreadCount;
  int? isEmailVerified;

  DashboardResponse({
    this.category,
    this.featuredServices,
    this.provider,
    this.service,
    this.slider,
    this.dashboardCustomerReview,
    this.upcomingData,
    this.notificationUnreadCount,
    this.isEmailVerified,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      category: json['category'] != null
          ? (json['category'] as List)
              .map((i) => CategoryData.fromJson(i))
              .toList()
          : null,
      provider: json['provider'] != null
          ? (json['provider'] as List).map((i) => UserData.fromJson(i)).toList()
          : null,
      service: json['service'] != null
          ? (json['service'] as List)
              .map((i) => ServiceData.fromJson(i))
              .toList()
          : null,
      featuredServices: json['featured_service'] != null
          ? (json['featured_service'] as List)
              .map((i) => ServiceData.fromJson(i))
              .toList()
          : null,
      slider: json['slider'] != null
          ? (json['slider'] as List)
              .map((i) => SliderModel.fromJson(i))
              .toList()
          : null,
      dashboardCustomerReview: json['customer_review'] != null
          ? (json['customer_review'] as List)
              .map((i) => DashboardCustomerReview.fromJson(i))
              .toList()
          : null,
      upcomingData: json['upcomming_confirmed_booking'] != null
          ? BookingData.fromJson(json['upcomming_confirmed_booking'])
          : null,
      notificationUnreadCount: json['notification_unread_count'],
      isEmailVerified:
          json['is_email_verified'] != null ? json['is_email_verified'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_email_verified'] = this.isEmailVerified;
    if (this.category != null) {
      data['category'] = this.category!.map((v) => v.toJson()).toList();
    }
    if (this.provider != null) {
      data['provider'] = this.provider!.map((v) => v.toJson()).toList();
    }
    if (this.service != null) {
      data['service'] = this.service!.map((v) => v.toJson()).toList();
    }
    if (this.featuredServices != null) {
      data['featured_service'] = this.service!.map((v) => v.toJson()).toList();
    }
    if (this.slider != null) {
      data['slider'] = this.slider!.map((v) => v.toJson()).toList();
    }
    if (this.dashboardCustomerReview != null) {
      data['customer_review'] =
          this.dashboardCustomerReview!.map((v) => v.toJson()).toList();
    }
    if (this.upcomingData != null) {
      data['upcomming_confirmed_booking'] != null
          ? BookingData.fromJson(data['upcomming_confirmed_booking'])
          : null;
    }

    return data;
  }
}

class SliderModel {
  String? description;
  int? id;
  String? serviceName;
  String? sliderImage;
  int? status;
  String? title;
  String? type;
  int? typeId;

  SliderModel({
    this.description,
    this.id,
    this.serviceName,
    this.sliderImage,
    this.status,
    this.title,
    this.type,
    this.typeId,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      description: json['description'],
      id: json['id'],
      serviceName: json['service_name'],
      sliderImage: json['slider_image'],
      status: json['status'],
      title: json['title'],
      type: json['type'],
      typeId: json['type_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['description'] = this.description;
    data['id'] = this.id;
    data['service_name'] = this.serviceName;
    data['slider_image'] = this.sliderImage;
    data['status'] = this.status;
    data['title'] = this.title;
    data['type'] = this.type;
    data['type_id'] = this.typeId;
    return data;
  }
}

class DashboardCustomerReview {
  List<String>? attchments;
  int? bookingId;
  String? createdAt;
  int? customerId;
  String? customerName;
  int? id;
  String? profileImage;
  num? rating;
  String? review;
  int? serviceId;
  String? serviceName;

  DashboardCustomerReview(
      {this.attchments,
      this.bookingId,
      this.createdAt,
      this.customerId,
      this.customerName,
      this.id,
      this.profileImage,
      this.rating,
      this.review,
      this.serviceId,
      this.serviceName});

  factory DashboardCustomerReview.fromJson(Map<String, dynamic> json) {
    return DashboardCustomerReview(
      attchments: json['attchments'] != null
          ? new List<String>.from(json['attchments'])
          : null,
      bookingId: json['booking_id'],
      createdAt: json['created_at'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      id: json['id'],
      profileImage: json['profile_image'],
      rating: json['rating'],
      review: json['review'],
      serviceId: json['service_id'],
      serviceName: json['service_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['booking_id'] = this.bookingId;
    data['created_at'] = this.createdAt;
    data['customer_id'] = this.customerId;
    data['customer_name'] = this.customerName;
    data['id'] = this.id;
    data['profile_image'] = this.profileImage;
    data['rating'] = this.rating;
    data['review'] = this.review;
    data['service_id'] = this.serviceId;
    data['service_name'] = this.serviceName;
    if (this.attchments != null) {
      data['attchments'] = this.attchments;
    }
    return data;
  }
}

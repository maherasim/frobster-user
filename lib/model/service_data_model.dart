import 'dart:convert';

import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/slot_data.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/app_configuration.dart';
import '../utils/model_keys.dart';
import 'multi_language_request_model.dart';

class ServiceData {
  int? id;
  int? categoryId;
  int? providerId;
  int? cityId;
  int? status;
  int? isFeatured;
  int? bookingAddressId;
  int? completedBookings;
  int? totalBookingCount;
  int? providerTotalServices;
  num? price;
  num? discount;
  num? totalViews;
  num? totalReview;
  num? totalRating;
  num? isFavourite;
  num? isSlot;
  num? serviceId;
  num? userId;
  String? duration;
  String? minimumOrders;
  String? description;
  String? providerName;
  String? categoryName;
  String? subCategoryName;
  String? providerImage;
  // Provider location from list API
  String? cityName;
  String? countryName;
  // Service location from detail/list
  String? serviceCityName;
  String? serviceCountryName;
  String? name;
  String? type;
  String? cancelationPolicy;
  String? createdAt;
  String? customerName;
  String? bookingDate;
  String? bookingDay;
  String? bookingSlot;
  List<String> dateTimeVal; // <-- Changed from String? to List<String>?
  String? bookingDescription;
  String? address;
  num? isEnableAdvancePayment;
  num? advancePaymentPercentage;
  num? advancePaymentAmount;
  List<String>? attachments;
  List<Attachments>? attachmentsArray;
  List<String>? serviceAttachments;
  List<ServiceAddressMapping>? serviceAddressMapping;
  List<SlotData>? bookingSlots;
  List<BookingPackage>? servicePackage;
  String? visitType;
  String? remoteWorkLevel; // e.g., 25_remote, 75_remote, onsite
  String? careerLevel;     // e.g., intern, junior, senior
  String? travelRequired;  // 'true'/'false'/'0'/'1' as string for easy display
  Map<String, MultiLanguageRequest>? translations;
  String? verifiedStickerIcon; // URL to verified/not verified icon
  String? membership; // Membership type: "gold", "silver", "basic", "free", etc.
  String? membershipIcon; // URL to membership icon

  // Local
  bool isSelected = false;

  bool get isSlotAvailable => isSlot.validate() == 1;

  bool get isHourlyService => type.validate() == SERVICE_TYPE_HOURLY;

  bool get isDailyService => type.validate() == SERVICE_TYPE_DAILY;

  bool get isFixedService => type.validate() == SERVICE_TYPE_FIXED;

  bool get isFreeService => price.validate() == 0;

  bool get isAdvancePayment =>
      isEnableAdvancePayment.validate() == 1 &&
      getBoolAsync(IS_ADVANCE_PAYMENT_ALLOWED) &&
      servicePackage.validate().isEmpty;

  bool get isOnlineService =>
      visitType.validate().toLowerCase() == VISIT_OPTION_ONLINE;

  bool get isOnSiteService =>
      visitType.validate().toLowerCase() == VISIT_OPTION_ON_SITE;

  num get getDiscountedPrice =>
      price.validate().calculatePercentage(discount.validate().toInt());

  ServiceData({
    this.attachments,
    this.bookingDate,
    this.bookingSlot,
    this.categoryId,
    this.categoryName,
    this.cityId,
    this.description,
    this.bookingDay,
    this.discount,
    this.duration,
    this.minimumOrders,
    this.isSlot,
    this.id,
    this.bookingSlots,
    this.isFeatured,
    this.name,
    this.price,
    this.providerId,
    this.providerName,
    this.cityName,
    this.countryName,
    this.serviceCityName,
    this.serviceCountryName,
    this.status,
    this.totalViews,
    this.totalRating,
    this.totalReview,
    this.providerImage,
    this.type,
    this.cancelationPolicy,
    this.isFavourite,
    this.serviceAddressMapping,
    this.subCategoryName,
    this.createdAt,
    this.customerName,
    this.serviceAttachments,
    this.serviceId,
    this.userId,
    this.dateTimeVal = const [],
    this.bookingAddressId,
    this.completedBookings,
    this.totalBookingCount,
    this.providerTotalServices,
    this.servicePackage,
    this.isEnableAdvancePayment,
    this.advancePaymentPercentage,
    this.advancePaymentAmount,
    this.attachmentsArray,
    this.visitType,
    this.remoteWorkLevel,
    this.careerLevel,
    this.travelRequired,
    this.translations,
    this.verifiedStickerIcon,
    this.membership,
    this.membershipIcon,
  });

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      providerId: json['provider_id'],
      price: json['price'],
      type: json['type'],
      cancelationPolicy: json['cancellation_policy'],
      bookingDate: json['booking_date'],
      bookingSlot: json['booking_slot'],
      bookingDay: json['booking_day'],
      isSlot: json['is_slot'],
      subCategoryName: json['subcategory_name'],
      discount: json['discount'] != null ? json['discount'] : 0,
      duration: json['duration'],
      minimumOrders: json['minimum_booking'],
      status: json['status'],
      description: json['description'],
      isFeatured: json['is_featured'],
      completedBookings: json['completed_booking_count'],
      totalBookingCount: json['total_booking_count'] != null 
          ? (json['total_booking_count'] is int 
              ? json['total_booking_count'] 
              : (json['total_booking_count'] as num?)?.toInt())
          : null,
      providerTotalServices: json['provider_total_services'] != null 
          ? (json['provider_total_services'] is int 
              ? json['provider_total_services'] 
              : (json['provider_total_services'] as num?)?.toInt())
          : null,
      providerName: json['provider_name'],
      cityName: json['city_name'],
      countryName: json['country_name'],
      serviceCityName: json['service_city_name'],
      serviceCountryName: json['service_country_name'],
      categoryName: json['category_name'],
      attachments: json['attchments'] != null
          ? (json['attchments'] is List)
              ? (json['attchments'] as List).map((item) {
                  if (item is String) {
                    return item;
                  } else if (item is Map && item['url'] != null) {
                    return item['url'].toString();
                  } else {
                    return item.toString();
                  }
                }).toList().cast<String>()
              : null
          : null,
      totalViews: json['total_views'],
      totalReview: json['total_review'],
      totalRating: json['total_rating'],
      isFavourite: json['is_favourite'],
      cityId: json['city_id'],
      providerImage: json['provider_image'],
      serviceAddressMapping: json['service_address_mapping'] != null
          ? (json['service_address_mapping'] as List)
              .map((i) => ServiceAddressMapping.fromJson(i))
              .toList()
          : null,
      bookingSlots: json['slots'] != null
          ? (json['slots'] as List).map((i) => SlotData.fromJson(i)).toList()
          : null,
      createdAt: json['created_at'],
      customerName: json['customer_name'],
      serviceAttachments: json['service_attchments'] != null
          ? List<String>.from(json['service_attchments'])
          : null,
      serviceId: json['service_id'],
      userId: json['user_id'],
      servicePackage: json['servicePackage'] != null
          ? (json['servicePackage'] as List)
              .map((i) => BookingPackage.fromJson(i))
              .toList()
          : null,
      isEnableAdvancePayment: json[AdvancePaymentKey.isEnableAdvancePayment],
      advancePaymentPercentage: json[AdvancePaymentKey.advancePaymentAmount],
      advancePaymentAmount: json['advance_payment_amount'],
      attachmentsArray: json['attchments_array'] != null
          ? (json['attchments_array'] as List)
              .map((i) => Attachments.fromJson(i))
              .toList()
          : null,
      // Some endpoints may return a misspelled key 'visite_type'
      visitType: json['visit_type'] ?? json['visite_type'],
      remoteWorkLevel: json['remote_work_level'],
      careerLevel: json['career_level'],
      travelRequired: json['travel_required']?.toString(),
      translations: json['translations'] != null
          ? (jsonDecode(json['translations']) as Map<String, dynamic>).map(
              (key, value) {
                if (value is Map<String, dynamic>) {
                  return MapEntry(key, MultiLanguageRequest.fromJson(value));
                } else {
                  print('Unexpected translation value for key $key: $value');
                  return MapEntry(key, MultiLanguageRequest());
                }
              },
            )
          : null,
      dateTimeVal: json['date_time_val'] != null
          ? List<String>.from(json['date_time_val'])
          : [],
      verifiedStickerIcon: json['verified_sticker_icon'],
      membership: json['membership'],
      membershipIcon: json['membership_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = this.categoryId;
    data['category_name'] = this.categoryName;
    data['city_id'] = this.cityId;
    data['description'] = this.description;
    data['discount'] = this.discount;
    data['booking_date'] = this.bookingDate;
    data['booking_slot'] = this.bookingSlot;
    data['booking_day'] = this.bookingDay;
    data['slots'] = this.bookingSlots;
    data['duration'] = this.duration;
    data['minimum_booking'] = this.minimumOrders;
    data['id'] = this.id;
    data['is_featured'] = this.isFeatured;
    data['completed_booking_count'] = this.completedBookings;
    if (this.totalBookingCount != null)
      data['total_booking_count'] = this.totalBookingCount;
    if (this.providerTotalServices != null)
      data['provider_total_services'] = this.providerTotalServices;
    data['name'] = this.name;
    data['price'] = this.price;
    data['is_slot'] = this.isSlot;
    data['digital_service'] = this.isOnlineService;
    data['provider_id'] = this.providerId;
    data['provider_name'] = this.providerName;
    if (this.cityName != null) data['city_name'] = this.cityName;
    if (this.countryName != null) data['country_name'] = this.countryName;
    if (this.serviceCityName != null) data['service_city_name'] = this.serviceCityName;
    if (this.serviceCountryName != null) data['service_country_name'] = this.serviceCountryName;
    data['status'] = this.status;
    data['total_views'] = this.totalViews;
    data['total_rating'] = this.totalRating;
    data['total_review'] = this.totalReview;
    data['provider_image'] = this.providerImage;
    data['subcategory_name'] = this.subCategoryName;
    data['created_at'] = this.createdAt;
    data['customer_name'] = this.customerName;
    data['service_id'] = this.serviceId;
    data['user_id'] = this.userId;
    data['type'] = this.type;
    data['cancellation_policy'] = this.cancelationPolicy;

    if (this.serviceAttachments != null) {
      data['service_attchments'] = this.serviceAttachments;
    }
    if (this.attachments != null) {
      data['attchments'] = this.attachments;
    }
    data['date_time_val'] = this.dateTimeVal;
    data['is_favourite'] = this.isFavourite;
    if (this.serviceAddressMapping != null) {
      data['service_address_mapping'] =
          this.serviceAddressMapping!.map((v) => v.toJson()).toList();
    }
    if (this.attachmentsArray != null) {
      data['attchments_array'] =
          this.attachmentsArray!.map((v) => v.toJson()).toList();
    }
    if (this.servicePackage != null) {
      data['servicePackage'] =
          this.servicePackage!.map((v) => v.toJson()).toList();
    }
    data[AdvancePaymentKey.isEnableAdvancePayment] = this.isAdvancePayment;
    data[AdvancePaymentKey.advancePaymentAmount] =
        this.advancePaymentPercentage;
    data['advance_payment_amount'] = this.advancePaymentAmount;
    data['visit_type'] = this.visitType;
    if (this.remoteWorkLevel != null) data['remote_work_level'] = this.remoteWorkLevel;
    if (this.careerLevel != null) data['career_level'] = this.careerLevel;
    if (this.travelRequired != null) data['travel_required'] = this.travelRequired;
    if (translations != null) {
      data['translations'] =
          translations!.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (this.verifiedStickerIcon != null) data['verified_sticker_icon'] = this.verifiedStickerIcon;
    if (this.membership != null) data['membership'] = this.membership;
    if (this.membershipIcon != null) data['membership_icon'] = this.membershipIcon;
    return data;
  }
}

class ServiceAddressMapping {
  int? id;
  int? serviceId;
  int? providerAddressId;
  String? createdAt;
  String? updatedAt;
  String? cityName;
  String? countryName;
  ProviderAddressMapping? providerAddressMapping;

  ServiceAddressMapping(
      {this.id,
      this.serviceId,
      this.providerAddressId,
      this.createdAt,
      this.updatedAt,
      this.cityName,
      this.countryName,
      this.providerAddressMapping});

  ServiceAddressMapping.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    serviceId = json['service_id'];
    providerAddressId = json['provider_address_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    cityName = json['city_name'];
    countryName = json['country_name'];
    providerAddressMapping = json['provider_address_mapping'] != null
        ? new ProviderAddressMapping.fromJson(json['provider_address_mapping'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['service_id'] = this.serviceId;
    data['provider_address_id'] = this.providerAddressId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.cityName != null) data['city_name'] = this.cityName;
    if (this.countryName != null) data['country_name'] = this.countryName;
    if (this.providerAddressMapping != null) {
      data['provider_address_mapping'] = this.providerAddressMapping!.toJson();
    }
    return data;
  }
}

class ProviderAddressMapping {
  int? id;
  int? providerId;
  String? address;
  String? latitude;
  String? longitude;
  var status;
  String? createdAt;
  String? updatedAt;

  ProviderAddressMapping(
      {this.id,
      this.providerId,
      this.address,
      this.latitude,
      this.longitude,
      this.status,
      this.createdAt,
      this.updatedAt});

  ProviderAddressMapping.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    providerId = json['provider_id'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['provider_id'] = this.providerId;
    data['address'] = this.address;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

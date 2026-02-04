import 'dart:ui';

import 'package:booking_system_flutter/model/pagination_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/colors.dart';

class GetPostJobResponse {
  Pagination? pagination;
  List<PostJobData>? myPostJobData;

  GetPostJobResponse({this.pagination, this.myPostJobData});

  GetPostJobResponse.fromJson(dynamic json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      myPostJobData = [];
      json['data'].forEach((v) {
        myPostJobData?.add(PostJobData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    if (myPostJobData != null) {
      map['data'] = myPostJobData?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class PostJobData {
  num? id;
  String? title;
  String? description;
  String? reason;
  num? price;
  num? providerId;
  num? customerId;
  RequestStatus status;
  JobType? type;
  String? startDate;
  String? endDate;
  num? totalDays;
  num? totalHours;
  int? countryId;
  int? cityId;
  String? requirement;
  int? categoryId;
  int? subCategoryId;
  bool? canBid;
  List<ServiceData>? service;
  String? createdAt;
  String? customerProfile;

  int? acceptedBidId;
  int? stateId;
  double? latitude;
  double? longitude;
  PriceType? priceType;
  JobSchedule? jobSchedule;
  RemoteWorkLevel? remoteWorkLevel;
  CareerLevel? careerLevel;
  EducationLevel? educationLevel;
  TravelRequirement? travelRequired;
  String? streetAddress;
  String? houseNumber;
  String? workingAddress;
  String? duties;
  String? benefits;
  num? totalBudget;

  List<String> images;
  DateTime? date;
  String? image;
  num? totalViews;
  DateTime? updatedAt;

  num? bidCount;
  String? countryName;
  String? cityName;


  PostJobData({
    this.id,
    this.title,
    this.description,
    this.reason,
    this.price,
    this.providerId,
    this.customerId,
    this.customerProfile,
    required this.status,
    this.canBid,
    this.service,
    this.createdAt,
    this.type,
    this.categoryId,
    this.subCategoryId,
    this.countryId,
    this.stateId,
    this.cityId,
    this.startDate,
    this.endDate,
    this.totalDays,
    this.totalHours,
    this.requirement,
    this.latitude,
    this.longitude,
    this.priceType,
    this.jobSchedule,
    this.remoteWorkLevel,
    this.careerLevel,
    this.travelRequired,
    this.educationLevel,
    this.streetAddress,
    this.houseNumber,
    this.workingAddress,
    this.duties,
    this.benefits,
    this.totalBudget,
    this.acceptedBidId,

    required this.images,
    this.date,
    this.image,
    this.totalViews,
    this.updatedAt,
    this.bidCount,
    this.countryName,
    this.cityName,
  });


  factory PostJobData.fromJson(Map<String, dynamic> json) {
    return PostJobData(
      id: json['id'],
      title: json['title'],
      description :json['description'],
      reason :json['reason'],
      price :json['price'],
      providerId :json['provider_id'],
      customerId :json['customer_id'],
      customerProfile :json['customer_profile'],
      canBid :json['can_bid'],
      createdAt :json['created_at'],
      categoryId :json['category_id'],
      subCategoryId :json['subcategory_id'],
      countryId :json['country_id'],
      cityId :json['city_id'],
      startDate :json['start_date'],
      endDate :json['end_date'],
      totalDays :json['total_days'],
      totalHours :json['total_hours'],
      requirement :json['requirement'],
      status: RequestStatus.values.firstWhere((e) => e.backendValue == (json['status']), orElse: () => RequestStatus.requested),
      type: JobType.values.firstWhere((e) => e.backendValue == json['type'], orElse: () => JobType.onSite),

      stateId :json['state_id'],
      latitude: (json['latitude'] != null) ? double.tryParse(json['latitude'].toString()) : null,
      longitude: (json['longitude'] != null) ? double.tryParse(json['longitude'].toString()) : null,
      priceType: PriceType.values.firstWhere((e) => e.backendValue == (json['price_type'] ?? json["job_price"]), orElse: () => PriceType.fixed),
      jobSchedule: JobSchedule.values.firstWhere((e) => e.backendValue == json['job_schedule'], orElse: () => JobSchedule.fullTime),
      remoteWorkLevel: RemoteWorkLevel.values.firstWhere((e) {
        print(e.backendValue == json['remote_work_level']);
        print("${e.backendValue} == ${json['remote_work_level']}");
        return e.backendValue == json['remote_work_level'];
      }, orElse: () => RemoteWorkLevel.onsite0,),
      careerLevel: CareerLevel.values.firstWhere((e) => e.backendValue == json['career_level'], orElse: () => CareerLevel.intern),
      travelRequired: TravelRequirement.values.firstWhere((e) => e.backendValue == json['travel_required'].toString() || e.alternateBackendValue == json['travel_required'].toString(), orElse: () => TravelRequirement.no),
      educationLevel: EducationLevel.values.firstWhere((e) => e.backendValue == json['education_level'], orElse: () => EducationLevel.highSchool),
      streetAddress :json['street_address'],
      houseNumber :json['house_number'],
      workingAddress :json['working_address'],
      duties :json['duties'],
      benefits :json['benefits'],
      totalBudget :json['total_budget'],
      acceptedBidId: json["accepted_bid_id"],
      service: json['service'] == null ? [] : List<ServiceData>.from(json['service'].map((e) => ServiceData.fromJson(e))),
      images: json["images"] == null ? [] : List<String>.from(json["images"]!.map((x) => x)),
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      image: json["image"],
      totalViews: json["total_views"],
      bidCount: json["bid_count"],
      countryName: json["country"],
      cityName: json["city"],
      updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "country_id": countryId,
    "state_id": stateId,
    "city_id": cityId,
    "category_id": categoryId,
    "subcategory_id": subCategoryId,
    "price_type": priceType?.backendValue,
    "price": price,
    "type": type?.backendValue,
    "start_date": startDate,
    "end_date": endDate,
    "total_day": totalDays,
    "total_days": totalDays,
    "total_hours": totalHours,
    "total_budget": totalBudget,
    "job_schedule": jobSchedule?.backendValue,
    "remote_work_level": remoteWorkLevel?.backendValue,
    "career_level": careerLevel?.backendValue,
    "education_level": educationLevel?.backendValue,
    "travel_required": travelRequired?.backendValue,
    "description": description,
    "street_address": streetAddress,
    "house_number": houseNumber,
    "working_address": workingAddress,
    "requirement": requirement,
    "duties": duties,
    "benefits": benefits,
    "accepted_bid_id": acceptedBidId,

    "latitude": latitude,
    "longitude": longitude,

    "reason": reason,
    "provider_id": providerId,
    "customer_id": customerId,
    "customer_profile": customerProfile,
    "status": status,
    "can_bid": canBid,
    "service": service?.map((e) => e.toJson()).toList(),
  };
  Map<String,dynamic> toJsonForCreate() => {
    "id": id,
    "title": title,
    "country_id": countryId,
    "state_id": stateId,
    "city_id": cityId,
    "category_id": categoryId,
    "subcategory_id": subCategoryId,
    "price_type": priceType?.backendValue,
    "price": price,
    "type": type?.backendValue,
    "start_date": startDate,
    "end_date": endDate,
    "total_day": totalDays,
    "total_days": totalDays,
    "total_hours": totalHours,
    "total_budget": totalBudget,
    "job_schedule": jobSchedule?.backendValue,
    "remote_work_level": remoteWorkLevel?.backendValue,
    "career_level": careerLevel?.backendValue,
    "education_level": educationLevel?.backendValue,
    "travel_required": travelRequired?.backendValue,
    "description": description,
    "street_address": streetAddress,
    "house_number": houseNumber,
    "working_address": workingAddress,
    "requirement": requirement,
    "duties": duties,
    "benefits": benefits,

    "latitude": latitude,
    "longitude": longitude,
  };
}


/// Price Type
enum PriceType {
  hourly("Hourly", "hourly"),
  fixed("Fixed", "fixed"),
  daily("Daily", "daily");

  final String displayName;
  final String backendValue;

  const PriceType(this.displayName, this.backendValue);
}

/// Job Type
enum JobType {
  onSite("On Site", "onsite"),
  hybrid("Hybrid", "hybrid"),
  remote("Remote / Home Office", "remote");

  final String displayName;
  final String backendValue;

  const JobType(this.displayName, this.backendValue);
}

/// Job Schedule
enum JobSchedule {
  fullTime("Full-time", "full_time"),
  partTime("Part-time", "part_time"),
  contract("Contract", "contract"),
  temporary("Temporary", "temporary"),
  internship("Internship", "internship");

  final String displayName;
  final String backendValue;

  const JobSchedule(this.displayName, this.backendValue);
}

/// Remote Work Level
enum RemoteWorkLevel {
  onsite0("Onsite (100%)", "onsite"),
  remote25("25% Remote", "25_remote"),
  remote50("50% Remote", "50_remote"),
  remote75("75% Remote", "75_remote"),
  remote100("100% Remote", "100_remote");

  final String displayName;
  final String backendValue;

  const RemoteWorkLevel(this.displayName, this.backendValue);
}

/// Career Level
enum CareerLevel {
  intern("Intern", "intern"),
  entry("Entry", "entry"),
  junior("Junior", "junior"),
  midLevel("Mid-Level", "mid"),
  senior("Senior", "senior"),
  lead("Lead", "lead"),
  manager("Manager", "manager");

  final String displayName;
  final String backendValue;

  const CareerLevel(this.displayName, this.backendValue);
}

/// Travel Requirement
enum TravelRequirement {
  no("No", "0","false"),
  yes("Yes", "1","true");

  final String displayName;
  final String backendValue;
  final String alternateBackendValue;

  const TravelRequirement(this.displayName, this.backendValue,this.alternateBackendValue);
}

/// Education Level
enum EducationLevel {
  highSchool("High School", "high_school"),
  associate("Associate Degree", "associate"),
  undergraduate("Undergraduate Degree", "undergraduate"),
  masters("Graduate/Master's", "masters"),
  doctorate("Doctorate", "doctorate");

  final String displayName;
  final String backendValue;

  const EducationLevel(this.displayName, this.backendValue);
}

/// Education Level
enum RequestStatus {
  requested('Requested','requested',defaultStatus),
  accepted('Accepted','accepted',accept),
  pendingAdvance('Advance Payment Pending','advance_payment_pending',primaryColorWithOpacity),
  advancePaid('Advance Paid','advance_paid',primaryColorWithOpacity),
  inProcess('In Process','in_process',primaryColorWithOpacity),
  inProgress('In Progress','in_progress',primaryColorWithOpacity),
  hold('Hold','hold',primaryColorWithOpacity),
  done('Done','done',primaryColorWithOpacity),
  confirmDone( 'Confirm Done','confirm_done',primaryColorWithOpacity),
  completed( 'Completed','completed',primaryColorWithOpacity),
  remainingPaid( 'Remaining Paid','remaining_paid',primaryColorWithOpacity),

  cancel( 'Cancelled','cancelled',cancelled);

  final String displayName;
  final String backendValue;
  final Color bgColor;
  const RequestStatus(this.displayName,this.backendValue,this.bgColor);
}

class BidderData {
  num? id;
  num? postRequestId;
  num? providerId;
  num? price;
  String? duration;
  String? whyChooseMe;
  String? type;
  UserData? provider;
  PostJobData? postJobData;
  RequestStatus? status;

  BidderData({
    this.id,
    this.postRequestId,
    this.providerId,
    this.price,
    this.duration,
    this.whyChooseMe,
    this.type,
    this.provider,
    this.postJobData,
    this.status,
  });

  BidderData.fromJson(dynamic json) {
    id = json['id'];
    postRequestId = json['post_request_id'];
    providerId = json['provider_id'];
    price = json['price'];
    duration = json['duration'];
    type = json['type'];
    whyChooseMe = json["why_choose_me"];
    status = json['status'] != null 
        ? RequestStatus.values.firstWhere(
            (e) => e.backendValue == json['status'],
            orElse: () => RequestStatus.requested,
          )
        : null;
    provider =
    json['provider'] != null ? UserData.fromJson(json['provider']) : null;
    postJobData = json['post_detail'] != null
        ? PostJobData.fromJson(json['post_detail'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['post_request_id'] = postRequestId;
    map['provider_id'] = providerId;
    map['price'] = price;
    map['duration'] = duration;
    map['type'] = type;
    map['why_choose_me'] = whyChooseMe;
    if (status != null) {
      map['status'] = status?.backendValue;
    }
    if (provider != null) {
      map['provider'] = provider?.toJson();
    }
    if (postJobData != null) {
      map['post_detail'] = postJobData?.toJson();
    }
    return map;
  }
}
class EditJobModel {
  PostJobData? postJob;

  EditJobModel({
    this.postJob,
  });

  factory EditJobModel.fromJson(Map<String, dynamic> json) => EditJobModel(
    postJob: json["postJob"] == null ? null : PostJobData.fromJson(json["postJob"]),
  );

  Map<String, dynamic> toJson() => {
    "postJob": postJob?.toJson(),
  };
}
import 'package:booking_system_flutter/model/pagination_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';

class ProviderListResponse {
  Pagination? pagination;
  List<UserData>? providerList;

  ProviderListResponse({this.pagination, this.providerList});

  ProviderListResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      providerList = json['data'] != null
          ? (json['data'] as List).map((i) => UserData.fromJson(i)).toList()
          : null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    if (this.providerList != null) {
      data['data'] = this.providerList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

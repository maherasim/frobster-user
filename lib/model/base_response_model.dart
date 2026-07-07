class BaseResponseModel {
  String? message;
  bool? status;

  BaseResponseModel({this.message, this.status});

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    final raw = json['status'];
    bool? parsedStatus;
    if (raw is bool) {
      parsedStatus = raw;
    } else if (raw is int) {
      parsedStatus = raw == 1;
    } else if (raw is String) {
      parsedStatus = raw == '1' || raw.toLowerCase() == 'true';
    }
    return BaseResponseModel(
      message: json['message'] is String ? json['message'] as String : null,
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['status'] = this.status;
    return data;
  }
}

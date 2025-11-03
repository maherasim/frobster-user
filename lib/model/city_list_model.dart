class CityListResponse {
  int? id;
  String? name;
  int? stateId;
  bool isSelected;

  CityListResponse({this.id, this.name, this.stateId, this.isSelected = false});

  factory CityListResponse.fromJson(Map<String, dynamic> json) {
    return CityListResponse(
      id: json['id'],
      name: json['name'],
      stateId: json['state_id'],
      isSelected: json['is_selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['name'] = this.name;
    data['state_id'] = this.stateId;
    data['is_selected'] = this.isSelected;
    return data;
  }
}

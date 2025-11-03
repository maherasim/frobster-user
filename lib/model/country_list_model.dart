class CountryListResponse {
  String? code;
  String? currencyCode;
  String? currencyName;
  var dialCode;
  int? id;
  String? name;
  String? symbol;
  bool isSelected;

  CountryListResponse({
    this.code,
    this.currencyCode,
    this.currencyName,
    this.dialCode,
    this.id,
    this.name,
    this.symbol,
    this.isSelected = false,
  });

  factory CountryListResponse.fromJson(Map<String, dynamic> json) {
    return CountryListResponse(
      code: json['code'],
      currencyCode: json['currency_code'],
      currencyName: json['currency_name'],
      dialCode: json['dial_code'],
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      isSelected: json['is_selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['code'] = this.code;
    data['currency_code'] = this.currencyCode;
    data['currency_name'] = this.currencyName;
    data['dial_code'] = this.dialCode;
    data['id'] = this.id;
    data['name'] = this.name;
    data['symbol'] = this.symbol;
    data['is_selected'] = this.isSelected;
    return data;
  }
}

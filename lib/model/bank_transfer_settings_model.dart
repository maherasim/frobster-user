class BankTransferSettings {
  int? id;
  String? language;
  String? recipient;
  String? iban;
  String? bic;
  String? bankName;
  String? bankAddress;
  String? email;
  int? isActive;

  BankTransferSettings({
    this.id,
    this.language,
    this.recipient,
    this.iban,
    this.bic,
    this.bankName,
    this.bankAddress,
    this.email,
    this.isActive,
  });

  factory BankTransferSettings.fromJson(Map<String, dynamic> json) => BankTransferSettings(
        id: json['id'],
        language: json['language'],
        recipient: json['recipient'],
        iban: json['iban'],
        bic: json['bic'],
        bankName: json['bank_name'],
        bankAddress: json['bank_address'],
        email: json['email'],
        isActive: json['is_active'],
      );
}

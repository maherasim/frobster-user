// To parse this JSON data, do
//
//     final transactionRequestData = transactionRequestDataFromJson(jsonString);

import 'dart:convert';

List<TransactionRequestData> transactionRequestDataFromJson( str) => List<TransactionRequestData>.from(str.map((x) => TransactionRequestData.fromJson(x)));

String transactionRequestDataToJson(List<TransactionRequestData> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TransactionRequestData {
  int id;
  int userId;
  String amount;
  String status;
  String transactionType;
  DateTime createdAt;
  DateTime updatedAt;

  TransactionRequestData({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.transactionType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionRequestData.fromJson(Map<String, dynamic> json) => TransactionRequestData(
    id: json["id"],
    userId: json["user_id"],
    amount: json["amount"],
    status: json["status"],
    transactionType: json["transaction_type"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "amount": amount,
    "status": status,
    "transaction_type": transactionType,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

import 'dart:convert';

KnownProductModel knownProductFromJson(String str) =>
    KnownProductModel.fromJson(json.decode(str));

class KnownProductModel {
  final int statusCode;
  final List<KnownProductData> data;
  final String? message;

  KnownProductModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory KnownProductModel.fromJson(Map<String, dynamic> json) {
    return KnownProductModel(
      statusCode: json['statusCode'],
      data: json['data'] != null
          ? List<KnownProductData>.from(
              json['data'].map((x) => KnownProductData.fromJson(x)))
          : [],
      message: json['message'],
    );
  }
}

class KnownProductData {
  int productId;
  int? categoryId;
  String productName;
  int quantity;
  List<String?>? serialNumber;

  KnownProductData(
      {required this.productId,
      required this.categoryId,
      required this.productName,
      required this.quantity,
      this.serialNumber});

  factory KnownProductData.fromJson(Map<String, dynamic> json) {
    return KnownProductData(
      productId: json['productId'],
      categoryId: json['categoryId'] ?? 1,
      productName: json['productName'],
      quantity: json['quantity'] ?? 0,
      serialNumber: json['serialNumber'],
    );
  }
}

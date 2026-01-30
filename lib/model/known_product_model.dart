import 'dart:convert';

import 'package:patrol_system/encrypteddecrypted/encrypt_and_decrypt.dart';

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
      productId: json['ProductId'],
      categoryId: json['CategoryId'] ?? 1,
      productName: json['ProductName'],
      quantity: json['Quantity'] ?? 0,
      serialNumber: json['SerialNumber'],
    );
  }
}

Future<KnownProductModel> parseKnownProducts(dynamic apiResponse) async {
  final decoded = apiResponse is String ? json.decode(apiResponse) : apiResponse;
  if (decoded == null || decoded['data'] == null || decoded['data']['result'] == null) {
    return KnownProductModel(
      statusCode: decoded?['statusCode'] ?? 0,
      data: [],
      message: decoded?['message'],
    );
  }
  


  List<KnownProductData> list = [];
  final EncryptAndDecrypt encryptAndDecrypt = EncryptAndDecrypt();
  final result = decoded['data']['result'] as List;

  for (final item in result) {
    if (item is String) {
      final decrypted = await encryptAndDecrypt.decryption(payload: item);
      final map = json.decode(decrypted) as Map<String, dynamic>;
      list.add(KnownProductData.fromJson(map));
    } else if (item is Map<String, dynamic>) {
      list.add(KnownProductData.fromJson(item));
    }
  }

  return KnownProductModel(
    statusCode: decoded['statusCode'],
    data: list,
    message: decoded['message'],
  );
}


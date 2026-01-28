import 'dart:convert';

ProductCategoryModel productCategoryFromJson(String str) =>
    ProductCategoryModel.fromJson(json.decode(str));

class ProductCategoryModel {
  final int statusCode;
  final List<ProductCategoryData> data;
  final String message;

  ProductCategoryModel({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      statusCode: json['statusCode'],
      data: List<ProductCategoryData>.from(
          json['data'].map((x) => ProductCategoryData.fromJson(x))),
      message: json['message'] ?? "",
    );
  }
}

class ProductCategoryData {
  int productCategoryId;
  String name;

  ProductCategoryData({required this.productCategoryId, required this.name});

  factory ProductCategoryData.fromJson(Map<String, dynamic> json) {
    return ProductCategoryData(
        productCategoryId: json['productCategoryId'], name: json['name']);
  }
}

import 'dart:convert';

InspectionProductModel inspectionProductModelFromJson(String str) =>
    InspectionProductModel.fromJson(json.decode(str));

class InspectionProductModel {
  int statusCode;
  List<ProductDetail> data;
  String? message;

  InspectionProductModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory InspectionProductModel.fromJson(Map<String, dynamic> json) {
    return InspectionProductModel(
      statusCode: json['statusCode'],
      data: List<ProductDetail>.from(
          json['data'].map((x) => ProductDetail.fromJson(x))),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}

class ProductDetail {
  int productDetailsId;
  int inspectionId;
  int typeId;
  List<Product> products;
  int productId;
  String productName;
  int qty;
  String createdOn;
  int? categoryId;
  String notes;

  ProductDetail({
    required this.productDetailsId,
    required this.inspectionId,
    required this.typeId,
    required this.products,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.createdOn,
    this.categoryId,
    required this.notes,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      productDetailsId: json['ProductDetailsId'],
      inspectionId: json['InspectionId'],
      typeId: json['TypeId'],
      products:
          List<Product>.from(json['Products'].map((x) => Product.fromJson(x))),
      productId: json['ProductId'],
      productName: json['ProductName'],
      qty: json['Qty']??1,
      createdOn: json['CreatedOn'],
      categoryId: json['CategoryId'] ?? 0,
      notes: json['Notes'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productDetailsId': productDetailsId,
      'inspectionId': inspectionId,
      'typeId': typeId,
      'products': products.map((e) => e.toJson()).toList(),
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'createdOn': createdOn,
      'categoryId': categoryId,
      'notes': notes,
    };
  }
}

class Product {
  int productSerialNumberId;
  int productDetailsId;
  String serialNumber;
  int? size;

  Product({
    required this.productSerialNumberId,
    required this.productDetailsId,
    required this.serialNumber,
    this.size,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productSerialNumberId: json['ProductSerialNumberId'],
      productDetailsId: json['ProductDetailsId'],
      serialNumber: json['SerialNumber'],
      size: json['Size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productSerialNumberId': productSerialNumberId,
      'productDetailsId': productDetailsId,
      'serialNumber': serialNumber,
      'size': size,
    };
  }
}

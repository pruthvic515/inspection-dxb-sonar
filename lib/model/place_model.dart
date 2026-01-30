import 'dart:convert';

PlaceModel placesFromJson(String str) => PlaceModel.fromJson(json.decode(str));

class PlaceModel {
  final int statusCode;
  final List<Places> data;
  final String message;

  PlaceModel({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      statusCode: json['statusCode'],
      data: List<Places>.from(json['data'].map((x) => Places.fromJson(x))),
      message: json['message'],
    );
  }
}

class Places {
  int? entityID;
  // num businessTypeId;
  final String? logoUrl;
  final String? lastVisitedDate;
  final String entityName;
  LocationModel? location;
  final String categoryName;
  String classificationName;
  final int monthlyLimit;
  // final String openingTime;
  // final String closingTime;
  final String status;

  Places({
    this.entityID,
    // required this.businessTypeId,
    required this.logoUrl,
    required this.lastVisitedDate,
    required this.entityName,
    this.location,
    required this.categoryName,
    required this.classificationName,
    required this.monthlyLimit,
    // required this.openingTime,
    // required this.closingTime,
    required this.status,
  });

  factory Places.fromJson(Map<String, dynamic> json) {
    return Places(
      entityID: json['EntityId'],
      // businessTypeId: json['businessTypeId'],
      logoUrl: json['LogoUrl'] ?? "",
      lastVisitedDate: json['LastVisitedDate'],
      status: json['status'] ?? "",
      entityName: json['EntityName'],
      location: json['Location'] == null
          ? null
          : LocationModel.fromJson(json['Location']),
      categoryName: json['CategoryName'] ?? "",
      classificationName: json['ClassificationName'] ?? "",
      monthlyLimit: json['MonthlyLimit'] ?? 0,
      // openingTime: json['OpeningTime'] ?? "-",
      // closingTime: json['closingTime'] ?? "-",
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "entityId": entityID,
      // "businessTypeId": businessTypeId,
      "logoUrl": logoUrl,
      "lastVisitedDate": lastVisitedDate,
      "entityName": entityName,
      "location": location?.toJson(),
      "categoryName": categoryName,
      "classificationName": classificationName,
      "monthlyLimit": monthlyLimit,
      // "openingTime": openingTime,
      // "closingTime": closingTime,
      "status": status,
    };
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String name;
  final String category;
  final String address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.category,
    required this.address,
  });

  factory LocationModel.fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return LocationModel(
      latitude: double.parse(data['Latitude'] ?? '0'),
      longitude: double.parse(data['Longitude'] ?? '0'),
      name: data['Name'] ?? '',
      category: data['Category'] == null ? "" : data['Category'].toString(),
      address: data['Address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "lat": latitude,
    "lng": longitude,
    "name": name,
    "category": category,
    "address": address,
  };
}

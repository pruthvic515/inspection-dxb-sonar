import 'dart:convert';

import 'package:patrol_system/model/place_model.dart';
import 'package:patrol_system/utils/utils.dart';

import 'outlet_model.dart';

EntityDetailModel entityFromJson(String str) =>
    EntityDetailModel.fromJson(json.decode(str));

class EntityDetailModel {
  int? inspectionId;
  int? inspectorId;
  int? inspectionStatusId;
  int entityID;
  final String entityName;
  LocationModel? location;
  String classification;
  int? categoryId;
  final String categoryName;
  final String ownerShipType;
  final int monthlyLimit;
  final String openingTime;
  final String closingTime;
  String? logoUrl;
  String? licenseStatus;
  String? licenseNumber;
  DateTime licenseExpiryDate;
  String? managerName;
  String? managerEmailId;
  String? managerContactNumber;
  String? roleName;
  List<OutletData> outletModels;
  final String? lastVisitedDate;
  String? message;

  EntityDetailModel({
    this.inspectionId,
    this.inspectorId,
    this.inspectionStatusId,
    required this.entityID,
    required this.entityName,
    this.location,
    required this.classification,
    this.categoryId,
    required this.categoryName,
    required this.ownerShipType,
    required this.monthlyLimit,
    required this.openingTime,
    required this.closingTime,
    this.logoUrl,
    this.licenseStatus,
    this.licenseNumber,
    required this.licenseExpiryDate,
    this.managerName,
    this.managerEmailId,
    this.managerContactNumber,
    this.roleName,
    required this.outletModels,
    this.lastVisitedDate,
    this.message,
  });

  factory EntityDetailModel.fromJson(Map<String, dynamic> json) {
    return EntityDetailModel(
      inspectionId: json['inspectionId'],
      inspectorId: json['inspectorId'],
      inspectionStatusId: json['inspectionStatusId'],
      entityID: json['entityID'] ?? 0,
      entityName: json['entityName'] ?? "-",
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location']),
      classification: json['classification'] ?? "",
      categoryId: json["categoryId"] ?? 0,
      categoryName: json['categoryName'] ?? "",
      ownerShipType: json['ownerShipType'] ?? "",
      monthlyLimit: json['monthlyLimit'] ?? 0,
      openingTime: json['openingTime'] ?? "-",
      closingTime: json['closingTime'] ?? "-",
      logoUrl: json['logoUrl'],
      licenseStatus: json['licenseStatus'] ?? "-",
      licenseNumber: json['licenseNumber'] ?? "",
      licenseExpiryDate: json['licenseExpiryDate'] == null
          ? Utils().getCurrentGSTTime()
          : DateTime.parse(json['licenseExpiryDate']),
      managerName: json['managerName'] ?? "-",
      managerEmailId: json['managerEmailId'] ?? "-",
      managerContactNumber: json['managerContactNumber'] ?? "-",
      roleName: json['roleName'] ?? "-",
      outletModels: json["outletModels"] == null
          ? []
          : List<OutletData>.from(
              json['outletModels'].map((x) => OutletData.fromJson(x))),
      lastVisitedDate: json['lastVisitedDate'],
      message: json['message'] ?? "-",
    );
  }
}

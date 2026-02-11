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
      inspectionId: json['InspectionId'] ?? 0,
      inspectorId: json['InspectorId'],
      inspectionStatusId: json['InspectionStatusId'],
      entityID: json['EntityID'] ?? 0,
      entityName: json['EntityName'] ?? "-",
      location: json['Location'] == null
          ? null
          : LocationModel.fromJson(json['Location']),
      classification: json['Classification'] ?? "",
      categoryId: json["CategoryId"] ?? 0,
      categoryName: json['CategoryName'] ?? "",
      ownerShipType: json['OwnerShipType'] ?? "",
      monthlyLimit: json['MonthlyLimit'] ?? 0,
      openingTime: json['OpeningTime'] ?? "-",
      closingTime: json['ClosingTime'] ?? "-",
      logoUrl: json['LogoUrl'],
      licenseStatus: json['LicenseStatus'] ?? "-",
      licenseNumber: json['LicenseNumber'] ?? "",
      licenseExpiryDate: json['LicenseExpiryDate'] == null
          ? Utils().getCurrentGSTTime()
          : DateTime.parse(json['LicenseExpiryDate']),
      managerName: json['ManagerName'] ?? "-",
      managerEmailId: json['ManagerEmailId'] ?? "-",
      managerContactNumber: json['ManagerContactNumber'] ?? "-",
      roleName: json['RoleName'] ?? "-",
      outletModels: json["OutletModels"] == null
          ? []
          : List<OutletData>.from(
              json['OutletModels'].map((x) => OutletData.fromJson(x))),
      lastVisitedDate: json['LastVisitedDate'],
      message: json['Message'] ?? "-",
    );
  }
}

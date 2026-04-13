import 'dart:convert';

RepresentativeModel representativeFromJson(String str) =>
    RepresentativeModel.fromJson(json.decode(str));

class RepresentativeModel {
  final int statusCode;
  final List<RepresentativeData> data;
  final String? message;

  RepresentativeModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory RepresentativeModel.fromJson(Map<String, dynamic> json) {
    return RepresentativeModel(
      statusCode: json['statusCode'],
      data: List<RepresentativeData>.from(
          json['data'].map((x) => RepresentativeData.fromJson(x))),
      message: json['message'],
    );
  }
}

class RepresentativeData {
  int entityRepresentativeId;
  int inspectionId;
  int typeId;
  String name;
  String emiratesId;
  String phoneNo;
  int roleId;
  String? roleName;
  String? notes;
  bool hasSignature;

  RepresentativeData(
      {required this.entityRepresentativeId,
      required this.inspectionId,
      required this.typeId,
      required this.name,
      required this.emiratesId,
      required this.phoneNo,
      required this.roleId,
      this.roleName,
      this.notes,
      this.hasSignature = false});

  static bool _signatureFromJson(Map<String, dynamic> json) {
    if (json['HasSignature'] == true || json['IsSigned'] == true) {
      return true;
    }
    final url = json['SignatureUrl'] ?? json['signatureUrl'];
    if (url is String && url.trim().isNotEmpty) return true;
    return false;
  }

  factory RepresentativeData.fromJson(Map<String, dynamic> json) {
    return RepresentativeData(
      entityRepresentativeId: json['EntityRepresentativeId'],
      inspectionId: json['InspectionId'],
      typeId: json['TypeId'],
      name: json['Name'],
      emiratesId: json['EmiratesId'],
      phoneNo: json['PhoneNo'],
      roleId: json['RoleId'],
      roleName: json['RoleName'] ?? "-",
      notes: json['Notes'] ?? "-",
      hasSignature: _signatureFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityRepresentativeId': entityRepresentativeId,
      'inspectionId': inspectionId,
      'typeId': typeId,
      'name': name,
      'emiratesId': emiratesId,
      'phoneNo': phoneNo,
      'roleId': roleId,
      'roleName': roleName,
      'notes': notes,
    };
  }
}

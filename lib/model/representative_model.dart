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

  RepresentativeData(
      {required this.entityRepresentativeId,
      required this.inspectionId,
      required this.typeId,
      required this.name,
      required this.emiratesId,
      required this.phoneNo,
      required this.roleId,
      this.roleName,
      this.notes});

  factory RepresentativeData.fromJson(Map<String, dynamic> json) {
    return RepresentativeData(
      entityRepresentativeId: json['entityRepresentativeId'],
      inspectionId: json['inspectionId'],
      typeId: json['typeId'],
      name: json['name'],
      emiratesId: json['emiratesId'],
      phoneNo: json['phoneNo'],
      roleId: json['roleId'],
      roleName: json['roleName'] ?? "-",
      notes: json['notes'] ?? "-",
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

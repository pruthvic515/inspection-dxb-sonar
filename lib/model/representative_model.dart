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
    final raw = json['data'];
    final List<dynamic> rows;
    if (raw == null) {
      rows = [];
    } else if (raw is List) {
      rows = raw;
    } else {
      rows = [raw];
    }
    return RepresentativeModel(
      statusCode: _asInt(json['statusCode']),
      data: List<RepresentativeData>.from(
        rows.map(
          (x) => RepresentativeData.fromJson(
            Map<String, dynamic>.from(x as Map),
          ),

        ),
      ),
      message: json['message']?.toString(),
    );
  }
}


int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
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

  static bool _truthy(dynamic v) {
    if (v == true) return true;
    if (v == 1 || v == '1') return true;
    if (v is String && v.trim().toLowerCase() == 'true') return true;
    return false;
  }

  static bool _signatureFromJson(Map<String, dynamic> json) {
    if (_truthy(json['HasSignature']) ||
        _truthy(json['hasSignature']) ||
        _truthy(json['IsSigned']) ||
        _truthy(json['isSigned'])) {
      return true;
    }
    final url = json['SignatureUrl'] ?? json['signatureUrl'];
    if (url is String && url.trim().isNotEmpty) return true;
    final sig = json['Signature'];
    if (sig is Map && sig.isNotEmpty) return true;
    if (sig is String && sig.trim().isNotEmpty) return true;
    return false;
  }

  factory RepresentativeData.fromJson(Map<String, dynamic> json) {
    return RepresentativeData(
      entityRepresentativeId: _asInt(json['EntityRepresentativeId']),
      inspectionId: _asInt(json['InspectionId']),
      typeId: _asInt(json['TypeId']),
      name: json['Name']?.toString() ?? '',
      emiratesId: json['EmiratesId']?.toString() ?? '',
      phoneNo: json['PhoneNo']?.toString() ?? '',
      roleId: _asInt(json['RoleId']),
      roleName: json['RoleName']?.toString() ?? "-",
      notes: json['Notes']?.toString() ?? "-",
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

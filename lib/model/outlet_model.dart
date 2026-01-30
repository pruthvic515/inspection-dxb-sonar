import 'dart:convert';

OutletModel outletFromJson(String str) =>
    OutletModel.fromJson(json.decode(str));

class OutletModel {
  final int statusCode;
  final List<OutletData> data;
  final String? message;

  OutletModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      statusCode: json['statusCode'],
      data: List<OutletData>.from(
          json['data'].map((x) => OutletData.fromJson(x))),
      message: json['message'],
    );
  }
}

class OutletData {
  int outletId;
  String outletName;
  int ownerShipTypeId;
  int serviceTypeId;
  String ownerShipType;
  String serviceType;
  String? managerName;
  String? emiratesId;
  String? contactNumber;
  int? outletStatusId;
  String? outletStatus;
  int? outletTypeId;
  String? outletType;
  String? notes;
  bool newAdded;
  int inspectionStatusId;
  int inspectionId;
  int inspectorId;

  OutletData({
    required this.outletId,
    required this.outletName,
    required this.ownerShipTypeId,
    required this.serviceTypeId,
    required this.ownerShipType,
    required this.serviceType,
    this.managerName,
    this.emiratesId,
    this.contactNumber,
    this.outletStatusId,
    this.outletStatus,
    this.outletTypeId,
    this.outletType,
    this.notes,
    required this.newAdded,
    required this.inspectionStatusId,
    required this.inspectionId,
    required this.inspectorId,
  });

  factory OutletData.fromJson(Map<String, dynamic> json) {
    return OutletData(
        outletId: json['OutletId'] ?? json["NewOutletId"] ?? 0,
        outletName: json['OutletName'] ?? "N/A",
        ownerShipTypeId: json['ownerShipTypeId'] ?? 1,
        serviceTypeId: json['ServiceTypeId'] ?? 1,
        ownerShipType: json['OwnerShipType'] ?? "",
        serviceType: json['ServiceType'] ?? "",
        managerName: json['<m>anagerName'] ?? "-",
        emiratesId: json['EmiratesId'] ?? "-",
        contactNumber: json['ContactNumber'] ?? "-",
        outletStatusId: json['OutletStatusId'] ?? 0,
        outletStatus: json['OutletStatus'],
        outletTypeId: json['OutletTypeId'] ?? 0,
        outletType: json['OutletType'] ?? "-",
        notes: json['Notes'] ?? "-",
        newAdded: json['NewAdded'] ?? false,
        inspectionStatusId: json['InspectionStatusId'] ?? 0,
        inspectionId: json['InspectionId'] ?? 0,
        inspectorId: json["InspectorId"] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'outletName': outletName,
      'ownerShipTypeId': ownerShipTypeId,
      'serviceTypeId': serviceTypeId,
      'ownerShipType': ownerShipType,
      'serviceType': serviceType,
      'managerName': managerName,
      'emiratesId': emiratesId,
      'contactNumber': contactNumber,
      'outletStatusId': outletStatusId,
      'outletStatus': outletStatus,
      'outletTypeId': outletTypeId,
      'outletType': outletType,
      'notes': notes,
      'newAdded': newAdded,
      'inspectionStatusId': inspectionStatusId,
      'inspectionId': inspectionId,
      'inspectorId': inspectorId,
    };
  }

  static Map<String, dynamic> toMap(OutletData data) => {
        'outletId': data.outletId,
        'outletName': data.outletName,
        'ownerShipTypeId': data.ownerShipTypeId,
        'serviceTypeId': data.serviceTypeId,
        'ownerShipType': data.ownerShipType,
        'serviceType': data.serviceType,
        'managerName': data.managerName,
        'emiratesId': data.emiratesId,
        'contactNumber': data.contactNumber,
        'outletStatusId': data.outletStatusId,
        'outletStatus': data.outletStatus,
        'outletTypeId': data.outletTypeId,
        'outletType': data.outletType,
        'notes': data.notes,
        'newAdded': data.newAdded,
        'inspectionStatusId': data.inspectionStatusId,
        'inspectionId': data.inspectionId,
      };

  static String encode(List<OutletData> musics) => json.encode(
        musics
            .map<Map<String, dynamic>>((music) => OutletData.toMap(music))
            .toList(),
      );

  static List<OutletData> decode(String musics) =>
      (json.decode(musics) as List<dynamic>)
          .map<OutletData>((item) => OutletData.fromJson(item))
          .toList();
}

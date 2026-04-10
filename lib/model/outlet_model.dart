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
  String? Floor;
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
    this.Floor,
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
        Floor: json['Floor'] ?? "-",
        notes: json['Notes'] ?? "-",
        newAdded: json['NewAdded'] ?? false,
        inspectionStatusId: json['InspectionStatusId'] ?? 0,
        inspectionId: json['InspectionId'] ?? 0,
        inspectorId: json["InspectorId"] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'OutletName': outletName,
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
      'Floor': Floor,
      'inspectorId': inspectorId,
    };
  }

  static Map<String, dynamic> toMap(OutletData data) => {
        'OutletId': data.outletId,
        'OutletName': data.outletName,
        'OwnerShipTypeId': data.ownerShipTypeId,
        'ServiceTypeId': data.serviceTypeId,
        'OwnerShipType': data.ownerShipType,
        'ServiceType': data.serviceType,
        'ManagerName': data.managerName,
        'EmiratesId': data.emiratesId,
        'ContactNumber': data.contactNumber,
        'OutletStatusId': data.outletStatusId,
        'OutletStatus': data.outletStatus,
        'OutletTypeId': data.outletTypeId,
        'OutletType': data.outletType,
        'Notes': data.notes,
        'NewAdded': data.newAdded,
        'InspectionStatusId': data.inspectionStatusId,
        'InspectionId': data.inspectionId,
        'Floor': data.Floor,
        'InspectorId': data.inspectorId,
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

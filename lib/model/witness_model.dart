import 'dart:convert';

WitnessModel witnessFromJson(String str) =>
    WitnessModel.fromJson(json.decode(str));

class WitnessModel {
  final int statusCode;
  final List<WitnessData> data;
  final String? message;

  WitnessModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory WitnessModel.fromJson(Map<String, dynamic> json) {
    return WitnessModel(
      statusCode: json['statusCode'],
      data: List<WitnessData>.from(
          json['data'].map((x) => WitnessData.fromJson(x))),
      message: json['message'],
    );
  }
}

class WitnessData {
  int agentEmployeeId;
  int agentId;
  int roldId;
  String roleName;
  String agentName;
  String emiratesId;
  String phoneNo;
  String emailId;
  bool isActive;

  WitnessData(
      {required this.agentEmployeeId,
      required this.agentId,
      required this.roldId,
      required this.roleName,
      required this.agentName,
      required this.emiratesId,
      required this.phoneNo,
      required this.emailId,
      required this.isActive});

  factory WitnessData.fromJson(Map<String, dynamic> json) {
    return WitnessData(
      agentEmployeeId: json['agentEmployeeId'],
      agentId: json['agentId'],
      roldId: json['roldId']??0,
      roleName: json['roleName'],
      agentName: json['agentName'],
      emiratesId: json['emiratesId'],
      phoneNo: json['phoneNo'],
      emailId: json['emailId'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentEmployeeId': agentEmployeeId,
      'agentId': agentId,
      'roldId': roldId,
      'agentName': agentName,
      'emiratesId': emiratesId,
      'phoneNo': phoneNo,
      'emailId': emailId,
      'isActive': isActive,
    };
  }
}

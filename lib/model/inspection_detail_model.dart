import 'dart:convert';
import 'package:patrol_system/model/attachments.dart';
import 'package:patrol_system/model/representative_model.dart';
import 'package:patrol_system/model/witness_model.dart';
import 'inspection_product_model.dart';

InspectionDetailModel detailFromJson(String str) =>
    InspectionDetailModel.fromJson(json.decode(str));

class InspectionDetailModel {
  int statusCode;
  InspectionData? data;
  String message;

  InspectionDetailModel({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory InspectionDetailModel.fromJson(Map<String, dynamic> json) {
    return InspectionDetailModel(
      statusCode: json['statusCode'],
      data: json['data'] != null ? InspectionData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class InspectionData {
  InspectionDetails inspectionDetails;
  InspectorAndAgentEmployee inspectorAndAgentEmployee;
  List<ProductDetail> productDetailModels;
  List<AttachmentData> attachments;
  List<RepresentativeData> entityRepresentatives;
  NotesModel notes;

  InspectionData({
    required this.inspectionDetails,
    required this.inspectorAndAgentEmployee,
    required this.productDetailModels,
    required this.attachments,
    required this.entityRepresentatives,
    required this.notes,
  });

  factory InspectionData.fromJson(Map<String, dynamic> json) {
    return InspectionData(
      inspectionDetails: InspectionDetails.fromJson(json['inspectiondetails']),
      inspectorAndAgentEmployee:
          InspectorAndAgentEmployee.fromJson(json['InspectorAndAgentEmployee']),
      productDetailModels: List<ProductDetail>.from(
          json['productDetailModels'].map((x) => ProductDetail.fromJson(x))),
      attachments: List<AttachmentData>.from(
          json['attachments'].map((x) => AttachmentData.fromJson(x))),
      entityRepresentatives: List<RepresentativeData>.from(
          json['entityRepresentatives']
              .map((x) => RepresentativeData.fromJson(x))),
      notes: NotesModel.fromJson(json['notes']),
    );
  }
}


class NotesModel {
  String? taskNotes;
  String? inspectionNotes;
  String? finalNotes;

  NotesModel({this.taskNotes, this.inspectionNotes, this.finalNotes});

  factory NotesModel.fromJson(Map<String, dynamic> json) {
    return NotesModel(
      taskNotes: json['TaskNotes'] ?? "-",
      inspectionNotes: json['InspectionNotes'] ?? "-",
      finalNotes: json['FinalNotes'] ?? "",
    );
  }
}

class InspectionDetails {
  int taskId;
  String taskName;
  String? entityName;
  String outletName;
  String createdOn;

  InspectionDetails({
    required this.taskId,
    required this.taskName,
    this.entityName,
    required this.outletName,
    required this.createdOn,
  });

  factory InspectionDetails.fromJson(Map<String, dynamic> json) {
    return InspectionDetails(
      taskId: json['TaskId'],
      taskName: json['TaskName'],
      entityName: json['EntityName'] ?? "-",
      outletName: json['OutletName'] ?? "-",
      createdOn: json['Createdon'],
    );
  }
}


class InspectorAndAgentEmployee {
  List<WitnessData> agentEmployeeModels;

  InspectorAndAgentEmployee({
    required this.agentEmployeeModels,
  });

  factory InspectorAndAgentEmployee.fromJson(Map<String, dynamic> json) {
    return InspectorAndAgentEmployee(
      agentEmployeeModels: json['agentEmployeeModels'] == null
          ? []
          : List<WitnessData>.from(
              json['agentEmployeeModels'].map((x) => WitnessData.fromJson(x))),
    );
  }
}

class DepartmentUserModel {
  int departmentUserId;
  String name;
  String userName;
  String? password;
  int designationId;
  int designation;
  String mobileNumber;
  String badgeNumber;
  String mpin;
  String fingerPrint;
  String registeredOn;
  String lastLogin;
  String modifiedOn;
  String mobileMacId;
  bool isActive;
  String currentLocation;

  DepartmentUserModel({
    required this.departmentUserId,
    required this.name,
    required this.userName,
    this.password,
    required this.designationId,
    required this.designation,
    required this.mobileNumber,
    required this.badgeNumber,
    required this.mpin,
    required this.fingerPrint,
    required this.registeredOn,
    required this.lastLogin,
    required this.modifiedOn,
    required this.mobileMacId,
    required this.isActive,
    required this.currentLocation,
  });

  factory DepartmentUserModel.fromJson(Map<String, dynamic> json) {
    return DepartmentUserModel(
      departmentUserId: json['departmentUserId'],
      name: json['name'],
      userName: json['userName'],
      password: json['password'],
      designationId: json['designationId'],
      designation: json['designation'],
      mobileNumber: json['mobileNumber'],
      badgeNumber: json['badgeNumber'],
      mpin: json['mpin'],
      fingerPrint: json['fingerPrint'],
      registeredOn: json['registeredOn'],
      lastLogin: json['lastLogin'],
      modifiedOn: json['modifiedOn'],
      mobileMacId: json['mobileMacId'],
      isActive: json['isActive'],
      currentLocation: json['currentLocation'],
    );
  }
}

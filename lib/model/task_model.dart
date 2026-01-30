import 'dart:convert';
import 'package:patrol_system/model/place_model.dart';

TaskModel tasksFromJson(String str) => TaskModel.fromJson(json.decode(str));

class TaskModel {
  final int statusCode;
  final List<Tasks> data;
  final String? message;

  TaskModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      statusCode: json['statusCode'] ?? 0,
      data: json['data'] != null && json['data'] is List
          ? List<Tasks>.from(json['data'].map((x) => Tasks.fromJson(x)))
          : <Tasks>[],
      message: json['message'],
    );
  }
}

class Tasks {
  int mainTaskId;
  int inspectionTaskId;
  int inspectionId;
  int inspectionType;
  String taskName;
  int? entityID;
  final String entityName;
  LocationModel? location;
  DateTime startDate;
  DateTime endDate;
  DateTime createdOn;
  int inspectorStatusId;
  int statusId;
  int outletId;
  int newOutletId;
  int taskType;
  String outletName;
  bool primary;
  num createdBy;
  num inspectorId;
  num agentUserId;
  String notes;
  DateTime modifiedOn;
  num modifiedBy;
  String categoryName;
  bool isAgentEmployees;

  Tasks({
    required this.mainTaskId,
    required this.inspectionTaskId,
    required this.taskName,
    required this.inspectionId,
    required this.inspectionType,
    this.entityID,
    required this.entityName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.createdOn,
    required this.inspectorStatusId,
    required this.statusId,
    required this.outletId,
    required this.newOutletId,
    required this.outletName,
    required this.primary,
    required this.createdBy,
    required this.inspectorId,
    required this.agentUserId,
    required this.notes,
    required this.modifiedOn,
    required this.modifiedBy,
    required this.categoryName,
    required this.taskType,
    required this.isAgentEmployees,
  });

  factory Tasks.fromJson(Map<String, dynamic> json) {
    final locationData = json['Location'];
    final location = _parseLocation(locationData);

    return Tasks(
      mainTaskId: json['MainTaskId'] ?? 0,
      taskType: json['TaskType'] ?? 0,
      inspectionTaskId: json['InspectionTaskId']??0,
      inspectionId: json['inspectionId'] ?? 0,
      inspectionType: json['inspection_type'] ?? 0,
      taskName: json['TaskName']?.toString() ?? "",
      entityID: json['EntityId'],
      entityName: json['EntityName']?.toString() ?? "",
      location: location,
      startDate: json['StartDate'] == null || json['StartDate'] is! String
          ? DateTime.now()
          : DateTime.parse(json['StartDate'] as String),
      endDate: json['EndDate'] == null || json['EndDate'] is! String
          ? DateTime.now()
          : DateTime.parse(json['EndDate'] as String),
      createdOn: json['CreatedOn'] == null || json['CreatedOn'] is! String
          ? DateTime.now()
          : DateTime.parse(json['CreatedOn'] as String),
      inspectorStatusId: json['InspectorStatusId'] ?? 1,
      statusId: json['StatusId'] ?? 0,
      outletId: json['OutletId'] ?? 0,
      newOutletId: json['NewOutletId'] ?? 0,
      outletName: json['OutletName']?.toString() ?? "",
      primary: json['Primary'] ?? false,
      createdBy: json['CreatedBy'] ?? 0,
      inspectorId: json['InspectorId'] ?? 0,
      agentUserId: json['agentUserId'] ?? 0,
      notes: json['Notes'] ?? "",
      modifiedOn: json['ModifiedOn'] == null || json['ModifiedOn'] is! String
          ? DateTime.now()
          : DateTime.parse(json['ModifiedOn'] as String),
      modifiedBy: json['ModifiedBy'] ?? 0,
        categoryName: json['CategoryName']?.toString() ?? "",
      isAgentEmployees: json['IsAgentEmployees'] ?? false,
    );
  }

  static LocationModel? _parseLocation(dynamic locationData) {
    if (locationData == null) {
      return null;
    }
    if (locationData == "") {
      return null;
    }
    return LocationModel.fromJson(locationData);
  }
}


TaskResponse taskResponseFromJson(String str) => TaskResponse.fromJson(json.decode(str));


class TaskResponse {
  final List<Tasks> tasks;
  final int totalCount;

  TaskResponse({
    required this.tasks,
    required this.totalCount,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      tasks: List<Tasks>.from(
        json["data"]["PaginationData"].map((x) => Tasks.fromJson(x)),
      ),
      totalCount: json["data"]["TotalCount"] ?? 0,
    );
  }
}

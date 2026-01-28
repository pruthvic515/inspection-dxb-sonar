import 'dart:convert';

PatrolVisitModel detailFromJson(String str) =>
    PatrolVisitModel.fromJson(json.decode(str));

class PatrolVisitModel {
  int statusCode;
  List<PatrolVisitData> data;
  String message;

  PatrolVisitModel({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory PatrolVisitModel.fromJson(Map<String, dynamic> json) {
    return PatrolVisitModel(
      statusCode: json['statusCode'],
      data: List<PatrolVisitData>.from(
          json['data'].map((x) => PatrolVisitData.fromJson(x))),
      message: json['message'],
    );
  }
}

class PatrolVisitData {
  int patrolId;
  int entityId;
  String entityName;
  String createdOn;
  int createdBy;
  int rating;
  String comments;

  PatrolVisitData({
    required this.patrolId,
    required this.entityId,
    required this.entityName,
    required this.createdOn,
    required this.createdBy,
    required this.rating,
    required this.comments,
  });

  factory PatrolVisitData.fromJson(Map<String, dynamic> json) {
    return PatrolVisitData(
      patrolId: json['PatrolId'],
      entityId: json['EntityId'],
      entityName: json['EntityName'],
      createdOn: json['CreatedOn'],
      createdBy: json['CreatedBy'],
      rating: json['Rating'],
      comments: json['Comments'],
    );
  }
}

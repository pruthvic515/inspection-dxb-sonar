import 'dart:convert';

SearchEntityModel allEntityFromJson(String str) =>
    SearchEntityModel.fromJson(json.decode(str));

class SearchEntityModel {
  int statusCode;

  List<SearchEntityData> data;
  String? message;

  SearchEntityModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory SearchEntityModel.fromJson(Map<String, dynamic> json) {
    return SearchEntityModel(
      data: List<SearchEntityData>.from(
          json['data'].map((x) => SearchEntityData.fromJson(x))),
      message: json['message'] ?? "-",
      statusCode: json['statusCode'],
    );
  }
}

class SearchEntityData {
  int entityId;
  final String entityName;

  SearchEntityData({
    required this.entityId,
    required this.entityName,
  });

  factory SearchEntityData.fromJson(Map<String, dynamic> json) {
    return SearchEntityData(
      entityId: json['entityId'] ?? 0,
      entityName: json['entityName'] ?? "-",
    );
  }
}

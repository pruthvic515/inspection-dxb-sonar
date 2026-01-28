import 'dart:convert';

AreaModel areaFromJson(String str) => AreaModel.fromJson(json.decode(str));

class AreaModel {
  final int statusCode;
  final List<AreaData> data;
  final String message;

  AreaModel({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      statusCode: json['statusCode'],
      data: List<AreaData>.from(json['data'].map((x) => AreaData.fromJson(x))),
      message: json['message'],
    );
  }
}

class AreaData {
  final int id;
  String text;

  AreaData({required this.id, required this.text});

  factory AreaData.fromJson(Map<String, dynamic> json) {
    return AreaData(
      id: json['id'],
      text: json['text'],
    );
  }
}

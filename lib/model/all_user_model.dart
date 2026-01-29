import 'dart:convert';

AllUserModel allUsersFromJson(String str) =>
    AllUserModel.fromJson(json.decode(str));

class AllUserModel {
  int statusCode = 0;
  List<AllUserData> data;
  String? message;

  AllUserModel({
    required this.statusCode,
    required this.data,
    this.message,
  });

  factory AllUserModel.fromJson(Map<String, dynamic> json) {
    return AllUserModel(
      data: List<AllUserData>.from(
          json['data'].map((x) => AllUserData.fromJson(x))),
      message: json['message'] ?? "-",
      statusCode: json['statusCode'],
    );
  }
}

class AllUserData {
  int departmentUserId;
  final String name;
  String userName;

  AllUserData({
    required this.departmentUserId,
    required this.name,
    required this.userName,
  });

  factory AllUserData.fromJson(Map<String, dynamic> json) {
    return AllUserData(
        departmentUserId: json['DepartmentUserId'] ?? 0,
        name: json['Name'] ?? "-",
        userName: json['UserName'] ?? "-");
  }
}

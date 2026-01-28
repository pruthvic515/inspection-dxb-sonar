import 'dart:convert';

ProfileModel profileFromJson(String str) =>
    ProfileModel.fromJson(json.decode(str));

class ProfileModel {
  int statusCode;
  ProfileData? data;
  String message;

  ProfileModel({
    required this.statusCode,
    this.data,
    required this.message,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      statusCode: json['statusCode'],
      data: json['data'] != null ? ProfileData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class ProfileData {
  int departmentUserMasterId;
  String name;
  String userName;
  dynamic password;
  int designationId;
//  num designation;
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
  String accessToken;

  ProfileData({
    required this.departmentUserMasterId,
    required this.name,
    required this.userName,
    this.password,
    required this.designationId,
    //required this.designation,
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
    required this.accessToken,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      departmentUserMasterId: json['DepartmentUserId'],
      name: json['Name'],
      userName: json['UserName'],
      password: json['Password'],
      designationId: json['DesignationId'],
     // designation: json['designation'],
      mobileNumber: json['MobileNumber'],
      badgeNumber: json['BadgeNumber'],
      mpin: json['Mpin'],
      fingerPrint: json['FingerPrint'],
      registeredOn: json['RegisteredOn'],
      lastLogin: json['LastLogin']??"",
      modifiedOn: json['ModifiedOn']??"",
      mobileMacId: json['MobileMacId']??"",
      isActive: json['IsActive'],
      currentLocation: json['CurrentLocation']??"",
      accessToken: json['AccessToken']??"",
    );
  }
}

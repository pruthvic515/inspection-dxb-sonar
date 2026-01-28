import 'dart:convert';

Attachments attachmentsFromJson(String str) =>
    Attachments.fromJson(json.decode(str));

class Attachments {
  int statusCode;
  List<AttachmentData> data;
  String message;

  Attachments({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  factory Attachments.fromJson(Map<String, dynamic> json) {
    return Attachments(
      statusCode: json['statusCode'],
      data: List<AttachmentData>.from(
          json['data'].map((x) => AttachmentData.fromJson(x))),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['data'] = this.data.map((attachment) => attachment.toJson()).toList();
    data['message'] = message;
    return data;
  }
}

class AttachmentData {
  int? inspectionDocumentId;
  int inspectionId;
  String documentExtension;
  String documentContentType;
  String documentFileName;
  String documentUrl;
  bool? isDeleted;
  DateTime createdOn;
  String? thumbnail;
  dynamic
      file; // This can be of any type, adjust it based on the actual data type

  AttachmentData({
    this.inspectionDocumentId,
    required this.inspectionId,
    required this.documentExtension,
    required this.documentContentType,
    required this.documentFileName,
    required this.documentUrl,
    this.isDeleted,
    required this.createdOn,
    this.file,
    this.thumbnail,
  });

  factory AttachmentData.fromJson(Map<String, dynamic> json) {
    return AttachmentData(
      inspectionDocumentId: json['inspectionDocumentId'],
      inspectionId: json['inspectionId'],
      documentExtension: json['documentExtension'],
      documentContentType: json['documentContentType'],
      documentFileName: json['documentFileName'],
      documentUrl: json['documentUrl'],
      isDeleted: json['isDeleted'],
      createdOn: DateTime.parse(json['createdOn']),
      file: json['file'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['inspectionDocumentId'] = inspectionDocumentId;
    data['inspectionId'] = inspectionId;
    data['documentExtension'] = documentExtension;
    data['documentContentType'] = documentContentType;
    data['documentFileName'] = documentFileName;
    data['documentUrl'] = documentUrl;
    data['isDeleted'] = isDeleted;
    data['createdOn'] = createdOn.toIso8601String();
    data['file'] = file;
    data['thumbnail'] = thumbnail;
    return data;
  }
}

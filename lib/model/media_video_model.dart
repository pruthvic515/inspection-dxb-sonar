import 'dart:io';

class VideoModel {
  final File file;
  String? thumbnail;

  VideoModel({required this.file, this.thumbnail});

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      file: json['file'],
      thumbnail: json['thumbnail'],
    );
  }
}

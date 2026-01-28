import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OpenPdfUtil {
  Future<File> loadPdfFromNetwork(String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    return _storeFile(url, bytes);
  }

  Future<File> _storeFile(String url, List<int> bytes) async {
    final filename = path.basename(url);

    final dir = await getExternalStorageDirectory();
    final downloadsDir = Directory('${dir!.path}');

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    final file = File('${downloadsDir.path}/$filename');

    await file.writeAsBytes(bytes, flush: true);

    if (kDebugMode) {
      print('PDF saved at: $file');
    }

    return file;
  }
}

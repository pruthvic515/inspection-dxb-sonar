import 'package:flutter/foundation.dart';

class LogPrint {
  void log(Object? data) {
    if (kDebugMode) {
      print(data);
    }
  }
}

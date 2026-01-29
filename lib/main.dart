import 'dart:isolate';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/pages/splash.dart';
import 'package:patrol_system/utils/api_service_dio.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/firebase_options.dart';
import 'package:patrol_system/utils/store_user_data.dart';

import 'notification_services/local_notification.dart';

// user
Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.data.toString());
  print(message.notification!.title);

  LocalNotificationService.createanddisplaynotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));


  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    final List<dynamic> errorAndStacktrace = pair;
    await FirebaseCrashlytics.instance
        .recordError(errorAndStacktrace.first, errorAndStacktrace.last);
  }).sendPort);
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
  await StoreUserData.init();
  ApiServiceDio.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
/*Dxb00101
Test@123

ae@gmail.com
Test@123
*/
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      supportedLocales: const [
        Locale("en"), // OR Locale('ar', 'AE') OR Other RTL locales
      ],
      locale: const Locale("en"),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: AppTheme.colorPrimary, primarySwatch: Colors.green),
      home: const Scaffold(
        body: Splash(),
      ),
    );
  }
}

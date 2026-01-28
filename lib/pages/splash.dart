import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/notification_services/local_notification.dart';
import 'package:patrol_system/pages/version_two/home_screen.dart';
import 'package:patrol_system/pages/welcome_page.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/log_print.dart';

import '../dialog/version_dialog.dart';
import '../utils/api.dart';
import '../utils/store_user_data.dart';
import '../utils/utils.dart';
import 'package:http/http.dart' as http;

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  var storeUserData = StoreUserData();

  @override
  void initState() {
    LogPrint().log("baseurl : $baseUrl");
    LogPrint().log("USER_TOKEN : ${storeUserData.getString(USER_TOKEN).toString()}");
    // todo version code manage version: 1.0.0+9
    // todo version name 1.0.0 and version code 8
    // todo latest version code is 1.0.9
    // todo latest version code is 1.0.10 PRO
    // todo latest version code is 1.0.9 UAT
    storeUserData.setString(LATEST_APP_VERSION, "1.0.9");
    Utils().hasNetwork(context, setState).then((value) {
      if (value) {
        Future.delayed(const Duration(milliseconds: 1500), () async {
          try {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            print("fcm : $fcmToken");
            StoreUserData().setString(USER_FCM, fcmToken!);
            FirebaseMessaging.instance.getInitialMessage().then(
              (message) {
                print("FirebaseMessaging.instance.getInitialMessage");
                if (message != null) {
                  print("New Notification");
                }
              },
            );
            // 2. This method only call when App in forground it mean app must be opened
            FirebaseMessaging.onMessage.listen(
              (message) {
                print("FirebaseMessaging.onMessage.listen");
                if (message.notification != null) {
                  print(message.notification!.title);
                  print(message.notification!.body);
                  print("message.data11 ${message.data}");
                  LocalNotificationService.createanddisplaynotification(
                      message);
                }
              },
            );

            // 3. This method only call when App in background and not terminated(not closed)
            FirebaseMessaging.onMessageOpenedApp.listen(
              (message) {
                print("FirebaseMessaging.onMessageOpenedApp.listen");
                if (message.notification != null) {
                  print(message.notification!.title);
                  print(message.notification!.body);
                  print("message.data22 ${message.data['_id']}");
                  // LocalNotificationService.createanddisplaynotification(message);
                }
              },
            );
          } catch (e) {
            print("Failed to get token: $e");
          }
          checkAppVersion();

          /*   */
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorPrimary,
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: CText(
                text: "INSPECTION DXB",
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.Poppins,
                textColor: AppTheme.white,
              )
              /*Padding(

                padding: EdgeInsets.all(20),
                child: Image.asset(
                  "${ASSET_PATH}app_logo.png",
                  height: 150,
                ),
              )*/
              ,
            ),
          ),
          CText(
            text: "licensedxb.ae",
            fontFamily: AppTheme.Urbanist,
            fontSize: 22,
            textColor: AppTheme.white,
            fontWeight: FontWeight.w700,
          ),
          CText(
            padding: EdgeInsets.only(bottom: 20),
            text: "1.0.10",
            fontFamily: AppTheme.Urbanist,
            fontSize: 12,
            textColor: AppTheme.white,
            fontWeight: FontWeight.w500,
          )
        ],
      ),
    );
  }

  Future<void> checkAppVersion() async {
    /*var response = await http.get(
      Uri.parse('${baseUrl}api/Department/Task/AppVersion'),
      headers: {
        'accept': "text/plain",
        'Content-Type': "application/json-patch+json",
      },
    );*/
    Api().getAPI(context, "Department/Task/AppVersion").then((value){
      print("Department/Task/AppVersion");
      var data = jsonDecode(value);

      if (data["statusCode"] != null && data["statusCode"] == 200) {
        if (data["data"] == storeUserData.getString(LATEST_APP_VERSION)) {
          if (Utils().hasLogin()) {
            Get.offAll(const HomeScreen());
          } else {
            Get.offAll(const WelcomePage());
          }
        } else {
          Get.dialog(
            const VersionDialog(),
            barrierDismissible: false,
          );
        }
      }
    });

  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/pages/login_page.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/utils.dart';

import '../notification_services/local_notification.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mainBackground,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /* Center(
                    child: CText(
                  text: "INSPECTION DXB",
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.Poppins,
                  textColor: AppTheme.colorPrimary,
                )),*/
                CText(
                  padding: const EdgeInsets.only(top: 20),
                  text: "Welcome to",
                  textColor: AppTheme.black,
                  textAlign: TextAlign.center,
                  fontFamily: AppTheme.urbanist,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
                CText(
                  text: "Inspection DXB",
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.urbanist,
                  textColor: AppTheme.colorPrimary,
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      requestPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppTheme.colorPrimary,
                      minimumSize: const Size.fromHeight(63),
                    ),
                    child: CText(
                      text: "Get started",
                      textColor: AppTheme.white,
                      fontSize: AppTheme.big,
                      fontFamily: AppTheme.poppins,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void requestPermissions() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: AppTheme.white,
            surfaceTintColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20.0),
                  CText(
                    text: "Unlock a Seamless Experience!",
                    maxLines: 5,
                    fontSize: AppTheme.big,
                    textAlign: TextAlign.start,
                  ),
                  CText(
                    padding: const EdgeInsets.only(top: 10),
                    text: "Accept Permissions for Enhanced Features.",
                    maxLines: 5,
                    fontSize: AppTheme.big,
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorPrimary),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        FirebaseMessaging messaging =
                            FirebaseMessaging.instance;

                        NotificationSettings settings =
                            await messaging.requestPermission(
                                alert: true,
                                announcement: false,
                                badge: true,
                                carPlay: false,
                                criticalAlert: false,
                                provisional: false,
                                sound: true);
                        if (settings.authorizationStatus ==
                            AuthorizationStatus.authorized) {
                          locationPermission();
                          print('User granted permission of notification');
                        } else if (settings.authorizationStatus ==
                            AuthorizationStatus.provisional) {
                          locationPermission();
                          print(
                              'User granted provisional permission of notification');
                        } else {
                          print(
                              'User declined or has not accepted permission of notification');
                        }
                        LocalNotificationService.initNotification();
                      },
                      child: CText(
                        text: 'I understand',
                        textColor: AppTheme.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> locationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      Utils().showAlert(
          buildContext: context,
          message: "Location services are disabled.",
          onPressed: () {
            Navigator.of(context).pop();
            Geolocator.openLocationSettings().whenComplete(() {
              locationPermission();
            });
          });
    } else {
      permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          Utils().showAlert(
              buildContext: context,
              message: "Location permissions are denied.",
              onPressed: () {
                Navigator.of(context).pop();
              });
        } else {
          Get.to(transition: Transition.rightToLeft, const LoginPage());
        }
      } else {
        Get.to(transition: Transition.rightToLeft, const LoginPage());
      }
    }
  }
}

import 'dart:convert';
import 'dart:core';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../controls/custom_dialog.dart';
import '../controls/custom_yes_no_dialog.dart';
import 'color_const.dart';
import 'constants.dart';

class Utils {
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(message),
    ));
  }

  void showAlert(
      {required buildContext,
      String? title,
      required String message,
      required VoidCallback onPressed}) {
    if (!buildContext.mounted) return;

    showDialog(
        context: buildContext,
        builder: (BuildContext dialogContext) {
          return CustomDialog(
              title: title,
              message: message,
              onOkPressed: () {
                Navigator.of(dialogContext).pop();
                onPressed();
              });
        });
  }

  bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget getPlaceHolder() {
    return const Center(
      child: SizedBox(
        height: 50,
        width: 50,
        child: CircularProgressIndicator(color: AppTheme.grey),
      ),
    );
  }

  /* Widget getError() {
    return const Center(
      child: SizedBox(
        height: 50,
        width: 50,
        child: Icon(Icons.error),
      ),
    );
  }*/
  Widget getError() {
    return Center(
      child: Image.asset("${ASSET_PATH}error.png", fit: BoxFit.contain),
    );
  }

  void showYesNoAlert(
      {required BuildContext context,
      String? title,
      required String message,
      required VoidCallback onYesPressed,
      required VoidCallback onNoPressed}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomYesNoDialog(
            title: title,
            message: message,
            onNoPressed: onNoPressed,
            onYesPressed: onYesPressed,
          );
        });
  }

  Route createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  bool isValidEmail(String text) {
    // ignore: deprecated_member_use
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(text);
  }

  bool isEmpty(TextEditingController controller) {
    if (controller.text.toString().isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  SizedBox sizeBoxHeight({double height = 20.0}) {
    return SizedBox(
      height: height,
    );
  }

  SizedBox sizeBoxWidth({double width = 20.0}) {
    return SizedBox(
      width: width,
    );
  }

  SizedBox sizeBoxHeightWidth({double width = 20.0, double height = 20.0}) {
    return SizedBox(
      width: width,
      height: height,
    );
  }

  bool hasLogin() {
    if (StoreUserData().getInt(USER_ID) != -1) {
      print("userId : ${StoreUserData().getInt(USER_ID)}");
      return true;
    }
    return false;
  }

  CText getTitle(
      {String title = "Inspection DXB",
      double fontSize = AppTheme.big,
      Color textColor = AppTheme.red}) {
    return CText(
      text: title,
      fontFamily: AppTheme.urbanist,
      fontWeight: FontWeight.w500,
      fontSize: fontSize,
      textColor: textColor,
    );
  }

  String getPriceFormat(String price) {
    var result = "";
    List<String> parts = price.split('.');
    result = parts.length > 1 && int.parse(parts[1]) > 0 ? price : parts[0];
    print(result); // Output: 500.5
    return result;
  }

  DateTime getCurrentGSTTime() {
    tz.initializeTimeZones();
    return tz.TZDateTime.from(DateTime.now(), tz.getLocation('Asia/Dubai'));
  }

  String getRatings(int rating) {
    if (rating == 1) {
      return "😐";
    } else if (rating == 2) {
      return "😞";
    } else if (rating == 3) {
      return "😊";
    } else if (rating == 4) {
      return "😊👍";
    } else if (rating == 5) {
      return "🤩";
    }
    return "🤩";
  }

  String getFileName(String name) {
    const maxLength = 5; // Set a max length for the filename

    var last = ".${name.split(".").last}";
    var input = name
        .split(".")
        .first
        .replaceAll(" ", "")
        .replaceAll("_", "")
        .replaceAll("-", "")
        .replaceAll("0", "a")
        .replaceAll("1", "a")
        .replaceAll("2", "b")
        .replaceAll("3", "c")
        .replaceAll("4", "d")
        .replaceAll("5", "e")
        .replaceAll("6", "f")
        .replaceAll("7", "g")
        .replaceAll("8", "h")
        .replaceAll("9", "i")
        // ignore: deprecated_member_use
        .replaceAllMapped(RegExp(r'(.)\1{3,}'), (match) => match.group(1)!)
        .capitalizeFirst
        .toString();

    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    var baseName = input + last;
    print("fileName: updated : $baseName");
    return baseName;
  }

  bool isVideoLink(String url) {
    List<String> videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.flv',
      '.wmv',
      '.mkv',
      '.webm'
    ];
    for (String ext in videoExtensions) {
      if (url.toLowerCase().endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  bool isImageLink(String url) {
    List<String> imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff'
    ];
    for (String ext in imageExtensions) {
      if (url.toLowerCase().endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> hasNetwork(context, StateSetter setState) async {
    var onlineStatus = false;
    var stList = await (Connectivity().checkConnectivity());
    if (stList.isNotEmpty &&
        stList
            .where((st) =>
                st == ConnectivityResult.mobile ||
                st == ConnectivityResult.wifi ||
                st == ConnectivityResult.vpn ||
                st == ConnectivityResult.ethernet ||
                st == ConnectivityResult.other ||
                st == ConnectivityResult.bluetooth)
            .isNotEmpty) {
      onlineStatus = true;
    } else {
      onlineStatus = false;
    }

    if (!isOpen && !onlineStatus) {
      if (context.mounted) {
        setState(() {
          isOpen = true;
        });
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
              surfaceTintColor: AppTheme.black,
              title: const Text(
                'Internet Disconnected!',
                style: TextStyle(fontSize: 16),
              ),
              content: const Text(
                  'Please check your internet connection and try again',
                  style: TextStyle(fontSize: 14)),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Okay',
                    style: TextStyle(color: AppTheme.colorPrimary),
                  ),
                  onPressed: () {
                    if (context.mounted) {
                      setState(() {
                        isOpen = false;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ]);
        },
      );
    }
    print("==online status== open :$isOpen");
    print("==online status==$onlineStatus");
    return onlineStatus;
  }

/*
  String trimImageUrl(String url) {
    return url.replaceAll(" ", "%20");
  }

  String formatDate(String date) {
    return DateFormat("dd MMM ''yy hh:mm a",
            StoreUserData().getString(constants.USER_LANGUAGE))
        .format(DateFormat("yyyy-MM-dd'T'HH:mm:ss", "en").parse(date));
  }

  String formatDatetime(DateTime date, BuildContext context) {
    return DateFormat(
            "dd MMM ''yy hh:mm a", Localizations.localeOf(context).toString())
        .format(date);
  }

  String? createMD5String(String rawData) {
    var sb = StringBuffer();
    try {
      var hash = md5.convert(utf8.encode(rawData)).bytes;
      for (var b in hash) {
        sb.write((b & 0xff).toRadixString(16).padLeft(2, '0'));
      }
    } catch (e) {
      print(e);
    }
    return sb.toString().toUpperCase();
  }

  String formatDateDetails(String date, BuildContext context) {
    try {
      // 2023-05-08T18:44:28
      DateTime dt = DateFormat("yyyy-MM-dd'T'HH:mm:ss", "en_US").parse(date);
      return DateFormat(
              DateUtils.isSameDay(dt, DateTime.now())
                  ? "hh:mm a"
                  : "dd MMM ''yy",
              Localizations.localeOf(context).toString())
          .format(dt ?? DateTime.now());
    } catch (e) {
      return date;
    }
  }

  Future<String> getVersionCode() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  Future<String> getVersionName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool isValidJsonString(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  void launchWhatsApp(String uri, BuildContext context) async {
    var whatsappW4bPackage = "com.whatsapp.w4b";
    var whatsappPackage = "com.whatsapp";
    var packageName =
        await getWhatsAppPackage([whatsappW4bPackage, whatsappPackage]);

    if (packageName != null) {
      var url = Uri.encodeComponent(uri);
      if (await canLaunch("whatsapp://$url")) {
        await launch("whatsapp://$url");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String> getWhatsAppPackage(List<String> packageNames) async {
    for (var packageName in packageNames) {
      if (await canLaunchUrl(Uri.parse("package:$packageName"))) {
        return packageName;
      }
    }
    return "";
  }

  void openWhatsApp(BuildContext context, String mobileNo) {
    String parsedMobileNo = mobileNo.replaceAll("+", "");
    String url = "http://api.whatsapp.com/send?phone=$parsedMobileNo";
    launchUrl(Uri.parse(url));
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }*/
}

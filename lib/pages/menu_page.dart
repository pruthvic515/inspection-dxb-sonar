import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:patrol_system/pages/welcome_page.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:patrol_system/utils/utils.dart';
import '../controls/loading_indicator_dialog.dart';
import '../controls/text.dart';
import '../model/patrol_visit_model.dart';
import '../utils/api.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  var visitCount = 0;
  var storeUserData = StoreUserData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mainBackground,
      body: Column(
        children: [
          Container(
              height: 182,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.colorPrimary,
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, top: 50, right: 10, bottom: 20),
                      child: Card(
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        elevation: 0,
                        surfaceTintColor: AppTheme.white.withValues(alpha: 0),
                        color: AppTheme.white.withValues(alpha: 0),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            "${ASSET_PATH}back.png",
                            height: 15,
                            width: 15,
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                    ),
                  ),
               storeUserData.getBoolean(IS_AGENT_LOGIN)?
                  Center(
                    child: CText(
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 20, bottom: 20),
                      text:
                          "${storeUserData.getString(NAME)}\nDepartment : ${storeUserData.getInt(USER_ID)}",
                      textColor: AppTheme.textPrimary,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.big,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                    ),
                  ) : Center(
                    child: CText(
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 20, bottom: 20),
                      text:
                          "${storeUserData.getString(NAME)}\nEmployee ID : ${storeUserData.getString(USER_BADGE_NUMBER)}\nDepartment : ${storeUserData.getInt(USER_ID)}",
                      textColor: AppTheme.textPrimary,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.big,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*     GestureDetector(
                      onTap: () {
                        Get.to(
                            transition: Transition.rightToLeft,
                            const VisitsPage());
                      },
                      child: Card(
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
                          color: AppTheme.white,
                          surfaceTintColor: AppTheme.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: SizedBox(
                            width: double.infinity,
                            child: CText(
                              padding: const EdgeInsets.all(20),
                              text: "My Visits",
                              textColor: AppTheme.text_color,
                              fontFamily: AppTheme.Urbanist,
                              fontSize: AppTheme.large,
                              fontWeight: FontWeight.w600,
                            ),
                          ))),
                  GestureDetector(
                      onTap: () {
                        Get.to(
                            transition: Transition.rightToLeft,
                            const TasksPage());
                      },
                      child: Card(
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
                          color: AppTheme.white,
                          surfaceTintColor: AppTheme.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: SizedBox(
                            width: double.infinity,
                            child: CText(
                              padding: const EdgeInsets.all(20),
                              text: "My Task",
                              textColor: AppTheme.text_color,
                              fontFamily: AppTheme.Urbanist,
                              fontSize: AppTheme.large,
                              fontWeight: FontWeight.w600,
                            ),
                          ))),
                  GestureDetector(
                    onTap: () {
                      Get.to(
                          transition: Transition.rightToLeft,
                          const DashboardPage());
                    },
                    child: Card(
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      color: AppTheme.white,
                      surfaceTintColor: AppTheme.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: SizedBox(
                        width: double.infinity,
                        child: CText(
                          padding: const EdgeInsets.all(20),
                          text: "Dashboard",
                          textColor: AppTheme.text_color,
                          fontFamily: AppTheme.Urbanist,
                          fontSize: AppTheme.large,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),*/
                  GestureDetector(
                    onTap: () {
                      Utils().showYesNoAlert(
                          context: context,
                          title: "Logout",
                          message: "Are you sure you want logout?",
                          onYesPressed: () {
                            Navigator.of(context).pop();
                            StoreUserData().clearData();
                            Get.offAll(
                                transition: Transition.rightToLeft,
                                const WelcomePage());
                          },
                          onNoPressed: () {
                            Navigator.of(context).pop();
                          });
                    },
                    child: Card(
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      color: AppTheme.white,
                      surfaceTintColor: AppTheme.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: SizedBox(
                        width: double.infinity,
                        child: CText(
                          padding: const EdgeInsets.all(20),
                          text: "Logout",
                          textColor: AppTheme.textColor,
                          fontFamily: AppTheme.urbanist,
                          fontSize: AppTheme.large,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(
                        text: StoreUserData().getString(USER_FCM)))
                    .then((value) {
                  if (!context.mounted) return;
                  Utils().showSnackBar(context, "Copied!");
                });
              },
              child: CText(
                padding: const EdgeInsets.all(20),
                text: 'Copy Device Token',
                textColor: AppTheme.colorPrimary,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.big,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getVisits() async {
    LoadingIndicatorDialog().show(context);
    var fields = {
      "dateFilter": {
        "startDate": DateFormat(fullDateTimeFormat)
            .format(DateTime(2024, 03, 01)),
        "enddate": DateFormat(fullDateTimeFormat)
            .format(Utils().getCurrentGSTTime())
      },
      "userId": StoreUserData().getInt(USER_ID)
    };

    var response = await http.post(
      Uri.parse('$baseUrl${Api().version}/Mobile/Patrol/GetAll'),
      headers: {
        'accept': "text/plain",
        'Content-Type': "application/json",
      },
      body: jsonEncode(fields),
    );
    print("${response.request!.url} ${response.statusCode}");
    print("fields : $fields");
    LoadingIndicatorDialog().dismiss();
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 400) {
      var data = detailFromJson(response.body);
      if (data.data.isNotEmpty) {
        setState(() {
          visitCount = data.data.length;
        });
      } else {
        if (!mounted) return;
        Utils().showAlert(
            buildContext: context,
            message: data.message,
            onPressed: () {
              Navigator.of(context).pop();
            });
      }
    } else {
      if (!mounted) return;
      Utils().showAlert(
          buildContext: context,
          message: jsonDecode(response.body)["message"],
          onPressed: () {
            Navigator.of(context).pop();
          });
    }
  }
}

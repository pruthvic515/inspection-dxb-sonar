import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../controls/form_text_field.dart';
import '../controls/text.dart';
import '../utils/api.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart';
import '../utils/store_user_data.dart';
import '../utils/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? startDate;
  DateTime? endDate;
  var count = 0;
  var isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.mainBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 182),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Row(
                      children: [
                        Expanded(
                            child: FormTextField(
                          hint: "",
                          value: startDate != null
                              ? DateFormat("dd-MM-yyyy").format(startDate!)
                              : "",
                          title: 'From Date:',
                          onTap: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate:
                                  startDate ?? Utils().getCurrentGSTTime(),
                              firstDate: DateTime(2015, 8),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              if (endDate != null && date.isAfter(endDate!)) {
                                if (!context.mounted) return;

                                Utils().showAlert(
                                    buildContext: context,
                                    message:
                                        "Please select date before to date",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else {
                                setState(() {
                                  startDate = date;

                                  if (endDate != null) {
                                    isLoading = true;
                                    getCount();
                                  }
                                });
                              }
                            }
                          },
                        )),
                        Expanded(
                            child: FormTextField(
                          hint: "",
                          value: endDate != null
                              ? DateFormat("dd-MM-yyyy").format(endDate!)
                              : "",
                          title: 'To Date:',
                          onTap: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate:
                                  endDate ?? Utils().getCurrentGSTTime(),
                              firstDate: DateTime(2015, 8),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              if (startDate != null &&
                                  date.isBefore(startDate!)) {
                                if (!context.mounted) return;

                                Utils().showAlert(
                                    buildContext: context,
                                    message:
                                        "Please select date after from date",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else {
                                setState(() {
                                  endDate = DateTime(date.year, date.month,
                                      date.day, 23, 59, 59);
                                  if (startDate != null) {
                                    isLoading = true;
                                    getCount();
                                  }
                                });
                              }
                            }
                          },
                        ))
                      ],
                    ),
                  ),
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: AppTheme.black,
                        ))
                      : count > 0
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.border, width: 1),
                                color: AppTheme.white,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CText(
                                    textAlign: TextAlign.center,
                                    text: "Total Sites Visited",
                                    textColor: AppTheme.textColorTwo,
                                    fontFamily: AppTheme.urbanist,
                                    fontSize: AppTheme.large,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  CText(
                                    padding: const EdgeInsets.only(top: 2),
                                    textAlign: TextAlign.center,
                                    text: "$count",
                                    textColor: AppTheme.textColorTwo,
                                    fontFamily: AppTheme.urbanist,
                                    fontSize: AppTheme.large,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ],
                              ))
                          : Container()
                ],
              ),
            ),
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
                            left: 20, top: 50, right: 20, bottom: 20),
                        child: Card(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          elevation: 0,
                          surfaceTintColor: AppTheme.white.withValues(alpha: 0.67),
                          color: AppTheme.white.withValues(alpha: 0.67),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              "${ASSET_PATH}back.png",
                              height: 15,
                              width: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: CText(
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 20, bottom: 20),
                        text: "Dashboard",
                        textColor: AppTheme.white,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )),
          ],
        ));
  }

  Future<void> getCount() async {
    var fields = {
      "dateFilter": {
        "startDate": DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ").format(startDate!),
        "enddate": DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ").format(endDate!)
      },
      "userId": StoreUserData().getInt(USER_ID)
    };

    var response = await http.post(
      Uri.parse('$baseUrl${Api().version}/Mobile/Patrol/Count'),
      headers: {
        'accept': "text/plain",
        'Content-Type': "application/json",
      },
      body: jsonEncode(fields),
    );
    print("${response.request!.url} ${response.statusCode}");
    print("fields : $fields");

    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 400) {
      var data = jsonDecode(response.body);
      setState(() {
        isLoading = false;
      });
      if (data["data"] != null) {
        setState(() {
          count = data["data"];
        });
      } else {
        if (!mounted) return;
        Utils().showAlert(
            buildContext: context,
            message: data["message"],
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

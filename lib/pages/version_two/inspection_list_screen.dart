import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:patrol_system/utils/ApiServiceDio.dart';
import 'package:patrol_system/utils/store_user_data.dart';

import '../../controls/LoadingIndicatorDialog.dart';
import '../../controls/text.dart';
import '../../model/inspection_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import 'notes_and_attachments_screen.dart';

class InspectionListScreen extends StatefulWidget {
  int inspectionId;
  int taskId;
  int mainTaskId;
  int entityId;
  bool isDXBTask;
  Map<String, dynamic> map;

  InspectionListScreen(
      {Key? key,
      required this.inspectionId,
      required this.taskId,
      required this.mainTaskId,
      required this.entityId,
      required this.map,
      required this.isDXBTask})
      : super(key: key);

  @override
  _InspectionListScreenState createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  List<InspectionModel> inspections = [];
  var storeUserData = StoreUserData();

  @override
  void initState() {
    getInspection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                height: 120,
                width: double.infinity,
                color: AppTheme.colorPrimary,
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
                          surfaceTintColor: AppTheme.white.withOpacity(0),
                          color: AppTheme.white.withOpacity(0),
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
                    Align(
                      alignment: Alignment.topCenter,
                      child: CText(
                        textAlign: TextAlign.center,
                        padding:
                            const EdgeInsets.only(left: 60, right: 60, top: 60),
                        text: "Inspection Task",
                        textColor: AppTheme.white,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          // Get selected inspections
                          List<InspectionModel> selected =
                              inspections.where((e) => e.isSelected).toList();

                          Get.back(result: selected);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("${selected.length} Selected")));
                        },
                        child: CText(
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.only(
                              left: 0, right: 20, top: 60),
                          text: "Done",
                          textColor: AppTheme.white,
                          fontFamily: AppTheme.Urbanist,
                          fontSize: AppTheme.big,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )),
            ListView.builder(
              itemCount: inspections.length,
              padding: EdgeInsets.only(top: 15),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final item = inspections[index];
                return Card(
                  color: AppTheme.white,
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  surfaceTintColor: AppTheme.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: CheckboxListTile(
                    value: item.isSelected,
                    onChanged: (value) {
                      setState(() {
                        item.isSelected = value!;
                      });
                    },
                    title: CText(
                      text: item.entityName.isNotEmpty
                          ? item.entityName
                          : "No Name",
                      textColor: AppTheme.colorPrimary,
                      fontFamily: AppTheme.Urbanist,
                      fontSize: AppTheme.big,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                    ),
                    subtitle: CText(
                      text: "Accompanied By: ${item.accompaniedBy}",
                      textColor: AppTheme.colorPrimary,
                      fontFamily: AppTheme.Urbanist,
                      fontSize: AppTheme.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void getInspection() async {
    try {
      var result = await context.apiDio
          .get("api/Department/User/GetInspectionList?inspectorId=${storeUserData.getInt(USER_ID)}");

      if (result.statusCode == 200 && result.data["data"] != null) {
        setState(() {
          inspections = (result.data["data"] as List)
              .map((item) => InspectionModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void createInspection(onValue) {
    print("createInspection ${widget.map}");
    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/Inspection/CreateInspection", widget.map)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      // LogPrint().log("createInspection response : $value");
      var data = jsonDecode(value);
      if (data["statusCode"] == 200 && data["data"] != null) {
        Get.to(
            transition: Transition.rightToLeft,
            NotesAndAttachmentsScreen(
              inspectionId: data["data"],
              entityId: widget.entityId,
              mainTaskId: widget.mainTaskId,
              taskId: widget.taskId!,
              isDXBTask: widget.isDXBTask,
            ));
      } else {
        Utils().showAlert(
            buildContext: context,
            message: data["message"],
            onPressed: () {
              Navigator.of(context).pop();
            });
      }
    });
  }
}

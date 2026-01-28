import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/utils/store_user_data.dart';

import '../../controls/LoadingIndicatorDialog.dart';
import '../../controls/formTextField.dart';
import '../../controls/text.dart';
import '../../model/area_model.dart';
import '../../model/entity_detail_model.dart';
import '../../model/outlet_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import 'create_new_patrol.dart';
import 'home_screen.dart';

class OutletDetailScreen extends StatefulWidget {
  EntityDetailModel entity;
  int? taskId;
  int inspectionId;
  var statusId;
  OutletData outlet;
  bool isNew;
  bool fromInactive;
  bool primary;
  bool isAgentEmployees;
  int mainTaskId;
  int taskType;

  OutletDetailScreen(
      {super.key,
      required this.entity,
      this.taskId,
      required this.fromInactive,
      required this.statusId,
      required this.inspectionId,
      required this.outlet,
      required this.isNew,
      required this.mainTaskId,
      required this.isAgentEmployees,
      required this.taskType,
      required this.primary});

  @override
  State<OutletDetailScreen> createState() =>
      _OutletDetailScreenState(taskId, entity, outlet);
}

class _OutletDetailScreenState extends State<OutletDetailScreen> {
  int? taskId;
  EntityDetailModel entity;
  var storeUserData = StoreUserData();
  List<AreaData> ownerShipList = [];
  List<AreaData> outletServiceList = [];
  OutletData outlet;

  _OutletDetailScreenState(this.taskId, this.entity, this.outlet);

  @override
  void initState() {
    getOutletService();
    getOutletOwnerShip();
    super.initState();
  }

  Future<void> getOutletService() async {
    if (await Utils().hasNetwork(context, setState)) {
      Api()
          .getAPI(context, "Mobile/Entity/GetOutletService")
          .then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            outletServiceList.clear();
            outletServiceList.addAll(data.data);
          });
        } else {
          Utils().showAlert(
              buildContext: context,
              message: data.message,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  Future<void> getOutletOwnerShip() async {
    if (await Utils().hasNetwork(context, setState)) {
      Api()
          .getAPI(context, "Mobile/Entity/GetOwnershipDetails")
          .then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            ownerShipList.clear();
            ownerShipList.addAll(data.data);
          });
        } else {
          Utils().showAlert(
              buildContext: context,
              message: data.message,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.main_background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 182,
              color: AppTheme.colorPrimary,
              width: double.infinity,
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
                  Center(
                    child: Column(
                      children: [
                        CText(
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.only(
                              left: 60, right: 60, top: 80),
                          text: outlet.outletName,
                          textColor: AppTheme.text_primary,
                          fontFamily: AppTheme.Urbanist,
                          fontSize: AppTheme.big,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w700,
                        ),
                        CText(
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.only(
                              left: 60, right: 60, top: 5),
                          text: entity.location?.address ?? "",
                          textColor: AppTheme.text_primary,
                          fontFamily: AppTheme.Urbanist,
                          fontSize: AppTheme.large,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              )),
          Expanded(
              child: SingleChildScrollView(
            child: outletServiceList.isNotEmpty && ownerShipList.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        text: "Outlet Details :",
                        textColor: AppTheme.black,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.big_20,
                        fontWeight: FontWeight.w700,
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border, width: 1),
                          color: AppTheme.white,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Outlet Name : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.outletName,
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Outlet Type : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.outletType ?? "-",
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      maxLines: 2,
                                      fontSize: AppTheme.large,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Ownership : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: ownerShipList
                                          .firstWhere((element) =>
                                              element.id ==
                                              outlet.ownerShipTypeId)
                                          .text,
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Service Type : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outletServiceList
                                          .firstWhere((element) =>
                                              element.id ==
                                              outlet.serviceTypeId)
                                          .text,
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      maxLines: 2,
                                      fontSize: AppTheme.large,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Manager Name : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.managerName ?? "-",
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Emirates ID : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.emiratesId ?? "-",
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      maxLines: 2,
                                      fontSize: AppTheme.large,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Contact Number : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.contactNumber ?? "-",
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CText(
                                      textAlign: TextAlign.center,
                                      text: "Notes : ",
                                      textColor: AppTheme.title_gray,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.medium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CText(
                                      padding: const EdgeInsets.only(top: 2),
                                      textAlign: TextAlign.center,
                                      text: outlet.notes ?? "-",
                                      textColor: AppTheme.text_black,
                                      fontFamily: AppTheme.Urbanist,
                                      maxLines: 2,
                                      fontSize: AppTheme.large,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                )),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                : Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(50),
                    child: const CircularProgressIndicator(
                      color: AppTheme.black,
                    )),
          )),
          Container(
            margin: EdgeInsets.only(
                top: 10,
                bottom: MediaQuery.of(context).viewPadding.bottom + 10),
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Visibility(
                  visible: !storeUserData.getBoolean(IS_AGENT_LOGIN),
                  child: Expanded(
                      child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.taskId != null &&
                            (outlet.inspectorId == 0 ||
                                outlet.inspectorId ==
                                    storeUserData.getInt(USER_ID))) {
                          if (widget.statusId == 5) {
                            Get.to(
                                    transition: Transition.rightToLeft,
                                    CreateNewPatrol(
                                        entityId: entity.entityID,
                                        taskId: taskId,
                                        statusId: widget.statusId,
                                        mainTaskId: widget.mainTaskId,
                                        inspectionId: widget.inspectionId,
                                        newAdded: widget.isNew,
                                        primary: widget.primary,
                                        outletData: outlet,
                                        isAgentEmployees:
                                            widget.isAgentEmployees,
                                        taskType: widget.taskType))
                                ?.then((value) {
                              if (value != null) {
                                if (!mounted) return;
                                setState(() {
                                  widget.statusId = value["statusId"];
                                  widget.inspectionId = value["inspectionId"];
                                  widget.taskId = value["taskId"];
                                  taskId = value["taskId"];
                                  outlet.inspectorId = value["inspectorId"];
                                });
                              }
                            });
                          } else {
                            Get.to(
                                    transition: Transition.rightToLeft,
                                    CreateNewPatrol(
                                        entityId: entity.entityID,
                                        taskId: taskId,
                                        statusId: widget.statusId,
                                        inspectionId: widget.inspectionId,
                                        outletData: outlet,
                                        mainTaskId: widget.mainTaskId,
                                        newAdded: widget.isNew,
                                        primary: widget.primary,
                                        isAgentEmployees:
                                            widget.isAgentEmployees,
                                        taskType: widget.taskType))
                                ?.then((value) {
                              if (value != null) {
                                if (!mounted) return;
                                setState(() {
                                  widget.statusId = value["statusId"];
                                  widget.inspectionId = value["inspectionId"];
                                  widget.taskId = value["taskId"];
                                  taskId = value["taskId"];
                                  outlet.inspectorId = value["inspectorId"];
                                });
                              }
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: widget.taskId != null &&
                                (outlet.inspectorId == 0 ||
                                    outlet.inspectorId ==
                                        storeUserData.getInt(USER_ID))
                            ? AppTheme.colorPrimary
                            : AppTheme.pale_gray,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: CText(
                        textAlign: TextAlign.center,
                        text: widget.statusId == 5
                            ? "Continue Inspection"
                            : "Create Inspection",
                        textColor: AppTheme.text_primary,
                        fontSize: AppTheme.large,
                        fontFamily: AppTheme.Urbanist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ),
                Visibility(
                    visible: !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                        taskId != null &&
                        widget.inspectionId != 0 &&
                        widget.primary == true,
                    child: Expanded(
                        child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: ElevatedButton(
                        onPressed: () {
                          Utils().showYesNoAlert(
                              context: context,
                              message:
                                  "Are you sure you want to cancel the inspection?",
                              onYesPressed: () {
                                Navigator.of(context).pop();
                                showRejectRemarkSheet(taskId);
                              },
                              onNoPressed: () {
                                Navigator.of(context).pop();
                              });
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor:
                              taskId != null && widget.primary == true
                                  ? AppTheme.colorPrimary
                                  : AppTheme.grey,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: CText(
                          textAlign: TextAlign.center,
                          text: "Cancel Inspection",
                          textColor: AppTheme.text_primary,
                          fontSize: AppTheme.large,
                          fontFamily: AppTheme.Urbanist,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))),
              ],
            ),
          )
        ],
      ),
    );
  }

  void showRejectRemarkSheet(dynamic taskId) {
    var remark = TextEditingController();
    var loading = false;
    FocusNode focusNode = FocusNode();

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext buildContext) {
        focusNode.requestFocus();
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                FormTextField(
                  cardColor: AppTheme.main_background,
                  hint: "",
                  controller: remark,
                  textColor: AppTheme.gray_Asparagus,
                  fontFamily: AppTheme.Urbanist,
                  title: 'Notes :',
                  maxLines: 10,
                  minLines: 5,
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (remark.text.isEmpty) {
                        Utils().showAlert(
                            buildContext: buildContext,
                            message: "Please enter the notes",
                            onPressed: () {
                              Navigator.of(context).pop();
                            });
                      } else {
                        setState(() {
                          loading = true;
                        });
                        Navigator.pop(context);
                        rejectTask(taskId, remark.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: AppTheme.red,
                      minimumSize: const Size(200, 40),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: AppTheme.white,
                          )
                        : const Text(
                            'Cancel',
                            style: TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
      },
    ).whenComplete(() {});
  }

  Future<void> rejectTask(int id, String notes) async {
    if (await Utils().hasNetwork(context, setState)) {
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Department/Task/UpdateInspectionTaskStatus", {
        "inspectionTaskId": id,
        "mainTaskId": widget.mainTaskId,
        "inspectionId": widget.inspectionId,
        "inspectorId": storeUserData.getInt(USER_ID),
        "statusId": 10,
        "notes": notes,
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          Get.offAll(transition: Transition.rightToLeft, const HomeScreen());
        } else {
          if (data["message"] != null &&
              data["message"].toString().isNotEmpty) {
            Utils().showAlert(
                buildContext: context,
                message: data["message"],
                onPressed: () {
                  Navigator.of(context).pop();
                });
          }
        }
      });
    }
  }
}

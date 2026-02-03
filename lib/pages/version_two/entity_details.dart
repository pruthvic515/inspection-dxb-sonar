import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/model/all_user_model.dart';
import 'package:patrol_system/model/entity_detail_model.dart';
import 'package:patrol_system/pages/version_two/notes_and_attachments_screen.dart';
import 'package:patrol_system/pages/version_two/select_agents.dart';
import 'package:patrol_system/pages/version_two/select_inspector.dart';
import 'package:patrol_system/utils/log_print.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controls/form_mobile_text_field.dart';
import '../../controls/form_text_field.dart';
import '../../controls/text.dart';
import '../../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../../model/area_model.dart';
import '../../model/outlet_model.dart';
import '../../model/patrol_visit_model.dart';
import '../../model/search_entity_model.dart';
import '../../model/task_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/store_user_data.dart';
import '../../utils/utils.dart';
import '../patrol_visits_all.dart';
import 'create_new_patrol.dart';
import 'home_screen.dart';
import 'inspection_detail_screen.dart';
import 'outlet_detail_screen.dart';

class EntityDetails extends StatefulWidget {
  int entityId;
  int? taskId;
  int inspectionId;
  int statusId;
  int category;
  Tasks? task;
  bool fromActive;
  bool isAgentEmployees;

  // bool isDXBTask;
  bool completeStatus;

  // int taskType;

  EntityDetails(
      {super.key,
      required this.entityId,
      this.taskId,
      required this.statusId,
      required this.inspectionId,
      required this.category,
      required this.fromActive,
      required this.isAgentEmployees,
      // required this.isDXBTask,
      required this.completeStatus,
      // required this.taskType,
      this.task});

  @override
  State<EntityDetails> createState() => _EntityDetailsState();
}

class _EntityDetailsState extends State<EntityDetails> {
  late int entityId;
  var storeUserData = StoreUserData();
  EntityDetailModel? entity;
  var tabType = 1;

  ///inspection logs
  List<PatrolVisitData> list = [];

  ///outlet
  List<OutletData> outletList = [];
  List<OutletData> searchOutletList = [];
  List<AreaData> ownerShipList = [];
  List<AreaData> outletServiceList = [];
  final _searchOutlet = TextEditingController();
  AreaData? ownerShipType;
  AreaData? serviceType;
  AreaData? outletType;
  final List<AreaData> taskStatus = [];
  var restaurantInspectionStatusId = 0;

  String googleAddress = "";

  List<Map<String, dynamic>> reasonList = [];

  @override
  void initState() {
    entityId = widget.entityId;
    getEntityDetail();

    if (widget.category == 1) {
      getOutletService();
      getOutletOwnerShip();
      getTaskStatus();
    } else {
      getVisitDetail();
    }
    super.initState();
  }

  Future<void> getTaskStatus() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      Api()
          .getAPI(context, "Department/Task/GetTaskStatus")
          .then((value) async {
        setState(() {
          taskStatus.clear();
          var data = areaFromJson(value);
          if (data.data.isNotEmpty) {
            taskStatus.addAll(data.data);
          } else {
            if (data.message.isNotEmpty) {
              Utils().showAlert(
                  buildContext: context,
                  message: data.message,
                  onPressed: () {
                    Navigator.of(context).pop();
                  });
            }
          }
        });
      });
    }
  }

  Future<void> getEntityDetail() async {
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    try {
      final endPoint = await _buildEntityDetailEndpoint();
      if (!mounted) return;

      final value = await Api().callAPI(context, endPoint, null);
      await _processEntityDetailResponse(value);
    } finally {
      if (mounted) {
        LoadingIndicatorDialog().dismiss();
      }
    }
  }

  Future<String> _buildEntityDetailEndpoint() async {
    final encryptAndDecrypt = EncryptAndDecrypt();
    final encryptedEntityId = await encryptAndDecrypt.encryption(
      payload: widget.entityId.toString(),
      urlEncode: false,
    );

    if (widget.task != null) {
      final encryptedMainTaskId = await encryptAndDecrypt.encryption(
        payload: widget.task!.mainTaskId.toString(),
        urlEncode: false,
      );
      _logEncryptionDetails(encryptedMainTaskId, encryptedEntityId);
      return "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${Uri.encodeComponent(encryptedMainTaskId)}&entityId=${Uri.encodeComponent(encryptedEntityId)}";
    }

    return "Mobile/Entity/GetEntityInspectionDetails?entityId=${Uri.encodeComponent(encryptedEntityId)}";
  }

  void _logEncryptionDetails(String encryptedMainTaskId, String encryptedEntityId) {
    debugPrint("Original MainTaskId ${widget.task!.mainTaskId}");
    debugPrint("encryptedMainTaskId $encryptedMainTaskId");
    debugPrint("Original EntityId ${widget.entityId}");
    debugPrint("encryptedEntityId $encryptedEntityId");
  }

  Future<void> _processEntityDetailResponse(String? value) async {
    if (value == null) {
      _handleNullResponse();
      return;
    }

    if (!mounted) return;
    debugPrint("Response with $value");

    setState(() {
      entity = entityFromJson(value);
      if (entity != null) {
        _processEntityData();
      } else {
        _handleNullEntity();
      }
    });
  }

  void _processEntityData() {
    if (widget.category == 1) {
      _processCategoryOneEntity();
    } else {
      _processOtherCategoryEntity();
    }
  }

  void _processCategoryOneEntity() {
    tabType = 1;
    searchOutletList.clear();
    _loadStoredOutlets();
    searchOutletList.addAll(entity!.outletModels);
    _buildOutletList();
  }

  void _loadStoredOutlets() {
    final storedData = storeUserData.getString(entityId.toString());
    if (storedData.isEmpty) return;

    final List<OutletData> data = OutletData.decode(storedData);
    for (var outlet in data) {
      if (_isOutletNotInEntity(outlet)) {
        searchOutletList.add(outlet);
      }
    }
  }

  bool _isOutletNotInEntity(OutletData outlet) {
    return entity!.outletModels.firstWhereOrNull(
          (element) => element.outletId == outlet.outletId,
        ) == null;
  }

  void _buildOutletList() {
    outletList.clear();
    for (var item in searchOutletList) {
      _markNewOutlet(item);
      if (_shouldAddOutletToList(item)) {
        outletList.add(item);
      }
    }
  }

  void _markNewOutlet(OutletData item) {
    if (item.outletStatus == null) {
      item.newAdded = true;
    }
  }

  bool _shouldAddOutletToList(OutletData item) {
    if (tabType == 2 && item.newAdded == true) {
      return true;
    }
    if (tabType == 1 && item.newAdded == false) {
      return item.outletStatus != null;
    }
    return false;
  }

  void _processOtherCategoryEntity() {
    if (entity!.inspectionId != null && entity!.inspectionId != 0) {
      widget.inspectionId = entity!.inspectionId!;
      restaurantInspectionStatusId = entity!.inspectionStatusId!;
    }
  }

  void _handleNullEntity() {
    Utils().showAlert(
      buildContext: context,
      message: noEntityMessage,
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.pop(context);
      },
    );
  }

  void _handleNullResponse() {
    if (!mounted) return;
    Utils().showAlert(
      buildContext: context,
      message: noEntityMessage,
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result1) async {
        if (!didPop) {
          Get.back(result: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 220,
                color: AppTheme.colorPrimary,
                width: double.infinity,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back(result: true);
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
                              color: AppTheme.white,
                              width: 15,
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
                                left: 60, right: 60, top: 65),
                            text: entity?.entityName ?? "",
                            textColor: AppTheme.textPrimary,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.big,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w700,
                          ),
                          CText(
                            textAlign: TextAlign.center,
                            padding: const EdgeInsets.only(
                                left: 60, right: 60, top: 5),
                            text: entity?.location?.address ?? "",
                            textColor: AppTheme.textPrimary,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.large,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: widget.taskId == null
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                              ),
                              // if (widget.taskId == null)
                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      widget.taskId == null
                                  ? GestureDetector(
                                      onTap: () {
                                        showAddTaskSheet(false);
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            left: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            right: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            bottom: BorderSide(
                                              color: AppTheme.textPrimary,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                        child: CText(
                                          padding: EdgeInsets.zero,
                                          text: "Add DXB Task",
                                          fontSize: AppTheme.medium - 1,
                                          textColor: AppTheme.textPrimary,
                                          fontFamily: AppTheme.poppins,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : Container(),

                              // Expanded(flex: 1, child: Container()),
                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      !widget.completeStatus &&
                                      widget.fromActive &&
                                      widget.taskId != null &&
                                      widget.category != 1 &&
                                      restaurantInspectionStatusId > 5 &&
                                      widget.task?.primary == true
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.white),
                                      onPressed: () {
                                        showCompleteSheet();
                                      },
                                      child: CText(
                                        text: "Complete task",
                                        fontSize: 12,
                                        textColor: AppTheme.colorPrimary,
                                        fontFamily: AppTheme.poppins,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : Container(),
                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                          widget.fromActive &&
                                          widget.category == 1 &&
                                          searchOutletList.isNotEmpty &&
                                          widget.taskId != null &&
                                          (widget.task?.primary == true &&
                                              searchOutletList
                                                  .where((element) =>
                                                      element.inspectionStatusId ==
                                                          6 ||
                                                      element.inspectionStatusId ==
                                                          7)
                                                  .isNotEmpty &&
                                              searchOutletList
                                                  .where((element) =>
                                                      element
                                                          .inspectionStatusId ==
                                                      5)
                                                  .isEmpty) ||
                                      searchOutletList
                                          .where((element) =>
                                              element.inspectionStatusId != 6 &&
                                              element.inspectionStatusId != 7)
                                          .isEmpty
                                  ? Visibility(
                                      visible: widget.category == 1 &&
                                          !widget.completeStatus &&
                                          searchOutletList.isNotEmpty,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.white),
                                        onPressed: () {
                                          showCompleteSheet();
                                        },
                                        child: CText(
                                          text: "Complete task",
                                          textColor: AppTheme.colorPrimary,
                                          fontFamily: AppTheme.poppins,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ))
                                  : Container(),

                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      !widget.completeStatus &&
                                      widget.fromActive &&
                                      widget.task?.primary == true &&
                                      widget.taskId != null &&
                                      widget.statusId == 2
                                  ? Visibility(
                                      visible: !widget.completeStatus &&
                                          widget.fromActive &&
                                          widget.taskId != null &&
                                          widget.statusId == 2,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.white),
                                        onPressed: () {
                                          /*    Utils().showYesNoAlert(
                                              context: context,
                                              message: "Note",
                                              onYesPressed: () {
                                                Get.back();
                                                // finishTaskWithInspectoer();
                                              },
                                              onNoPressed: () {

                                              });*/
                                          createInspection();
                                        },
                                        child: CText(
                                          text: "Finish Inspection",
                                          textColor: AppTheme.colorPrimary,
                                          fontFamily: AppTheme.poppins,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ))
                                  : Container(),

                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      widget.taskId == null
                                  ? GestureDetector(
                                      onTap: () {
                                        showAddTaskSheet(true);
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            left: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            right: BorderSide(
                                              color: Colors.transparent,
                                              width: 0,
                                            ),
                                            bottom: BorderSide(
                                              color: AppTheme.textPrimary,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                        child: CText(
                                          text: "Add Liquor Task",
                                          fontSize: AppTheme.medium - 1,
                                          textColor: AppTheme.textPrimary,
                                          fontFamily: AppTheme.poppins,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : Container(),

                              !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      widget.completeStatus &&
                                      widget.category == 1
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.white),
                                      onPressed: () {
                                        getDownloadReport();
                                      },
                                      child: CText(
                                        text: "Download Report",
                                        textColor: AppTheme.colorPrimary,
                                        fontFamily: AppTheme.poppins,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : Container(),
                              const SizedBox(
                                width: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  CText(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    text: "Entity Details :",
                    textColor: AppTheme.black,
                    fontFamily: AppTheme.urbanist,
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
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        entity?.logoUrl != null
                            ? Center(
                                child: Image.network(
                                  entity?.logoUrl ?? "",
                                  height: 40,
                                  width: 40,
                                ),
                              )
                            : Container(),
                        const SizedBox(
                          height: 10,
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
                                  text: "Status",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.licenseStatus ?? "",
                                  textColor: AppTheme.colorPrimary,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.large,
                                  fontWeight: FontWeight.w700,
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
                                  text: "License No :",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.licenseNumber ?? "",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Monthly Limit",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.monthlyLimit.toString() ?? "",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.large,
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
                                  text: "Expiry Date :",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity != null
                                      ? DateFormat(dateFormat)
                                          .format(entity!.licenseExpiryDate)
                                      : "",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Opening Hours",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.openingTime ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.large,
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
                                  text: "Closing Hours",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.closingTime ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Classification : ",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.classification ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Ownership Type : ",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.ownerShipType ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.managerName ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Manager Contact : ",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.managerContactNumber ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Role Name : ",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.roleName ?? "-",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                                  text: "Last Inspection Date : ",
                                  textColor: AppTheme.titleGray,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                CText(
                                  padding: const EdgeInsets.only(top: 2),
                                  textAlign: TextAlign.center,
                                  text: entity?.lastVisitedDate == null
                                      ? "-"
                                      : "${DateFormat(dateFormat).format(DateFormat("yyyy-MM-ddTHH:mm:ss.SSS").parse(entity!.lastVisitedDate!))} \n${DateFormat("hh:mm:ss aa").format(DateFormat("yyyy-MM-ddTHH:mm:ss.SSS").parse(entity!.lastVisitedDate!))}",
                                  textColor: AppTheme.textBlack,
                                  fontFamily: AppTheme.urbanist,
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
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  widget.category == 1
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CText(
                                    text: "Entity Outlets :",
                                    textColor: AppTheme.black,
                                    fontFamily: AppTheme.urbanist,
                                    fontSize: AppTheme.big_20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  if (!storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                      widget.fromActive &&
                                      widget.statusId != 6 &&
                                      widget.statusId != 7)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.colorPrimary),
                                      onPressed: () {
                                        showAddOutletSheet(null);
                                      },
                                      child: CText(
                                        text: "Add Outlet",
                                        textColor: AppTheme.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5, bottom: 10),
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            setState(() {
                                              tabType = 1;
                                              outletList.clear();
                                              for (var item
                                                  in searchOutletList) {
                                                if (tabType == 2 &&
                                                    item.newAdded == true) {
                                                  outletList.add(item);
                                                } else if (tabType == 1 &&
                                                    item.newAdded == false) {
                                                  outletList.add(item);
                                                }
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.only(top: 20),
                                            child: Column(
                                              children: [
                                                CText(
                                                    text: "Active Outlets",
                                                    textColor: tabType == 1
                                                        ? AppTheme.black
                                                        : AppTheme
                                                            .textColorGray,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppTheme.urbanist,
                                                    fontSize: AppTheme.medium),
                                                Container(
                                                  height: 3,
                                                  margin: const EdgeInsets.only(
                                                      top: 8),
                                                  color: tabType == 1
                                                      ? AppTheme.colorPrimary
                                                      : AppTheme.mainBackground,
                                                )
                                              ],
                                            ),
                                          ))),
                                  Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            setState(() {
                                              outletList.clear();
                                              tabType = 2;
                                              for (var item
                                                  in searchOutletList) {
                                                print(jsonEncode(item));
                                                if (tabType == 2 &&
                                                    item.newAdded == true) {
                                                  outletList.add(item);
                                                } else if (tabType == 1 &&
                                                    item.newAdded == false) {
                                                  outletList.add(item);
                                                }
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.only(top: 20),
                                            child: Column(
                                              children: [
                                                CText(
                                                    text: "Inactive Outlets",
                                                    textColor: tabType == 2
                                                        ? AppTheme.black
                                                        : AppTheme
                                                            .textColorGray,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppTheme.urbanist,
                                                    fontSize: AppTheme.medium),
                                                Container(
                                                  height: 3,
                                                  margin: const EdgeInsets.only(
                                                      top: 8),
                                                  color: tabType == 2
                                                      ? AppTheme.colorPrimary
                                                      : AppTheme.mainBackground,
                                                )
                                              ],
                                            ),
                                          ))),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20, bottom: 20),
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: AppTheme.white,
                              ),
                              child: TextFormField(
                                controller: _searchOutlet,
                                onChanged: (searchText) {
                                  outletList.clear();
                                  setState(() {
                                    if (searchText.isEmpty) {
                                      for (var item in searchOutletList) {
                                        if (item.outletStatus == null) {
                                          item.newAdded = true;
                                        }
                                        if (tabType == 2 &&
                                            item.newAdded == true) {
                                          outletList.add(item);
                                        } else if (tabType == 1 &&
                                            item.newAdded == false) {
                                          outletList.add(item);
                                        }
                                      }
                                    } else {
                                      for (var item in searchOutletList) {
                                        if (item.outletName
                                            .toLowerCase()
                                            .contains(
                                                searchText.toLowerCase())) {
                                          if (item.outletStatus == null) {
                                            item.newAdded = true;
                                          }
                                          if (tabType == 2 &&
                                              item.newAdded == true) {
                                            outletList.add(item);
                                          } else if (tabType == 1 &&
                                              item.newAdded == false) {
                                            outletList.add(item);
                                          }
                                        }
                                      }
                                    }
                                  });
                                },
                                maxLines: 1,
                                cursorColor: AppTheme.colorPrimary,
                                cursorWidth: 2,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.all(5),
                                    hintText: searchHint,
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppTheme.grey,
                                    ),
                                    hintStyle: TextStyle(
                                        fontFamily: AppTheme.urbanist,
                                        fontWeight: FontWeight.w400,
                                        color: AppTheme.black,
                                        fontSize: AppTheme.large)),
                              ),
                            ),
                            outletList.isNotEmpty &&
                                    ownerShipList.isNotEmpty &&
                                    outletServiceList.isNotEmpty
                                ? ListView.builder(
                                    padding: const EdgeInsets.only(top: 20),
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: outletList.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          debugPrint(outletList[index]
                                              .inspectorId
                                              .toString());
                                          debugPrint(storeUserData
                                              .getInt(USER_ID)
                                              .toString());

                                          if (outletList[index].inspectorId ==
                                                  0 ||
                                              (outletList[index].inspectorId ==
                                                      storeUserData
                                                          .getInt(USER_ID) &&
                                                  widget.task?.primary ==
                                                      true)) {
                                            if (outletList[index]
                                                    .inspectionStatusId <=
                                                5) {
                                              Get.to(
                                                      transition: Transition
                                                          .rightToLeft,
                                                      OutletDetailScreen(
                                                          entity: entity!,
                                                          fromInactive: tabType != 2 &&
                                                              outletList[index]
                                                                  .newAdded,
                                                          statusId: outletList[index]
                                                              .inspectionStatusId,
                                                          inspectionId:
                                                              outletList[index]
                                                                  .inspectionId,
                                                          outlet:
                                                              outletList[index],
                                                          isNew:
                                                              outletList[index]
                                                                  .newAdded,
                                                          taskId: widget.taskId,
                                                          primary: widget.task
                                                                  ?.primary ??
                                                              false,
                                                          mainTaskId: widget
                                                                  .task
                                                                  ?.mainTaskId ??
                                                              0,
                                                          isAgentEmployees: widget
                                                              .isAgentEmployees,
                                                          taskType: widget.task
                                                                  ?.taskType ??
                                                              0))
                                                  ?.whenComplete(() {
                                                getEntityDetail();
                                              });
                                            } else {
                                              Get.to(
                                                  transition:
                                                      Transition.rightToLeft,
                                                  InspectionDetailScreen(
                                                    task: widget.task!,
                                                    inspectionId:
                                                        outletList[index]
                                                            .inspectionId,
                                                    completeStatus: widget
                                                            .completeStatus &&
                                                        widget.category == 0,
                                                  ));
                                            }
                                          } else if (storeUserData
                                              .getBoolean(IS_AGENT_LOGIN)) {
                                            Get.to(
                                                transition:
                                                    Transition.rightToLeft,
                                                InspectionDetailScreen(
                                                  task: widget.task!,
                                                  inspectionId:
                                                      outletList[index]
                                                          .inspectionId,
                                                  completeStatus:
                                                      widget.completeStatus &&
                                                          widget.category == 0,
                                                ));
                                          }
                                        },
                                        child: Card(
                                          color: AppTheme.white,
                                          margin: const EdgeInsets.only(
                                              left: 20, right: 20, bottom: 10),
                                          surfaceTintColor: AppTheme.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                        child: CText(
                                                      textAlign:
                                                          TextAlign.start,
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 10,
                                                              top: 10,
                                                              bottom: 5),
                                                      text: outletList[index]
                                                          .outletName,
                                                      textColor:
                                                          AppTheme.colorPrimary,
                                                      fontFamily:
                                                          AppTheme.urbanist,
                                                      fontSize: AppTheme.large,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    )),
                                                    outletList[index]
                                                                .inspectionStatusId !=
                                                            0
                                                        ? Expanded(
                                                            flex: 0,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5),
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 10,
                                                                      top: 5,
                                                                      bottom:
                                                                          5),
                                                              decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .all(
                                                                          Radius.circular(
                                                                              5)),
                                                                  color: AppTheme.getStatusColor(
                                                                      outletList[
                                                                              index]
                                                                          .inspectionStatusId)),
                                                              child: CText(
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                text: outletList[index]
                                                                            .inspectionStatusId ==
                                                                        1
                                                                    ? "Pending"
                                                                    : outletList[index].inspectionStatusId ==
                                                                            2
                                                                        ? "In Progress"
                                                                        : outletList[index].inspectionStatusId ==
                                                                                3
                                                                            ? "Not Accepted"
                                                                            : outletList[index].inspectionStatusId == 6 || outletList[index].inspectionStatusId == 7
                                                                                ? "Completed"
                                                                                : taskStatus.firstWhere((item) => item.id == outletList[index].inspectionStatusId).text,
                                                                textColor:
                                                                    AppTheme
                                                                        .white,
                                                                fontFamily:
                                                                    AppTheme
                                                                        .urbanist,
                                                                fontSize:
                                                                    AppTheme
                                                                        .small,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ))
                                                        : Container()
                                                  ],
                                                ),
                                                CText(
                                                  textAlign: TextAlign.start,
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 10),
                                                  text: outletList[index]
                                                      .ownerShipType,
                                                  textColor:
                                                      AppTheme.grayAsparagus,
                                                  fontFamily: AppTheme.urbanist,
                                                  fontSize: AppTheme.large,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                outletList[index].newAdded &&
                                                        outletList[index]
                                                                .inspectionStatusId <
                                                            2
                                                    ? Row(
                                                        children: [
                                                          Expanded(
                                                              child: CText(
                                                            textAlign:
                                                                TextAlign.start,
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 10,
                                                                    top: 0,
                                                                    bottom: 5),
                                                            text: outletList[
                                                                    index]
                                                                .serviceType,
                                                            textColor: AppTheme
                                                                .grayAsparagus,
                                                            fontFamily: AppTheme
                                                                .urbanist,
                                                            fontSize:
                                                                AppTheme.large,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          )),
                                                          GestureDetector(
                                                            onTap: () {
                                                              showAddOutletSheet(
                                                                  outletList[
                                                                      index]);
                                                            },
                                                            behavior:
                                                                HitTestBehavior
                                                                    .translucent,
                                                            child: CText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 10,
                                                                      top: 5,
                                                                      bottom:
                                                                          5),
                                                              text: "EDIT",
                                                              textColor: AppTheme
                                                                  .colorPrimary,
                                                              fontFamily:
                                                                  AppTheme
                                                                      .urbanist,
                                                              fontSize: AppTheme
                                                                  .large,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 10),
                                                            width: 0.5,
                                                            height:
                                                                AppTheme.big_20,
                                                            color:
                                                                AppTheme.grey,
                                                          ),
                                                          IconButton(
                                                              onPressed: () {
                                                                Utils()
                                                                    .showYesNoAlert(
                                                                        context:
                                                                            context,
                                                                        message:
                                                                            "Are you sure you want to delete the outlet?",
                                                                        onYesPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();

                                                                          deleteOutlet(
                                                                              outletList[index].outletId);
                                                                        },
                                                                        onNoPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                color: AppTheme
                                                                    .red,
                                                                size: 20,
                                                              ))
                                                        ],
                                                      )
                                                    : CText(
                                                        textAlign:
                                                            TextAlign.start,
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 10,
                                                                top: 0,
                                                                bottom: 5),
                                                        text: outletList[index]
                                                            .serviceType,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                : Container()
                          ],
                        )
                      : Column(
                          children: [
                            list.isNotEmpty
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CText(
                                        padding: const EdgeInsets.only(
                                            left: 20, right: 20),
                                        text: "Recent Inspection Logs",
                                        textColor: AppTheme.black,
                                        fontFamily: AppTheme.urbanist,
                                        fontSize: AppTheme.big_20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(
                                              transition:
                                                  Transition.rightToLeft,
                                              PatrolVisitsAll(
                                                place: entity!,
                                                list: list,
                                              ));
                                        },
                                        child: CText(
                                          padding: const EdgeInsets.only(
                                              left: 20, right: 20),
                                          textAlign: TextAlign.end,
                                          text: "VIEW ALL LOGS",
                                          textColor: AppTheme.textColorTwo,
                                          fontFamily: AppTheme.urbanist,
                                          fontSize: AppTheme.medium,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    ],
                                  )
                                : Container(),
                            list.isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    scrollDirection: Axis.vertical,
                                    itemCount:
                                        list.length > 4 ? 4 : list.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {},
                                        child: Card(
                                            elevation: 2,
                                            color: AppTheme.white,
                                            surfaceTintColor: AppTheme.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            child: Column(
                                              children: [
                                                Utils()
                                                    .sizeBoxHeight(height: 15),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 20,
                                                                right: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text: "Visit ID",
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 20,
                                                                left: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text: list[index]
                                                            .patrolId
                                                            .toString(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Utils()
                                                    .sizeBoxHeight(height: 5),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 20,
                                                                right: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text: "Date & Time",
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    // 2024-04-29T18:49:24.103
                                                    Expanded(
                                                      flex: 3,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 20,
                                                                left: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text:
                                                            "${DateFormat(dateFormat).format(DateFormat(fullDateTimeFormat).parse(list[index].createdOn))} \n${DateFormat("hh:mm:ss aa").format(DateFormat(fullDateTimeFormat).parse(list[index].createdOn))}",
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Utils()
                                                    .sizeBoxHeight(height: 5),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 20,
                                                                right: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text: "Comments",
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: CText(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 20,
                                                                left: 10),
                                                        textAlign:
                                                            TextAlign.start,
                                                        text: list[index]
                                                            .comments,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textColor: AppTheme
                                                            .textColorRed,
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Utils()
                                                    .sizeBoxHeight(height: 15),
                                              ],
                                            )),
                                      );
                                    })
                                : Container(),
                          ],
                        ),
                ],
              ),
            )),
            widget.category != 1 && restaurantInspectionStatusId < 6
                ? Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewPadding.bottom),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Visibility(
                          visible: !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                              widget.fromActive,
                          child: Expanded(
                              child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint(widget.taskId.toString());
                                debugPrint(widget.statusId.toString());
                                debugPrint(widget.task?.primary.toString());
                                if (widget.taskId != null) {
                                  if (widget.statusId == 5 ||
                                      widget.task?.primary == true) {
                                    Get.to(
                                        transition: Transition.rightToLeft,
                                        CreateNewPatrol(
                                          entityId: widget.entityId,
                                          taskId: widget.taskId,
                                          statusId: widget.statusId,
                                          inspectionId: widget.inspectionId,
                                          mainTaskId:
                                              widget.task?.mainTaskId ?? 0,
                                          primary:
                                              widget.task?.primary ?? false,
                                          newAdded: false,
                                          isAgentEmployees:
                                              widget.isAgentEmployees,
                                          taskType: widget.task?.taskType ?? 0,
                                        ))?.then((value) {
                                      if (value != null) {
                                        if (!mounted) return;
                                        setState(() {
                                          widget.statusId = value["statusId"];
                                          widget.inspectionId =
                                              value["inspectionId"];
                                          widget.taskId = value["taskId"];
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
                                backgroundColor: widget.taskId != null
                                    ? AppTheme.colorPrimary
                                    : AppTheme.paleGray,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: CText(
                                textAlign: TextAlign.center,
                                text: widget.statusId == 5
                                    ? "Continue Inspection"
                                    : "Create Inspection",
                                textColor: AppTheme.textPrimary,
                                fontSize: AppTheme.large,
                                fontFamily: AppTheme.urbanist,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ),
                        Visibility(
                            visible:
                                !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                                    widget.taskId != null &&
                                    widget.inspectionId != 0 &&
                                    widget.task?.primary == true,
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
                                        showRejectRemarkSheet(widget.taskId);
                                      },
                                      onNoPressed: () {
                                        Navigator.of(context).pop();
                                      });
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: widget.taskId != null
                                      ? AppTheme.colorPrimary
                                      : AppTheme.grey,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                child: CText(
                                  text: "Cancel Inspection",
                                  textColor: AppTheme.textPrimary,
                                  textAlign: TextAlign.center,
                                  fontSize: AppTheme.large,
                                  fontFamily: AppTheme.urbanist,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> getVisitDetail() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      Api().callAPI(context, "Mobile/Entity/GetPatrolLogs", {
        "patrolId": 0,
        "dateFilter": null,
        "entityId": widget.entityId.toString(),
        "userId": storeUserData.getInt(USER_ID).toString()
      }).then((value) async {
        print(value);
        setState(() {
          var data = detailFromJson(value);
          if (data.data.isNotEmpty) {
            list.clear();
            list.addAll(data.data.reversed);
          } else {
            if (data.message.isNotEmpty) {
              Utils().showAlert(
                  buildContext: context,
                  message: data.message,
                  onPressed: () {
                    Navigator.of(context).pop();
                  });
            }
          }
        });
      });
    }
  }

  Future<void> getOutletService() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      Api()
          .getAPI(context, "Mobile/Entity/GetOutletService")
          .then((value) async {
        if (value == null) {
          return;
        }
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            outletServiceList.clear();
            outletServiceList.addAll(data.data);
          });
        } else {
          debugPrint("getOutletService ${data.message}");
          // Utils().showAlert(
          //     buildContext: context,
          //     message: data.message,
          //     onPressed: () {
          //       Navigator.of(context).pop();
          //     });
        }
      });
    }
  }

  Future<void> getOutletOwnerShip() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
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
          debugPrint("getOutletOwnerShip ${data.message}");
          /*  Utils().showAlert(
              buildContext: context,
              message: data.message,
              onPressed: () {
                Navigator.of(context).pop();
              });*/
        }
      });
    }
  }

  void showAddTaskSheet(bool isHideAgents) {
    var taskName = TextEditingController();
    var notes = TextEditingController();
    //   List<String> entities = [];
    List<String> users = [];
    List<String> primaryUsers = [];
    List<String> agents = [];
    //  List<SearchEntityData> selectedEntity = [];
    List<AllUserData> selectedUsers = [];
    List<AllUserData> selectedPrimaryUsers = [];
    List<SearchEntityData> selectedAgents = [];
    // AllUserData? primaryInspector;
    FocusNode node = FocusNode();
    FocusNode notesNode = FocusNode();

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: MediaQuery.of(context).size.height - 50,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust padding based on keyboard
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: CText(
                        padding:
                            const EdgeInsets.only(right: 20, left: 10, top: 10),
                        textAlign: TextAlign.center,
                        text: "DONE",
                        textColor: AppTheme.black,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: taskName,
                    hint: "",
                    focusNode: node,
                    value: taskName.text,
                    title: 'Task Name :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  FormTextField(
                    onTap: () {
                      Get.to(
                              SelectInspector(
                                isPrimary: true,
                                selectedUsers: selectedUsers,
                                primaryInspector: selectedPrimaryUsers,
                              ),
                              preventDuplicates: false)
                          ?.then((value) {
                        if (value != null) {
                          myState(() {
                            primaryUsers.clear();
                            users.clear();
                            selectedUsers.clear();
                            selectedPrimaryUsers = value;
                            for (var test in selectedPrimaryUsers) {
                              primaryUsers.add(test.name);
                            }
                            node.unfocus();
                            notesNode.unfocus();
                            FocusScope.of(context).unfocus();
                          });
                        }
                      });
                    },
                    hint: "",
                    value: primaryUsers.isNotEmpty
                        ? primaryUsers.join(", ").toString()
                        : "",
                    title: 'Primary Inspector :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  FormTextField(
                    onTap: () {
                      if (primaryUsers.isEmpty) {
                        Utils().showAlert(
                            buildContext: buildContext,
                            message: "Please select primary inspector first.",
                            onPressed: () {
                              Navigator.of(context).pop();
                            });
                      } else {
                        Get.to(
                                SelectInspector(
                                  primaryInspector: selectedPrimaryUsers,
                                  isPrimary: false,
                                  selectedUsers: selectedUsers,
                                ),
                                preventDuplicates: false)
                            ?.then((value) {
                          if (value != null) {
                            myState(() {
                              users.clear();
                              selectedUsers = value;
                              for (var test in selectedUsers) {
                                users.add(test.name);
                              }
                              node.unfocus();
                              notesNode.unfocus();
                              FocusScope.of(context).unfocus();
                            });
                          }
                        });
                      }
                    },
                    hint: "",
                    value: users.isNotEmpty ? users.join(", ").toString() : "",
                    title: 'Other Inspectors :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  Visibility(
                    visible: isHideAgents,
                    child: FormTextField(
                      onTap: () {
                        List<SearchEntityData> list = [];
                        list.add(
                            SearchEntityData(entityId: 1, entityName: "MMI"));
                        list.add(
                            SearchEntityData(entityId: 2, entityName: "AE"));
                        Get.to(
                                SelectAgents(
                                  list: list,
                                  selectedAgents: selectedAgents,
                                ),
                                preventDuplicates: false)
                            ?.then((value) {
                          if (value != null) {
                            myState(() {
                              agents.clear();
                              selectedAgents = value;
                              for (var test in selectedAgents) {
                                agents.add(test.entityName);
                              }
                              node.unfocus();
                              notesNode.unfocus();
                              FocusScope.of(context).unfocus();
                            });
                          }
                        });
                      },
                      hint: "",
                      value:
                          agents.isNotEmpty ? agents.join(", ").toString() : "",
                      title: 'Agents :',
                      inputBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      textColor: AppTheme.grayAsparagus,
                      inputType: TextInputType.text,
                    ),
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: notes,
                    hint: "",
                    focusNode: notesNode,
                    value: notes.text,
                    title: notesTitle,
                    minLines: 2,
                    maxLines: 3,
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          if (taskName.text.isNotEmpty &&
                              selectedPrimaryUsers.isNotEmpty &&
                              selectedUsers.isNotEmpty &&
                              (!isHideAgents || selectedAgents.isNotEmpty)) {
                            addTask(
                                taskName.text,
                                selectedPrimaryUsers,
                                selectedUsers,
                                selectedAgents,
                                notes.text,
                                isHideAgents);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: taskName.text.isNotEmpty &&
                                  selectedUsers.isNotEmpty &&
                                  selectedUsers.isNotEmpty &&
                                  (!isHideAgents || selectedAgents.isNotEmpty)
                              ? AppTheme.colorPrimary
                              : AppTheme.paleGray,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: CText(
                          text: "Add",
                          textColor: AppTheme.textPrimary,
                          fontSize: AppTheme.large,
                          fontFamily: AppTheme.urbanist,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Utils().sizeBoxHeight(height: 250)
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  Future<void> addTask(
      String taskName,
      List<AllUserData> primaryUser,
      List<AllUserData> otherUsers,
      List<SearchEntityData> agents,
      String notes,
      bool isHideAgents) async {
    // isHideAgents true means Liquor Task  task else DXB task
    if (await Utils().hasNetwork(context, setState)) {
      // List<int> entityList = [];
      List<int> agentUserId = [];

      /*     entities.forEach((entity) => entityList.add(entity.entityId));
      if (!entityList.contains(widget.entityId)) {
        entityList.add(widget.entityId);
      }*/
      for (var entity in agents) {
        agentUserId.add(entity.entityId);
      }
      List<Map<String, dynamic>> users = [];

// Assuming primaryUsers is now a List
//       List<AllUserData> primaryUsers = [primaryUser]; // or already a list

      for (var pUser in primaryUser) {
        users.add({"item1": pUser.departmentUserId, "item2": true});
      }

      for (var user in otherUsers) {
        // Only add if not in primaryUsers
        if (!primaryUser
            .any((pUser) => pUser.departmentUserId == user.departmentUserId)) {
          users.add({"item1": user.departmentUserId, "item2": false});
        }
      }
      var fields = {
        "taskName": taskName,
        "entityId": [widget.entityId],
        "statusId": 1,
        "inspectorId": users,
        "agentUserId": agentUserId.isEmpty ? [] : agentUserId,
        "notes": notes,
        "createdBy": storeUserData.getInt(USER_ID),
        "createdOn":
            DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      };

      // isHideAgents is true means liquor task else DXB task
      /*    if (isHideAgents) {

      } else {
        fields["taskType"] = 2;
      }*/
      fields["taskType"] = 1;
      LogPrint().log("CreateTask $fields");
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);

      Api()
          .callAPI(context, "Department/Task/CreateTask", fields)
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          Navigator.of(context).pop();
          Get.offAll(transition: Transition.rightToLeft, const HomeScreen());
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

  void showCompleteSheet() {
    var remark = TextEditingController();
    FocusNode focusNode = FocusNode();
    var loading = false;
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
                  onChange: (value) {
                    setState(() {});
                  },
                  cardColor: AppTheme.mainBackground,
                  hint: "",
                  controller: remark,
                  textColor: AppTheme.grayAsparagus,
                  fontFamily: AppTheme.urbanist,
                  title: notesTitle,
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
                            message: "Please enter the Notes.",
                            onPressed: () {
                              Navigator.of(context).pop();
                            });
                      } else {
                        setState(() {
                          loading = true;
                        });
                        Navigator.pop(context);
                        completeTask(remark.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: remark.text.isNotEmpty
                          ? AppTheme.colorPrimary
                          : AppTheme.paleGray,
                      minimumSize: const Size(200, 40),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: AppTheme.white,
                          )
                        : const Text(
                            'Complete Task',
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
                  cardColor: AppTheme.mainBackground,
                  hint: "",
                  controller: remark,
                  textColor: AppTheme.grayAsparagus,
                  fontFamily: AppTheme.urbanist,
                  title: notesTitle,
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
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Department/Task/UpdateInspectionTaskStatus", {
        "inspectionTaskId": id,
        "mainTaskId": widget.task!.mainTaskId,
        "inspectionId": widget.inspectionId,
        // "inspectorId": storeUserData.getInt(USER_ID),
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

  Future<void> deleteOutlet(int outletId) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context, "Mobile/NewOutlet/Delete?newOutletid=$outletId")
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          setState(() {
            var position = searchOutletList
                .indexWhere((test) => test.outletId == outletId);
            searchOutletList.removeAt(position);
            outletList.clear();
            List<OutletData> inActiveList = [];
            for (var item in searchOutletList) {
              if (item.newAdded == true) {
                inActiveList.add(item);
              }
              if (tabType == 2 && item.newAdded == true) {
                outletList.add(item);
              } else if (tabType == 1 && item.newAdded == false) {
                outletList.add(item);
              }
            }
            storeUserData.setString(
                entityId.toString(), OutletData.encode(inActiveList));
          });
        } else {
          Utils().showAlert(
              buildContext: context,
              message: noEntityMessage,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  String formatEmiratesID(String id) {
    // ignore: deprecated_member_use
    id = id.replaceAll(RegExp(r'\D'), '');
    if (id.length != 15) {
      throw const FormatException(
          "Invalid Emirates ID length. It should be 15 digits.");
    }
    return '${id.substring(0, 3)}-${id.substring(3, 7)}-${id.substring(7, 14)}-${id.substring(14, 15)}';
  }

  void showAddOutletSheet(OutletData? model) {
    var maskFormatter = MaskTextInputFormatter(
        mask: 'XXX-XXXX-XXXXXXX-X',
        // ignore: deprecated_member_use
        filter: {"X": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy);
    final itemName = TextEditingController();
    final managerName = TextEditingController();
    final emiratesId = TextEditingController();
    final mobileNumber = TextEditingController();
    final notes = TextEditingController();
    var focusNode = FocusNode();
    var focusNodeButton = FocusNode();
    ownerShipType = null;
    serviceType = null;
    outletType = null;
    if (model != null) {
      setState(() {
        itemName.text = model.outletName;
        managerName.text = model.managerName ?? "";
        emiratesId.text = formatEmiratesID(model.emiratesId ?? "");
        mobileNumber.text = model.contactNumber?.replaceAll("+9715", "") ?? "";
        notes.text = model.notes ?? "";
        ownerShipType =
            AreaData(id: model.ownerShipTypeId, text: model.ownerShipType);
        serviceType =
            AreaData(id: model.serviceTypeId, text: model.serviceType);
        outletType =
            AreaData(id: model.outletTypeId ?? 0, text: model.outletType ?? "");
      });
    }

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: MediaQuery.of(context).size.height - 50,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: CText(
                        padding:
                            const EdgeInsets.only(right: 20, left: 10, top: 10),
                        textAlign: TextAlign.center,
                        text: "DONE",
                        textColor: AppTheme.black,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FormTextField(
                    focusNode: focusNode,
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: itemName,
                    hint: "",
                    value: itemName.text,
                    title: 'Outlet Name :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    hint: "",
                    value: ownerShipType?.text ?? "",
                    title: 'Ownership :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                    onTap: () {
                      selectOutletTypeSheet(
                          ownerShipList, "ownership", myState, focusNodeButton);
                    },
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    hint: "",
                    value: serviceType?.text ?? "",
                    title: 'Service Type :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                    onTap: () {
                      selectOutletTypeSheet(outletServiceList, "service",
                          myState, focusNodeButton);
                    },
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    hint: "",
                    value: outletType?.text ?? "",
                    title: 'Outlet Type :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                    onTap: () {
                      List<AreaData> types = [];
                      types.add(AreaData(id: 1, text: "Main Outlet"));
                      types.add(AreaData(id: 2, text: "Sub Outlet"));
                      selectOutletTypeSheet(
                          types, "type", myState, focusNodeButton);
                    },
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: managerName,
                    hint: "",
                    value: managerName.text,
                    title: 'Manager Name :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    inputFormatters: [
                      maskFormatter,
                    ],
                    controller: emiratesId,
                    hint: "XXX-XXXX-XXXXXXX-X",
                    value: emiratesId.text,
                    title: 'Emirates ID :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.number,
                  ),
                  FormMobileTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: mobileNumber,
                    hint: "",
                    value: mobileNumber.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(8),
                      // Limits the length to 8 characters
                    ],
                    title: 'Contact Number :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.phone,
                  ),
                  FormTextField(
                    onChange: (value) {
                      myState(() {});
                    },
                    controller: notes,
                    hint: "",
                    value: notes.text,
                    title: notesTitle,
                    minLines: 2,
                    maxLines: 2,
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.text,
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: ElevatedButton(
                        focusNode: focusNodeButton,
                        onPressed: () {
                          if (itemName.text.isEmpty) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please enter outlet name",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (serviceType == null) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please select service type",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (ownerShipType == null) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please select ownership type",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (outletType == null) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please select outlet type",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (managerName.text.isEmpty) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please enter manager name",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (emiratesId.text.isEmpty ||
                              emiratesId.text.length != 18) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please enter valid emiratesID",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (mobileNumber.text.isEmpty ||
                              mobileNumber.text.length != 8) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please enter valid contact number",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else if (notes.text.isEmpty) {
                            Utils().showAlert(
                                buildContext: buildContext,
                                message: "Please enter notes",
                                onPressed: () {
                                  Navigator.of(context).pop();
                                });
                          } else {
                            if (model != null) {
                              updateOutlet(
                                  myState,
                                  OutletData(
                                      outletId: model.outletId,
                                      outletName: itemName.text,
                                      ownerShipTypeId: ownerShipType!.id,
                                      serviceTypeId: serviceType!.id,
                                      ownerShipType: ownerShipType!.text,
                                      emiratesId: emiratesId.text
                                          .toString()
                                          .replaceAll("-", ""),
                                      managerName: managerName.text,
                                      contactNumber:
                                          "+9715${mobileNumber.text}",
                                      notes: notes.text,
                                      outletTypeId: outletType!.id,
                                      outletType: outletType!.text,
                                      newAdded: true,
                                      serviceType: serviceType!.text,
                                      inspectionStatusId:
                                          model.inspectionStatusId,
                                      inspectorId:
                                          storeUserData.getInt(USER_ID),
                                      inspectionId: model.inspectionId));
                            } else {
                              addOutlet(
                                  myState,
                                  OutletData(
                                      outletId: 0,
                                      outletName: itemName.text,
                                      ownerShipTypeId: ownerShipType!.id,
                                      serviceTypeId: serviceType!.id,
                                      ownerShipType: ownerShipType!.text,
                                      emiratesId: emiratesId.text
                                          .toString()
                                          .replaceAll("-", ""),
                                      managerName: managerName.text,
                                      contactNumber:
                                          "+9715${mobileNumber.text}",
                                      notes: notes.text,
                                      newAdded: true,
                                      inspectorId:
                                          storeUserData.getInt(USER_ID),
                                      serviceType: serviceType!.text,
                                      outletTypeId: outletType!.id,
                                      outletType: outletType!.text,
                                      inspectionStatusId: 0,
                                      inspectionId: 0));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: serviceType != null &&
                                  itemName.text.isNotEmpty &&
                                  managerName.text.isNotEmpty &&
                                  emiratesId.text.isNotEmpty &&
                                  mobileNumber.text.isNotEmpty &&
                                  ownerShipType != null &&
                                  outletType != null &&
                                  notes.text.isNotEmpty &&
                                  emiratesId.text.length == 18 &&
                                  mobileNumber.text.length == 8
                              ? AppTheme.colorPrimary
                              : AppTheme.paleGray,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: CText(
                          text: model == null ? "Add" : "Update",
                          textColor: AppTheme.textPrimary,
                          fontSize: AppTheme.large,
                          fontFamily: AppTheme.urbanist,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Utils().sizeBoxHeight(height: 250)
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  Future<void> updateOutlet(StateSetter myState, OutletData model) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Mobile/NewOutlet/Update", {
        "newOutletId": model.outletId,
        "entityId": entityId,
        "outletName": model.outletName,
        "ownerShipTypeId": model.ownerShipTypeId,
        "serviceTypeId": model.serviceTypeId,
        "outletTypeId": model.outletTypeId,
        "managerName": model.managerName,
        "contactNumber": model.contactNumber,
        "emiratesId": model.emiratesId,
        "notes": model.notes,
        "createdBy": storeUserData.getInt(USER_ID),
        "createdOn":
            DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
        "modifiedOn":
            DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
        "modifiedBy": storeUserData.getInt(USER_ID)
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          myState(() {
            var position = searchOutletList
                .indexWhere((test) => test.outletId == model.outletId);
            searchOutletList.removeAt(position);
            searchOutletList.insert(position, model);
            outletList.clear();
            List<OutletData> inActiveList = [];
            for (var item in searchOutletList) {
              if (item.newAdded == true) {
                inActiveList.add(item);
              }
              if (tabType == 2 && item.newAdded == true) {
                outletList.add(item);
              } else if (tabType == 1 && item.newAdded == false) {
                outletList.add(item);
              }
            }
            print("inActiveList.length ");
            print(inActiveList.length);
            storeUserData.setString(
                entityId.toString(), OutletData.encode(inActiveList));
          });
          Navigator.of(context).pop();
        } else {
          Utils().showAlert(
              buildContext: context,
              message: noEntityMessage,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  Future<void> completeTask(String notes) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Department/Task/UpdateTaskStatus", {
        "mainTaskId": widget.task?.mainTaskId ?? 0,
        // "inspectorId": storeUserData.getInt(USER_ID),
        "finalNotes": notes,
        "statusId": 7,
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200 && data["data"] != null) {
          Navigator.of(context).pop();
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

  Future<void> addOutlet(StateSetter myState, OutletData model) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Mobile/NewOutlet/Create", {
        "newOutletId": 0,
        "entityId": entityId,
        "outletName": model.outletName,
        "ownerShipTypeId": model.ownerShipTypeId,
        "serviceTypeId": model.serviceTypeId,
        "outletTypeId": model.outletTypeId,
        "managerName": model.managerName,
        "contactNumber": model.contactNumber,
        "emiratesId": model.emiratesId,
        "notes": model.notes,
        "createdBy": storeUserData.getInt(USER_ID),
        "createdOn":
            DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
        "modifiedOn":
            DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
        "modifiedBy": storeUserData.getInt(USER_ID)
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200 && data["data"] != null) {
          myState(() {
            model.outletId = data["data"];
            searchOutletList.insert(0, model);
            outletList.clear();
            List<OutletData> inActiveList = [];
            for (var item in searchOutletList) {
              if (item.newAdded == true) {
                inActiveList.add(item);
              }
              if (tabType == 2 && item.newAdded == true) {
                outletList.add(item);
              } else if (tabType == 1 && item.newAdded == false) {
                outletList.add(item);
              }
            }
            storeUserData.setString(
                entityId.toString(), OutletData.encode(inActiveList));
          });
          Navigator.of(context).pop();
        } else {
          Utils().showAlert(
              buildContext: context,
              message: noEntityMessage,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  void selectOutletTypeSheet(List<AreaData> list, String types,
      StateSetter myState, FocusNode focusNode) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: MediaQuery.of(context).size.height - 50,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: CText(
                        padding: const EdgeInsets.all(20),
                        textAlign: TextAlign.center,
                        text: "DONE",
                        textColor: AppTheme.black,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ListView.builder(
                      padding: const EdgeInsets.only(top: 20),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              myState(() {
                                if (types == "ownership") {
                                  ownerShipType = list[index];
                                } else if (types == "service") {
                                  serviceType = list[index];
                                } else {
                                  outletType = list[index];
                                }
                              });
                            });
                            Navigator.of(context).pop();
                          },
                          child: Card(
                            color: AppTheme.white,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 10),
                            surfaceTintColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: CText(
                              textAlign: TextAlign.start,
                              padding: const EdgeInsets.all(15.0),
                              text: list[index].text,
                              textColor: AppTheme.colorPrimary,
                              fontFamily: AppTheme.urbanist,
                              fontSize: AppTheme.large,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                  Utils().sizeBoxHeight()
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
      myState(() {
        focusNode.requestFocus();
      });
    });
  }

  Future<void> getDownloadReport() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) {
        return;
      }
      LoadingIndicatorDialog().show(context);
      // http://4.161.39.155:8096/inspectionApi/api/Department/Report/ViewReport?mainTaskId=4512&inspectionId=0
      Api()
          .getAPI(context,
              "Department/Report/ViewReport?mainTaskId=${widget.task!.mainTaskId}&inspectionId=0")
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        print("ViewReport $value");
        if (value != null) {
          var data = jsonDecode(value);
          if (data["data"] != null) {
            final url = Uri.parse(
              data["data"],
            );
            if (await canLaunchUrl(url)) {
              print(url);
              await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
            } else {
              print("Can't launch ${data["data"]}");
            }
          } else {
            Utils().showAlert(
                buildContext: context,
                message: "No Found Report ",
                onPressed: () {
                  Navigator.pop(context);
                });
          }
        } else {
          Utils().showAlert(
              buildContext: context,
              message: "No PDF ",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              });
        }
      });
    }
  }

  // Method to extract filename from URL
  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }

  bool isLoading = false;

  // Method to download and save PDF file
  Future<void> downloadAndOpenPdf(String pdfUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      var status = await requestStoragePermission();
      if (!status) {
        throw Exception('Storage permission denied');
      }

      Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception("Couldn't access the Downloads directory");
      }

      String fileName = getFileNameFromUrl(pdfUrl);
      String savePath = "${downloadsDir.path}/$fileName";

      var response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode == 200) {
        File file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      print("Error: $e");
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download and open PDF')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to request permissions based on Android version
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        return true;
      }
      if (Platform.operatingSystemVersion.contains('33')) {
        return true;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  void createInspection() {
    var agentMap = [];

    var inspectorMap = [];
    var map = {
      "inspectionId": 0,
      "inspectorId": storeUserData.getInt(USER_ID),
      "createdBy": storeUserData.getInt(USER_ID),
      "inspectionTaskId": widget.taskId ?? 0,
      "entityId": widget.entityId,
      "outletId": 0,
      "newOutletId": 0,
      "location": googleAddress,
      "agentEmployeeIds": agentMap,
      "departmentEmployeeId": inspectorMap,
      "createdOn":
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      "comments": "",
      "finalNotes": "",
      "createdByName": "",
      "isTaskCreatedByOwn": widget.taskId == null,
      "statusId": 5,
      "inspectionType": widget.isAgentEmployees ? 1 : 0
    };

    if (widget.task != null && widget.task!.taskType == 1) {
      map["Inspectiontask"] = 1;
    } else if (widget.task != null && widget.task!.taskType == 2) {
      map["ExpiredTask"] = 2;
    }

    print("createInspection $map");
    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/Inspection/CreateInspection", map)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      // LogPrint().log("createInspection response : $value");
      var data = jsonDecode(value);
      if (data["statusCode"] == 200 && data["data"] != null) {
        Get.to(
            transition: Transition.rightToLeft,
            NotesAndAttachmentsScreen(
              inspectionId: data["data"],
              entityId: entityId,
              mainTaskId: widget.task!.mainTaskId,
              taskId: widget.taskId!,
              isDXBTask: widget.task != null &&
                  (widget.task!.taskType == 2 || widget.task!.taskType == 3),
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

  Future getGeoLocationPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _handleLocationServiceDisabled();
      return;
    }

    final permission = await _checkAndRequestPermission();
    if (permission == null) return;

    await _getPositionAndAddress();
  }

  void _handleLocationServiceDisabled() {
    if (!mounted) return;
    Utils().showAlert(
        buildContext: context,
        message: "Location services are disabled.",
        onPressed: () {
          Navigator.of(context).pop();
          Geolocator.openLocationSettings().whenComplete(() {
            getGeoLocationPosition();
          });
        });
  }

  Future<LocationPermission?> _checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) {
      return permission;
    }

    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _handlePermissionDenied();
      return null;
    }

    return permission;
  }

  void _handlePermissionDenied() {
    if (!mounted) return;
    Utils().showAlert(
        buildContext: context,
        message: "Location permissions are denied.",
        onPressed: () {
          Navigator.of(context).pop();
        });
  }

  Future<void> _getPositionAndAddress() async {
    final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ));

    try {
      final placeMarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      LogPrint().log(placeMarks);
      final place = placeMarks[0];
      _updateGoogleAddress(place);
    } on TimeoutException catch (_) {
      LogPrint().log("The request timed out.");
    } catch (e) {
      _setDefaultAddress();
      LogPrint().log("An error occurred: $e");
    }

    LogPrint().log("address$googleAddress");
  }

  void _updateGoogleAddress(Placemark place) {
    if (!mounted) return;
    setState(() {
      googleAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    });
  }

  void _setDefaultAddress() {
    if (mounted) {
      setState(() {
        googleAddress = "Bur Dubai";
      });
    }
  }
}

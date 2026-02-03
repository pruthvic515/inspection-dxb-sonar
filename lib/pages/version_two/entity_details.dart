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

class _AddTaskFormState {
  final taskName = TextEditingController();
  final notes = TextEditingController();
  final List<String> users = [];
  final List<String> primaryUsers = [];
  final List<String> agents = [];
  List<AllUserData> selectedUsers = [];
  List<AllUserData> selectedPrimaryUsers = [];
  List<SearchEntityData> selectedAgents = [];
  final node = FocusNode();
  final notesNode = FocusNode();
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

  void _logEncryptionDetails(
      String encryptedMainTaskId, String encryptedEntityId) {
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
    outletList.clear();
    for (var item in searchOutletList) {
      _markNewOutlet(item);
      if (_shouldAddOutletToList(item)) {
        outletList.add(item);
      }
    }
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
        ) ==
        null;
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildEntityDetailsSection(),
                    const SizedBox(height: 20),
                    _buildCategoryContent(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 220,
      color: AppTheme.colorPrimary,
      width: double.infinity,
      child: Stack(
        children: [
          _buildBackButton(),
          Center(
            child: Column(
              children: [
                _buildEntityTitle(),
                _buildEntityAddress(),
                const SizedBox(height: 15),
                _buildHeaderActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Get.back(result: true);
      },
      child: Padding(
        padding:
            const EdgeInsets.only(left: 10, top: 50, right: 10, bottom: 20),
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
    );
  }

  Widget _buildEntityTitle() {
    return CText(
      textAlign: TextAlign.center,
      padding: const EdgeInsets.only(left: 60, right: 60, top: 65),
      text: entity?.entityName ?? "",
      textColor: AppTheme.textPrimary,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.big,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildEntityAddress() {
    return CText(
      textAlign: TextAlign.center,
      padding: const EdgeInsets.only(left: 60, right: 60, top: 5),
      text: entity?.location?.address ?? "",
      textColor: AppTheme.textPrimary,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
    );
  }

  Widget _buildHeaderActions() {
    final isAgentLogin = storeUserData.getBoolean(IS_AGENT_LOGIN);
    final hasTaskId = widget.taskId != null;

    return Row(
      mainAxisAlignment:
          hasTaskId ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20),
        if (!isAgentLogin && !hasTaskId) _buildAddDxbTaskButton(),
        if (!isAgentLogin &&
            !widget.completeStatus &&
            widget.fromActive &&
            hasTaskId &&
            widget.category != 1 &&
            restaurantInspectionStatusId > 5 &&
            widget.task?.primary == true)
          _buildCompleteTaskButton(),
        if (!isAgentLogin &&
            widget.fromActive &&
            widget.category == 1 &&
            searchOutletList.isNotEmpty &&
            hasTaskId &&
            _shouldShowCategoryOneCompleteButton())
          _buildCategoryOneCompleteButton(),
        if (!isAgentLogin &&
            !widget.completeStatus &&
            widget.fromActive &&
            widget.task?.primary == true &&
            hasTaskId &&
            widget.statusId == 2)
          _buildFinishInspectionButton(),
        if (!isAgentLogin && !hasTaskId) _buildAddLiquorTaskButton(),
        if (!isAgentLogin && widget.completeStatus && widget.category == 1)
          _buildDownloadReportButton(),
        const SizedBox(width: 20),
      ],
    );
  }

  bool _shouldShowCategoryOneCompleteButton() {
    final hasCompletedOutlets = searchOutletList
        .where((element) =>
            element.inspectionStatusId == 6 || element.inspectionStatusId == 7)
        .isNotEmpty;
    final hasInProgressOutlets = searchOutletList
        .where((element) => element.inspectionStatusId == 5)
        .isEmpty;
    final allCompleted = searchOutletList
        .where((element) =>
            element.inspectionStatusId != 6 && element.inspectionStatusId != 7)
        .isEmpty;

    return (widget.task?.primary == true &&
            hasCompletedOutlets &&
            hasInProgressOutlets) ||
        allCompleted;
  }

  Widget _buildAddDxbTaskButton() {
    return GestureDetector(
      onTap: () => showAddTaskSheet(false),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.transparent, width: 0),
            left: BorderSide(color: Colors.transparent, width: 0),
            right: BorderSide(color: Colors.transparent, width: 0),
            bottom: BorderSide(color: AppTheme.textPrimary, width: 2),
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
    );
  }

  Widget _buildCompleteTaskButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.white),
      onPressed: () => showCompleteSheet(),
      child: CText(
        text: "Complete task",
        fontSize: 12,
        textColor: AppTheme.colorPrimary,
        fontFamily: AppTheme.poppins,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildCategoryOneCompleteButton() {
    return Visibility(
      visible: widget.category == 1 &&
          !widget.completeStatus &&
          searchOutletList.isNotEmpty,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.white),
        onPressed: () => showCompleteSheet(),
        child: CText(
          text: "Complete task",
          textColor: AppTheme.colorPrimary,
          fontFamily: AppTheme.poppins,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFinishInspectionButton() {
    return Visibility(
      visible: !widget.completeStatus &&
          widget.fromActive &&
          widget.taskId != null &&
          widget.statusId == 2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.white),
        onPressed: () => createInspection(),
        child: CText(
          text: "Finish Inspection",
          textColor: AppTheme.colorPrimary,
          fontFamily: AppTheme.poppins,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAddLiquorTaskButton() {
    return GestureDetector(
      onTap: () => showAddTaskSheet(true),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.transparent, width: 0),
            left: BorderSide(color: Colors.transparent, width: 0),
            right: BorderSide(color: Colors.transparent, width: 0),
            bottom: BorderSide(color: AppTheme.textPrimary, width: 2),
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
    );
  }

  Widget _buildDownloadReportButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.white),
      onPressed: () => getDownloadReport(),
      child: CText(
        text: "Download Report",
        textColor: AppTheme.colorPrimary,
        fontFamily: AppTheme.poppins,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildEntityDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CText(
          padding: const EdgeInsets.only(left: 20, right: 20),
          text: "Entity Details :",
          textColor: AppTheme.black,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.big_20,
          fontWeight: FontWeight.w700,
        ),
        _buildEntityDetailsCard(),
      ],
    );
  }

  Widget _buildEntityDetailsCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border, width: 1),
        color: AppTheme.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (entity?.logoUrl != null)
            Center(
              child: Image.network(
                entity?.logoUrl ?? "",
                height: 40,
                width: 40,
              ),
            ),
          const SizedBox(height: 10),
          _buildStatusAndLicenseRow(),
          const SizedBox(height: 20),
          _buildMonthlyLimitAndExpiryRow(),
          const SizedBox(height: 20),
          _buildOpeningAndClosingHoursRow(),
          const SizedBox(height: 20),
          _buildClassificationAndOwnershipRow(),
          const SizedBox(height: 20),
          _buildManagerNameAndContactRow(),
          const SizedBox(height: 20),
          _buildRoleNameAndLastInspectionRow(),
        ],
      ),
    );
  }

  Widget _buildStatusAndLicenseRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyLimitAndExpiryRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
                    ? DateFormat(dateFormat).format(entity!.licenseExpiryDate)
                    : "",
                textColor: AppTheme.textBlack,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.large,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningAndClosingHoursRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationAndOwnershipRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildManagerNameAndContactRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildRoleNameAndLastInspectionRow() {
    return Row(
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
          ),
        ),
        const SizedBox(width: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent() {
    if (widget.category == 1) {
      return _buildOutletSection();
    } else {
      return _buildInspectionLogsSection();
    }
  }

  Widget _buildOutletSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOutletHeader(),
        _buildOutletTabs(),
        _buildOutletSearchField(),
        if (outletList.isNotEmpty &&
            ownerShipList.isNotEmpty &&
            outletServiceList.isNotEmpty)
          _buildOutletList(),
      ],
    );
  }

  Widget _buildOutletHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  backgroundColor: AppTheme.colorPrimary),
              onPressed: () => showAddOutletSheet(null),
              child: CText(
                text: "Add Outlet",
                textColor: AppTheme.white,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutletTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 10),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _switchToActiveOutlets(),
              child: Container(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    CText(
                      text: "Active Outlets",
                      textColor: tabType == 1
                          ? AppTheme.black
                          : AppTheme.textColorGray,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.medium,
                    ),
                    Container(
                      height: 3,
                      margin: const EdgeInsets.only(top: 8),
                      color: tabType == 1
                          ? AppTheme.colorPrimary
                          : AppTheme.mainBackground,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _switchToInactiveOutlets(),
              child: Container(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    CText(
                      text: "Inactive Outlets",
                      textColor: tabType == 2
                          ? AppTheme.black
                          : AppTheme.textColorGray,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.medium,
                    ),
                    Container(
                      height: 3,
                      margin: const EdgeInsets.only(top: 8),
                      color: tabType == 2
                          ? AppTheme.colorPrimary
                          : AppTheme.mainBackground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchToActiveOutlets() {
    setState(() {
      tabType = 1;
      outletList.clear();
      for (var item in searchOutletList) {
        if (tabType == 1 && item.newAdded == false) {
          outletList.add(item);
        }
      }
    });
  }

  void _switchToInactiveOutlets() {
    setState(() {
      outletList.clear();
      tabType = 2;
      for (var item in searchOutletList) {
        if (tabType == 2 && item.newAdded == true) {
          outletList.add(item);
        }
      }
    });
  }

  Widget _buildOutletSearchField() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: AppTheme.white,
      ),
      child: TextFormField(
        controller: _searchOutlet,
        onChanged: (searchText) => _handleOutletSearch(searchText),
        maxLines: 1,
        cursorColor: AppTheme.colorPrimary,
        cursorWidth: 2,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(5),
          hintText: searchHint,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppTheme.grey),
          hintStyle: TextStyle(
            fontFamily: AppTheme.urbanist,
            fontWeight: FontWeight.w400,
            color: AppTheme.black,
            fontSize: AppTheme.large,
          ),
        ),
      ),
    );
  }

  void _handleOutletSearch(String searchText) {
    outletList.clear();
    setState(() {
      if (searchText.isEmpty) {
        _populateOutletListFromSearch(searchOutletList);
      } else {
        final filtered = searchOutletList
            .where((item) => item.outletName
                .toLowerCase()
                .contains(searchText.toLowerCase()))
            .toList();
        _populateOutletListFromSearch(filtered);
      }
    });
  }

  void _populateOutletListFromSearch(List<OutletData> items) {
    for (var item in items) {
      if (item.outletStatus == null) {
        item.newAdded = true;
      }
      if (tabType == 2 && item.newAdded == true) {
        outletList.add(item);
      } else if (tabType == 1 && item.newAdded == false) {
        outletList.add(item);
      }
    }
  }

  Widget _buildOutletList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: outletList.length,
      itemBuilder: (context, index) => _buildOutletCard(index),
    );
  }

  Widget _buildOutletCard(int index) {
    final outlet = outletList[index];
    return GestureDetector(
      onTap: () => _handleOutletTap(outlet),
      child: Card(
        color: AppTheme.white,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutletHeaderRow(outlet),
              _buildOutletOwnershipType(outlet),
              if (outlet.newAdded && outlet.inspectionStatusId < 2)
                _buildNewOutletActions(outlet)
              else
                _buildOutletServiceType(outlet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutletHeaderRow(OutletData outlet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CText(
            textAlign: TextAlign.start,
            padding: const EdgeInsets.only(right: 10, top: 10, bottom: 5),
            text: outlet.outletName,
            textColor: AppTheme.colorPrimary,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (outlet.inspectionStatusId != 0)
          Expanded(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: AppTheme.getStatusColor(outlet.inspectionStatusId),
              ),
              child: CText(
                textAlign: TextAlign.start,
                text: _getOutletStatusText(outlet.inspectionStatusId),
                textColor: AppTheme.white,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOutletOwnershipType(OutletData outlet) {
    return CText(
      textAlign: TextAlign.start,
      padding: const EdgeInsets.only(right: 10),
      text: outlet.ownerShipType,
      textColor: AppTheme.grayAsparagus,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildOutletServiceType(OutletData outlet) {
    return CText(
      textAlign: TextAlign.start,
      padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
      text: outlet.serviceType,
      textColor: AppTheme.grayAsparagus,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildNewOutletActions(OutletData outlet) {
    return Row(
      children: [
        Expanded(
          child: CText(
            textAlign: TextAlign.start,
            padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
            text: outlet.serviceType,
            textColor: AppTheme.grayAsparagus,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => showAddOutletSheet(outlet),
          behavior: HitTestBehavior.translucent,
          child: CText(
            textAlign: TextAlign.start,
            padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
            text: "EDIT",
            textColor: AppTheme.colorPrimary,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          width: 0.5,
          height: AppTheme.big_20,
          color: AppTheme.grey,
        ),
        IconButton(
          onPressed: () => _showDeleteOutletConfirmation(outlet.outletId),
          icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 20),
        ),
      ],
    );
  }

  void _showDeleteOutletConfirmation(int outletId) {
    Utils().showYesNoAlert(
      context: context,
      message: "Are you sure you want to delete the outlet?",
      onYesPressed: () {
        Navigator.of(context).pop();
        deleteOutlet(outletId);
      },
      onNoPressed: () => Navigator.of(context).pop(),
    );
  }

  void _handleOutletTap(OutletData outlet) {
    debugPrint(outlet.inspectorId.toString());
    debugPrint(storeUserData.getInt(USER_ID).toString());

    final canAccess = outlet.inspectorId == 0 ||
        (outlet.inspectorId == storeUserData.getInt(USER_ID) &&
            widget.task?.primary == true);
    final isAgentLogin = storeUserData.getBoolean(IS_AGENT_LOGIN);

    if (canAccess) {
      if (outlet.inspectionStatusId <= 5) {
        Get.to(
          transition: Transition.rightToLeft,
          OutletDetailScreen(
            entity: entity!,
            fromInactive: tabType != 2 && outlet.newAdded,
            statusId: outlet.inspectionStatusId,
            inspectionId: outlet.inspectionId,
            outlet: outlet,
            isNew: outlet.newAdded,
            taskId: widget.taskId,
            primary: widget.task?.primary ?? false,
            mainTaskId: widget.task?.mainTaskId ?? 0,
            isAgentEmployees: widget.isAgentEmployees,
            taskType: widget.task?.taskType ?? 0,
          ),
        )?.whenComplete(() => getEntityDetail());
      } else {
        Get.to(
          transition: Transition.rightToLeft,
          InspectionDetailScreen(
            task: widget.task!,
            inspectionId: outlet.inspectionId,
            completeStatus: widget.completeStatus && widget.category == 0,
          ),
        );
      }
    } else if (isAgentLogin) {
      Get.to(
        transition: Transition.rightToLeft,
        InspectionDetailScreen(
          task: widget.task!,
          inspectionId: outlet.inspectionId,
          completeStatus: widget.completeStatus && widget.category == 0,
        ),
      );
    }
  }

  Widget _buildInspectionLogsSection() {
    return Column(
      children: [
        if (list.isNotEmpty) _buildInspectionLogsHeader(),
        if (list.isNotEmpty) _buildInspectionLogsList(),
      ],
    );
  }

  Widget _buildInspectionLogsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CText(
          padding: const EdgeInsets.only(left: 20, right: 20),
          text: "Recent Inspection Logs",
          textColor: AppTheme.black,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.big_20,
          fontWeight: FontWeight.w700,
        ),
        GestureDetector(
          onTap: () {
            Get.to(
              transition: Transition.rightToLeft,
              PatrolVisitsAll(place: entity!, list: list),
            );
          },
          child: CText(
            padding: const EdgeInsets.only(left: 20, right: 20),
            textAlign: TextAlign.end,
            text: "VIEW ALL LOGS",
            textColor: AppTheme.textColorTwo,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.medium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionLogsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: list.length > 4 ? 4 : list.length,
      itemBuilder: (context, index) => _buildInspectionLogCard(index),
    );
  }

  Widget _buildInspectionLogCard(int index) {
    final log = list[index];
    return GestureDetector(
      onTap: () {},
      child: Card(
        elevation: 2,
        color: AppTheme.white,
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Utils().sizeBoxHeight(height: 15),
            _buildLogRow("Visit ID", log.patrolId.toString()),
            Utils().sizeBoxHeight(height: 5),
            _buildLogRow(
              "Date & Time",
              "${DateFormat(dateFormat).format(DateFormat(fullDateTimeFormat).parse(log.createdOn))} \n${DateFormat("hh:mm:ss aa").format(DateFormat(fullDateTimeFormat).parse(log.createdOn))}",
            ),
            Utils().sizeBoxHeight(height: 5),
            _buildLogRow("Comments", log.comments,
                textColor: AppTheme.textColorRed, maxLines: 1),
            Utils().sizeBoxHeight(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(String label, String value,
      {Color? textColor, int maxLines = 2}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CText(
            padding: const EdgeInsets.only(left: 20, right: 10),
            textAlign: TextAlign.start,
            text: label,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            textColor: AppTheme.grayAsparagus,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          flex: 3,
          child: CText(
            padding: const EdgeInsets.only(right: 20, left: 10),
            textAlign: TextAlign.start,
            text: value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textColor: textColor ?? AppTheme.grayAsparagus,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    if (widget.category != 1 && restaurantInspectionStatusId < 6) {
      return Container(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            _buildCreateInspectionButton(),
            _buildCancelInspectionButton(),
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildCreateInspectionButton() {
    final isAgentLogin = storeUserData.getBoolean(IS_AGENT_LOGIN);
    if (isAgentLogin || !widget.fromActive) {
      return Container();
    }

    return Expanded(
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () => _handleCreateInspection(),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      ),
    );
  }

  void _handleCreateInspection() {
    debugPrint(widget.taskId.toString());
    debugPrint(widget.statusId.toString());
    debugPrint(widget.task?.primary.toString());

    if (widget.taskId != null) {
      if (widget.statusId == 5 || widget.task?.primary == true) {
        Get.to(
          transition: Transition.rightToLeft,
          CreateNewPatrol(
            entityId: widget.entityId,
            taskId: widget.taskId,
            statusId: widget.statusId,
            inspectionId: widget.inspectionId,
            mainTaskId: widget.task?.mainTaskId ?? 0,
            primary: widget.task?.primary ?? false,
            newAdded: false,
            isAgentEmployees: widget.isAgentEmployees,
            taskType: widget.task?.taskType ?? 0,
          ),
        )?.then((value) {
          if (value != null && mounted) {
            setState(() {
              widget.statusId = value["statusId"];
              widget.inspectionId = value["inspectionId"];
              widget.taskId = value["taskId"];
            });
          }
        });
      }
    }
  }

  Widget _buildCancelInspectionButton() {
    final isAgentLogin = storeUserData.getBoolean(IS_AGENT_LOGIN);
    final shouldShow = !isAgentLogin &&
        widget.taskId != null &&
        widget.inspectionId != 0 &&
        widget.task?.primary == true;

    if (!shouldShow) {
      return Container();
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () => _handleCancelInspection(),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor:
                widget.taskId != null ? AppTheme.colorPrimary : AppTheme.grey,
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
      ),
    );
  }

  void _handleCancelInspection() {
    Utils().showYesNoAlert(
      context: context,
      message: "Are you sure you want to cancel the inspection?",
      onYesPressed: () {
        Navigator.of(context).pop();
        showRejectRemarkSheet(widget.taskId);
      },
      onNoPressed: () => Navigator.of(context).pop(),
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
    final formState = _AddTaskFormState();

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
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _buildDoneButton(context),
                  _buildTaskNameField(formState, myState),
                  _buildPrimaryInspectorField(
                      context, formState, myState, buildContext),
                  _buildOtherInspectorsField(
                      context, formState, myState, buildContext),
                  if (isHideAgents)
                    _buildAgentsField(context, formState, myState),
                  _buildNotesField(formState, myState),
                  _buildAddButton(
                      context, formState, isHideAgents, myState, buildContext),
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

  Widget _buildDoneButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.of(context).pop(),
        child: CText(
          padding: const EdgeInsets.only(right: 20, left: 10, top: 10),
          textAlign: TextAlign.center,
          text: "DONE",
          textColor: AppTheme.black,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.medium,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTaskNameField(_AddTaskFormState formState, StateSetter myState) {
    return FormTextField(
      onChange: (value) => myState(() {}),
      controller: formState.taskName,
      hint: "",
      focusNode: formState.node,
      value: formState.taskName.text,
      title: 'Task Name :',
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      inputType: TextInputType.text,
    );
  }

  Widget _buildPrimaryInspectorField(
      BuildContext context,
      _AddTaskFormState formState,
      StateSetter myState,
      BuildContext buildContext) {
    return FormTextField(
      onTap: () => _handlePrimaryInspectorSelection(
          context, formState, myState, buildContext),
      hint: "",
      value: formState.primaryUsers.isNotEmpty
          ? formState.primaryUsers.join(", ")
          : "",
      title: 'Primary Inspector :',
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      inputType: TextInputType.text,
    );
  }

  Widget _buildOtherInspectorsField(
      BuildContext context,
      _AddTaskFormState formState,
      StateSetter myState,
      BuildContext buildContext) {
    return FormTextField(
      onTap: () => _handleOtherInspectorsSelection(
          context, formState, myState, buildContext),
      hint: "",
      value: formState.users.isNotEmpty ? formState.users.join(", ") : "",
      title: 'Other Inspectors :',
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      inputType: TextInputType.text,
    );
  }

  Widget _buildAgentsField(
      BuildContext context, _AddTaskFormState formState, StateSetter myState) {
    return FormTextField(
      onTap: () => _handleAgentsSelection(context, formState, myState),
      hint: "",
      value: formState.agents.isNotEmpty ? formState.agents.join(", ") : "",
      title: 'Agents :',
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      inputType: TextInputType.text,
    );
  }

  Widget _buildNotesField(_AddTaskFormState formState, StateSetter myState) {
    return FormTextField(
      onChange: (value) => myState(() {}),
      controller: formState.notes,
      hint: "",
      focusNode: formState.notesNode,
      value: formState.notes.text,
      title: notesTitle,
      minLines: 2,
      maxLines: 3,
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      inputType: TextInputType.text,
    );
  }

  Widget _buildAddButton(BuildContext context, _AddTaskFormState formState,
      bool isHideAgents, StateSetter myState, BuildContext buildContext) {
    final isValid = _isFormValid(formState, isHideAgents);
    return Center(
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: ElevatedButton(
          onPressed:
              isValid ? () => _submitTask(formState, isHideAgents) : null,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor:
                isValid ? AppTheme.colorPrimary : AppTheme.paleGray,
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
    );
  }

  void _handlePrimaryInspectorSelection(
      BuildContext context,
      _AddTaskFormState formState,
      StateSetter myState,
      BuildContext buildContext) {
    Get.to(
            SelectInspector(
              isPrimary: true,
              selectedUsers: formState.selectedUsers,
              primaryInspector: formState.selectedPrimaryUsers,
            ),
            preventDuplicates: false)
        ?.then((value) {
      if (value != null) {
        if (!context.mounted) return;
        _updatePrimaryInspectorSelection(context, formState, value, myState);
      }
    });
  }

  void _updatePrimaryInspectorSelection(
      BuildContext context,
      _AddTaskFormState formState,
      List<AllUserData> value,
      StateSetter myState) {
    myState(() {
      formState.primaryUsers.clear();
      formState.users.clear();
      formState.selectedUsers.clear();
      formState.selectedPrimaryUsers = value;
      for (var user in formState.selectedPrimaryUsers) {
        formState.primaryUsers.add(user.name);
      }
      _unfocusFields(context, formState);
    });
  }

  void _handleOtherInspectorsSelection(
      BuildContext context,
      _AddTaskFormState formState,
      StateSetter myState,
      BuildContext buildContext) {
    if (formState.primaryUsers.isEmpty) {
      _showPrimaryInspectorRequiredAlert(buildContext);
      return;
    }
    Get.to(
            SelectInspector(
              primaryInspector: formState.selectedPrimaryUsers,
              isPrimary: false,
              selectedUsers: formState.selectedUsers,
            ),
            preventDuplicates: false)
        ?.then((value) {
      if (value != null) {
        if (!context.mounted) return;
        _updateOtherInspectorsSelection(context, formState, value, myState);
      }
    });
  }

  void _updateOtherInspectorsSelection(
      BuildContext context,
      _AddTaskFormState formState,
      List<AllUserData> value,
      StateSetter myState) {
    myState(() {
      formState.users.clear();
      formState.selectedUsers = value;
      for (var user in formState.selectedUsers) {
        formState.users.add(user.name);
      }
      _unfocusFields(context, formState);
    });
  }

  void _handleAgentsSelection(
      BuildContext context, _AddTaskFormState formState, StateSetter myState) {
    final agentList = _buildAgentList();
    Get.to(
            SelectAgents(
                list: agentList, selectedAgents: formState.selectedAgents),
            preventDuplicates: false)
        ?.then((value) {
      if (value != null) {
        if (!context.mounted) return;
        _updateAgentsSelection(context, formState, value, myState);
      }
    });
  }

  List<SearchEntityData> _buildAgentList() {
    return [
      SearchEntityData(entityId: 1, entityName: "MMI"),
      SearchEntityData(entityId: 2, entityName: "AE"),
    ];
  }

  void _updateAgentsSelection(BuildContext context, _AddTaskFormState formState,
      List<SearchEntityData> value, StateSetter myState) {
    myState(() {
      formState.agents.clear();
      formState.selectedAgents = value;
      for (var agent in formState.selectedAgents) {
        formState.agents.add(agent.entityName);
      }
      _unfocusFields(context, formState);
    });
  }

  void _unfocusFields(BuildContext context, _AddTaskFormState formState) {
    formState.node.unfocus();
    formState.notesNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _showPrimaryInspectorRequiredAlert(BuildContext buildContext) {
    Utils().showAlert(
      buildContext: buildContext,
      message: "Please select primary inspector first.",
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  bool _isFormValid(_AddTaskFormState formState, bool isHideAgents) {
    return formState.taskName.text.isNotEmpty &&
        formState.selectedPrimaryUsers.isNotEmpty &&
        formState.selectedUsers.isNotEmpty &&
        (!isHideAgents || formState.selectedAgents.isNotEmpty);
  }

  void _submitTask(_AddTaskFormState formState, bool isHideAgents) {
    addTask(
      formState.taskName.text,
      formState.selectedPrimaryUsers,
      formState.selectedUsers,
      formState.selectedAgents,
      formState.notes.text,
      isHideAgents,
    );
  }

  Future<void> addTask(
      String taskName,
      List<AllUserData> primaryUser,
      List<AllUserData> otherUsers,
      List<SearchEntityData> agents,
      String notes,
      bool isHideAgents) async {
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    final agentUserId = _collectAgentUserIds(agents);
    final users = _buildUserList(primaryUser, otherUsers);
    final fields = _buildTaskFields(
      taskName,
      users,
      agentUserId,
      notes,
    );

    LogPrint().log("CreateTask $fields");
    LoadingIndicatorDialog().show(context);

    Api()
        .callAPI(context, "Department/Task/CreateTask", fields)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      _handleAddTaskResponse(value);
    });
  }

  List<int> _collectAgentUserIds(List<SearchEntityData> agents) {
    return agents.map((entity) => entity.entityId).toList();
  }

  List<Map<String, dynamic>> _buildUserList(
    List<AllUserData> primaryUser,
    List<AllUserData> otherUsers,
  ) {
    final users = <Map<String, dynamic>>[];

    for (var pUser in primaryUser) {
      users.add({"item1": pUser.departmentUserId, "item2": true});
    }

    for (var user in otherUsers) {
      if (!primaryUser
          .any((pUser) => pUser.departmentUserId == user.departmentUserId)) {
        users.add({"item1": user.departmentUserId, "item2": false});
      }
    }

    return users;
  }

  Map<String, dynamic> _buildTaskFields(
    String taskName,
    List<Map<String, dynamic>> users,
    List<int> agentUserId,
    String notes,
  ) {
    return {
      "taskName": taskName,
      "entityId": [widget.entityId],
      "statusId": 1,
      "inspectorId": users,
      "agentUserId": agentUserId.isEmpty ? [] : agentUserId,
      "notes": notes,
      "createdBy": storeUserData.getInt(USER_ID),
      "createdOn":
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      "taskType": 1,
    };
  }

  void _handleAddTaskResponse(String value) {
    final data = jsonDecode(value);

    if (data["statusCode"] == 200) {
      _navigateToHomeScreen();
    } else {
      _showErrorAlert(data["message"]);
    }
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pop();
    Get.offAll(transition: Transition.rightToLeft, const HomeScreen());
  }

  void _showErrorAlert(String message) {
    Utils().showAlert(
      buildContext: context,
      message: message,
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
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
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    final url = "Mobile/NewOutlet/Delete?newOutletid=$outletId";

    Api().getAPI(context, url).then((value) async {
      LoadingIndicatorDialog().dismiss();
      _handleDeleteOutletResponse(value, outletId);
    });
  }

  void _handleDeleteOutletResponse(String value, int outletId) {
    final data = jsonDecode(value);

    if (data["statusCode"] == 200) {
      _processSuccessfulOutletDelete(outletId);
    } else {
      _showErrorAlert(noEntityMessage);
    }
  }

  void _processSuccessfulOutletDelete(int outletId) {
    setState(() {
      _removeOutletFromList(outletId);
      outletList.clear();

      final inActiveList = _buildInActiveList();
      _populateOutletList();

      storeUserData.setString(
        entityId.toString(),
        OutletData.encode(inActiveList),
      );
    });
  }

  void _removeOutletFromList(int outletId) {
    final position =
        searchOutletList.indexWhere((test) => test.outletId == outletId);
    if (position != -1) {
      searchOutletList.removeAt(position);
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

  void initOutletControllers(
    OutletData? model,
    TextEditingController itemName,
    TextEditingController managerName,
    TextEditingController emiratesId,
    TextEditingController mobileNumber,
    TextEditingController notes,
  ) {
    if (model == null) return;

    itemName.text = model.outletName;
    managerName.text = model.managerName ?? "";
    emiratesId.text = formatEmiratesID(model.emiratesId ?? "");
    mobileNumber.text = model.contactNumber?.replaceAll("+9715", "") ?? "";
    notes.text = model.notes ?? "";

    ownerShipType =
        AreaData(id: model.ownerShipTypeId, text: model.ownerShipType);
    serviceType = AreaData(id: model.serviceTypeId, text: model.serviceType);
    outletType =
        AreaData(id: model.outletTypeId ?? 0, text: model.outletType ?? "");
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

    ownerShipType = null;
    serviceType = null;
    outletType = null;

    initOutletControllers(
      model,
      itemName,
      managerName,
      emiratesId,
      mobileNumber,
      notes,
    );
    var focusNode = FocusNode();
    var focusNodeButton = FocusNode();

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        bool isOutletFormValid(
          TextEditingController itemName,
          TextEditingController managerName,
          TextEditingController emiratesId,
          TextEditingController mobileNumber,
          TextEditingController notes,
        ) {
          return itemName.text.isNotEmpty &&
              managerName.text.isNotEmpty &&
              emiratesId.text.length == 18 &&
              mobileNumber.text.length == 8 &&
              notes.text.isNotEmpty &&
              serviceType != null &&
              ownerShipType != null &&
              outletType != null;
        }

        String? validateOutletForm() {
          if (itemName.text.isEmpty) return "Please enter outlet name";
          if (serviceType == null) return "Please select service type";
          if (ownerShipType == null) return "Please select ownership type";
          if (outletType == null) return "Please select outlet type";
          if (managerName.text.isEmpty) return "Please enter manager name";
          if (emiratesId.text.length != 18) {
            return "Please enter valid emirates ID";
          }
          if (mobileNumber.text.length != 8) {
            return "Please enter valid contact number";
          }
          if (notes.text.isEmpty) return "Please enter notes";
          return null;
        }

        void submitOutlet(
          StateSetter myState,
          OutletData? model,
          TextEditingController itemName,
          TextEditingController managerName,
          TextEditingController emiratesId,
          TextEditingController mobileNumber,
          TextEditingController notes,
        ) {
          final outlet = OutletData(
            outletId: model?.outletId ?? 0,
            outletName: itemName.text,
            serviceTypeId: serviceType!.id,
            ownerShipTypeId: ownerShipType!.id,
            outletTypeId: outletType!.id,
            serviceType: serviceType!.text,
            ownerShipType: ownerShipType!.text,
            outletType: outletType!.text,
            managerName: managerName.text,
            emiratesId: emiratesId.text,
            contactNumber: mobileNumber.text,
            notes: notes.text,
            newAdded: model == null,
            inspectionStatusId: model?.inspectionStatusId ?? 0,
            inspectionId: model?.inspectionId ?? 0,
            inspectorId: storeUserData.getInt(USER_ID),
          );

          model != null
              ? updateOutlet(myState, outlet)
              : addOutlet(myState, outlet);
        }

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
                          final error = validateOutletForm();

                          if (error != null) {
                            Utils().showAlert(
                              buildContext: buildContext,
                              message: error,
                              onPressed: () => Navigator.pop(context),
                            );
                            return;
                          }

                          submitOutlet(
                            myState,
                            model,
                            itemName,
                            managerName,
                            emiratesId,
                            mobileNumber,
                            notes,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: isOutletFormValid(itemName,
                                  managerName, emiratesId, mobileNumber, notes)
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
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    final payload = _buildUpdateOutletPayload(model);

    Api()
        .callAPI(context, "Mobile/NewOutlet/Update", payload)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      _handleUpdateOutletResponse(value, myState, model);
    });
  }

  Map<String, dynamic> _buildUpdateOutletPayload(OutletData model) {
    final currentTime =
        DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime());
    final userId = storeUserData.getInt(USER_ID);

    return {
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
      "createdBy": userId,
      "createdOn": currentTime,
      "modifiedOn": currentTime,
      "modifiedBy": userId,
    };
  }

  void _handleUpdateOutletResponse(
      String value, StateSetter myState, OutletData model) {
    final data = jsonDecode(value);

    if (data["statusCode"] == 200) {
      _processSuccessfulOutletUpdate(myState, model);
      Navigator.of(context).pop();
    } else {
      _showErrorAlert(noEntityMessage);
    }
  }

  void _processSuccessfulOutletUpdate(StateSetter myState, OutletData model) {
    myState(() {
      _updateOutletInList(model);
      outletList.clear();

      final inActiveList = _buildInActiveList();
      _populateOutletList();

      print("inActiveList.length ");
      print(inActiveList.length);
      storeUserData.setString(
        entityId.toString(),
        OutletData.encode(inActiveList),
      );
    });
  }

  void _updateOutletInList(OutletData model) {
    final position =
        searchOutletList.indexWhere((test) => test.outletId == model.outletId);
    if (position != -1) {
      searchOutletList.removeAt(position);
      searchOutletList.insert(position, model);
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
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    final payload = _buildOutletPayload(model);

    Api()
        .callAPI(context, "Mobile/NewOutlet/Create", payload)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      _handleAddOutletResponse(value, myState, model);
    });
  }

  Map<String, dynamic> _buildOutletPayload(OutletData model) {
    final currentTime =
        DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime());
    final userId = storeUserData.getInt(USER_ID);

    return {
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
      "createdBy": userId,
      "createdOn": currentTime,
      "modifiedOn": currentTime,
      "modifiedBy": userId,
    };
  }

  void _handleAddOutletResponse(
      String value, StateSetter myState, OutletData model) {
    final data = jsonDecode(value);

    if (data["statusCode"] == 200 && data["data"] != null) {
      _processSuccessfulOutletAdd(myState, model, data["data"]);
      Navigator.of(context).pop();
    } else {
      _showErrorAlert(noEntityMessage);
    }
  }

  void _processSuccessfulOutletAdd(
      StateSetter myState, OutletData model, dynamic outletId) {
    myState(() {
      model.outletId = outletId;
      searchOutletList.insert(0, model);
      outletList.clear();

      final inActiveList = _buildInActiveList();
      _populateOutletList();

      storeUserData.setString(
        entityId.toString(),
        OutletData.encode(inActiveList),
      );
    });
  }

  List<OutletData> _buildInActiveList() {
    final inActiveList = <OutletData>[];
    for (var item in searchOutletList) {
      if (item.newAdded == true) {
        inActiveList.add(item);
      }
    }
    return inActiveList;
  }

  void _populateOutletList() {
    for (var item in searchOutletList) {
      if (_shouldAddToOutletList(item)) {
        outletList.add(item);
      }
    }
  }

  bool _shouldAddToOutletList(OutletData item) {
    if (tabType == 2) {
      return item.newAdded == true;
    } else if (tabType == 1) {
      return item.newAdded == false;
    }
    return false;
  }

  String _getOutletStatusText(int statusId) {
    if (statusId == 1) {
      return "Pending";
    } else if (statusId == 2) {
      return "In Progress";
    } else if (statusId == 3) {
      return "Not Accepted";
    } else if (statusId == 6 || statusId == 7) {
      return "Completed";
    } else {
      return taskStatus.firstWhere((item) => item.id == statusId).text;
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
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    final url =
        "Department/Report/ViewReport?mainTaskId=${widget.task!.mainTaskId}&inspectionId=0";

    Api().getAPI(context, url).then((value) async {
      LoadingIndicatorDialog().dismiss();
      print("ViewReport $value");
      _handleReportResponse(value);
    });
  }

  void _handleReportResponse(String? value) {
    if (value == null) {
      _showNoPdfAlert();
      return;
    }

    final data = jsonDecode(value);
    if (data["data"] == null) {
      _showNoReportAlert();
      return;
    }

    _launchReportUrl(data["data"]);
  }

  Future<void> _launchReportUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      print(url);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Can't launch $urlString");
    }
  }

  void _showNoReportAlert() {
    Utils().showAlert(
      buildContext: context,
      message: "No Found Report ",
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _showNoPdfAlert() {
    Utils().showAlert(
      buildContext: context,
      message: "No PDF ",
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.pop(context);
      },
    );
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
      final placeMarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
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

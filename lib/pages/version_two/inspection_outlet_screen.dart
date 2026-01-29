import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/pages/version_two/inspection_detail_screen.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controls/loading_indicator_dialog.dart';
import '../../controls/text.dart';
import '../../model/area_model.dart';
import '../../model/entity_detail_model.dart';
import '../../model/outlet_model.dart';
import '../../model/task_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import 'package:http/http.dart' as http;

class InspectionOutletScreen extends StatefulWidget {
  final int entityId;
  final Tasks task;
  bool completeStatus;

   InspectionOutletScreen({
    super.key,
    required this.task,
    required this.entityId,
    required this.completeStatus,
  });


  @override
  State<InspectionOutletScreen> createState() => _InspectionOutletScreenState();
}

class _InspectionOutletScreenState extends State<InspectionOutletScreen> {
  List<OutletData> outletList = [];
  List<AreaData> ownerShipList = [];
  List<AreaData> outletServiceList = [];
  final List<AreaData> taskStatus = [];
  EntityDetailModel? entity;
  var storeUserData = StoreUserData();

  @override
  void initState() {
    getOutletService();
    getOutletOwnerShip();
    getTaskStatus();
    getEntityDetail();
    super.initState();
  }

  Future<void> getOutletService() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
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

  void getEntityDetail() {
    LoadingIndicatorDialog().show(context);
    Api().callAPI(
        context,
        "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${widget.task.mainTaskId}&entityId=${widget.entityId}",
        {}).then((value) async {
      LoadingIndicatorDialog().dismiss();
      if (value != null) {
        setState(() {
          entity = entityFromJson(value);
          if (entity != null) {
            outletList.clear();
            outletList.addAll(entity!.outletModels);
          } else {
            Utils().showAlert(
                buildContext: context,
                message: noEntityMessage,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                });
          }
        });
      } else {
        Utils().showAlert(
            buildContext: context,
            message: noEntityMessage,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.pop(context);
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildOutletListSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 215,
      color: AppTheme.colorPrimary,
      width: double.infinity,
      child: Stack(
        children: [
          _buildBackButton(),
          _buildHeaderTitle(),
          _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Get.back();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          top: 50,
          right: 10,
          bottom: 20,
        ),
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

  Widget _buildHeaderTitle() {
    return Center(
      child: Column(
        children: [
          CText(
            textAlign: TextAlign.center,
            padding: const EdgeInsets.only(left: 60, right: 60, top: 80),
            text: entity?.entityName ?? "",
            textColor: AppTheme.white,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.big,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w700,
          ),
          CText(
            textAlign: TextAlign.center,
            padding: const EdgeInsets.only(left: 60, right: 60, top: 5),
            text: entity?.location?.address ?? "",
            textColor: AppTheme.white,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    final isVisible = !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
        widget.completeStatus;

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Visibility(
        visible: isVisible,
        child: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.white,
            ),
            onPressed: () {
              getDownloadReport();
            },
            child: CText(
              text: "Download Report",
              textColor: AppTheme.colorPrimary,
              fontFamily: AppTheme.poppins,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
          _buildEntityLogo(),
          const SizedBox(height: 10),
          _buildEntityDetailRow(
            "Status",
            entity?.licenseStatus ?? "",
            "License No :",
            entity?.licenseNumber ?? "",
            textColor: AppTheme.colorPrimary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 20),
          _buildEntityDetailRow(
            "Monthly Limit",
            entity?.monthlyLimit.toString() ?? "",
            "Expiry Date :",
            _formatExpiryDate(),
          ),
          const SizedBox(height: 20),
          _buildEntityDetailRow(
            "Opening Hours",
            entity?.openingTime ?? "-",
            "Closing Hours",
            entity?.closingTime ?? "-",
          ),
          const SizedBox(height: 20),
          _buildEntityDetailRow(
            "Classification : ",
            entity?.classification ?? "-",
            "Ownership Type : ",
            entity?.ownerShipType ?? "-",
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _buildEntityDetailRow(
            "Manager Name : ",
            entity?.managerName ?? "-",
            "Manager Contact : ",
            entity?.managerContactNumber ?? "-",
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _buildEntityDetailRow(
            "Role Name : ",
            entity?.roleName ?? "-",
            "Last Inspection Date : ",
            _formatLastVisitedDate(),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEntityLogo() {
    if (entity?.logoUrl == null) {
      return Container();
    }
    return Center(
      child: Image.network(
        entity!.logoUrl!,
        height: 40,
        width: 40,
      ),
    );
  }

  Widget _buildEntityDetailRow(
    String label1,
    String value1,
    String label2,
    String value2, {
    Color? textColor,
    FontWeight? fontWeight,
    int? maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CText(
                textAlign: TextAlign.center,
                text: label1,
                textColor: AppTheme.titleGray,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.medium,
                fontWeight: FontWeight.w600,
              ),
              CText(
                padding: const EdgeInsets.only(top: 2),
                textAlign: TextAlign.center,
                text: value1,
                textColor: textColor ?? AppTheme.textBlack,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.large,
                maxLines: maxLines,
                fontWeight: fontWeight ?? FontWeight.w600,
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
                text: label2,
                textColor: AppTheme.titleGray,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.medium,
                fontWeight: FontWeight.w600,
              ),
              CText(
                padding: const EdgeInsets.only(top: 2),
                textAlign: TextAlign.center,
                text: value2,
                textColor: AppTheme.textBlack,
                fontFamily: AppTheme.urbanist,
                fontSize: AppTheme.large,
                maxLines: maxLines,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatExpiryDate() {
    if (entity == null) return "";
    return DateFormat("dd-MM-yyyy").format(entity!.licenseExpiryDate);
  }

  String _formatLastVisitedDate() {
    if (entity?.lastVisitedDate == null) return "-";
    try {
      final date = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS")
          .parse(entity!.lastVisitedDate!);
      final dateStr = DateFormat("dd-MM-yyyy").format(date);
      final timeStr = DateFormat("hh:mm:ss aa").format(date);
      return "$dateStr \n$timeStr";
    } catch (e) {
      return "-";
    }
  }

  Widget _buildOutletListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CText(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          text: "Entity Outlets :",
          textColor: AppTheme.black,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.big_20,
          fontWeight: FontWeight.w700,
        ),
        _shouldShowOutletList()
            ? _buildOutletListView()
            : Container(),
      ],
    );
  }

  bool _shouldShowOutletList() {
    return outletList.isNotEmpty &&
        ownerShipList.isNotEmpty &&
        outletServiceList.isNotEmpty;
  }

  Widget _buildOutletListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: outletList.length,
      itemBuilder: (context, index) {
        return _buildOutletCard(index);
      },
    );
  }

  Widget _buildOutletCard(int index) {
    return GestureDetector(
      onTap: () => _handleOutletTap(index),
      child: Card(
        color: AppTheme.white,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutletHeader(index),
              _buildOutletInfo(index),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOutletTap(int index) {
    final statusId = outletList[index].inspectionStatusId;
    if (statusId == 6 || statusId == 7) {
      Get.to(
        transition: Transition.rightToLeft,
        InspectionDetailScreen(
          task: widget.task,
          inspectionId: outletList[index].inspectionId,
          completeStatus: widget.completeStatus,
        ),
      );
    }
  }

  Widget _buildOutletHeader(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CText(
            textAlign: TextAlign.start,
            padding: const EdgeInsets.only(right: 10, top: 10, bottom: 5),
            text: outletList[index].outletName,
            textColor: AppTheme.colorPrimary,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w700,
          ),
        ),
        _buildStatusBadge(index),
      ],
    );
  }

  Widget _buildStatusBadge(int index) {
    if (outletList[index].inspectionStatusId == 0) {
      return Container();
    }

    return Expanded(
      flex: 0,
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: AppTheme.getStatusColor(
            outletList[index].inspectionStatusId,
          ),
        ),
        child: CText(
          textAlign: TextAlign.start,
          text: _getStatusText(outletList[index].inspectionStatusId),
          textColor: AppTheme.white,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.small,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText(int statusId) {
    if (statusId == 1) return "Pending";
    if (statusId == 2) return "In Progress";
    if (statusId == 3) return "Rejected";
    if (statusId == 6 || statusId == 7) return "Completed";
    try {
      return taskStatus
          .firstWhere((item) => item.id == statusId)
          .text;
    } catch (e) {
      return "";
    }
  }

  Widget _buildOutletInfo(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CText(
          textAlign: TextAlign.start,
          padding: const EdgeInsets.only(right: 10),
          text: outletList[index].ownerShipType,
          textColor: AppTheme.grayAsparagus,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.large,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w600,
        ),
        CText(
          textAlign: TextAlign.start,
          padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
          text: outletList[index].serviceType,
          textColor: AppTheme.grayAsparagus,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.large,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Future<void> getTaskStatus() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
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

  Future<void> getOutletOwnerShip() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
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


  //todo download pdf

  Future<void> getDownloadReport() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      // http://4.161.39.155:8096/inspectionApi/api/Department/Report/ViewReport?mainTaskId=4512&inspectionId=0
      Api()
          .getAPI(context,
          "Department/Report/ViewReport?mainTaskId=${widget.task.mainTaskId}&inspectionId=0")
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
      if (!mounted) return;
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
}

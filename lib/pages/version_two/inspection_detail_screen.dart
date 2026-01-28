import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/LoadingIndicatorDialog.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/log_print.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/area_model.dart';
import '../../model/attachments.dart';
import '../../model/entity_detail_model.dart';
import '../../model/inspection_detail_model.dart';
import '../../model/inspection_product_model.dart';
import '../../model/product_category_model.dart';
import '../../model/representative_model.dart';
import '../../model/task_model.dart';
import '../../model/witness_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import '../full_screen_image.dart';
import '../video_player_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  final Tasks task;
  final bool completeStatus;

  const InspectionDetailScreen(
      {super.key,
      required this.task,
      required this.inspectionId,
      required this.completeStatus});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  var tabType = 1;
  var productTab = 3;
  InspectionData? detail;
  EntityDetailModel? entity;
  var storeUserData = StoreUserData();

  ///sizes
  var currentHeight = 0.0;
  var currentWidth = 0.0;

  ///product
  List<ProductCategoryData> productCategoryList = [];
  List<ProductDetail> selectedKnownProductListData = [];
  List<ProductDetail> foreignLabelsList = [];
  List<ProductDetail> unknownProductList = [];
  List<AreaData> searchSizeList = [];

  ///attachments
  List<AttachmentData> attachmentList = [];

  ///witness & representatives
  List<RepresentativeData> managerList = [];
  List<RepresentativeData> witnessList = [];
  List<WitnessData> selectedAEList = [];
  List<WitnessData> selectedMMIList = [];
  List<AreaData?> roleList = [];
  Timer? timer;

  @override
  void initState() {
    getInspectionDetail();
    getKnownProductCategories();
    getLiquorSize();
    getEntityRole();

    super.initState();
  }

  @override
  void dispose() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    super.dispose();
  }

  Future<void> getEntityDetail() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api().callAPI(
          context,
          "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${widget.task.mainTaskId}&entityId=${widget.task.entityID}",
          {}).then((value) async {
        setState(() {
          entity = entityFromJson(value);
          if (entity != null) {
          } else {
            Utils().showAlert(
                buildContext: context,
                message: "No Entity Found",
                onPressed: () {
                  Navigator.of(context).pop();
                });
          }
        });
      });
    }
  }

  Future<void> getInspectionDetail() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Mobile/Inspection/GetInspectionDetails", {
        "mainTaskId": widget.task.mainTaskId,
        "inspectionId": widget.inspectionId
      }).then((value) async {
        var data = detailFromJson(value);
        if (data.data != null) {
          setState(() {
            detail = data.data!;
            setState(() {
              getThumbnails(data.data!.attachments);
              timer = Timer.periodic(const Duration(seconds: 2), (timer) {
                if (attachmentList.length == data.data!.attachments.length) {
                  LoadingIndicatorDialog().dismiss();
                  timer.cancel();
                }
              });
              for (var i in data.data!.productDetailModels) {
                if (i.typeId == 1) {
                  selectedKnownProductListData.add(i);
                } else if (i.typeId == 2) {
                  foreignLabelsList.add(i);
                } else if (i.typeId == 3) {
                  unknownProductList.add(i);
                }
              }
              for (var i in data.data!.entityRepresentatives) {
                if (i.typeId == 1) {
                  managerList.add(i);
                } else if (i.typeId == 2) {
                  witnessList.add(i);
                }
              }
              for (var i
                  in data.data!.inspectorAndAgentEmployee.agentEmployeeModels) {
                if (i.agentId == 1) {
                  selectedAEList.add(i);
                } else if (i.agentId == 2) {
                  selectedMMIList.add(i);
                }
              }
            });
          });
        } else {
          LoadingIndicatorDialog().dismiss();
          if (data.message.isNotEmpty) {
            Utils().showAlert(
                buildContext: context,
                message: data.message,
                onPressed: () {
                  Navigator.of(context).pop();
                });
          } else {}
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    currentWidth = MediaQuery.of(context).size.width;
    currentHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.main_background,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: widget.completeStatus ? 240 : 200,
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
                        text: "Inspection Task detail",
                        textColor: AppTheme.white,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 10, top: 120),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.center,
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: tabType > 0
                                          ? AppTheme.light_blue
                                          : AppTheme.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CText(
                                      text: "1",
                                      textColor: AppTheme.colorPrimary,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                    )),
                                const SizedBox(
                                  height: 5,
                                ),
                                CText(
                                    text: "Details",
                                    fontFamily: AppTheme.Urbanist,
                                    textAlign: TextAlign.center,
                                    textColor: tabType > 0
                                        ? AppTheme.white
                                        : AppTheme.white,
                                    fontSize: AppTheme.small),
                              ],
                            ),
                            Expanded(
                                flex: 1,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  color: AppTheme.white,
                                  height: 1,
                                )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.center,
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: tabType > 1
                                          ? AppTheme.light_blue
                                          : AppTheme.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CText(
                                      text: "2",
                                      textColor: AppTheme.colorPrimary,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                    )),
                                const SizedBox(
                                  height: 5,
                                ),
                                CText(
                                    text: "Products \nInspections",
                                    fontFamily: AppTheme.Urbanist,
                                    textAlign: TextAlign.center,
                                    textColor: tabType > 1
                                        ? AppTheme.white
                                        : AppTheme.white,
                                    fontSize: AppTheme.small),
                              ],
                            ),
                            Expanded(
                                flex: 1,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  color: AppTheme.white,
                                  height: 1,
                                )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.center,
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: tabType > 2
                                          ? AppTheme.light_blue
                                          : AppTheme.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CText(
                                      text: "3",
                                      textColor: AppTheme.colorPrimary,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                    )),
                                const SizedBox(
                                  height: 5,
                                ),
                                CText(
                                    text: "Attachments",
                                    fontFamily: AppTheme.Urbanist,
                                    textAlign: TextAlign.center,
                                    textColor: tabType > 2
                                        ? AppTheme.white
                                        : AppTheme.white,
                                    fontSize: AppTheme.small),
                              ],
                            ),
                            Expanded(
                                flex: 1,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  color: AppTheme.white,
                                  height: 1,
                                )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                    alignment: Alignment.center,
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: tabType > 3
                                          ? AppTheme.light_blue
                                          : AppTheme.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CText(
                                      text: "4",
                                      textColor: AppTheme.colorPrimary,
                                      fontFamily: AppTheme.Urbanist,
                                      fontSize: AppTheme.large,
                                    )),
                                const SizedBox(
                                  height: 5,
                                ),
                                CText(
                                    text: "Witness & \nRepresentative",
                                    fontFamily: AppTheme.Urbanist,
                                    textAlign: TextAlign.center,
                                    textColor: tabType > 3
                                        ? AppTheme.white
                                        : AppTheme.white,
                                    fontSize: AppTheme.small),
                              ],
                            ),
                          ],
                        )),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Visibility(
                          visible: !storeUserData.getBoolean(IS_AGENT_LOGIN) &&
                              widget.completeStatus == true,
                          child: Container(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.white),
                              onPressed: () {
                                getDownloadReport();
                              },
                              child: CText(
                                text: "Download Report",
                                textColor: AppTheme.colorPrimary,
                                fontFamily: AppTheme.Poppins,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )),
                    )
                  ],
                )),
            Container(
                padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                        visible: tabType > 1,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              tabType--;
                            });
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: AppTheme.colorPrimary,
                              ),
                              CText(
                                textAlign: TextAlign.center,
                                text: "Previous",
                                textColor: AppTheme.colorPrimary,
                                fontFamily: AppTheme.Urbanist,
                                fontSize: AppTheme.medium,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        )),
                    Visibility(
                      visible: tabType != 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            tabType++;
                          });
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CText(
                              textAlign: TextAlign.center,
                              text: "Next",
                              textColor: AppTheme.colorPrimary,
                              fontFamily: AppTheme.Urbanist,
                              fontSize: AppTheme.medium,
                              fontWeight: FontWeight.w700,
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: AppTheme.colorPrimary,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
            detail == null
                ? const Center(
                    child: CircularProgressIndicator(
                    color: AppTheme.black,
                  ))
                : tabType == 1
                    ? tabOneUI()
                    : tabType == 2
                        ? tabTwoUI()
                        : tabType == 3
                            ? tabThreeUI()
                            : tabType == 4
                                ? tabFourUI()
                                : Container()
          ],
        ),
      ),
    );
  }

  Widget tabOneUI() {
    return Card(
        elevation: 2,
        color: AppTheme.white,
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Utils().sizeBoxHeight(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CText(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    textAlign: TextAlign.start,
                    text: "Task Name :",
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.title_gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: CText(
                    padding: const EdgeInsets.only(right: 20, left: 10),
                    textAlign: TextAlign.start,
                    text: widget.task.taskName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.text_black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Utils().sizeBoxHeight(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CText(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    textAlign: TextAlign.start,
                    text: "Entity Name :",
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.title_gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: CText(
                    padding: const EdgeInsets.only(right: 20, left: 10),
                    textAlign: TextAlign.start,
                    text: widget.task.entityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.text_black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Utils().sizeBoxHeight(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CText(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    textAlign: TextAlign.start,
                    text: "Started on :",
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.title_gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // 2024-04-29T18:49:24.103
                Expanded(
                  flex: 3,
                  child: CText(
                    padding: const EdgeInsets.only(right: 20, left: 10),
                    textAlign: TextAlign.start,
                    text:
                        "${DateFormat("dd-MM-yyyy").format(widget.task.startDate)} \n${DateFormat("hh:mm:ss aa").format(widget.task.startDate)}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.text_black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Utils().sizeBoxHeight(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CText(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    textAlign: TextAlign.start,
                    text: "Ended on :",
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.title_gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: CText(
                    padding: const EdgeInsets.only(right: 20, left: 10),
                    textAlign: TextAlign.start,
                    text:
                        "${DateFormat("dd-MM-yyyy").format(widget.task.endDate)} \n${DateFormat("hh:mm:ss aa").format(widget.task.endDate)}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontFamily: AppTheme.Urbanist,
                    fontSize: AppTheme.large,
                    textColor: AppTheme.text_black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Utils().sizeBoxHeight(height: 15),
          ],
        ));
  }

  Widget tabTwoUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Container(
            margin: const EdgeInsets.only(top: 5, bottom: 10),
            color: AppTheme.white,
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            productTab = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          color: AppTheme.white,
                          child: Column(
                            children: [
                              CText(
                                  text: "Known Product \nwith Stickers",
                                  textColor: productTab == 1
                                      ? AppTheme.black
                                      : AppTheme.text_color_gray,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.Urbanist,
                                  fontSize: AppTheme.thirteen),
                              Container(
                                height: 3,
                                margin: const EdgeInsets.only(top: 8),
                                color: productTab == 1
                                    ? AppTheme.colorPrimary
                                    : AppTheme.transparent,
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
                            productTab = 2;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          color: AppTheme.white,
                          child: Column(
                            children: [
                              CText(
                                  text: "Foreign Labels &\nScratched Code",
                                  textColor: productTab == 2
                                      ? AppTheme.black
                                      : AppTheme.text_color_gray,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.Urbanist,
                                  fontSize: AppTheme.thirteen),
                              Container(
                                height: 3,
                                margin: const EdgeInsets.only(top: 8),
                                color: productTab == 2
                                    ? AppTheme.colorPrimary
                                    : AppTheme.transparent,
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
                            productTab = 3;
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.only(top: 20),
                            color: AppTheme.white,
                            child: Column(
                              children: [
                                CText(
                                    text: "Unknown \nProducts",
                                    textColor: productTab == 3
                                        ? AppTheme.black
                                        : AppTheme.text_color_gray,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.thirteen),
                                Container(
                                  height: 3,
                                  margin: const EdgeInsets.only(top: 8),
                                  color: productTab == 3
                                      ? AppTheme.colorPrimary
                                      : AppTheme.transparent,
                                )
                              ],
                            )))),
              ],
            ),
          ),*/
          getProductUI()
        ],
      ),
    );
  }

  Widget getProductUI() {
    return productTab == 1
        ? ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedKnownProductListData.length,
            itemBuilder: (context, index) {
              List<String> serialNumber = [];
              for (var element
                  in selectedKnownProductListData[index].products) {
                serialNumber.add(element.serialNumber);
              }
              return Card(
                color: AppTheme.white,
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                surfaceTintColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText(
                        textAlign: TextAlign.start,
                        padding:
                            const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                        text: productCategoryList
                            .firstWhere((element) =>
                                element.productCategoryId ==
                                selectedKnownProductListData[index].categoryId)
                            .name,
                        textColor: AppTheme.colorPrimary,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.large,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                      CText(
                        textAlign: TextAlign.start,
                        padding:
                            const EdgeInsets.only(right: 10, top: 0, bottom: 5),
                        text: selectedKnownProductListData[index].productName,
                        textColor: AppTheme.gray_Asparagus,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.large,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                      CText(
                        textAlign: TextAlign.start,
                        padding: const EdgeInsets.only(right: 10, top: 0),
                        text:
                            "Quantity : ${selectedKnownProductListData[index].qty}",
                        textColor: AppTheme.gray_Asparagus,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.large,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                      CText(
                        textAlign: TextAlign.start,
                        padding:
                            const EdgeInsets.only(right: 10, top: 0, bottom: 5),
                        text: "Serial Number : ${serialNumber.join(", ")}",
                        textColor: AppTheme.gray_Asparagus,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.large,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              );
            })
        : productTab == 2
            ? ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: foreignLabelsList.length,
                itemBuilder: (context, index) {
                  return getProductList(foreignLabelsList, index);
                })
            : productTab == 3
                ? ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: unknownProductList.length,
                    itemBuilder: (context, index) {
                      return getProductList(unknownProductList, index);
                    })
                : Container();
  }

  Widget getProductList(List<ProductDetail> list, int index) {
    List<String> serialNumber = [];
    List<String> sizes = [];
    for (var element in list[index].products) {
      serialNumber.add(element.serialNumber);
    }
    for (var element in list[index].products) {
      var data =
          searchSizeList.firstWhereOrNull(((size) => size.id == element.size));
      if (data != null) {
        sizes.add(data.text);
      }
    }
    return Card(
      color: AppTheme.white,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      surfaceTintColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              text: list[index].productName,
              textColor: AppTheme.colorPrimary,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w700,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
              text: "Quantity : ${list[index].qty}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Serial Number : ${serialNumber.join(",")}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, bottom: 5),
              text: "Size : ${sizes.join(", ")}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            )
          ],
        ),
      ),
    );
  }

  Widget tabThreeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CText(
          textAlign: TextAlign.start,
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 30, bottom: 10),
          text: "Submitted Attachments:",
          textColor: AppTheme.black,
          fontFamily: AppTheme.Urbanist,
          fontSize: AppTheme.big,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w700,
        ),
        attachmentList.isNotEmpty
            ? GridView.count(
                childAspectRatio: 1.15,
                crossAxisCount: 3,
                crossAxisSpacing: 0.0,
                mainAxisSpacing: 0.0,
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 60.0, top: 10),
                children: List.generate(attachmentList.length, (index) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: Card(
                      margin: const EdgeInsets.all(5),
                      color: AppTheme.black,
                      surfaceTintColor: AppTheme.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: attachmentList[index]
                              .documentContentType
                              .startsWith("video")
                          ? Stack(children: [
                              Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5)),
                                  border: Border.all(
                                      color: AppTheme.black, width: 0.4),
                                  image: DecorationImage(
                                    fit: BoxFit.fill,
                                    image: Image.file(
                                            File(attachmentList[index]
                                                    .thumbnail ??
                                                ""),
                                            fit: BoxFit.contain)
                                        .image,
                                    colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.2),
                                        BlendMode.srcOver),
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 20,
                                  color: AppTheme.white,
                                ),
                              )
                            ])
                          : Container(
                              height: 150,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: FastCachedImageProvider(
                                    attachmentList[index].documentUrl,
                                  ),
                                  colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.2),
                                      BlendMode.srcOver),
                                ),
                              ),
                            ),
                    ),
                    onTap: () {
                      if (attachmentList[index]
                          .documentContentType
                          .startsWith("video")) {
                        Get.to(
                            transition: Transition.rightToLeft,
                            VideoPlayerScreen(
                              url: attachmentList[index].documentUrl,
                            ));
                      } else {
                        Get.to(
                            transition: Transition.rightToLeft,
                            FullScreenImage(
                              imageUrl: attachmentList[index].documentUrl,
                            ));
                      }
                    },
                  );
                }))
            : CText(
                textAlign: TextAlign.center,
                padding: const EdgeInsets.all(20),
                text: "NO DATA FOUND",
                textColor: AppTheme.black,
                fontFamily: AppTheme.Urbanist,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w600,
                fontSize: AppTheme.large,
              ),
      ],
    );
  }

  Widget tabFourUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CText(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            text: "Client Representative",
            textColor: AppTheme.black,
            fontFamily: AppTheme.Urbanist,
            fontSize: AppTheme.large,
            fontWeight: FontWeight.w600,
          ),
          managerList.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: managerList.length,
                  itemBuilder: (context, index) {
                    return getManagerUI(managerList, index, 1);
                  })
              : CText(
                  textAlign: TextAlign.start,
                  padding: const EdgeInsets.all(20),
                  text: "No Client Representative Found",
                  textColor: AppTheme.darkGray,
                  fontFamily: AppTheme.Urbanist,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTheme.small,
                ),
          CText(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            text: "Witness",
            textColor: AppTheme.black,
            fontFamily: AppTheme.Urbanist,
            fontSize: AppTheme.large,
            fontWeight: FontWeight.w600,
          ),
          witnessList.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: witnessList.length,
                  itemBuilder: (context, index) {
                    return getManagerUI(witnessList, index, 2);
                  })
              : CText(
                  textAlign: TextAlign.start,
                  padding: const EdgeInsets.all(20),
                  text: "No Witness Found",
                  textColor: AppTheme.darkGray,
                  fontFamily: AppTheme.Urbanist,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTheme.small,
                ),
          CText(
            padding: const EdgeInsets.only(left: 20, right: 20),
            text: "Inspection Concluding Notes :",
            textColor: AppTheme.black,
            fontFamily: AppTheme.Urbanist,
            fontSize: AppTheme.large,
            fontWeight: FontWeight.w600,
          ),
          CText(
            textAlign: TextAlign.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            text: detail?.notes.finalNotes ?? "-",
            textColor: AppTheme.black,
            fontFamily: AppTheme.Urbanist,
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.large,
          ),
        ],
      ),
    );
  }

  Widget getManagerUI(List<RepresentativeData> list, int index, int type) {
    return Card(
      color: AppTheme.white,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      surfaceTintColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              text: list[index].name,
              textColor: AppTheme.colorPrimary,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w700,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
              text: "Role : ${list[index].roleName}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Emirates ID : ${list[index].emiratesId}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Contact Number : ${list[index].phoneNo}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Notes : ${list[index].notes}",
              textColor: AppTheme.gray_Asparagus,
              fontFamily: AppTheme.Urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  void getThumbnails(List<AttachmentData> data) {
    if (data.isEmpty) {
      LoadingIndicatorDialog().dismiss();
    }
    attachmentList.clear();
    for (var i in data) {
      if (i.documentContentType.startsWith("video")) {
        if (Platform.isAndroid) {
          getExternalStorageDirectory().then((value1) async {
            try {
              var thumbnail = await FlutterVideoThumbnailPlus.thumbnailFile(
                video: i.documentUrl,
                thumbnailPath: value1!.absolute.path,
                imageFormat: ImageFormat.png,
                quality: 100,
              );
              if (thumbnail != null) {
                LogPrint().log("thumbnail path: $thumbnail");
                setState(() {
                  i.thumbnail = thumbnail;
                  attachmentList.add(i);
                });
              } else {
                setState(() {
                  i.thumbnail = "";
                  attachmentList.add(i);
                  LogPrint().log("return thumbnail path: 1");
                });
              }
            } on Exception catch (e) {
              setState(() {
                i.thumbnail = "";
                attachmentList.add(i);
                LogPrint().log(e);
                LogPrint().log("return thumbnail path: catch");
              });
            }
          });
        } else {
          getApplicationDocumentsDirectory().then((value1) async {
            try {
              var thumbnail = await FlutterVideoThumbnailPlus.thumbnailFile(
                video: i.documentUrl,
                thumbnailPath: value1.absolute.path,
                imageFormat: ImageFormat.png,
                quality: 100,
              );
              if (thumbnail != null) {
                LogPrint().log("thumbnail path: $thumbnail");
                setState(() {
                  i.thumbnail = thumbnail;
                  attachmentList.add(i);
                });
              } else {
                setState(() {
                  i.thumbnail = "";
                  attachmentList.add(i);
                  LogPrint().log("return thumbnail path: 1");
                });
              }
            } on Exception catch (e) {
              setState(() {
                i.thumbnail = "";
                attachmentList.add(i);
                LogPrint().log(e);
                LogPrint().log("return thumbnail path: catch");
              });
            }
          });
        }
      } else {
        setState(() {
          attachmentList.add(i);
        });
      }
    }
  }

  Future<void> getEntityRole() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api().getAPI(context, "Mobile/Entity/GetEntityRole").then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            roleList.clear();
            roleList.addAll(data.data);
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

  Future<void> getLiquorSize() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api()
          .getAPI(context, "Mobile/ProduectDetail/GetLiquorSizeEnum")
          .then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            searchSizeList.clear();
            searchSizeList.addAll(data.data);
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

  Future<void> getKnownProductCategories() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api()
          .getAPI(context, "Mobile/ProduectDetail/GetProductCategory")
          .then((value) async {
        var data = productCategoryFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            productCategoryList.clear();
            productCategoryList.addAll(data.data);
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

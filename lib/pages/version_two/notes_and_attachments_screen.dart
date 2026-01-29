import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:patrol_system/controls/text_field.dart';
import 'package:patrol_system/utils/api.dart';
import 'package:patrol_system/utils/api_service_dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';

import '../../controls/loading_indicator_dialog.dart';
import '../../controls/text.dart';
import '../../model/entity_detail_model.dart';
import '../../model/outlet_model.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/log_print.dart';
import '../../utils/store_user_data.dart';
import '../../utils/utils.dart';
import '../full_screen_image.dart';
import '../video_player_screen.dart';
import 'home_screen.dart';

class NotesAndAttachmentsScreen extends StatefulWidget {
  int inspectionId;
  int taskId;
  int mainTaskId;
  int entityId;
  bool isDXBTask;
  final OutletData? outletData;

  NotesAndAttachmentsScreen(
      {super.key,
      required this.inspectionId /*,required this.inspectorId*/,
      required this.mainTaskId,
      required this.entityId,
      required this.taskId,
      required this.isDXBTask,
      this.outletData});

  @override
  State<NotesAndAttachmentsScreen> createState() =>
      _NotesAndAttachmentsScreenState();
}

class _NotesAndAttachmentsScreenState extends State<NotesAndAttachmentsScreen> {
  var tabType = "notes";
  final TextEditingController _notes = TextEditingController();

  var storeUserData = StoreUserData();
  EntityDetailModel? entity;
  List<http.MultipartFile> image = [];
  var inspectorId = 0;

  ///outlet
  OutletData? outletModel;
  List<Map<String, dynamic>> reasonList = [];

  @override
  void initState() {
    getEntityDetail();
    getReasonListing();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mainBackground,
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 170,
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
                  Align(
                    alignment: Alignment.center,
                    child: CText(
                      text: "Complete Task",
                      textColor: AppTheme.white,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.big_20,
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
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                setState(() {
                                  tabType = "notes";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.only(top: 20),
                                color: AppTheme.white,
                                child: Column(
                                  children: [
                                    CText(
                                        text: "Notes",
                                        textColor: tabType == "notes"
                                            ? AppTheme.black
                                            : AppTheme.textColorGray,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppTheme.poppins,
                                        fontSize: AppTheme.medium),
                                    Container(
                                      height: 3,
                                      margin: const EdgeInsets.only(top: 8),
                                      color: tabType == "notes"
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
                                  tabType = "attachments";
                                });
                              },
                              child: Container(
                                  padding: const EdgeInsets.only(top: 20),
                                  color: AppTheme.white,
                                  child: Column(
                                    children: [
                                      CText(
                                          text: "Attachments",
                                          textColor: tabType == "attachments"
                                              ? AppTheme.black
                                              : AppTheme.textColorGray,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppTheme.poppins,
                                          fontSize: AppTheme.medium),
                                      Container(
                                        height: 3,
                                        margin: const EdgeInsets.only(top: 8),
                                        color: tabType == "attachments"
                                            ? AppTheme.colorPrimary
                                            : AppTheme.mainBackground,
                                      )
                                    ],
                                  )))),
                    ],
                  ),
                ),
                if (tabType == "notes")
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10, top: 15),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: AppTheme.white,
                        border: Border.all(color: AppTheme.grey),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10))),
                    child: CTextField(
                      textColor: AppTheme.textColor,
                      hint: "Notes here.....",
                      fontSize: AppTheme.medium,
                      minLines: 5,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTheme.poppins,
                      controller: _notes,
                      focusedBorder: InputBorder.none,
                      inputBorder: InputBorder.none,
                      onChange: (vl) {
                        setState(() {});
                      },
                    ),
                  ),
                if (tabType == "attachments")
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (await Utils().hasNetwork(context, setState)) {
                            requestCameraPermissions(
                                "video", null, 9, setState);
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(
                              left: 20, right: 5, top: 10),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          elevation: 2,
                          child: Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              alignment: Alignment.center,
                              height:
                                  (MediaQuery.of(context).size.width - 50) / 2,
                              width:
                                  (MediaQuery.of(context).size.width - 50) / 2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 30,
                                    color: AppTheme.red,
                                  ),
                                  CText(
                                    text: "Videos",
                                    padding: const EdgeInsets.only(left: 10),
                                    fontSize: AppTheme.big,
                                    textColor: AppTheme.black,
                                  ),
                                ],
                              )),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (await Utils().hasNetwork(context, setState)) {
                            requestCameraPermissions(
                                "image", null, 9, setState);
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(
                              left: 5, right: 20, top: 10),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          elevation: 2,
                          child: Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              alignment: Alignment.center,
                              height:
                                  (MediaQuery.of(context).size.width - 50) / 2,
                              width:
                                  (MediaQuery.of(context).size.width - 50) / 2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 30,
                                    color: AppTheme.red,
                                  ),
                                  CText(
                                    text: "Images",
                                    padding: const EdgeInsets.only(left: 10),
                                    fontSize: AppTheme.big,
                                    textColor: AppTheme.black,
                                  ),
                                ],
                              )),
                        ),
                      ),
                    ],
                  ),
                if (tabType == "attachments")
                  Container(
                    margin: const EdgeInsets.only(
                        top: 30, right: 20, left: 20, bottom: 30),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_notes.text.isNotEmpty && image.isNotEmpty) {
                          Utils().showYesNoAlert(
                              context: context,
                              message:
                                  "Are you sure you want to finish the inspections?",
                              onYesPressed: () {
                                Get.back();
                                if (widget.isDXBTask) {
                                  reasonBottomSheet(context, reasonList,
                                      onSelected: (selected) {
                                    submitInspection(
                                        selected["inspectionReasonMasterId"]);
                                  });
                                } else {
                                  submitInspection(0);
                                }
                              },
                              onNoPressed: () {
                                Get.back();
                              });
                        } else {
                          Utils().showAlert(
                              buildContext: context,
                              title: "Alert",
                              message: "Please attach at least one image.",
                              onPressed: () {
                                Navigator.of(context).pop();
                              });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor:
                            _notes.text.isNotEmpty && image.isNotEmpty
                                ? AppTheme.colorPrimary
                                : AppTheme.grey,
                        minimumSize: const Size.fromHeight(55),
                      ),
                      child: CText(
                        text: "SUBMIT & FINISH MY INSPECTION",
                        textColor: AppTheme.textPrimary,
                        fontSize: AppTheme.large,
                        fontFamily: AppTheme.urbanist,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ))
        ],
      ),
    );
  }

  Future<void> getEntityDetail() async {
    Api().callAPI(
        context,
        "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${widget.mainTaskId}&entityId=${widget.entityId}",
        {}).then((value) async {
      setState(() {
        entity = entityFromJson(value);
        if (entity != null) {
          if (outletModel == null) {
            inspectorId = entity!.inspectorId ?? 0;
          } else {
            inspectorId = outletModel!.inspectorId;
          }
        } else {
          Utils().showAlert(
              buildContext: context,
              message: noEntityMessage,
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    });
  }

  Future<void> requestCameraPermissions(
      String type, int? productId, int? categoryId, StateSetter myState) async {
    if (Platform.isIOS) {
      cameraUpload(type, productId, categoryId, myState);
    } else {
      bool permissionStatus = false;
      var cameraPermission = await Permission.camera.request();
      LogPrint().log("camera permission is $cameraPermission");
      if (cameraPermission.isGranted || cameraPermission.isProvisional) {
        var microphone = await Permission.microphone.request();
        LogPrint().log("microphone permission is $microphone");
        if (microphone.isGranted || microphone.isProvisional) {
          if (Platform.isIOS) {
            permissionStatus = true;
            cameraUpload(type, productId, categoryId, myState);
          } else {
            DeviceInfoPlugin().androidInfo.then((value) async {
              LogPrint().log("sdk level ${value.version.sdkInt}");
              if (value.version.sdkInt > 32) {
                permissionStatus = true;
              } else {
                permissionStatus = await Permission.storage.request().isGranted;
              }
              LogPrint().log("permission : camera $permissionStatus");
              cameraUpload(type, productId, categoryId, myState);
            });
          }
        }
      }
    }
  }

  Future<void> cameraUpload(
      String type, int? productId, int? categoryId, StateSetter myState) async {
    if (type == "video") {
      LoadingIndicatorDialog().show(context);
      final ImagePicker picker = ImagePicker();
      var image = await picker.pickVideo(
        maxDuration: const Duration(seconds: 10),
        source: ImageSource.camera,
      );
      if (image != null) {
        var file = File(image.path);
        LogPrint().log(image.length.toString());
        await VideoCompress.setLogLevel(0);
        final info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
        LogPrint().log(info!.path);
        uploadImage(
            http.MultipartFile(
                'file',
                File(info.path!).readAsBytes().asStream(),
                File(info.path!).lengthSync(),
                filename: Utils().getFileName(info.path!.split("/").last)),
            productId,
            categoryId,
            myState,
            "video");
      } else {
        LogPrint().log('exception');
        LoadingIndicatorDialog().dismiss();
      }
    } else {
      LoadingIndicatorDialog().show(context);
      final ImagePicker picker = ImagePicker();
      var xFile = await picker.pickImage(source: ImageSource.camera);
      if (xFile != null) {
        LogPrint().log(xFile.length.toString());
        File file = File(xFile.path);
        img.Image? image = img.decodeImage(await file.readAsBytes());
        img.Image compressedImage = img.copyResize(image!, width: 800);
        List<int> compressedBytes = img.encodeJpg(compressedImage, quality: 96);
        if (widget.inspectionId != 0) {
          uploadImage(
              http.MultipartFile.fromBytes(
                'file',
                compressedBytes,
                filename: Utils().getFileName(xFile.path.split("/").last),
              ),
              productId,
              categoryId,
              myState,
              "image");
        } else {
          LoadingIndicatorDialog().dismiss();
        }
      } else {
        LogPrint().log('exception');
        LoadingIndicatorDialog().dismiss();
      }
    }
  }

  void uploadImage(http.MultipartFile media, int? productId, int? categoryId,
      StateSetter myState, String type) {
    LogPrint().log(media.length);
    LogPrint().log(media);
    List<http.MultipartFile> listMedia = [];
    listMedia.add(media);
    var map = {
      "InspectionId": widget.inspectionId.toString(),
    };
    if (productId != null) {
      map.addAll({"ProductDetailsId": productId.toString()});
    }
    if (categoryId != null) {
      map.addAll({"CategoryId": categoryId.toString()});
    }
    print(map);
    Api()
        .callAPIWithFiles(
            context, "Mobile/InspectionDocument/Create", map, listMedia)
        .then((value) {
      LoadingIndicatorDialog().dismiss();
      LogPrint().log(value);
      print("uploadImage value");
      print(value);
      if (value == "error") {
        Utils()
            .showAlert(buildContext: context, message: value, onPressed: () {});
      } else {
        var json = jsonDecode(value);
        if (json["data"] != null) {
          if (type == "image") {
            setState(() {
              image.add(media);
            });
          }

          showAttachmentDialog(json["data"]);
          Utils().showSnackBar(context, "Uploaded successfully.");
        } else {
          Utils().showAlert(
              buildContext: context,
              message: json["message"],
              onPressed: () {
                Get.back();
              });
        }
      }
    });
  }

  showAttachmentDialog(String link) {
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
                  Center(
                    child: CText(
                      text: "Image Uploaded Successfully",
                      maxLines: 5,
                      fontSize: AppTheme.big,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            if (Utils().isVideoLink(link)) {
                              Get.to(
                                  transition: Transition.rightToLeft,
                                  VideoPlayerScreen(
                                    url: link,
                                  ));
                            } else {
                              Get.to(
                                  transition: Transition.rightToLeft,
                                  FullScreenImage(
                                    imageUrl: link,
                                  ));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorPrimary),
                          child: CText(
                            text: 'View',
                            fontSize: AppTheme.medium,
                            textColor: AppTheme.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: CText(
                            text: 'Back',
                            fontSize: AppTheme.medium,
                            textColor: AppTheme.black,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  void submitInspection([selected]) {
    LoadingIndicatorDialog().show(context);
    var map = {
      "inspectionTaskId": widget.taskId,
      "inspectionId": widget.inspectionId,
      "inspectorId": storeUserData.getInt(USER_ID),
      "statusId": 7,
      "finalNotes": _notes.text.toString(),
    };
    if (widget.isDXBTask) {
      map["inspectionReasonMasterId"] = selected;
    }

    Api()
        .callAPI(context, "Mobile/Inspection/UpdateInspection", map)
        .then((value) {
      LoadingIndicatorDialog().dismiss();
      var data = jsonDecode(value);
      if (data["statusCode"] == 200) {
        completeTask(_notes.text.toString());
      } else {
        Utils().showAlert(
            buildContext: context,
            message: data["message"] ?? "",
            onPressed: () {
              Navigator.of(context).pop();
            });
      }
    });
  }

  Future<void> completeTask(String notes) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Department/Task/UpdateTaskStatus", {
        "mainTaskId": widget.mainTaskId,
        "inspectorId": storeUserData.getInt(USER_ID),
        "finalNotes": notes,
        "statusId": 7,
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = jsonDecode(value);
        if (data["statusCode"] == 200 && data["data"] != null) {
          Utils().showAlert(
              buildContext: context,
              message: data["message"],
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(
                    transition: Transition.rightToLeft, const HomeScreen());
              });
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

  void getReasonListing() async {
    var result = await context.apiDio
        .get("api/Department/InspectionReasonMaster/InspectionReasonDropDown");
    if (result.isSuccess) {
      reasonList = (result.data["data"] as List).cast<Map<String, dynamic>>();
      setState(() {});
    }
  }

  void showReason() {
    showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: AppTheme.black,
            surfaceTintColor: AppTheme.black,
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
                  Center(
                    child: CText(
                      text: "Note:",
                      fontSize: AppTheme.big,
                      textAlign: TextAlign.center,
                      fontFamily: AppTheme.poppins,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CText(
                    padding: const EdgeInsets.only(top: 10),
                    text: "Please select reason for complete this task",
                    maxLines: 5,
                    fontSize: AppTheme.medium,
                    fontFamily: AppTheme.poppins,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorPrimary),
                      onPressed: () async {
                        Get.back();
                      },
                      child: CText(
                        text: 'Ok',
                        textColor: AppTheme.black,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> reasonBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> reasonList, {
    Function(Map<String, dynamic>)? onSelected,
  }) {
    int selectedIndex = -1; // local variable to keep track of selection
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Select Reason",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: reasonList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final reason = reasonList[index];
                            return RadioGroup<int>(
                              groupValue: selectedIndex,
                              onChanged: (value) {
                                setState(() {
                                  selectedIndex = value ?? -1;
                                });
                              },
                              child: RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                value: index,
                                title: CText(
                                  text: reason["name"],
                                  textColor: AppTheme.black,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                onChanged: (_) {}, // required but ignored
                              ),
                            );
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              top: 30, right: 20, left: 20, bottom: 30),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedIndex > -1) {
                                Navigator.pop(context);
                                if (onSelected != null) {
                                  onSelected(reasonList[selectedIndex]);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: selectedIndex != -1
                                  ? AppTheme.colorPrimary
                                  : AppTheme.grey,
                              minimumSize: const Size.fromHeight(55),
                            ),
                            child: CText(
                              text: "Submit",
                              textColor: AppTheme.white,
                              fontSize: AppTheme.large,
                              fontFamily: AppTheme.urbanist,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

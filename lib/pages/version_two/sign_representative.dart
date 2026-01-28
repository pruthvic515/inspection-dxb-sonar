import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/LoadingIndicatorDialog.dart';
import 'package:patrol_system/utils/utils.dart';
import 'package:signature/signature.dart';

import '../../controls/text.dart';
import '../../model/representative_model.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/log_print.dart';

class SignRepresentative extends StatefulWidget {
  final RepresentativeData model;
  final int type;
  final int inspectionId;
  final int entityId;

  const SignRepresentative({super.key,
    required this.model,
    required this.type,
    required this.entityId,
    required this.inspectionId});

  @override
  State<SignRepresentative> createState() => _SignRepresentativeState();
}

class _SignRepresentativeState extends State<SignRepresentative> {
  var isAgree = false;
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: AppTheme.black,
    exportBackgroundColor: AppTheme.white,
  );

  @override
  void initState() {
    _controller.onDrawEnd = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.main_background,
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
                    child: CText(
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 20, bottom: 20),
                      text: "Add E-Sign",
                      textColor: AppTheme.white,
                      fontFamily: AppTheme.Urbanist,
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
                  Center(
                    child: CText(
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.all(20),
                      text: "Agree Terms & Conditions",
                      textColor: AppTheme.white,
                      fontFamily: AppTheme.Urbanist,
                      fontSize: AppTheme.large,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  if (isAgree) {
                                    isAgree = false;
                                  } else {
                                    isAgree = true;
                                  }
                                });
                              },
                              icon: isAgree
                                  ? const Icon(
                                Icons.check_box,
                                size: 20,
                                color: AppTheme.colorPrimary,
                              )
                                  : const Icon(
                                Icons.check_box_outline_blank,
                                size: 20,
                                color: AppTheme.grey,
                              )),
                          Expanded(
                              child: CText(
                                text:
                                "By signing, I, ${widget.model
                                    .name} with Emirates ID ${widget.model
                                    .emiratesId}, agree that all products taken will be subject to investigation, and I confirm my consent to this.",
                                textColor: AppTheme.black,
                                fontFamily: AppTheme.Urbanist,
                                maxLines: 3,
                                fontSize: AppTheme.medium,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      )),
                  Card(
                    color: AppTheme.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    margin: EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        Signature(
                          controller: _controller,
                          height: 200,
                          backgroundColor: Colors.white,
                        ),
                        Visibility(
                            visible: _controller.isNotEmpty,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _controller.clear();
                                  });
                                },
                                child: CText(
                                  padding: EdgeInsets.all(10),
                                  text: "Clear",
                                  textColor: AppTheme.red,
                                  fontSize: AppTheme.medium,
                                  fontFamily: AppTheme.Urbanist,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 30, right: 20, left: 20, bottom: 30),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_controller.isNotEmpty && isAgree) {
                          LoadingIndicatorDialog().show(context);

                          var signImage = await _controller.toPngBytes();
                          final tempDir = await getTemporaryDirectory();
                          var media =
                              '${tempDir.path}/${DateTime
                              .timestamp()
                              .microsecondsSinceEpoch}.png';
                          File file = await File(media).create();
                          file.writeAsBytesSync(signImage!);

                          print("path ${file.path}");
                          uploadImage(http.MultipartFile.fromBytes(
                            'file',
                            img.encodeJpg(
                                img.copyResize(
                                    img.decodeImage(await file.readAsBytes())!,
                                    width: 800),
                                quality: 96),
                            filename:
                            Utils().getFileName(file.path
                                .split("/")
                                .last),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: _controller.isNotEmpty && isAgree
                            ? AppTheme.colorPrimary
                            : AppTheme.grey,
                        minimumSize: const Size.fromHeight(55),
                      ),
                      child: CText(
                        text: "Submit",
                        textColor: AppTheme.text_primary,
                        fontSize: AppTheme.large,
                        fontFamily: AppTheme.Urbanist,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void uploadImage(http.MultipartFile media) {
    LogPrint().log(media.length);
    LogPrint().log(media);
    List<http.MultipartFile> listMedia = [];
    listMedia.add(media);
    Api()
        .callAPIWithFiles(
        context,
        "Mobile/InspectionDocument/Create",
        {
          "InspectionId": widget.inspectionId.toString(),
          "EntityId": widget.entityId.toString(),
          "CategoryId": widget.type == 1 ? "6" : "7"
        },
        listMedia)
        .then((value) {
      LoadingIndicatorDialog().dismiss();
      // LogPrint().log(value);
      print("uploadImage Signature" + value);
      if (value == "error") {
        Utils().showAlert(
            buildContext: context,
            message: value,
            onPressed: () {
              Navigator.of(context).pop();
            });
      } else {
        var json = jsonDecode(value);
        if (json["data"] != null) {
          Utils().showSnackBar(context, "Uploaded successfully.");
          Navigator.of(context).pop();
        } else {
          Utils().showAlert(
              buildContext: context,
              message: json["message"],
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      }
    });
  }
}

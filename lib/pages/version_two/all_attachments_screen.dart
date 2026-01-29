import 'dart:io';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/pages/video_player_screen.dart';

// import 'package:video_thumbnail/video_thumbnail.dart';

import '../../controls/text.dart';
import '../../model/attachments.dart';
import '../../utils/api.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../full_screen_image.dart';

class AllAttachmentsScreen extends StatefulWidget {
  final int patrolId;

  const AllAttachmentsScreen({super.key, required this.patrolId});

  @override
  State<AllAttachmentsScreen> createState() => _AllAttachmentsScreenState();
}

class _AllAttachmentsScreenState extends State<AllAttachmentsScreen> {
  late final int inspectionId;
  var isLoading = true;
  List<AttachmentData> attachmentList = [];

  @override
  void initState() {
    inspectionId = widget.patrolId;
    getAttachments();
    super.initState();
  }

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
                  isLoading
                      ? Container(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height - 182,
                          child: const CircularProgressIndicator(
                            color: AppTheme.black,
                          ))
                      : attachmentList.isNotEmpty
                          ? GridView.count(
                              childAspectRatio: 1.15,
                              crossAxisCount: 3,
                              crossAxisSpacing: 0.0,
                              mainAxisSpacing: 0.0,
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.only(bottom: 60.0, top: 30),
                              children:
                                  List.generate(attachmentList.length, (index) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  child: Card(
                                    margin: const EdgeInsets.all(5),
                                    color: AppTheme.black,
                                    surfaceTintColor: AppTheme.white,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5))),
                                    child: attachmentList[index]
                                            .documentContentType
                                            .startsWith("video")
                                        ? Stack(children: [
                                            Container(
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(5)),
                                                border: Border.all(
                                                    color: AppTheme.black,
                                                    width: 0.4),
                                                image: DecorationImage(
                                                  fit: BoxFit.fill,
                                                  image: Image.file(
                                                          File(attachmentList[
                                                                      index]
                                                                  .thumbnail ??
                                                              ""),
                                                          fit: BoxFit.contain)
                                                      .image,
                                                  colorFilter: ColorFilter.mode(
                                                      Colors.black
                                                          .withValues(alpha: 0.2),
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
                                                  const BorderRadius.all(
                                                      Radius.circular(5)),
                                              image: DecorationImage(
                                                fit: BoxFit.fill,
                                                image: FastCachedImageProvider(
                                                  attachmentList[index]
                                                      .documentUrl,
                                                ),
                                                colorFilter: ColorFilter.mode(
                                                    Colors.black
                                                        .withValues(alpha: 0.2),
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
                                            url: attachmentList[index]
                                                .documentUrl,
                                          ));
                                    } else {
                                      Get.to(
                                          transition: Transition.rightToLeft,
                                          FullScreenImage(
                                            imageUrl: attachmentList[index]
                                                .documentUrl,
                                          ));
                                    }
                                  },
                                );
                              }))
                          : Container(
                              alignment: Alignment.center,
                              height: MediaQuery.of(context).size.height - 182,
                              child: CText(
                                textAlign: TextAlign.center,
                                padding: const EdgeInsets.all(20),
                                text: "NO DATA FOUND",
                                textColor: AppTheme.black,
                                fontFamily: AppTheme.urbanist,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w600,
                                fontSize: AppTheme.large,
                              ),
                            )
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
                        text: "My Attachments",
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
          ],
        ));
  }

  void getAttachments() {
    Api()
        .getAPI(context,
            "Mobile/InspectionDocument/GetAllByInspectionId?Id=$inspectionId")
        .then((value) async {
      var data = attachmentsFromJson(value);
      if (data.data.isNotEmpty) {
        getThumbnails(data);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void getThumbnails(Attachments data) {
    attachmentList.clear();
    for (var i in data.data) {
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
                print("thumbnail path: $thumbnail");
                setState(() {
                  i.thumbnail = thumbnail;
                  attachmentList.add(i);
                });
              } else {
                setState(() {
                  i.thumbnail = "";
                  attachmentList.add(i);
                  print("return thumbnail path: 1");
                });
              }
            } on Exception catch (e) {
              setState(() {
                i.thumbnail = "";
                attachmentList.add(i);
                print(e);
                print("return thumbnail path: catch");
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
                print("thumbnail path: $thumbnail");
                setState(() {
                  i.thumbnail = thumbnail;
                  attachmentList.add(i);
                });
              } else {
                setState(() {
                  i.thumbnail = "";
                  attachmentList.add(i);
                  print("return thumbnail path: 1");
                });
              }
            } on Exception catch (e) {
              setState(() {
                i.thumbnail = "";
                attachmentList.add(i);
                print(e);
                print("return thumbnail path: catch");
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
    setState(() {
      isLoading = false;
    });
  }
}

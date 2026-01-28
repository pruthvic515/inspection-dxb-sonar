import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:patrol_system/utils/utils.dart';

import '../controls/text.dart';
import '../model/entity_detail_model.dart';
import '../model/patrol_visit_model.dart';
import '../utils/color_const.dart';

class PatrolVisitsAll extends StatefulWidget {
  EntityDetailModel place;
  List<PatrolVisitData> list;

  PatrolVisitsAll({super.key, required this.list, required this.place});

  @override
  State<PatrolVisitsAll> createState() => _PatrolVisitsAllState(list, place);
}

class _PatrolVisitsAllState extends State<PatrolVisitsAll> {
  EntityDetailModel place;
  var storeUserData = StoreUserData();
  List<PatrolVisitData> list = [];

  _PatrolVisitsAllState(this.list, this.place);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.main_background,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(top: 182),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  list.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                /* Get.to(
                              transition: Transition.rightToLeft,
                              AddNewPatrol(
                                place: place,
                                visit: list[index],
                              ));*/
                              },
                              child: Card(
                                  elevation: 2,
                                  color: AppTheme.white,
                                  surfaceTintColor: AppTheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Column(
                                    children: [
                                      Utils().sizeBoxHeight(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  left: 20, right: 10),
                                              textAlign: TextAlign.start,
                                              text: "Visit ID",
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor:
                                                  AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  right: 20, left: 10),
                                              textAlign: TextAlign.start,
                                              text: list[index]
                                                  .patrolId
                                                  .toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor:
                                                  AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      /*    Utils().sizeBoxHeight(height: 5),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  left: 20, right: 10),
                                              textAlign: TextAlign.start,
                                              text: "Outlet Name",
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor: AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  right: 20, left: 10),
                                              textAlign: TextAlign.start,
                                              text:"X",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor: AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),*/
                                      Utils().sizeBoxHeight(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  left: 20, right: 10),
                                              textAlign: TextAlign.start,
                                              text: "Date & Time",
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor:
                                                  AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          // 2024-04-29T18:49:24.103
                                          Expanded(
                                            flex: 3,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  right: 20, left: 10),
                                              textAlign: TextAlign.start,
                                              text:
                                                  "${DateFormat("dd-MM-yyyy").format(DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ").parse(list[index].createdOn))} \n${DateFormat("hh:mm:ss aa").format(DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ").parse(list[index].createdOn))}",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor:
                                                  AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      /*  Utils().sizeBoxHeight(height: 5),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  left: 20, right: 10),
                                              textAlign: TextAlign.start,
                                              text: "Experience",
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor: AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  right: 20, left: 10),
                                              textAlign: TextAlign.start,
                                              text: Utils()
                                                  .getRatings(list[index].rating),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor: AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),*/
                                      Utils().sizeBoxHeight(height: 5),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  left: 20, right: 10),
                                              textAlign: TextAlign.start,
                                              text: "Comments",
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              textColor:
                                                  AppTheme.gray_Asparagus,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: CText(
                                              padding: const EdgeInsets.only(
                                                  right: 20, left: 10),
                                              textAlign: TextAlign.start,
                                              text: list[index].comments,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textColor:
                                                  AppTheme.text_color_red,
                                              fontFamily: AppTheme.Urbanist,
                                              fontSize: AppTheme.large,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Utils().sizeBoxHeight(height: 15),
                                    ],
                                  )),
                            );
                          })
                      : Container(),
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
                                left: 60, right: 60, top: 70, bottom: 0),
                            text: place.entityName,
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
                                left: 60, right: 60, bottom: 0),
                            text: place.location?.address ?? "",
                            textColor: AppTheme.text_primary,
                            fontFamily: AppTheme.Urbanist,
                            fontSize: AppTheme.big,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          ],
        ));
  }
}

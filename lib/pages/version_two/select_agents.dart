import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:patrol_system/controls/LoadingIndicatorDialog.dart';
import 'package:patrol_system/controls/text.dart';

import '../../model/search_entity_model.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';

class SelectAgents extends StatefulWidget {
 final List<SearchEntityData> list;
 final List<SearchEntityData> selectedAgents;
  const SelectAgents({super.key,required this.list,required this.selectedAgents});

  @override
  State<SelectAgents> createState() => _SelectAgentsState(selectedAgents);
}

class _SelectAgentsState extends State<SelectAgents> {
  List<SearchEntityData> selectedAgents;

  _SelectAgentsState(this. selectedAgents);
  @override
  void initState() {
    LoadingIndicatorDialog().show(context);
    Future.delayed(const Duration(milliseconds: 1000), () async {
      LoadingIndicatorDialog().dismiss();
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.main_background,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Get.back(result: selectedAgents);
                      },
                      child: CText(
                        padding: const EdgeInsets.all(10),
                        textAlign: TextAlign.center,
                        text: "DONE",
                        textColor: AppTheme.black,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.medium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.list.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: AppTheme.white,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10),
                          surfaceTintColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                if (selectedAgents.firstWhereOrNull((element) =>
                                element.entityId ==
                                    widget.list[index].entityId) ==
                                    null) {
                                  selectedAgents.add(widget.list[index]);
                                } else {
                                  selectedAgents.remove(widget.list[index]);
                                }
                              });
                            },
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 10, bottom: 10),
                                    text: widget.list[index].entityName,
                                    textColor: AppTheme.gray_Asparagus,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  selectedAgents.firstWhereOrNull((element) =>
                                  element.entityId ==
                                      widget.list[index].entityId) !=
                                      null
                                      ? const Icon(
                                    Icons.check_box,
                                    size: 20,
                                    color: AppTheme.colorPrimary,
                                  )
                                      : const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 20,
                                    color: AppTheme.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  Utils().sizeBoxHeight()
                ],
              ),
            ),
            Container(
                height: 182,
                color: AppTheme.colorPrimary,
                width: double.infinity,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back(result: selectedAgents);
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
                      alignment: Alignment.center,
                      child: CText(
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.only(
                            left: 0, right: 0, top: 35, bottom: 0),
                        text: "Select Agents",
                        textColor: AppTheme.white,
                        fontFamily: AppTheme.Urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )),
          ],
        ));
  }
}

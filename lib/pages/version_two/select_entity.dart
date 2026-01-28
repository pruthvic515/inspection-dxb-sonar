import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/utils/api.dart';
import 'package:patrol_system/utils/color_const.dart';

import '../../controls/LoadingIndicatorDialog.dart';
import '../../controls/text.dart';
import '../../model/search_entity_model.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';

class SelectEntity extends StatefulWidget {
  List<SearchEntityData> selectedEntity;

  SelectEntity({super.key, required this.selectedEntity});

  @override
  State<SelectEntity> createState() => _SelectEntityState(selectedEntity);
}

class _SelectEntityState extends State<SelectEntity> {
  final _searchEntity = TextEditingController();
  List<SearchEntityData> searchList = [];
  List<SearchEntityData> list = [];
  List<SearchEntityData> selectedEntity = [];

  _SelectEntityState(this.selectedEntity);

  @override
  void initState() {
    getAllEntities();
    super.initState();
  }

  Future<void> getAllEntities() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context, "Mobile/Entity/GetAllEntityBasicDetail")
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        setState(() {
          searchList.clear();
          list.clear();
          var data = allEntityFromJson(value);
          if (data.data.isNotEmpty) {
            searchList.addAll(data.data);
            list.addAll(data.data);
          } else {
            Utils().showAlert(
                buildContext: context,
                message: data.data.isEmpty
                    ? "No Data Found"
                    : "Something Went Wrong",
                onPressed: () {
                  Navigator.of(context).pop();
                });
          }
        });
      });
    }
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
                        Get.back(result: selectedEntity);
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
                  Container(
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: AppTheme.white,
                    ),
                    child: TextFormField(
                      controller: _searchEntity,
                      onChanged: _filterList,
                      maxLines: 1,
                      cursorColor: AppTheme.colorPrimary,
                      cursorWidth: 2,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          hintText: "Search...",
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.grey,
                          ),
                          hintStyle: TextStyle(
                              fontFamily: AppTheme.Poppins,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.black,
                              fontSize: AppTheme.large)),
                    ),
                  ),
                  ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
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
                                if (selectedEntity.firstWhereOrNull((element) =>
                                        element.entityId ==
                                        list[index].entityId) ==
                                    null) {
                                  selectedEntity.add(list[index]);
                                } else {
                                  selectedEntity.remove(list[index]);
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
                                    text: list[index].entityName,
                                    textColor: AppTheme.gray_Asparagus,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  selectedEntity.firstWhereOrNull((element) =>
                                              element.entityId ==
                                              list[index].entityId) !=
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
                        Get.back(result: selectedEntity);
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
                        text: "Select Entities",
                        textColor: AppTheme.text_primary,
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

  void _filterList(String searchText) {
    list.clear();
    if (searchText.isEmpty) {
      list.addAll(searchList);
    } else {
      for (var item in searchList) {
        if (item.entityName.toLowerCase().contains(searchText.toLowerCase())) {
          list.add(item);
        }
      }
    }
    setState(() {});
  }
}

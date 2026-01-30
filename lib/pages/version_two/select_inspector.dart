import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/utils/api.dart';
import '../../controls/text.dart';
import '../../model/all_user_model.dart';
import '../../utils/color_const.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';

class SelectInspector extends StatefulWidget {
  bool isPrimary;
  List<AllUserData> selectedUsers;
  List<AllUserData>? primaryInspector;

  SelectInspector(
      {super.key,
      required this.isPrimary,
      required this.selectedUsers,
      this.primaryInspector});

  @override
  State<SelectInspector> createState() => _SelectInspectorState();
}

class _SelectInspectorState extends State<SelectInspector> {
  final _searchController = TextEditingController();
  List<AllUserData> list = [];
  List<AllUserData> searchList = [];
  List<AllUserData> selectedUsers = [];

  // _SelectInspectorState(this.selectedUsers);

  @override
  void initState() {
    selectedUsers.clear();
    if (widget.isPrimary) {
      selectedUsers.addAll(widget.primaryInspector ?? []);
    } else {
      selectedUsers.addAll(widget.selectedUsers);
    }

    getAllUsers();
    super.initState();
  }

  Future<void> getAllUsers() async {
    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    try {
      final value = await Api().getAPI(context, "Department/User/GetAllUser");
      debugPrint(value);
      await _processUsersResponse(value);
    } finally {
      if (mounted) {
        LoadingIndicatorDialog().dismiss();
      }
    }
  }

  Future<void> _processUsersResponse(String value) async {
    if (!mounted) return;

    setState(() {
      searchList.clear();
      list.clear();
      final data = allUsersFromJson(value);

      if (data.data.isEmpty) {
        _showEmptyDataAlert(data.data.isEmpty);
        return;
      }

      _populateUserLists(data.data);
    });
  }

  void _populateUserLists(List<AllUserData> users) {
    if (widget.isPrimary == false) {
      _addFilteredUsers(users);
    } else {
      _addAllUsers(users);
    }
  }

  void _addFilteredUsers(List<AllUserData> users) {
    final primaryIds =
        widget.primaryInspector?.map((e) => e.departmentUserId).toSet() ?? {};
    final filteredUsers = users
        .where((element) => !primaryIds.contains(element.departmentUserId))
        .toList();
    list.addAll(filteredUsers);
  }

  void _addAllUsers(List<AllUserData> users) {
    debugPrint("primaryInspector ${widget.primaryInspector?.length}");
    debugPrint("selectedUsers ${selectedUsers.length}");
    searchList.addAll(users);
    list.addAll(users);
  }

  void _showEmptyDataAlert(bool isEmpty) {
    Utils().showAlert(
      buildContext: context,
      message: isEmpty ? "No Data Found" : "Something Went Wrong",
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.mainBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: AppTheme.white,
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: _filterList,
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
                              fontFamily: AppTheme.poppins,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.black,
                              fontSize: AppTheme.large)),
                    ),
                  ),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() {
                              final exists = selectedUsers.any((u) =>
                                  u.departmentUserId ==
                                  list[index].departmentUserId);
                              if (!exists) {
                                selectedUsers.add(list[index]);
                              } else {
                                selectedUsers.removeWhere((u) =>
                                    u.departmentUserId ==
                                    list[index].departmentUserId);
                              }
                            });
                          },
                          child: Card(
                            color: AppTheme.white,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 10),
                            surfaceTintColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CText(
                                        textAlign: TextAlign.start,
                                        padding: const EdgeInsets.only(
                                            right: 10, top: 20, bottom: 5),
                                        text: list[index].name,
                                        textColor: AppTheme.colorPrimary,
                                        fontFamily: AppTheme.urbanist,
                                        fontSize: AppTheme.large,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      CText(
                                        textAlign: TextAlign.start,
                                        padding: const EdgeInsets.only(
                                            right: 10, top: 0, bottom: 5),
                                        text: list[index].userName,
                                        textColor: AppTheme.grayAsparagus,
                                        fontFamily: AppTheme.urbanist,
                                        fontSize: AppTheme.large,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      const SizedBox(
                                        height: 15,
                                      )
                                    ],
                                  )),
                                  Visibility(
                                    visible: true, // keep always visible
                                    child: Icon(
                                      selectedUsers.any((element) =>
                                              element.departmentUserId ==
                                              list[index].departmentUserId)
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 20,
                                      color: selectedUsers.any((element) =>
                                              element.departmentUserId ==
                                              list[index].departmentUserId)
                                          ? AppTheme.colorPrimary
                                          : AppTheme.grey,
                                    ),
                                  )
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
                        Get.back(result: selectedUsers);
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
                        text: "Search Inspector",
                        textColor: AppTheme.textPrimary,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Positioned(
                      top: 55,
                      right: 10,
                      child: Visibility(
                          visible: true,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                Get.back(result: selectedUsers);
                              },
                              child: CText(
                                padding: const EdgeInsets.all(10),
                                textAlign: TextAlign.center,
                                text: "DONE",
                                textColor: AppTheme.white,
                                fontFamily: AppTheme.urbanist,
                                fontSize: AppTheme.medium,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )),
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
        if (item.name.toLowerCase().contains(searchText.toLowerCase()) ||
            item.userName.toLowerCase().contains(searchText.toLowerCase())) {
          list.add(item);
        }
      }
    }
    setState(() {});
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/controls/form_text_field.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/model/area_model.dart';
import 'package:patrol_system/pages/menu_page.dart';
import 'package:patrol_system/pages/search_page.dart';
import 'package:patrol_system/utils/api.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/log_print.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:patrol_system/utils/utils.dart';

import '../../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../../model/entity_detail_model.dart';
import '../../model/task_model.dart';
import 'entity_details.dart';
import 'inspection_detail_screen.dart';
import 'inspection_outlet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var storeUserData = StoreUserData();
  var latitude = -99.99;
  var longitude = -99.99;
  var googleAddress = "";
  var isFetched = false;
  var tabType = "pending";
  final _searchController = TextEditingController();
  List<Tasks> list = [];
  List<Tasks> tasks = [];
  var currentHeight = 0.0;
  final TextEditingController _searchArea = TextEditingController();
  final List<AreaData> _filteredItems = [];
  final List<AreaData> data = [];
  final List<AreaData> taskStatus = [];
  AreaData? area;
  AreaData? category;
  int pendingCount = 0;
  int completeCount = 0;

  int waitingCount = 0;
  int feedbackCount = 0;

  bool _hasFetchedTasks = false;

  // Agent-specific tab state
  String agentTabType =
      "feedback"; // "waiting" for statusId 4, "feedback" for statusId 6

  int currentPageIndex = 1;

  // Legacy pagination (for non-agent users)
  int pageIndex = 1;
  final int pageSize = 10;
  bool isLastPage = false;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    if (storeUserData.getBoolean(IS_AGENT_LOGIN)) {
      agentTabType = "feedback";
      // Load feedback tab (statusId = 6)
      // Preload waiting tab (statusId = 4)
      refreshTask();
    }
    _scrollController.addListener(() {
      if (!isLoading &&
          !isLastPage &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100) {
        debugPrint("🔽 Reached bottom, loading next page...");
        refreshTask();
      }
    });
    getGeoLocationPosition();
    getTaskStatus();
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchArea.dispose();
    super.dispose();
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
          debugPrint("GetTaskStatus $value}");
          if (data.data.isNotEmpty) {
            taskStatus.addAll(data.data);
            if (!storeUserData.getBoolean(IS_AGENT_LOGIN)) {
              refreshTask();
            }
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

  Future<void> getTasks() async {
    if (_hasFetchedTasks) return;
    _hasFetchedTasks = true;

    if (!mounted) return;

    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      var map = storeUserData.getBoolean(IS_AGENT_LOGIN)
          ? {"agentId": storeUserData.getInt(USER_ID)}
          : {
              "userId": storeUserData.getInt(USER_ID),
            };

      Api()
          .callAPI(context, "Department/Task/GetTask", map)
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        if (!mounted) return;

        debugPrint(value);
        try {
          if (value == null || value.isEmpty) {
            _hasFetchedTasks = false;
            return;
          }

          String decryptedValue = value;

          try {
            final responseJson = jsonDecode(decryptedValue);

            if (responseJson is Map<String, dynamic> &&
                responseJson['data'] != null &&
                responseJson['data'] is String) {
              final encryptAndDecrypt = EncryptAndDecrypt();
              final decryptedData = await encryptAndDecrypt.decryption(
                payload: responseJson['data'] as String,
              );

              if (decryptedData.isNotEmpty) {
                final decryptedJson = jsonDecode(decryptedData);
                responseJson['data'] = decryptedJson;
                decryptedValue = jsonEncode(responseJson);
              }
            }
          } catch (jsonError) {
            print("Error parsing JSON: $jsonError");
          }

          setState(() {
            list.clear();
            tasks.clear();
            var data = tasksFromJson(decryptedValue);
            if (data.data.isNotEmpty) {
              _hasFetchedTasks = false;
              tasks.addAll(data.data);
              pendingCount = tasks
                  .where((item) => item.statusId < 6 && item.statusId != 3)
                  .length;
              completeCount = tasks
                  .where((item) => item.statusId > 5 || item.statusId == 3)
                  .length;
              if (tabType == "pending") {
                list.addAll(tasks
                    .where((item) => item.statusId < 6 && item.statusId != 3));
              } else {
                list.addAll(tasks
                    .where((item) => item.statusId > 5 || item.statusId == 3));
              }
            } else {
              pendingCount = 0;
              completeCount = 0;
              _hasFetchedTasks = false;
              if (data.message != null && data.message!.isNotEmpty) {
                Utils().showAlert(
                  buildContext: context,
                  message: data.message!,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                );
              }
            }
          });
        } catch (e) {
          debugPrint("Error processing response:  $e");
          _hasFetchedTasks = false;
          if (mounted) {
            Utils().showAlert(
              buildContext: context,
              message: "Error processing response: $e",
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
        }
      });
    }
  }

  Future<void> getAgentTasks() async {
    if (isLastPage || isLoading) return;
    if (currentPageIndex == 1) {
      tasks.clear();
      list.clear();
    }
    if (!mounted) return;
    if (!await Utils().hasNetwork(context, setState)) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    try {
      final payload = {
        "globalSearch": _searchController.text.toString(),
        "agentId": storeUserData.getInt(USER_DESIGNATION_ID).toString(),
        "paginationModel": {
          "pageIndex": currentPageIndex,
          "pageSize": pageSize,
        }
      };

      final value =
          await Api().callAPI(context, "Department/Task/GetAll", payload);

      if (!mounted) return;
      if (currentPageIndex == 1) {}
      String decryptedValue = value;

      try {
        final responseJson = jsonDecode(decryptedValue);

        if (responseJson is Map<String, dynamic> &&
            responseJson['data'] != null &&
            responseJson['data'] is String) {
          final encryptAndDecrypt = EncryptAndDecrypt();
          final decryptedData = await encryptAndDecrypt.decryption(
            payload: responseJson['data'] as String,
          );

          if (decryptedData.isNotEmpty) {
            final decryptedJson = jsonDecode(decryptedData);
            responseJson['data'] = decryptedJson;
            decryptedValue = jsonEncode(responseJson);
          }
        }
      } catch (jsonError) {
        print("Error parsing JSON: $jsonError");
      }

      LoadingIndicatorDialog().dismiss();

      final data = taskResponseFromJson(decryptedValue);

      if (data.tasks.isNotEmpty) {
        tasks.addAll(data.tasks);
        waitingCount = tasks.where((e) => e.statusId == 4).toList().length;
        feedbackCount = tasks.where((e) => e.statusId == 6).toList().length;

        if (agentTabType == "waiting") {
          list.addAll(data.tasks.where((e) => e.statusId == 4).toList());
        } else {
          list.addAll(data.tasks.where((e) => e.statusId == 6).toList());
        }
        if (tasks.length >= data.totalCount) {
          if (mounted) {
            isLastPage = true;
            isLoading = false;
          }
        } else {
          if (mounted) {
            setState(() {
              currentPageIndex++;
            });
          }
        }
      } else {
        // // No more tasks from backend
        if (mounted) {
          setState(() {
            isLastPage = true;
          });
        }
      }

      // // Auto-load next page if screen is not scrollable yet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isLastPage) {
          getAgentTasks();
        }
      });
    } catch (e) {
      debugPrint("Pagination error for $currentPageIndex tab: $e");
    } finally {
      LoadingIndicatorDialog().dismiss();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildAgentTasksView() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
            ),
            width: MediaQuery.of(context).size.width,
            color: AppTheme.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CText(
                  text: "My Task",
                  textColor: AppTheme.black,
                  fontFamily: AppTheme.urbanist,
                  fontSize: AppTheme.big_20,
                  fontWeight: FontWeight.w800,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorPrimary),
                  onPressed: () {
                    showSelectionSheet();
                  },
                  child: CText(
                    text: "Search Entity",
                    textColor: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Tabs for Agent Users (statusId 6 first, then 4)
          Container(
            width: MediaQuery.of(context).size.width,
            color: AppTheme.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // First tab: Proceed For Agent Feedback (statusId = 6)
                Expanded(
                    flex: 1,
                    child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            agentTabType = "feedback";
                          });
                          // Load data if not already loaded
                          if (tasks.isEmpty) {
                            getAgentTasks();
                          } else {
                            list.clear();
                            list.addAll(tasks.where((e) => e.statusId == 6));
                          }
                        },
                        child: Container(
                            padding: const EdgeInsets.only(top: 10),
                            color: AppTheme.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CText(
                                    text: "Awaiting Feedback($feedbackCount)",
                                    textColor: agentTabType == "feedback"
                                        ? AppTheme.black
                                        : AppTheme.textColorGray,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppTheme.poppins,
                                    textAlign: TextAlign.center,
                                    fontSize: AppTheme.medium),
                                Container(
                                  height: 3,
                                  margin: const EdgeInsets.only(top: 8),
                                  color: agentTabType == "feedback"
                                      ? AppTheme.colorPrimary
                                      : AppTheme.mainBackground,
                                )
                              ],
                            )))),
                // Second tab: Waiting For Agent Confirmation (statusId = 4)
                Expanded(
                    flex: 1,
                    child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            agentTabType = "waiting";
                          });
                          // Load data if not already loaded
                          if (list.isEmpty) {
                            getAgentTasks();
                          } else {
                            list.clear();
                            list.addAll(tasks.where((e) => e.statusId == 4));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 10),
                          color: AppTheme.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CText(
                                text: "Awaiting Confirmation($waitingCount)",
                                textColor: agentTabType == "waiting"
                                    ? AppTheme.black
                                    : AppTheme.textColorGray,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppTheme.poppins,
                                fontSize: AppTheme.medium,
                                textAlign: TextAlign.center,
                              ),
                              Container(
                                height: 3,
                                margin: const EdgeInsets.only(top: 8),
                                color: agentTabType == "waiting"
                                    ? AppTheme.colorPrimary
                                    : AppTheme.mainBackground,
                              )
                            ],
                          ),
                        ))),
              ],
            ),
          ),
          // Search field
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: AppTheme.white,
            ),
            child: TextFormField(
              controller: _searchController,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }

                _debounce = Timer(const Duration(milliseconds: 850), () {
                  currentPageIndex = 1;
                  isLastPage = false;
                  getAgentTasks();
                });
              },
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
                      fontFamily: AppTheme.poppins,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.black,
                      fontSize: AppTheme.large)),
            ),
          ),
          // Task list or empty state
          list.isEmpty && !isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  padding: const EdgeInsets.only(top: 10),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildTaskCard(list[index]);
                  }),
          if (isLoading && list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.grey,
            ),
            const SizedBox(height: 16),
            CText(
              text: "No tasks found",
              textColor: AppTheme.textColorGray,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            CText(
              text: agentTabType == "waiting"
                  ? "No tasks waiting for agent confirmation"
                  : "No tasks ready for agent feedback",
              textColor: AppTheme.textColorGray,
              fontFamily: AppTheme.poppins,
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Tasks task) {
    return GestureDetector(
      child: Card(
          margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
          color: AppTheme.white,
          surfaceTintColor: AppTheme.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Padding(
              padding: const EdgeInsets.only(left: 15.0, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CText(
                          textAlign: TextAlign.start,
                          padding: const EdgeInsets.only(right: 10, top: 10),
                          text: task.taskName,
                          textColor: AppTheme.grayAsparagus,
                          fontFamily: AppTheme.urbanist,
                          fontSize: AppTheme.large,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CText(
                    textAlign: TextAlign.start,
                    padding:
                        const EdgeInsets.only(right: 10, top: 0, bottom: 5),
                    text: task.outletName.isEmpty
                        ? task.entityName
                        : "${task.entityName} (${task.outletName})",
                    textColor: AppTheme.colorPrimary,
                    fontFamily: AppTheme.urbanist,
                    fontSize: AppTheme.large,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CText(
                        textAlign: TextAlign.end,
                        padding: const EdgeInsets.only(right: 5, top: 5),
                        text: "Date & Time :",
                        textColor: AppTheme.grayAsparagus,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                      CText(
                        textAlign: TextAlign.end,
                        padding: const EdgeInsets.only(right: 20, top: 5),
                        text: DateFormat("dd-MM-yyyy hh:mm:ss aa")
                            .format(task.createdOn),
                        textColor: AppTheme.grayAsparagus,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  Visibility(
                      visible: task.notes.isNotEmpty,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CText(
                            textAlign: TextAlign.end,
                            padding: const EdgeInsets.only(right: 5, top: 10),
                            text: "Notes :",
                            textColor: AppTheme.colorPrimary,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.medium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w700,
                          ),
                          Expanded(
                              child: CText(
                            padding: const EdgeInsets.only(right: 20, top: 10),
                            text: task.notes,
                            textColor: AppTheme.grayAsparagus,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.medium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      )),
                ],
              ))),
      onTap: () async {
        Get.to(
            transition: Transition.rightToLeft,
            EntityDetails(
              fromActive: agentTabType == "waiting",
              task: task,
              entityId: task.entityID!,
              taskId: task.inspectionTaskId,
              statusId: task.statusId,
              inspectionId: 0,
              category: 1,
              isAgentEmployees: task.isAgentEmployees,
              completeStatus: agentTabType == "feedback",
            ))?.then((onValue) {
          refreshTask();
        });
      },
    );
  }

  Future getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
    } else {
      permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          Utils().showAlert(
              buildContext: context,
              message: "Location permissions are denied.",
              onPressed: () {
                Navigator.of(context).pop();
              });
        } else {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          latitude = position.latitude;
          longitude = position.longitude;
          List placeMarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          LogPrint().log(placeMarks);
          Placemark place = placeMarks[0];
          if (mounted) {
            setState(() {
              isFetched = true;
              googleAddress =
                  '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
            });
          }
          LogPrint().log("address$googleAddress");
        }
      } else {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        latitude = position.latitude;
        longitude = position.longitude;
        List placeMarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        LogPrint().log(placeMarks);
        Placemark place = placeMarks[0];
        if (mounted) {
          setState(() {
            isFetched = true;
            googleAddress =
                '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
          });
        }
        LogPrint().log("address$googleAddress");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    currentHeight = MediaQuery.of(context).size.height;
    return RefreshIndicator(
        onRefresh: () async {
          refreshTask();
        },
        child: Scaffold(
            backgroundColor: AppTheme.mainBackground,
            body: Column(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppTheme.colorPrimary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 50,
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: CText(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  text:
                                      "${DateFormat("dd MMMM yyyy").format(Utils().getCurrentGSTTime())} \nHi, ${storeUserData.getString(NAME)} ",
                                  textColor: AppTheme.textPrimary,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.big,
                                  fontWeight: FontWeight.w600,
                                )),
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(
                                      transition: Transition.rightToLeft,
                                      const MenuPage());
                                },
                                child: Image.asset(
                                  "${ASSET_PATH}profile.png",
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                        CText(
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 20),
                          text: googleAddress.isEmpty
                              ? "Your Location \nLoading...\n"
                              : "Your Location \n$googleAddress",
                          textColor: AppTheme.textPrimary,
                          fontFamily: AppTheme.urbanist,
                          fontSize: AppTheme.large,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    )),
                Expanded(
                    child: storeUserData.getBoolean(IS_AGENT_LOGIN)
                        ? _buildAgentTasksView()
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 20,
                                        bottom: 5),
                                    width: MediaQuery.of(context).size.width,
                                    color: AppTheme.white,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CText(
                                          text: "My Task",
                                          textColor: AppTheme.black,
                                          fontFamily: AppTheme.urbanist,
                                          fontSize: AppTheme.big_20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.colorPrimary),
                                          onPressed: () {
                                            showSelectionSheet();
                                          },
                                          child: CText(
                                            text: "Search Entity",
                                            textColor: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )),
                                // Tabs for Non-Agent Users
                                if (!storeUserData.getBoolean(IS_AGENT_LOGIN))
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    color: AppTheme.white,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  setState(() {
                                                    list.clear();
                                                    tabType = "pending";
                                                    refreshTask();
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  color: AppTheme.white,
                                                  child: Column(
                                                    children: [
                                                      CText(
                                                          text:
                                                              "Active ($pendingCount)",
                                                          textColor: tabType ==
                                                                  "pending"
                                                              ? AppTheme.black
                                                              : AppTheme
                                                                  .textColorGray,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily:
                                                              AppTheme.poppins,
                                                          fontSize:
                                                              AppTheme.medium),
                                                      Container(
                                                        height: 3,
                                                        margin: const EdgeInsets
                                                            .only(top: 8),
                                                        color: tabType == "pending"
                                                            ? AppTheme
                                                                .colorPrimary
                                                            : AppTheme
                                                                .mainBackground,
                                                      )
                                                    ],
                                                  ),
                                                ))),
                                        Expanded(
                                            flex: 1,
                                            child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  setState(() {
                                                    list.clear();
                                                    tabType = "completed";
                                                    refreshTask();
                                                  });
                                                },
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    color: AppTheme.white,
                                                    child: Column(
                                                      children: [
                                                        CText(
                                                            text:
                                                                "Inactive ($completeCount)",
                                                            textColor: tabType ==
                                                                    "completed"
                                                                ? AppTheme.black
                                                                : AppTheme
                                                                    .textColorGray,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontFamily: AppTheme
                                                                .poppins,
                                                            fontSize: AppTheme
                                                                .medium),
                                                        Container(
                                                          height: 3,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(top: 8),
                                                          color: tabType ==
                                                                      "completed" &&
                                                                  !storeUserData
                                                                      .getBoolean(
                                                                          IS_AGENT_LOGIN)
                                                              ? AppTheme
                                                                  .colorPrimary
                                                              : AppTheme
                                                                  .mainBackground,
                                                        )
                                                      ],
                                                    )))),
                                      ],
                                    ),
                                  ),
                                // Search field
                                Container(
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 20),
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: AppTheme.white,
                                  ),
                                  child: TextFormField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      _filterList(value);
                                    },
                                    maxLines: 1,
                                    cursorColor: AppTheme.colorPrimary,
                                    cursorWidth: 2,
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.all(5),
                                        hintText: "Search...",
                                        border: InputBorder.none,
                                        prefixIcon: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(
                                                Icons.search,
                                                color: AppTheme.grey,
                                              ),
                                            ),
                                          ],
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
                                    itemCount: list.length,
                                    padding: const EdgeInsets.only(top: 10),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      var task = list[index];
                                      return GestureDetector(
                                        child: Card(
                                            margin: const EdgeInsets.only(
                                                left: 20, right: 20, top: 10),
                                            color: AppTheme.white,
                                            surfaceTintColor: AppTheme.white,
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(12))),
                                            child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 15.0, bottom: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: CText(
                                                            textAlign:
                                                                TextAlign.start,
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 10,
                                                                    top: 10),
                                                            text: list[index]
                                                                .taskName,
                                                            textColor: AppTheme
                                                                .grayAsparagus,
                                                            fontFamily: AppTheme
                                                                .urbanist,
                                                            fontSize:
                                                                AppTheme.large,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 10,
                                                                  top: 5,
                                                                  bottom: 5),
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .all(
                                                                      Radius.circular(
                                                                          5)),
                                                              color: AppTheme
                                                                  .getStatusColor(
                                                                      list[index]
                                                                          .statusId)),
                                                          child: CText(
                                                            textAlign:
                                                                TextAlign.start,
                                                            text: list[index]
                                                                        .statusId ==
                                                                    2
                                                                ? "Accepted"
                                                                : list[index]
                                                                            .statusId ==
                                                                        3
                                                                    ? "Not Accepted"
                                                                    : taskStatus
                                                                        .firstWhere((item) =>
                                                                            item.id ==
                                                                            list[index].statusId)
                                                                        .text,
                                                            textColor:
                                                                AppTheme.white,
                                                            fontFamily: AppTheme
                                                                .urbanist,
                                                            fontSize:
                                                                AppTheme.small,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    CText(
                                                      textAlign:
                                                          TextAlign.start,
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 10,
                                                              top: 0,
                                                              bottom: 5),
                                                      text: list[index]
                                                              .outletName
                                                              .isEmpty
                                                          ? list[index]
                                                              .entityName
                                                          : "${list[index].entityName} (${list[index].outletName})",
                                                      textColor:
                                                          AppTheme.colorPrimary,
                                                      fontFamily:
                                                          AppTheme.urbanist,
                                                      fontSize: AppTheme.large,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    if (!storeUserData
                                                        .getBoolean(
                                                            IS_AGENT_LOGIN))
                                                      CText(
                                                        textAlign:
                                                            TextAlign.start,
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 10,
                                                                top: 0,
                                                                bottom: 5),
                                                        text: list[index]
                                                                .location
                                                                ?.address ??
                                                            "",
                                                        textColor: AppTheme
                                                            .grayAsparagus,
                                                        fontFamily:
                                                            AppTheme.urbanist,
                                                        fontSize:
                                                            AppTheme.large,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        CText(
                                                          textAlign:
                                                              TextAlign.end,
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5,
                                                                  top: 5),
                                                          text: "Date & Time :",
                                                          textColor: AppTheme
                                                              .grayAsparagus,
                                                          fontFamily:
                                                              AppTheme.urbanist,
                                                          fontSize:
                                                              AppTheme.medium,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        CText(
                                                          textAlign:
                                                              TextAlign.end,
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 20,
                                                                  top: 5),
                                                          text: DateFormat(
                                                                  "dd-MM-yyyy hh:mm:ss aa")
                                                              .format(list[
                                                                      index]
                                                                  .createdOn),
                                                          textColor: AppTheme
                                                              .grayAsparagus,
                                                          fontFamily:
                                                              AppTheme.urbanist,
                                                          fontSize:
                                                              AppTheme.medium,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ],
                                                    ),
                                                    Visibility(
                                                        visible: list[index]
                                                            .notes
                                                            .isNotEmpty,
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            CText(
                                                              textAlign:
                                                                  TextAlign.end,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 5,
                                                                      top: 10),
                                                              text: "Notes :",
                                                              textColor: AppTheme
                                                                  .colorPrimary,
                                                              fontFamily:
                                                                  AppTheme
                                                                      .urbanist,
                                                              fontSize: AppTheme
                                                                  .medium,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            Expanded(
                                                                child: CText(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 20,
                                                                      top: 10),
                                                              text: list[index]
                                                                  .notes,
                                                              textColor: AppTheme
                                                                  .grayAsparagus,
                                                              fontFamily:
                                                                  AppTheme
                                                                      .urbanist,
                                                              fontSize: AppTheme
                                                                  .medium,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            )),
                                                          ],
                                                        )),
                                                  ],
                                                ))),
                                        onTap: () async {
                                          if (storeUserData
                                              .getBoolean(IS_AGENT_LOGIN)) {
                                            Get.to(
                                                transition:
                                                    Transition.rightToLeft,
                                                EntityDetails(
                                                  fromActive:
                                                      tabType == "pending",
                                                  task: list[index],
                                                  entityId: task.entityID!,
                                                  taskId: task.inspectionTaskId,
                                                  statusId: task.statusId,
                                                  inspectionId: 0,
                                                  category: 1,
                                                  isAgentEmployees:
                                                      task.isAgentEmployees,
                                                  completeStatus:
                                                      tabType == "completed",
                                                ))?.then((onValue) {
                                              refreshTask();
                                            });
                                          } else if (tabType == "completed") {
                                            if (list[index]
                                                    .location
                                                    ?.category
                                                    .toString()
                                                    .toLowerCase() ==
                                                "hotel") {
                                              print(
                                                  "EntityDetails completed hotel 1");

                                              Get.to(
                                                  transition:
                                                      Transition.rightToLeft,
                                                  EntityDetails(
                                                    fromActive:
                                                        tabType == "pending",
                                                    task: list[index],
                                                    entityId: task.entityID!,
                                                    taskId:
                                                        task.inspectionTaskId,
                                                    statusId: task.statusId,
                                                    inspectionId: 0,
                                                    category: 1,
                                                    isAgentEmployees:
                                                        task.isAgentEmployees,
                                                    completeStatus:
                                                        tabType == "completed",
                                                  ))?.whenComplete(() {
                                                refreshTask();
                                              });
                                            } else {
                                              getEntityDetail(list[index]);
                                            }
                                          } else if (list[index].statusId !=
                                              3) {
                                            if (list[index].statusId < 7) {
                                              if (list[index]
                                                      .inspectorStatusId ==
                                                  1) {
                                                showRejectRemarkSheet(
                                                    list[index]);
                                              } else {
                                                if (list[index]
                                                        .location
                                                        ?.category
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "hotel") {
                                                  print(
                                                      "EntityDetails hotel 1");
                                                  Get.to(
                                                    () => EntityDetails(
                                                      fromActive:
                                                          tabType == "pending",
                                                      task: list[index],
                                                      entityId: task.entityID!,
                                                      taskId:
                                                          task.inspectionTaskId,
                                                      statusId: task.statusId,
                                                      inspectionId: 0,
                                                      category: 1,
                                                      isAgentEmployees:
                                                          task.isAgentEmployees,
                                                      completeStatus: tabType ==
                                                          "completed",
                                                    ),
                                                    transition:
                                                        Transition.rightToLeft,
                                                  )?.then((onValue) {
                                                    if (!mounted) return;
                                                    if (onValue != null &&
                                                        onValue == true) {
                                                      refreshTask();
                                                    }
                                                  });
                                                } else {
                                                  print(
                                                      "EntityDetails other category  2");
                                                  print(task.inspectionId);
                                                  Get.to(
                                                          transition: Transition
                                                              .rightToLeft,
                                                          EntityDetails(
                                                              fromActive:
                                                                  tabType ==
                                                                      "pending",
                                                              task: task,
                                                              entityId: task
                                                                  .entityID!,
                                                              taskId: task
                                                                  .inspectionTaskId,
                                                              statusId:
                                                                  task.statusId,
                                                              inspectionId: task
                                                                  .inspectionId,
                                                              category: 0,
                                                              isAgentEmployees: task
                                                                  .isAgentEmployees,
                                                              completeStatus:
                                                                  tabType ==
                                                                      "completed"))
                                                      ?.whenComplete(() {
                                                    refreshTask();
                                                  });
                                                }
                                              }
                                            } else {
                                              if (task.statusId == 7) {
                                                if (list[index]
                                                        .location
                                                        ?.category
                                                        .toLowerCase() ==
                                                    "hotel") {
                                                  Get.to(
                                                          transition: Transition
                                                              .rightToLeft,
                                                          InspectionOutletScreen(
                                                              task: task,
                                                              entityId: task
                                                                  .entityID!,
                                                              completeStatus:
                                                                  tabType ==
                                                                      "completed"))
                                                      ?.whenComplete(() {
                                                    refreshTask();
                                                  });
                                                } else {
                                                  getEntityDetail(list[index]);
                                                }
                                              } else {
                                                Get.to(
                                                        transition: Transition
                                                            .rightToLeft,
                                                        EntityDetails(
                                                            fromActive:
                                                                tabType ==
                                                                    "pending",
                                                            task: task,
                                                            entityId:
                                                                task.entityID!,
                                                            taskId: task
                                                                .inspectionTaskId,
                                                            statusId:
                                                                task.statusId,
                                                            inspectionId: task
                                                                .inspectionId,
                                                            category: 0,
                                                            isAgentEmployees: task
                                                                .isAgentEmployees,
                                                            completeStatus:
                                                                tabType ==
                                                                    "completed"))
                                                    ?.whenComplete(() {
                                                  refreshTask();
                                                });
                                              }
                                            }
                                          } else if (list[index].statusId ==
                                              3) {
                                            Get.to(
                                                    transition:
                                                        Transition.rightToLeft,
                                                    EntityDetails(
                                                        fromActive: tabType ==
                                                            "pending",
                                                        task: task,
                                                        entityId:
                                                            task.entityID!,
                                                        taskId: task
                                                            .inspectionTaskId,
                                                        statusId: task.statusId,
                                                        inspectionId:
                                                            task.inspectionId,
                                                        category: 0,
                                                        isAgentEmployees: task
                                                            .isAgentEmployees,
                                                        completeStatus:
                                                            tabType ==
                                                                "completed"))
                                                ?.whenComplete(() {
                                              refreshTask();
                                            });
                                          }
                                        },
                                      );
                                    }),
                                const SizedBox(
                                  height: 20,
                                )
                              ],
                            ),
                          )),
              ],
            )));
  }

  void showRejectRemarkSheet(Tasks task) {
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
                  title: 'Notes :',
                  maxLines: 10,
                  minLines: 5,
                ),
                Container(
                    margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Expanded(
                            child: Container(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              updateTask(task, 2, remark.text);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: AppTheme.colorPrimary,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            child: CText(
                              textAlign: TextAlign.center,
                              text: "Accept",
                              textColor: AppTheme.textPrimary,
                              fontSize: AppTheme.large,
                              fontFamily: AppTheme.urbanist,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                            child: Container(
                          alignment: Alignment.center,
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
                                Navigator.of(context).pop();
                                updateTask(task, 3, remark.text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: AppTheme.red,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            child: CText(
                              textAlign: TextAlign.center,
                              text: "Not Accept",
                              textColor: AppTheme.white,
                              fontSize: AppTheme.large,
                              fontFamily: AppTheme.urbanist,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                      ],
                    )),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
      },
    ).whenComplete(() {});
  }

  Future<void> updateTask(Tasks task, int statusId, String notes) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Department/Task/UpdateInspectionTaskStatus", {
        "inspectionTaskId": task.inspectionTaskId,
        "mainTaskId": task.mainTaskId,
        "statusId": statusId,
        "inspectorId": storeUserData.getInt(USER_ID),
        "notes": notes
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        setState(() {
          _hasFetchedTasks = false;
        });
        refreshTask();
      });
    }
  }

  Future<void> getEntityDetail(Tasks task) async {
    LogPrint().log(jsonEncode(task));
    if (await Utils().hasNetwork(context, setState)) {
      // LoadingIndicatorDialog().show(context);
      if (!mounted) return;
      Api().callAPI(
          context,
          "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${task.mainTaskId}&entityId=${task.entityID}",
          {}).then((value) async {
        // LoadingIndicatorDialog().dismiss();
        setState(() {
          var entity = entityFromJson(value);
          if (entity != null) {
            if (task.statusId == 7 ||
                (tabType == "completed" /*&& task.statusId == 6*/)) {
              Get.to(
                      transition: Transition.rightToLeft,
                      InspectionDetailScreen(
                          task: task,
                          inspectionId: entity.inspectionId!,
                          completeStatus: tabType == "completed"))
                  ?.whenComplete(() {
                refreshTask();
              });
            } else {
              print("EntityDetails 4");
              Get.to(
                      transition: Transition.rightToLeft,
                      EntityDetails(
                          fromActive: tabType == "pending",
                          task: task,
                          entityId: task.entityID!,
                          taskId: task.inspectionTaskId,
                          statusId: task.statusId,
                          inspectionId: task.inspectionId,
                          category: 0,
                          isAgentEmployees: task.isAgentEmployees,
                          completeStatus: tabType == "completed"))
                  ?.whenComplete(() {
                refreshTask();
              });
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
  }

  void showSelectionSheet() {
    setState(() {
      area = null;
      category = null;
    });
    showModalBottomSheet(
        enableDrag: false,
        isDismissible: false,
        context: context,
        backgroundColor: AppTheme.mainBackground,
        isScrollControlled: true,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                  color: AppTheme.mainBackground,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      topLeft: Radius.circular(15))),
              height: currentHeight - 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    children: [
                      Center(
                          child: CText(
                        text: "Search Entity",
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        textColor: AppTheme.black,
                        fontSize: AppTheme.big_20,
                        fontFamily: AppTheme.urbanist,
                        fontWeight: FontWeight.w700,
                      )),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppTheme.black,
                            )),
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 10),
                    child: FormTextField(
                      value: category?.text ?? "",
                      title: 'Select Category',
                      onTap: () {
                        getCategory(setState, category);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: FormTextField(
                      value: area?.text ?? "",
                      title: 'Select Area',
                      onTap: () {
                        getArea(setState);
                        // showAreaPopup();
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, top: 20, bottom: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.to(
                            transition: Transition.rightToLeft,
                            SearchPage(
                              categoryId: category != null
                                  ? category!.id.toString()
                                  : "0",
                              location: area?.text ?? "",
                            ))?.whenComplete(() {
                          refreshTask();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: isFetched
                            ? AppTheme.colorPrimary
                            : AppTheme.paleGray,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: CText(
                        text: "Search",
                        textColor: AppTheme.textPrimary,
                        fontSize: AppTheme.big,
                        fontFamily: AppTheme.poppins,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        }).whenComplete(() {
      setState(() {});
    });
  }

  Future<void> getArea(StateSetter myState) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().getAPI(context, "Mobile/Entity/GetArea").then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          showAreaSheet(data.data, myState, "area");
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

  void showAreaSheet(List<AreaData> data, myState, type) {
    _filteredItems.clear();
    _filteredItems.addAll(data);

    showModalBottomSheet(
      isDismissible: false,
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
            height: currentHeight - 50,
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
                      padding: const EdgeInsets.all(10),
                      textAlign: TextAlign.center,
                      text: "DONE",
                      textColor: AppTheme.black,
                      fontFamily: AppTheme.urbanist,
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
                    controller: _searchArea,
                    onChanged: _filterAreaList,
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
                            fontFamily: AppTheme.urbanist,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.black,
                            fontSize: AppTheme.large)),
                  ),
                ),
                ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: AppTheme.white,
                        margin: const EdgeInsets.only(
                            left: 20, right: 20, bottom: 10),
                        surfaceTintColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              myState(() {
                                if (type == "area") {
                                  area = _filteredItems[index];
                                } else {
                                  category = _filteredItems[index];
                                }
                              });
                            });
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: CText(
                              textAlign: TextAlign.start,
                              padding: const EdgeInsets.only(
                                  right: 10, top: 10, bottom: 10),
                              text: _filteredItems[index].text,
                              textColor: AppTheme.grayAsparagus,
                              fontFamily: AppTheme.urbanist,
                              fontSize: AppTheme.large,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                Utils().sizeBoxHeight()
              ],
            ),
          );
        });
      },
    ).whenComplete(() {
      myState(() {});
    });
  }

  void _filterAreaList(String searchText) {
    _filteredItems.clear();

    if (searchText.isEmpty) {
      _filteredItems.addAll(data);
    } else {
      for (var item in data) {
        if (item.text.toLowerCase().contains(searchText.toLowerCase())) {
          _filteredItems.add(item);
        }
      }
    }
    setState(() {});
  }

  Future<void> getCategory(StateSetter setState, AreaData? area) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().getAPI(context, "Mobile/Entity/GetCategory").then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          showAreaSheet(data.data, setState, "category");
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

  void _filterList(String searchText) {
    if (!storeUserData.getBoolean(IS_AGENT_LOGIN)) {
      list.clear();
      if (searchText.isEmpty) {
        if (tabType == "pending") {
          list.addAll(tasks.where((item) =>
              item.statusId == 1 ||
              item.statusId == 2 ||
              item.statusId == 4 ||
              item.statusId == 5));
        } else {
          list.addAll(tasks.where((item) =>
              item.statusId != 1 &&
              item.statusId != 2 &&
              item.statusId != 4 &&
              item.statusId != 5));
        }
      } else {
        for (var item in tasks) {
          if (item.entityName
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              item.taskName.toLowerCase().contains(searchText.toLowerCase())) {
            if (tabType == "pending" &&
                (item.statusId < 6 || item.statusId != 3)) {
              list.add(item);
            } else {
              if (item.statusId > 5 || item.statusId == 3) {
                list.add(item);
              }
            }
          }
        }
      }
      setState(() {});
    }
  }

  void refreshTask() {
    if (!storeUserData.getBoolean(IS_AGENT_LOGIN)) {
      getTasks();
    } else {
      // Refresh both tabs
      getAgentTasks();
    }
  }
}

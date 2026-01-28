import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:patrol_system/model/place_model.dart';
import 'package:patrol_system/pages/version_two/entity_details.dart';

import '../controls/LoadingIndicatorDialog.dart';
import '../controls/text.dart';
import '../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../utils/api.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

class SearchPage extends StatefulWidget {
  var location = "";
  var categoryId = "";

  SearchPage({super.key, required this.categoryId, required this.location});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Places> list = [];
  List<Places> places = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    getPlaces();
    super.initState();
  }

  Future<void> getPlaces() async {
    print(widget.categoryId);
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api().callAPI(context, "Mobile/Entity/GetEntity", {
        "categoryId": int.parse(widget.categoryId),
        "location": widget.location
      }).then((value) async {
        LoadingIndicatorDialog().dismiss();
        try {
          debugPrint(value.toString().substring(0, 15));
          // value = "LdKiHhGNCz64i3X"

          final encryptAndDecrypt = EncryptAndDecrypt();

          final decryptedData = await encryptAndDecrypt.decryption(
            payload: value,
          );

          if (decryptedData.isEmpty) {
            print("Decryption failed");
            return;
          }

          // print("Decrypted response => $decryptedData");

          // ✅ THEN parse JSON
          // final jsonResponse = jsonDecode(decryptedData);

          debugPrint("response $decryptedData");
          setState(() {
            var data = placesFromJson(decryptedData);
            if (data.data.isNotEmpty) {
              list.addAll(data.data);
              places.addAll(data.data);
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
        } catch (jsonError) {
          print("Error parsing JSON: $jsonError");
        }
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            try {
                              final data = list[index].toJson();
                              final jsonStr = jsonEncode(data);
                              debugPrint("EntityDetails: $jsonStr");
                            } catch (e) {
                              debugPrint(
                                  "EntityDetails: Error encoding JSON → $e");
                            }
                            Get.to(
                                transition: Transition.rightToLeft,
                                EntityDetails(
                                    fromActive: false,
                                    isAgentEmployees: true,
                                    entityId: list[index].entityID!,
                                    statusId: 1,
                                    inspectionId: 0,
                                    completeStatus: false,
                                    // taskType: 0,
                                    category: (widget.categoryId == "1" ||
                                            (list[index]
                                                    .categoryName
                                                    .toLowerCase() ==
                                                "hotel"))
                                        ? 1
                                        : 0));
                          },
                          child: Card(
                            color: AppTheme.white,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 10),
                            surfaceTintColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CText(
                                          textAlign: TextAlign.start,
                                          padding: const EdgeInsets.only(
                                              right: 10, top: 20, bottom: 5),
                                          text: list[index].entityName,
                                          textColor: AppTheme.colorPrimary,
                                          fontFamily: AppTheme.Urbanist,
                                          fontSize: AppTheme.large,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        margin: const EdgeInsets.only(
                                            right: 10, top: 5, bottom: 5),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          color: list[index]
                                                      .status
                                                      .toLowerCase() ==
                                                  "active"
                                              ? AppTheme.active
                                              : list[index]
                                                          .status
                                                          .toLowerCase() ==
                                                      "expired"
                                                  ? AppTheme.expired
                                                  : list[index]
                                                              .status
                                                              .toLowerCase() ==
                                                          "freezed"
                                                      ? AppTheme.freezed
                                                      : list[index]
                                                                  .status
                                                                  .toLowerCase() ==
                                                              "canceled"
                                                          ? AppTheme.cancelled
                                                          : list[index]
                                                                      .status
                                                                      .toLowerCase() ==
                                                                  "Closed"
                                                              ? AppTheme.closed
                                                              : AppTheme
                                                                  .colorPrimary,
                                        ),
                                        child: CText(
                                          textAlign: TextAlign.start,
                                          text: list[index].status,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w600,
                                          textColor: AppTheme.white,
                                          fontFamily: AppTheme.Urbanist,
                                          fontSize: AppTheme.small,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 0, bottom: 5),
                                    text: list[index].location?.address ?? "",
                                    textColor: AppTheme.gray_Asparagus,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 10),
                                    text:
                                        "${list[index].categoryName} ${list[index].classificationName.isNotEmpty ? " - ${list[index].classificationName}" : ""}",
                                    textColor: AppTheme.gray_Asparagus,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 0),
                                    text:
                                        "Monthly Limit : ${list[index].monthlyLimit}",
                                    textColor: AppTheme.gray_Asparagus,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Visibility(
                                      visible:
                                          list[index].lastVisitedDate != null &&
                                              list[index]
                                                  .lastVisitedDate!
                                                  .isNotEmpty,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          CText(
                                            textAlign: TextAlign.end,
                                            padding: const EdgeInsets.only(
                                                right: 5, top: 15),
                                            text: "Last Inspection Visit :",
                                            textColor: AppTheme.colorPrimary,
                                            fontFamily: AppTheme.Urbanist,
                                            fontSize: AppTheme.medium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          CText(
                                            textAlign: TextAlign.end,
                                            padding: const EdgeInsets.only(
                                                right: 20, top: 15),
                                            text: list[index].lastVisitedDate !=
                                                    null
                                                ? DateFormat(
                                                        "dd-MM-yyyy hh:mm:ss aa")
                                                    .format(DateFormat(
                                                            "yyyy-MM-ddTHH:mm:ss.SSS")
                                                        .parse(list[index]
                                                            .lastVisitedDate!))
                                                : "",
                                            textColor: AppTheme.black,
                                            fontFamily: AppTheme.Urbanist,
                                            fontSize: AppTheme.medium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      )),
                                  const SizedBox(
                                    height: 15,
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
                      alignment: Alignment.center,
                      child: CText(
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.only(
                            left: 0, right: 0, top: 35, bottom: 0),
                        text: "Search Results",
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
      list.addAll(places);
    } else {
      for (var item in places) {
        if (item.entityName.toLowerCase().contains(searchText.toLowerCase()) ||
            item.categoryName
                .toLowerCase()
                .contains(searchText.toLowerCase())) {
          list.add(item);
        }
      }
    }
    setState(() {});
  }
}

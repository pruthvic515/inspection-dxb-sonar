import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:patrol_system/model/place_model.dart';
import 'package:patrol_system/pages/version_two/entity_details.dart';

import '../controls/loading_indicator_dialog.dart';
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
    if (!await Utils().hasNetwork(context, setState)) {
      return;
    }

    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    try {
      final value = await Api().callAPI(context, "Mobile/Entity/GetEntity", {
        "categoryId": int.parse(widget.categoryId),
        "location": widget.location
      });

      LoadingIndicatorDialog().dismiss();
      await _processApiResponse(value);
    } catch (error) {
      LoadingIndicatorDialog().dismiss();
      print("Error in getPlaces: $error");
    }
  }

  Future<void> _processApiResponse(String value) async {
    try {

      // final decryptedData = await _decryptResponse(value);
      debugPrint(value);
      if (value.isEmpty) {
        print("Decryption failed");
        return;
      }

      debugPrint("response $value");
      _updatePlacesList(value);
    } catch (jsonError) {
      print("Error parsing JSON: $jsonError");
    }
  }

  Future<String> _decryptResponse(String value) async {
    final encryptAndDecrypt = EncryptAndDecrypt();
    return await encryptAndDecrypt.decryption(payload: value);
  }

  void _updatePlacesList(String decryptedData) {
    setState(() {
      final data = placesFromJson(decryptedData);
      if (data.data.isNotEmpty) {
        list.addAll(data.data);
        places.addAll(data.data);
      } else {
        _showEmptyDataMessage(data.message);
      }
    });
  }

  void _showEmptyDataMessage(String message) {
    if (message.isNotEmpty) {
      Utils().showAlert(
        buildContext: context,
        message: message,
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
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
                _buildSearchField(),
                _buildPlacesList(),
                Utils().sizeBoxHeight(),
              ],
            ),
          ),
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
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
            fontFamily: AppTheme.poppins,
            fontWeight: FontWeight.w400,
            color: AppTheme.black,
            fontSize: AppTheme.large,
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildPlaceCard(index);
      },
    );
  }

  Widget _buildPlaceCard(int index) {
    return GestureDetector(
      onTap: () => _navigateToEntityDetails(index),
      child: Card(
        color: AppTheme.white,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlaceHeader(index),
              _buildPlaceAddress(index),
              _buildPlaceCategory(index),
              _buildPlaceMonthlyLimit(index),
              _buildLastVisitedDate(index),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceHeader(int index) {
    return Row(
      children: [
        Expanded(
          child: CText(
            textAlign: TextAlign.start,
            padding: const EdgeInsets.only(right: 10, top: 20, bottom: 5),
            text: list[index].entityName,
            textColor: AppTheme.colorPrimary,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w700,
          ),
        ),
        _buildStatusBadge(index),
      ],
    );
  }

  Widget _buildStatusBadge(int index) {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: _getStatusColor(list[index].status),
      ),
      child: CText(
        textAlign: TextAlign.start,
        text: list[index].status,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.w600,
        textColor: AppTheme.white,
        fontFamily: AppTheme.urbanist,
        fontSize: AppTheme.small,
        maxLines: 1,
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == "active") return AppTheme.active;
    if (statusLower == "expired") return AppTheme.expired;
    if (statusLower == "freezed") return AppTheme.freezed;
    if (statusLower == "canceled") return AppTheme.cancelled;
    if (statusLower == "closed") return AppTheme.closed;
    return AppTheme.colorPrimary;
  }

  Widget _buildPlaceAddress(int index) {
    return CText(
      textAlign: TextAlign.start,
      padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
      text: list[index].location?.address ?? "",
      textColor: AppTheme.grayAsparagus,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildPlaceCategory(int index) {
    final categoryText = list[index].classificationName.isNotEmpty
        ? "${list[index].categoryName} - ${list[index].classificationName}"
        : list[index].categoryName;

    return CText(
      textAlign: TextAlign.start,
      padding: const EdgeInsets.only(right: 10, top: 10),
      text: categoryText,
      textColor: AppTheme.grayAsparagus,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildPlaceMonthlyLimit(int index) {
    return CText(
      textAlign: TextAlign.start,
      padding: const EdgeInsets.only(right: 10, top: 0),
      text: "Monthly Limit : ${list[index].monthlyLimit}",
      textColor: AppTheme.grayAsparagus,
      fontFamily: AppTheme.urbanist,
      fontSize: AppTheme.large,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildLastVisitedDate(int index) {
    final lastVisitedDate = list[index].lastVisitedDate;
    final hasLastVisitedDate =
        lastVisitedDate != null && lastVisitedDate.isNotEmpty;

    if (!hasLastVisitedDate) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CText(
          textAlign: TextAlign.end,
          padding: const EdgeInsets.only(right: 5, top: 15),
          text: "Last Inspection Visit :",
          textColor: AppTheme.colorPrimary,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.medium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w600,
        ),
        CText(
          textAlign: TextAlign.end,
          padding: const EdgeInsets.only(right: 20, top: 15),
          text: _formatLastVisitedDate(lastVisitedDate),
          textColor: AppTheme.black,
          fontFamily: AppTheme.urbanist,
          fontSize: AppTheme.medium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  String _formatLastVisitedDate(String dateString) {
    try {
      final parsedDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS").parse(dateString);
      return DateFormat("dd-MM-yyyy hh:mm:ss aa").format(parsedDate);
    } catch (e) {
      return "";
    }
  }

  void _navigateToEntityDetails(int index) {
    try {
      final data = list[index].toJson();
      final jsonStr = jsonEncode(data);
      debugPrint("EntityDetails: $jsonStr");
    } catch (e) {
      debugPrint("EntityDetails: Error encoding JSON → $e");
    }

    final category = _calculateCategory(index);
    Get.to(
      transition: Transition.rightToLeft,
      EntityDetails(
        fromActive: false,
        isAgentEmployees: true,
        entityId: list[index].entityID!,
        statusId: 1,
        inspectionId: 0,
        completeStatus: false,
        category: category,
      ),
    );
  }

  int _calculateCategory(int index) {
    final isCategoryOne = widget.categoryId == "1";
    final isHotel = list[index].categoryName.toLowerCase() == "hotel";
    return (isCategoryOne || isHotel) ? 1 : 0;
  }

  Widget _buildHeader() {
    return Container(
      height: 182,
      color: AppTheme.colorPrimary,
      width: double.infinity,
      child: Stack(
        children: [
          _buildBackButton(),
          _buildHeaderTitle(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Get.back();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          top: 50,
          right: 10,
          bottom: 20,
        ),
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
    );
  }

  Widget _buildHeaderTitle() {
    return Align(
      alignment: Alignment.center,
      child: CText(
        textAlign: TextAlign.center,
        padding: const EdgeInsets.only(
          left: 0,
          right: 0,
          top: 35,
          bottom: 0,
        ),
        text: "Search Results",
        textColor: AppTheme.textPrimary,
        fontFamily: AppTheme.urbanist,
        fontSize: AppTheme.big,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.w700,
      ),
    );
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

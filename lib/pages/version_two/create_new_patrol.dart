import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/controls/form_text_field.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/model/known_product_model.dart';
import 'package:patrol_system/model/outlet_model.dart';
import 'package:patrol_system/model/witness_model.dart';
import 'package:patrol_system/pages/version_two/all_attachments_screen.dart';
import 'package:patrol_system/pages/version_two/home_screen.dart';
import 'package:patrol_system/pages/version_two/select_quantity.dart';
import 'package:patrol_system/pages/version_two/sign_representative.dart';
import 'package:patrol_system/utils/api_service_dio.dart';
import 'package:patrol_system/utils/api.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/log_print.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';
import '../../controls/form_mobile_text_field.dart';
import '../../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../../model/all_user_model.dart';
import '../../model/area_model.dart';
import '../../model/entity_detail_model.dart';
import '../../model/inspection_detail_model.dart';
import '../../model/inspection_product_model.dart';
import '../../model/product_category_model.dart';
import '../../model/representative_model.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import '../full_screen_image.dart';
import '../video_player_screen.dart';

class CreateNewPatrol extends StatefulWidget {
  final int entityId;
  final int? taskId;
  final int inspectionId;
  final int statusId;
  final OutletData? outletData;
  final bool newAdded;
  final int mainTaskId;
  final bool primary;
  final bool isAgentEmployees;
  final int taskType;

  const CreateNewPatrol(
      {super.key,
      required this.entityId,
      this.taskId,
      required this.statusId,
      required this.inspectionId,
      this.outletData,
      required this.mainTaskId,
      required this.newAdded,
      required this.isAgentEmployees,
      required this.primary,
      required this.taskType});

  @override
  State<CreateNewPatrol> createState() => _CreateNewPatrolState();
}

class _CreateNewPatrolState extends State<CreateNewPatrol> {
  var inspectionId = 0;
  var inspectorId = 0;
  int? taskId;
  late int statusId;
  var storeUserData = StoreUserData();

  ///tab
  var tabType = 1;
  var productTab = 3;
  InspectionData? detail;

  /// attachment
  // List<AttachmentData> attachmentList = [];
  String? attachedThumbnail = "";

  String attachedLink = "";
  String attachedProduct = "";
  String imageAttach = "";

  List<String> image = [];

  ///outlet
  OutletData? outletModel;

  ///witness & representatives
  List<RepresentativeData> managerList = [];
  List<RepresentativeData> witnessList = [];
  List<WitnessData> selectedAEList = [];
  List<WitnessData> selectedMMIList = [];
  List<String> aeNameList = [];
  List<String> mmiNameList = [];
  List<AreaData?> roleList = [];
  List<AllUserData> selectedInspectors = [];
  List<String> inspectorNameList = [];
  var isAE = false;
  var isMMI = false;
  AreaData? role;

  ///controllers
  final _outlets = TextEditingController();
  final _searchKnownProduct = TextEditingController();
  final _searchSize = TextEditingController();
  final initialNotes = TextEditingController();
  final concludeNotes = TextEditingController();
  FocusNode concludeFocusNode = FocusNode();

  ///sizes
  var currentHeight = 0.0;
  var currentWidth = 0.0;

  ///location
  var latitude = -99.99;
  var longitude = -99.99;
  var googleAddress = "";
  AreaData? type;
  AreaData? category;

  ///product
  List<ProductCategoryData> productCategoryList = [];
  List<KnownProductData> knownProductList = [];
  List<ProductDetail> selectedKnownProductListData = [];
  List<ProductDetail> foreignLabelsList = [];
  List<ProductDetail> unknownProductList = [];
  List<AreaData> sizeList = [];
  List<AreaData> searchSizeList = [];
  final productName = TextEditingController();
  var quantity = 0;
  final notes = TextEditingController();
  var focusNode = FocusNode();
  EntityDetailModel? entity;
  Timer? timer;
  List<Map<String, dynamic>> reasonList = [];
  final encryptAndDecrypt = EncryptAndDecrypt();

  @override
  void dispose() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState(); // always call super first
    taskId = widget.taskId;
    statusId = widget.statusId;
    inspectionId = widget.inspectionId;
    outletModel = widget.outletData;
    if (statusId == 5) {
      tabType = 2;
      debugPrint("Type $tabType");
      debugPrint("statusId $statusId");
      getInspectionDetail(); // async method
    } else {
      tabType = 1;
    }

    if (outletModel != null) {
      _outlets.text = outletModel!.outletName;
    }

    getEntityDetail();
    getGeoLocationPosition();
    getKnownProductCategories();
    getLiquorSize();
    getEntityRole();
    getReasonListing();
  }

  Future<void> getEntityDetail() async {
    final encryptedMainTaskId = await encryptAndDecrypt.encryption(
      payload: widget.mainTaskId.toString(),
      urlEncode: false,
    );
    final encryptedEntityId = await encryptAndDecrypt.encryption(
      payload: widget.entityId.toString(),
      urlEncode: false,
    );

    debugPrint(
        "Original value ${widget.mainTaskId} encrypted value :- $encryptedMainTaskId");
    debugPrint(
        "Original value ${widget.entityId} encrypted value :- $encryptedEntityId");

    if (!mounted) return;
    Api()
        .callAPI(
            context,
            "Mobile/Entity/GetEntityInspectionDetails?mainTaskId=${Uri.encodeComponent(encryptedMainTaskId)}&entityId=${Uri.encodeComponent(encryptedEntityId)}",
            null)
        .then((value) async {
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

  Future<void> getInspectionDetail() async {
    if (!await Utils().hasNetwork(context, setState)) {
      return;
    }

    _clearInspectionData();
    if (!mounted) return;

    LoadingIndicatorDialog().show(context);
    await _fetchInspectionDetails();
  }

  void _clearInspectionData() {
    setState(() {
      isAE = false;
      isMMI = false;
      selectedKnownProductListData.clear();
      foreignLabelsList.clear();
      unknownProductList.clear();
      managerList.clear();
      witnessList.clear();
      selectedAEList.clear();
      selectedMMIList.clear();
    });
  }

  Future<void> _fetchInspectionDetails() async {
    try {
      final value = await Api().callAPI(
        context,
        "Mobile/Inspection/GetInspectionDetails",
        {"mainTaskId": widget.mainTaskId, "inspectionId": inspectionId},
      );

      final data = detailFromJson(value);
      if (data.data != null) {
        _processInspectionData(data.data!);
      } else {
        _handleInspectionError(data.message);
      }
    } catch (e) {
      LoadingIndicatorDialog().dismiss();
      debugPrint("Error fetching inspection details: $e");
    }
  }

  void _processInspectionData(InspectionData inspectionData) {
    setState(() {
      detail = inspectionData;
      taskId = inspectionData.inspectionDetails.taskId;
      debugPrint("GetInspectionDetails processed");
    });

    setState(() {
      _processAttachments(inspectionData.attachments);
      _processProductDetails(inspectionData.productDetailModels);
      _processEntityRepresentatives(inspectionData.entityRepresentatives);
      _processAgentEmployees(
        inspectionData.inspectorAndAgentEmployee.agentEmployeeModels,
      );
      _updateFlagsAndNotes(inspectionData.notes.finalNotes);
      LoadingIndicatorDialog().dismiss();
    });
  }

  void _processAttachments(List<dynamic> attachments) {
    try {
      image.clear();
      for (var file in attachments) {
        image.add(file.documentUrl);
      }
    } catch (e) {
      image.clear();
    }
  }

  void _processProductDetails(List<ProductDetail> productDetails) {
    for (var product in productDetails) {
      if (product.typeId == 1) {
        selectedKnownProductListData.add(product);
      } else if (product.typeId == 2) {
        foreignLabelsList.add(product);
      } else if (product.typeId == 3) {
        unknownProductList.add(product);
      }
    }
  }

  void _processEntityRepresentatives(List<RepresentativeData> representatives) {
    for (var representative in representatives) {
      if (representative.typeId == 1) {
        managerList.add(representative);
      } else if (representative.typeId == 2) {
        witnessList.add(representative);
      }
    }
  }

  void _processAgentEmployees(List<WitnessData> agentEmployees) {
    for (var employee in agentEmployees) {
      if (employee.agentId == 1) {
        selectedAEList.add(employee);
      } else if (employee.agentId == 2) {
        selectedMMIList.add(employee);
      }
    }
  }

  void _updateFlagsAndNotes(String? finalNotes) {
    isAE = selectedAEList.isNotEmpty;
    isMMI = selectedMMIList.isNotEmpty;
    concludeNotes.text = finalNotes ?? "";
  }

  void _handleInspectionError(String message) {
    LoadingIndicatorDialog().dismiss();
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

  void getAttachedThumbnail() {
    _getStorageDirectory().then((directory) async {
      await _generateThumbnail(directory);
    });
  }

  Future<Directory> _getStorageDirectory() {
    if (Platform.isAndroid) {
      return getExternalStorageDirectory().then((value) => value!);
    } else {
      return getApplicationDocumentsDirectory();
    }
  }

  Future<void> _generateThumbnail(Directory directory) async {
    try {
      final thumbnail = await FlutterVideoThumbnailPlus.thumbnailFile(
        video: attachedLink,
        thumbnailPath: directory.absolute.path,
        imageFormat: ImageFormat.png,
        quality: 100,
      );
      _updateThumbnail(thumbnail);
    } on Exception catch (e) {
      _handleThumbnailError(e);
    }
  }

  void _updateThumbnail(String? thumbnail) {
    setState(() {
      attachedThumbnail = thumbnail ?? "";
    });

    if (thumbnail != null) {
      LogPrint().log("thumbnail path: $thumbnail");
    } else {
      LogPrint().log("return thumbnail path: 1");
    }
  }

  void _handleThumbnailError(Exception error) {
    setState(() {
      attachedThumbnail = "";
    });
    LogPrint().log(error);
    LogPrint().log("return thumbnail path: catch");
  }

  Future<void> getEntityRole() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api().getAPI(context, "Mobile/Entity/GetEntityRole").then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            roleList.clear();
            roleList.addAll(data.data);
          });
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

  Future<void> getLiquorSize() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api()
          .getAPI(context, "Mobile/ProduectDetail/GetLiquorSizeEnum")
          .then((value) async {
        var data = areaFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            searchSizeList.clear();
            searchSizeList.addAll(data.data);
            sizeList.clear();
            sizeList.addAll(data.data);
          });
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

  Future<void> getKnownProductCategories() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api()
          .getAPI(context, "Mobile/ProduectDetail/GetProductCategory")
          .then((value) async {
        var data = productCategoryFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            productCategoryList.clear();
            productCategoryList.addAll(data.data);
          });
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

  void getAllKnownProducts(StateSetter myState) {
    knownProductList.clear();
    Api().callAPI(context, "Mobile/ProduectDetail/GetAllProduct", {
      "name": _searchKnownProduct.text.toString(),
      "categoryId": 0
    }).then((value) async {
      if (value == null) return;
      await _processKnownProductsResponse(value, myState);
    });
  }

  Future<void> _processKnownProductsResponse(
      dynamic value, StateSetter myState) async {
    debugPrint("ProduectDetail $value");
    final parsed = value is String ? jsonDecode(value) : value;

    if (!_hasValidProductData(parsed)) {
      return;
    }

    final KnownProductModel data = await parseKnownProducts(value);
    if (data.data.isNotEmpty) {
      _updateKnownProductList(data.data, myState);
    } else {
      _handleEmptyProductData(data);
    }
  }

  bool _hasValidProductData(dynamic parsed) {
    return parsed != null &&
        parsed["data"] != null &&
        parsed["data"]["result"] != null;
  }

  void _updateKnownProductList(
      List<KnownProductData> products, StateSetter myState) {
    myState(() {
      knownProductList.clear();
      knownProductList.addAll(products);
    });
  }

  void _handleEmptyProductData(KnownProductModel data) {
    if (data.message != null && data.message!.isNotEmpty) {
      if (!mounted) return;
      Utils().showAlert(
        buildContext: context,
        message: data.message.toString(),
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  Future<void> _processSearchProductsResponse(
      dynamic value, StateSetter myState) async {
    final result = value is String ? jsonDecode(value) : value;
    if (result == null ||
        result["data"] == null ||
        result["data"]["result"] == null) {
      return;
    }

    final KnownProductModel data = await parseKnownProducts(value);
    if (!mounted) return;

    if (data.data.isNotEmpty) {
      _updateKnownProductList(data.data, myState);
    } else {
      _handleSearchEmptyProductData(data, myState);
    }
  }

  void _handleSearchEmptyProductData(
      KnownProductModel data, StateSetter myState) {
    if (data.data.isEmpty && data.message == null) {
      myState(() {
        knownProductList.clear();
      });
    } else if (data.message != null && data.message!.isNotEmpty) {
      if (!mounted) return;
      Utils().showAlert(
        buildContext: context,
        message: data.message.toString(),
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  void getSearchAllKnownProducts(StateSetter myState) {
    knownProductList.clear();
    if (_searchKnownProduct.text.isEmpty) {
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      Api().callAPI(context, "Mobile/ProduectDetail/GetAllProduct", {
        "name": _searchKnownProduct.text.toString(),
        "categoryId": 0
      }).then((value) async {
        if (value == null) return;
        await _processSearchProductsResponse(value, myState);
      });
    }
  }

  Future getGeoLocationPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _handleLocationServiceDisabled();
      return;
    }

    final permission = await _checkAndRequestPermission();
    if (!_hasLocationPermission(permission)) {
      _handlePermissionDenied();
      return;
    }

    await _fetchLocationAndAddress();
  }

  void _handleLocationServiceDisabled() {
    if (!mounted) return;
    Utils().showAlert(
      buildContext: context,
      message: "Location services are disabled.",
      onPressed: () {
        Navigator.of(context).pop();
        Geolocator.openLocationSettings().whenComplete(() {
          getGeoLocationPosition();
        });
      },
    );
  }

  Future<LocationPermission> _checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void _handlePermissionDenied() {
    if (!mounted) return;
    Utils().showAlert(
      buildContext: context,
      message: "Location permissions are denied.",
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _fetchLocationAndAddress() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updateLocation(position);
      await _fetchAddressFromCoordinates(position);
    } catch (e) {
      LogPrint().log("Error getting location: $e");
    }
  }

  void _updateLocation(Position position) {
    latitude = position.latitude;
    longitude = position.longitude;
  }

  Future<void> _fetchAddressFromCoordinates(Position position) async {
    try {
      final placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      LogPrint().log(placeMarks);
      final place = placeMarks[0];
      _updateAddress(place);
    } on TimeoutException catch (_) {
      LogPrint().log("The request timed out.");
    } catch (e) {
      _setDefaultAddress();
      LogPrint().log("An error occurred: $e");
    }
    LogPrint().log("address$googleAddress");
  }

  void _updateAddress(Placemark place) {
    if (!mounted) return;
    setState(() {
      googleAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    });
  }

  void _setDefaultAddress() {
    setState(() {
      googleAddress = "Bur Dubai";
    });
  }

  @override
  Widget build(BuildContext context) {
    currentWidth = MediaQuery.of(context).size.width;
    currentHeight = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.back(result: {
            "statusId": statusId,
            "inspectionId": inspectionId,
            "taskId": taskId,
            "inspectorId": inspectorId
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildNavigationButtons(),
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      color: AppTheme.colorPrimary,
      width: double.infinity,
      child: Stack(
        children: [
          _buildBackButton(),
          _buildTitle(),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Get.back(result: {
          "statusId": statusId,
          "inspectionId": inspectionId,
          "taskId": taskId
        });
      },
      child: Padding(
        padding:
            const EdgeInsets.only(left: 10, top: 50, right: 10, bottom: 20),
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
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

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.topCenter,
      child: CText(
        textAlign: TextAlign.center,
        padding: const EdgeInsets.only(left: 60, right: 60, top: 60),
        text: "Add a new Inspection Visit",
        textColor: AppTheme.textPrimary,
        fontFamily: AppTheme.urbanist,
        fontSize: AppTheme.big,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin:
          const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10, top: 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepItem(1, "Details"),
          _buildStepDivider(),
          _buildStepItem(2, "Products \nInspections"),
          _buildStepDivider(),
          _buildStepItem(3, "Attachments"),
          _buildStepDivider(),
          _buildStepItem(4, "Witness & \nRepresentative"),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String label) {
    final isActive = tabType >= stepNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          height: 25,
          width: 25,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.lightBlueTwo : AppTheme.white,
            shape: BoxShape.circle,
          ),
          child: CText(
            text: "$stepNumber",
            textColor: AppTheme.colorPrimary,
            fontFamily: AppTheme.urbanist,
            fontSize: AppTheme.large,
          ),
        ),
        const SizedBox(height: 5),
        CText(
          text: label,
          fontFamily: AppTheme.urbanist,
          textAlign: TextAlign.center,
          textColor: AppTheme.textPrimary,
          fontSize: AppTheme.small,
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        color: AppTheme.white,
        height: 1,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPreviousButton(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPreviousButton() {
    return Visibility(
      visible: tabType > 2,
      child: GestureDetector(
        onTap: _handlePreviousTap,
        behavior: HitTestBehavior.translucent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.arrow_back,
              size: 18,
              color: AppTheme.colorPrimary,
            ),
            CText(
              textAlign: TextAlign.center,
              text: "Previous",
              textColor: AppTheme.colorPrimary,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePreviousTap() {
    if (tabType > 1) {
      setState(() {
        tabType--;
      });
    }
  }

  Widget _buildNextButton() {
    return Visibility(
      visible: tabType != 4 && inspectionId != 0,
      child: GestureDetector(
        onTap: _handleNextTap,
        behavior: HitTestBehavior.translucent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CText(
              textAlign: TextAlign.center,
              text: _getNextButtonText(),
              textColor: _getNextButtonColor(),
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.w700,
            ),
            Icon(
              _getNextButtonIcon(),
              size: 18,
              color: _getNextButtonColor(),
            )
          ],
        ),
      ),
    );
  }

  String _getNextButtonText() {
    return tabType == 4 ? "Close Task" : "Next";
  }

  Color _getNextButtonColor() {
    return validateNext() ? AppTheme.colorPrimary : AppTheme.grey;
  }

  IconData _getNextButtonIcon() {
    return tabType == 4 ? Icons.close : Icons.arrow_forward;
  }

  void _handleNextTap() {
    if (!validateNext()) return;

    if (tabType == 3 && image.isEmpty) {
      _showImageRequiredAlert();
      return;
    }

    if (tabType < 4) {
      setState(() {
        tabType++;
      });
    }
  }

  void _showImageRequiredAlert() {
    Utils().showAlert(
      buildContext: context,
      title: "Alert",
      message: "Please attach at least one image.",
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildTabContent() {
    if (tabType == 1) return tabOneUI();
    if (tabType == 2) return tabTwoUI();
    if (tabType == 3) return tabThreeUI();
    if (tabType == 4) return tabFourUI();
    return Container();
  }

  ///tab two
  Widget tabTwoUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorPrimary),
              onPressed: () {
                if (productTab == 1) {
                  showKnownProductSheet();
                } else if (productTab == 2) {
                  showAddProductSheet(null);
                } else if (productTab == 3) {
                  showAddProductSheet(null);
                }
              },
              child: CText(
                text: "Add Product",
                textColor: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          getProductUI()
        ],
      ),
    );
  }

  Widget getProductUI() {
    if (productTab == 1) {
      return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedKnownProductListData.length,
          itemBuilder: (context, index) {
            List<String> serialNumber = [];
            for (var element
                in selectedKnownProductListData[index].products) {
              serialNumber.add(element.serialNumber);
            }
            return Card(
              color: AppTheme.white,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              surfaceTintColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CText(
                          textAlign: TextAlign.start,
                          padding: const EdgeInsets.only(
                              right: 10, top: 5, bottom: 5),
                          text: productCategoryList
                              .firstWhere((element) =>
                                  element.productCategoryId ==
                                  selectedKnownProductListData[index]
                                      .categoryId)
                              .name,
                          textColor: AppTheme.colorPrimary,
                          fontFamily: AppTheme.urbanist,
                          fontSize: AppTheme.large,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w700,
                        ),
                        IconButton(
                            onPressed: () {
                              requestCameraPermissions(
                                  "image",
                                  selectedKnownProductListData[index]
                                      .productDetailsId,
                                  1,
                                  setState);
                              /*   openImageVideoOption(
                                  selectedKnownProductListData[index]
                                      .productDetailsId);*/
                            },
                            icon: const Icon(Icons.attach_file))
                      ],
                    ),
                    CText(
                      textAlign: TextAlign.start,
                      padding:
                          const EdgeInsets.only(right: 10, top: 0, bottom: 5),
                      text: selectedKnownProductListData[index].productName,
                      textColor: AppTheme.grayAsparagus,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.large,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w600,
                    ),
                    CText(
                      textAlign: TextAlign.start,
                      padding: const EdgeInsets.only(right: 10, top: 0),
                      text:
                          "Quantity : ${selectedKnownProductListData[index].qty}",
                      textColor: AppTheme.grayAsparagus,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.large,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w600,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CText(
                            textAlign: TextAlign.start,
                            padding: const EdgeInsets.only(
                                right: 10, top: 0, bottom: 5),
                            text: "Product Code : ${serialNumber.join(", ")}",
                            textColor: AppTheme.grayAsparagus,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.large,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showQuantitySheet(
                                selectedKnownProductListData[index],
                                true,
                                index);
                          },
                          behavior: HitTestBehavior.translucent,
                          child: CText(
                            textAlign: TextAlign.start,
                            padding: const EdgeInsets.only(
                                right: 10, top: 5, bottom: 5),
                            text: "EDIT",
                            textColor: AppTheme.colorPrimary,
                            fontFamily: AppTheme.urbanist,
                            fontSize: AppTheme.large,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 10),
                          width: 0.5,
                          height: AppTheme.big_20,
                          color: AppTheme.grey,
                        ),
                        IconButton(
                            onPressed: () {
                              Utils().showYesNoAlert(
                                  context: context,
                                  message:
                                      "Are you sure you want to delete the product?",
                                  onYesPressed: () {
                                    Navigator.of(context).pop();
                                    deleteProduct(
                                        selectedKnownProductListData[index]
                                            .productDetailsId);
                                  },
                                  onNoPressed: () {
                                    Navigator.of(context).pop();
                                  });
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.red,
                              size: 20,
                            ))
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
    } else if (productTab == 2) {
      return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: foreignLabelsList.length,
          itemBuilder: (context, index) {
            return getProductList(foreignLabelsList, index);
          });
    } else if (productTab == 3) {
      return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: unknownProductList.length,
          itemBuilder: (context, index) {
            return getProductList(unknownProductList, index);
          });
    } else {
      return Container();
    }
  }

  Future<void> updateProduct(Map<String, dynamic> fields) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .callAPI(context, "Mobile/ProduectDetail/Update", fields)
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        LogPrint().log("response : $value");
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          getInspectionDetail();
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

  Future<void> addProduct(Map<String, dynamic> fields) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .callAPI(context, "Mobile/ProduectDetail/Create", fields)
          .then((value) async {
        if (!mounted) return;
        LoadingIndicatorDialog().dismiss();
        LogPrint().log("response : $value");
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          if (data["data"] == false) {
            Utils().showAlert(
                buildContext: context,
                message: data["message"],
                onPressed: () {
                  Navigator.of(context).pop();
                });
          } else {
            getInspectionDetail();
          }
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

  Future<void> deleteProduct(int productId) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context,
              "Mobile/ProduectDetail/Delete?productDetailsId=$productId")
          .then((value) async {
        if (!mounted) return;
        LoadingIndicatorDialog().dismiss();
        LogPrint().log("response : $value");
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          getInspectionDetail();
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

  Widget getProductList(List<ProductDetail> list, int index) {
    List<String> serialNumber = [];
    List<String> sizes = [];
    for (var element in list[index].products) {
      serialNumber.add(element.serialNumber);
    }
    for (var element in list[index].products) {
      var data =
          searchSizeList.firstWhereOrNull(((size) => size.id == element.size));
      if (data != null) {
        sizes.add(data.text);
      }
    }
    return Card(
      color: AppTheme.white,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      surfaceTintColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                flex: 1,
                child: CText(
                  textAlign: TextAlign.start,
                  padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                  text: list[index].productName,
                  textColor: AppTheme.colorPrimary,
                  fontFamily: AppTheme.urbanist,
                  fontSize: AppTheme.large,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                  onPressed: () {
                    requestCameraPermissions(
                        "image", list[index].productDetailsId, 1, setState);
                    //  openImageVideoOption(list[index].productDetailsId);
                  },
                  icon: const Icon(Icons.attach_file))
            ]),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
              text: "Quantity : ${list[index].qty}",
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Product Code : ${serialNumber.join(",")}",
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            Row(
              children: [
                Expanded(
                    child: CText(
                  textAlign: TextAlign.start,
                  padding: const EdgeInsets.only(right: 10, bottom: 5),
                  text: "Size : ${sizes.join(", ")}",
                  textColor: AppTheme.grayAsparagus,
                  fontFamily: AppTheme.urbanist,
                  fontSize: AppTheme.large,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                )),
                GestureDetector(
                  onTap: () {
                    showAddProductSheet(list[index]);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: CText(
                    textAlign: TextAlign.start,
                    padding:
                        const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                    text: "EDIT",
                    textColor: AppTheme.colorPrimary,
                    fontFamily: AppTheme.urbanist,
                    fontSize: AppTheme.large,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  width: 0.5,
                  height: AppTheme.big_20,
                  color: AppTheme.grey,
                ),
                IconButton(
                    onPressed: () {
                      Utils().showYesNoAlert(
                          context: context,
                          message:
                              "Are you sure you want to delete the product?",
                          onYesPressed: () {
                            Navigator.of(context).pop();
                            deleteProduct(list[index].productDetailsId);
                          },
                          onNoPressed: () {
                            Navigator.of(context).pop();
                          });
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.red,
                      size: 20,
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToFocusedField(
      FocusNode focusNode, ScrollController scrollController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          focusNode.context!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final offset = scrollController.offset + position.dy - 100;
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void showAddProductSheet(ProductDetail? model) {
    final scrollController = ScrollController();
    final serial = <TextEditingController>[];
    final sizeList = <AreaData?>[];
    final focusNodeList = <FocusNode>[];
    final node = FocusNode();

    _initializeProductSheet(model, serial, sizeList, focusNodeList);
    _setupFocusListeners(focusNodeList, scrollController);
    showModalBottomSheet(
      enableDrag: false,
      isDismissible: false,
      context: context,
      backgroundColor: AppTheme.mainBackground,
      isScrollControlled: true,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _buildProductSheetContent(
              model,
              serial,
              sizeList,
              focusNodeList,
              node,
              scrollController,
              setState,
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        productName.text = "";
        quantity = 0;
        notes.text = "";
      });
    });
  }

  Widget _buildProductSheetContent(
    ProductDetail? model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    FocusNode node,
    ScrollController scrollController,
    StateSetter setState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppTheme.mainBackground,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(15),
          topLeft: Radius.circular(15),
        ),
      ),
      height: currentHeight - 50,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _buildProductSheetHeader(context),
            _buildProductNameField(setState),
            const SizedBox(height: 5),
            _buildQuantityField(serial, sizeList, focusNodeList, setState),
            const SizedBox(height: 5),
            _buildSerialNumberList(
              serial,
              sizeList,
              focusNodeList,
              node,
              setState,
            ),
            const SizedBox(height: 5),
            _buildNotesField(serial, sizeList),
            const SizedBox(height: 10),
            _buildSaveButton(
              model,
              serial,
              sizeList,
              node,
              setState,
            ),
            Utils().sizeBoxHeight(height: 250),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSheetHeader(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: CText(
            text: "Add Product",
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            textColor: AppTheme.black,
            fontSize: AppTheme.big_20,
            fontFamily: AppTheme.urbanist,
            fontWeight: FontWeight.w700,
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppTheme.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductNameField(StateSetter setState) {
    return Stack(
      children: [
        FormTextField(
          onChange: (value) {
            if (productName.text.length > 3 && focusNode.hasFocus) {
              _searchKnownProduct.text = productName.text;
              getAllKnownProducts(setState);
            }
            setState(() {});
          },
          focusNode: focusNode,
          controller: productName,
          hint: "",
          value: productName.text,
          title: 'Product Name :',
          inputBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          textColor: AppTheme.grayAsparagus,
          inputType: TextInputType.text,
        ),
        Positioned(
          top: 0,
          right: 10,
          child: GestureDetector(
            onTap: () => _handleProductSearchTap(setState),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.transparent, width: 0),
                  left: BorderSide(color: Colors.transparent, width: 0),
                  right: BorderSide(color: Colors.transparent, width: 0),
                  bottom: BorderSide(color: AppTheme.colorPrimary, width: 2),
                ),
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: CText(
                text: "Search",
                fontSize: AppTheme.large,
                textColor: AppTheme.colorPrimary,
                fontFamily: AppTheme.poppins,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleProductSearchTap(StateSetter setState) {
    setState(() {
      knownProductList.clear();
      _searchKnownProduct.text = productName.text;
      if (_searchKnownProduct.text.isNotEmpty) {
        getSearchAllKnownProducts(setState);
      }
      showKnownProductSheet();
    });
  }

  Widget _buildQuantityField(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    StateSetter setState,
  ) {
    return FormTextField(
      hint: "",
      value: quantity.toString(),
      title: 'Quantity :',
      inputBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      textColor: AppTheme.grayAsparagus,
      onTap: () {
        Get.to(const SelectQuantity())?.then((value) {
          if (value != null) {
            _handleQuantityChange(
              value,
              serial,
              sizeList,
              focusNodeList,
              setState,
            );
          }
        });
      },
    );
  }

  Widget _buildSerialNumberList(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    FocusNode node,
    StateSetter setState,
  ) {
    if (serial.isEmpty) return Container();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: serial.length,
      itemBuilder: (context, index) {
        return _buildSerialNumberItem(
          index,
          serial,
          sizeList,
          focusNodeList,
          node,
          setState,
        );
      },
    );
  }

  Widget _buildSerialNumberItem(
    int index,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    FocusNode node,
    StateSetter setState,
  ) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FormTextField(
                onChange: (value) {
                  setState(() {
                    focusNodeList[index].requestFocus();
                    LogPrint().log("on changes value : $value");
                  });
                },
                controller: serial[index],
                focusNode: focusNodeList[index],
                hint: "",
                title: "Product code - ${index + 1}:",
                inputBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                textColor: AppTheme.grayAsparagus,
                inputType: TextInputType.text,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: FormTextField(
                onChange: (value) => setState(() {}),
                hint: "",
                value: sizeList[index]?.text ?? "",
                title: "Size - ${index + 1} :",
                inputBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                textColor: AppTheme.grayAsparagus,
                onTap: () => showSizeSheet(node, sizeList, index, setState),
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            onPressed: () => _handleDeleteSerial(
              index,
              serial,
              sizeList,
              focusNodeList,
              setState,
            ),
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.red,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _handleDeleteSerial(
    int index,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    StateSetter setState,
  ) {
    Utils().showYesNoAlert(
      context: context,
      message: "Are you sure delete this serial number?",
      onNoPressed: () => Navigator.of(context).pop(),
      onYesPressed: () {
        Navigator.of(context).pop();
        setState(() {
          serial.removeAt(index);
          focusNodeList.removeAt(index);
          sizeList.removeAt(index);
          quantity = serial.length;
        });
      },
    );
  }

  Widget _buildNotesField(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
  ) {
    return Visibility(
      visible: _isFormValid(serial, sizeList),
      child: FormTextField(
        onChange: (value) {},
        hint: "",
        controller: notes,
        textColor: AppTheme.grayAsparagus,
        fontFamily: AppTheme.urbanist,
        title: 'Notes',
        maxLines: 3,
        minLines: 1,
      ),
    );
  }

  Widget _buildSaveButton(
    ProductDetail? model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    FocusNode node,
    StateSetter setState,
  ) {
    return Center(
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: ElevatedButton(
          focusNode: node,
          onPressed: () => _handleSaveProduct(
            model,
            serial,
            sizeList,
            setState,
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: _isFormValid(serial, sizeList)
                ? AppTheme.colorPrimary
                : AppTheme.paleGray,
            minimumSize: const Size.fromHeight(50),
          ),
          child: CText(
            text: "SAVE",
            textColor: AppTheme.textPrimary,
            fontSize: AppTheme.large,
            fontFamily: AppTheme.urbanist,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _handleSaveProduct(
    ProductDetail? model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    StateSetter setState,
  ) {
    final errorMessage = _validateProductForm(serial, sizeList);
    if (errorMessage != null) {
      Utils().showAlert(
        buildContext: context,
        message: errorMessage,
        onPressed: () => Navigator.of(context).pop(),
      );
    } else {
      _saveProduct(model, serial, sizeList, setState, context);
    }
  }

  void _initializeProductSheet(
    ProductDetail? model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    if (model != null) {
      setState(() {
        if (model.qty > 0) {
          _initializeFromModel(model, serial, sizeList, focusNodeList);
        } else {
          _initializeEmptyModel(model, serial, sizeList, focusNodeList);
        }
      });
    } else {
      _initializeNewProduct(serial, sizeList, focusNodeList);
    }
  }

  void _initializeFromModel(
    ProductDetail model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    productName.text = model.productName.toString();
    quantity = model.qty;
    notes.text = model.notes.toString();
    if (model.products.isNotEmpty) {
      for (var element in model.products) {
        serial.add(TextEditingController(text: element.serialNumber));
        focusNodeList.add(FocusNode());
        sizeList.add(_findSizeData(element.size!));
      }
    }
  }

  AreaData _findSizeData(int sizeId) {
    return searchSizeList.firstWhere((test) => test.id == sizeId);
  }

  void _initializeEmptyModel(
    ProductDetail model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    model.qty = 1;
    model.products = [];
    serial.add(TextEditingController(text: ""));
    focusNodeList.add(FocusNode());
    sizeList.add(null);
  }

  void _initializeNewProduct(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    quantity = 1;
    serial.add(TextEditingController(text: ""));
    focusNodeList.add(FocusNode());
    sizeList.add(null);
  }

  void _setupFocusListeners(
    List<FocusNode> focusNodeList,
    ScrollController scrollController,
  ) {
    for (var node in focusNodeList) {
      node.addListener(() {
        if (node.hasFocus) {
          _scrollToFocusedField(node, scrollController);
        }
      });
    }
  }

  void _handleQuantityChange(
    int newQuantity,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
    StateSetter setState,
  ) {
    setState(() {
      quantity = newQuantity;
      if (quantity > serial.length) {
        _addSerialItems(serial, sizeList, focusNodeList);
      } else if (quantity < serial.length) {
        _removeSerialItems(serial, sizeList, focusNodeList);
      }
    });
  }

  void _addSerialItems(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    for (int i = serial.length; i < quantity; i++) {
      serial.add(TextEditingController());
      focusNodeList.add(FocusNode());
      sizeList.add(sizeList.isNotEmpty ? sizeList[0] : null);
    }
  }

  void _removeSerialItems(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    List<FocusNode> focusNodeList,
  ) {
    serial.removeRange(quantity, serial.length);
    focusNodeList.removeRange(quantity, focusNodeList.length);
    sizeList.removeRange(quantity, sizeList.length);
  }

  String? _validateProductForm(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
  ) {
    if (productName.text.isEmpty) {
      return "Please enter product name";
    }
    if (quantity == 0) {
      return "Please select quantity";
    }
    if (_hasInvalidSerialNumbers(serial)) {
      return "Please enter valid serial number";
    }
    if (_hasMissingSizes(sizeList)) {
      return "Please select size";
    }
    return null;
  }

  bool _hasInvalidSerialNumbers(List<TextEditingController> serial) {
    return serial
        .any((element) => element.text.isEmpty || element.text.length < 5);
  }

  bool _hasMissingSizes(List<AreaData?> sizeList) {
    return sizeList.any((element) => element == null);
  }

  void _saveProduct(
    ProductDetail? model,
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
    StateSetter setState,
    BuildContext context,
  ) {
    final products = _buildProductsList(serial, sizeList);
    setState(() {
      if (model == null) {
        _addNewProduct(products);
      } else {
        _updateExistingProduct(model, products);
      }
      Navigator.of(context).pop();
    });
  }

  List<Product> _buildProductsList(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
  ) {
    final products = <Product>[];
    for (var i = 0; i < sizeList.length; i++) {
      products.add(Product(
        productSerialNumberId: 0,
        productDetailsId: 0,
        serialNumber: serial[i].text,
        size: sizeList[i]!.id,
      ));
    }
    return products;
  }

  void _addNewProduct(List<Product> products) {
    addProduct(ProductDetail(
      productDetailsId: 0,
      productName: productName.text,
      qty: quantity,
      inspectionId: inspectionId,
      typeId: productTab,
      products: products,
      productId: 0,
      createdOn:
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      categoryId: 0,
      notes: notes.text,
    ).toJson());
  }

  void _updateExistingProduct(ProductDetail model, List<Product> products) {
    updateProduct(ProductDetail(
      productDetailsId: model.productDetailsId,
      productName: productName.text,
      qty: quantity,
      inspectionId: inspectionId,
      typeId: productTab,
      products: products,
      productId: model.productId,
      createdOn:
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      categoryId: 0,
      notes: notes.text,
    ).toJson());
  }

  bool _isFormValid(
    List<TextEditingController> serial,
    List<AreaData?> sizeList,
  ) {
    return productName.text.isNotEmpty &&
        quantity != 0 &&
        !_hasInvalidSerialNumbers(serial) &&
        !_hasMissingSizes(sizeList);
  }

  void showQuantitySheet(
      ProductDetail knownProductModel, bool isEdit, int? position) {
    LogPrint().log("edit : $isEdit $position");
    final model = knownProductModel;
    var quantity = 0;
    final notes = TextEditingController();
    final controllers = <TextEditingController>[];
    final focusNodes = <FocusNode>[];
    final scrollController = ScrollController();

    _initializeQuantitySheet(model, isEdit, notes, controllers, focusNodes);
    quantity = _getInitialQuantity(model, isEdit);
    LogPrint().log("quantity : ${model.categoryId} ${model.qty}");

    showModalBottomSheet<void>(
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: currentHeight - 50,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust padding based on keyboard
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 5,
                  ),
                  FormTextField(
                    //  controller: quantity,
                    hint: "",
                    value: quantity.toString(),
                    title: 'Quantity :',
                    inputBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    textColor: AppTheme.grayAsparagus,
                    inputType: TextInputType.number,
                    onTap: () {
                      Get.to(const SelectQuantity())?.then((value) {
                        if (value != null) {
                          myState(() {
                            quantity = value;
                            _handleQuantityChangeForSheet(
                              quantity,
                              controllers,
                              focusNodes,
                            );
                          });
                        }
                      });
                    },
                  ),
                  controllers.isNotEmpty
                      ? ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          itemCount: controllers.length,
                          itemBuilder: (context, index) {
                            LogPrint().log(
                                "on set value : ${controllers[index].text}");
                            return FormTextField(
                              titleWidget: IconButton(
                                onPressed: () {
                                  Utils().showYesNoAlert(
                                      context: buildContext,
                                      message:
                                          "Are you sure delete this serial number?",
                                      onNoPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      onYesPressed: () {
                                        Navigator.of(context).pop();
                                        myState(() {
                                          controllers.removeAt(index);
                                          focusNodes.removeAt(index);
                                          quantity = controllers.length;
                                        });
                                      });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.red,
                                  size: 20,
                                ),
                              ),
                              onChange: (value) {
                                myState(() {
                                  focusNodes[index].requestFocus();
                                  LogPrint().log("on changes value : $value");
                                });
                              },
                              controller: controllers[index],
                              focusNode: focusNodes[index],
                              hint: "",
                              title: 'Product Code - ${index + 1} :',
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                              ],
                              inputBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              textColor: AppTheme.grayAsparagus,
                              inputType: TextInputType.text,
                            );
                          })
                      : Container(),
                  Visibility(
                      visible: _isQuantityFormValid(quantity, controllers),
                      child: FormTextField(
                        onChange: (value) {
                          setState(() {});
                        },
                        hint: "",
                        controller: notes,
                        textColor: AppTheme.grayAsparagus,
                        fontFamily: AppTheme.urbanist,
                        title: 'Notes',
                        maxLines: 3,
                        minLines: 1,
                      )),
                  Center(
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          final errorMessage = _validateQuantityForm(
                            quantity,
                            controllers,
                            buildContext,
                          );
                          if (errorMessage != null) {
                            Utils().showAlert(
                              buildContext: buildContext,
                              message: errorMessage,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            );
                          } else {
                            _saveQuantitySheet(
                              model,
                              isEdit,
                              quantity,
                              controllers,
                              notes,
                              setState,
                              context,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor:
                              _isQuantityFormValid(quantity, controllers)
                                  ? AppTheme.colorPrimary
                                  : AppTheme.paleGray,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: CText(
                          text: "SAVE",
                          textColor: AppTheme.textPrimary,
                          fontSize: AppTheme.large,
                          fontFamily: AppTheme.urbanist,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  //  Utils().sizeBoxHeight(height: 250)
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {
        // productTab = 3;
      });
    });
  }

  void _initializeQuantitySheet(
    ProductDetail model,
    bool isEdit,
    TextEditingController notes,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    setState(() {
      if (model.qty > 0 && isEdit) {
        _initializeFromModelForQuantity(
          model,
          notes,
          controllers,
          focusNodes,
        );
      } else {
        _initializeEmptyQuantitySheet(
          model,
          controllers,
          focusNodes,
        );
      }
    });
  }

  int _getInitialQuantity(ProductDetail model, bool isEdit) {
    if (model.qty > 0 && isEdit) {
      return model.qty;
    }
    model.qty = 1;
    return model.qty;
  }

  void _initializeFromModelForQuantity(
    ProductDetail model,
    TextEditingController notes,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    notes.text = model.notes.toString();
    if (model.products.isNotEmpty) {
      for (var element in model.products) {
        controllers.add(TextEditingController(text: element.serialNumber));
        focusNodes.add(FocusNode());
      }
    }
  }

  void _initializeEmptyQuantitySheet(
    ProductDetail model,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    model.qty = 1;
    model.products = [];
    controllers.add(TextEditingController(text: ""));
    focusNodes.add(FocusNode());
  }

  void _handleQuantityChangeForSheet(
    int newQuantity,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    if (newQuantity > controllers.length) {
      _addControllersForQuantity(newQuantity, controllers, focusNodes);
    } else if (newQuantity < controllers.length) {
      _removeControllersForQuantity(newQuantity, controllers, focusNodes);
    }
  }

  void _addControllersForQuantity(
    int quantity,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    for (int i = controllers.length; i < quantity; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
  }

  void _removeControllersForQuantity(
    int quantity,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    controllers.removeRange(quantity, controllers.length);
    focusNodes.removeRange(quantity, focusNodes.length);
  }

  String? _validateQuantityForm(
    int quantity,
    List<TextEditingController> controllers,
    BuildContext buildContext,
  ) {
    if (quantity == 0) {
      return "Please select quantity";
    }
    if (_hasInvalidSerialNumbersForQuantity(controllers)) {
      return "Please enter valid serial number";
    }
    return null;
  }

  bool _hasInvalidSerialNumbersForQuantity(
    List<TextEditingController> controllers,
  ) {
    return controllers
        .any((element) => element.text.isEmpty || element.text.length < 5);
  }

  bool _isQuantityFormValid(
    int quantity,
    List<TextEditingController> controllers,
  ) {
    return quantity != 0 && !_hasInvalidSerialNumbersForQuantity(controllers);
  }

  void _saveQuantitySheet(
    ProductDetail model,
    bool isEdit,
    int quantity,
    List<TextEditingController> controllers,
    TextEditingController notes,
    StateSetter setState,
    BuildContext context,
  ) {
    final products = _buildProductsListForQuantity(controllers, model, isEdit);
    setState(() {
      if (isEdit) {
        _updateProductForQuantity(model, quantity, products, notes);
      } else {
        _addProductForQuantity(model, quantity, products, notes);
      }
      Navigator.of(context).pop();
    });
  }

  List<Map<String, dynamic>> _buildProductsListForQuantity(
    List<TextEditingController> controllers,
    ProductDetail model,
    bool isEdit,
  ) {
    final products = <Map<String, dynamic>>[];
    for (var element in controllers) {
      products.add(Product(
        productSerialNumberId: 0,
        productDetailsId: isEdit ? model.productId : 0,
        serialNumber: element.text,
      ).toJson());
    }
    return products;
  }

  void _updateProductForQuantity(
    ProductDetail model,
    int quantity,
    List<Map<String, dynamic>> products,
    TextEditingController notes,
  ) {
    updateProduct({
      "productDetailsId": model.productDetailsId,
      "inspectionId": inspectionId,
      "typeId": productTab,
      "products": products,
      "productId": model.productId,
      "productName": model.productName,
      "qty": quantity,
      "createdOn":
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      "categoryId": model.categoryId,
      "notes": notes.text,
    });
    LogPrint().log("true $model");
  }

  void _addProductForQuantity(
    ProductDetail model,
    int quantity,
    List<Map<String, dynamic>> products,
    TextEditingController notes,
  ) {
    LogPrint().log("false $model");
    addProduct({
      "productDetailsId": 0,
      "inspectionId": inspectionId,
      "typeId": productTab,
      "products": products,
      "productId": model.productId,
      "productName": model.productName,
      "qty": quantity,
      "createdOn":
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      "categoryId": model.categoryId,
      "notes": notes.text,
    });
  }

  void showSizeSheet(FocusNode focusNode, List<AreaData?>? size, position,
      StateSetter myState) {
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
                    controller: _searchSize,
                    onChanged: (searchText) {
                      sizeList.clear();
                      myState(() {
                        if (searchText.isEmpty) {
                          sizeList.addAll(searchSizeList);
                        } else {
                          for (var item in searchSizeList) {
                            if (item.text
                                .toLowerCase()
                                .contains(searchText.toLowerCase())) {
                              sizeList.add(item);
                            }
                          }
                        }
                      });
                    },
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
                    itemCount: sizeList.length,
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
                              size![position] = sizeList[index];
                            });
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: CText(
                              textAlign: TextAlign.start,
                              padding: const EdgeInsets.only(
                                  right: 10, top: 10, bottom: 10),
                              text: sizeList[index].text,
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
      myState(() {
        LogPrint().log(size![position]);
      });
      setState(() {
        focusNode.requestFocus();
      });
    });
  }

  void showKnownProductSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: currentHeight - 50,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust padding based on keyboard
              ),
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
                        padding: const EdgeInsets.all(20),
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
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: AppTheme.white,
                    ),
                    child: TextFormField(
                      controller: _searchKnownProduct,
                      onChanged: (searchText) {
                        myState(() {
                          productName.text = _searchKnownProduct.text;
                        });
                        getSearchAllKnownProducts(myState);
                      },
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
                      itemCount: knownProductList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            /*    var data = ProductDetail(
                                productDetailsId: 0,
                                inspectionId: inspectionId,
                                typeId: 1,
                                products: [],
                                categoryId: knownProductList[index].categoryId,
                                productId: knownProductList[index].productId,
                                productName:
                                    knownProductList[index].productName,
                                qty: 1,
                                createdOn: '',
                                notes: "");*/
                            productName.text =
                                knownProductList[index].productName;
                            focusNode.requestFocus();
                            _searchKnownProduct.clear();
                            knownProductList.clear();
                            Navigator.of(context).pop();

                            // showQuantitySheet(data, false, null);
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
                                  /*  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 20, bottom: 5),
                                    text: productCategoryList
                                        .firstWhere((element) =>
                                            element.productCategoryId ==
                                            knownProductList[index].categoryId)
                                        .name,
                                    textColor: AppTheme.colorPrimary,
                                    fontFamily: AppTheme.Urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w700,
                                  ),*/
                                  CText(
                                    textAlign: TextAlign.start,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 10, bottom: 10),
                                    text: knownProductList[index].productName,
                                    textColor: AppTheme.grayAsparagus,
                                    fontFamily: AppTheme.urbanist,
                                    fontSize: AppTheme.large,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w600,
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
          );
        });
      },
    ).whenComplete(() {
      setState(() {
        productTab = 3;
        _searchKnownProduct.text = "";
      });
    });
  }

  ///other tab

  Widget tabOneUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
              visible: widget.outletData != null,
              child: FormTextField(
                hint: "",
                enabled: false,
                controller: _outlets,
                value: outletModel != null ? outletModel!.outletName : "",
                title: 'Selected Outlet :',
              )),
          CText(
            padding: EdgeInsets.only(
                bottom: currentWidth > SIZE_600 ? 20 : 10,
                top: currentWidth > SIZE_600 ? 20 : 10,
                left: currentWidth > SIZE_600 ? 15 : 10,
                right: currentWidth > SIZE_600 ? 15 : 10),
            textColor: AppTheme.black,
            fontSize: AppTheme.large,
            fontFamily: AppTheme.urbanist,
            fontWeight: FontWeight.w600,
            text: 'Your Location',
            // fontWeight: FontWeight.w400,
            // textColor: AppTheme.black,
            // fontSize: currentWidth > SIZE_600 ? 16 : 12
          ),
          Card(
            margin: EdgeInsets.only(
                left: currentWidth > SIZE_600 ? 15 : 10,
                right: currentWidth > SIZE_600 ? 15 : 10),
            elevation: 2,
            surfaceTintColor: AppTheme.white,
            color: AppTheme.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: SizedBox(
              width: currentWidth,
              child: CText(
                padding: const EdgeInsets.all(15),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textColor: AppTheme.grayAsparagus,
                fontSize: AppTheme.large,
                fontFamily: AppTheme.urbanist,
                fontWeight: FontWeight.w600,
                text: googleAddress.isEmpty ? "Loading..." : googleAddress,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          FormTextField(
            hint: "",
            value: inspectorNameList.join(","),
            textColor: AppTheme.grayAsparagus,
            fontFamily: AppTheme.urbanist,
            title: 'Select Inspectors',
            maxLines: 2,
            minLines: 1,
            onTap: () {
              getAllUsers();
            },
          ),
          // todo Representative
          Visibility(
            visible: widget.isAgentEmployees,
            child: FormTextField(
              hint: "",
              value: mmiNameList.join(","),
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              title: 'Select AE Representative',
              maxLines: 2,
              minLines: 1,
              onTap: () {
                getAgents(2);
              },
            ),
          ),
          Visibility(
            visible: widget.isAgentEmployees,
            child: FormTextField(
              hint: "",
              value: aeNameList.join(","),
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              title: 'Select MMI Representative',
              maxLines: 2,
              minLines: 1,
              onTap: () {
                getAgents(1);
              },
            ),
          ),
          FormTextField(
            hint: "",
            controller: initialNotes,
            textColor: AppTheme.grayAsparagus,
            fontFamily: AppTheme.urbanist,
            title: 'Comments',
            maxLines: 10,
            minLines: 3,
          ),
          Visibility(
            visible: !storeUserData.getBoolean(IS_AGENT_LOGIN),
            child: Container(
              margin: const EdgeInsets.only(
                  top: 20, right: 10, left: 10, bottom: 20),
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: () {
                  if (validateNext()) {
                    createInspection();
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor:
                      validateNext() ? AppTheme.colorPrimary : AppTheme.grey,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: CText(
                  text: "Start",
                  textColor: AppTheme.textPrimary,
                  fontSize: AppTheme.large,
                  fontFamily: AppTheme.urbanist,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getAllUsers() async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context,
              "Department/Task/GetAssignedTaskInspectors?mainTaskId=${widget.mainTaskId}")
          .then((value) async {
        try {
          LoadingIndicatorDialog().dismiss();
          setState(() {
            var data = allUsersFromJson(value);
            if (data.data.isNotEmpty) {
              showInspectorSheet(data.data);
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
        } catch (e) {
          LoadingIndicatorDialog().dismiss();
          setState(() {});
        }
      });
    }
  }

  void showInspectorSheet(List<AllUserData> list) {
    List<AllUserData> selected = [];
    selected.addAll(selectedInspectors);
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
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
                      // updateInspection();
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
                Expanded(
                  child: ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: AppTheme.white,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10),
                          surfaceTintColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CText(
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
                                ),
                                IconButton(
                                    onPressed: () {
                                      myState(() {
                                        if (selected.firstWhereOrNull(
                                                (element) =>
                                                    element.departmentUserId ==
                                                    list[index]
                                                        .departmentUserId) !=
                                            null) {
                                          selected.removeWhere((element) =>
                                              element.departmentUserId ==
                                              list[index].departmentUserId);
                                        } else {
                                          selected.add(list[index]);
                                        }
                                      });
                                    },
                                    icon: selected.firstWhereOrNull((element) =>
                                                element.departmentUserId ==
                                                list[index].departmentUserId) !=
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
                                          )),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
                Utils().sizeBoxHeight(height: 30)
              ],
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {
        tabType = 1;
        inspectorNameList.clear();
        selectedInspectors.clear();
        selectedInspectors.addAll(selected);
        for (var element in selectedInspectors) {
          inspectorNameList.add(element.name);
        }
      });
    });
  }

  void createInspection() {
    var agentMap = [];
    for (var element in selectedAEList) {
      agentMap.add({
        "agentId": element.agentId,
        "agentEmployeeId": element.agentEmployeeId
      });
    }
    for (var element in selectedMMIList) {
      agentMap.add({
        "agentId": element.agentId,
        "agentEmployeeId": element.agentEmployeeId
      });
    }
    var inspectorMap = [];
    for (var element in selectedInspectors) {
      inspectorMap.add({
        "departmnetInspectionId": 0,
        "inspectionId": 0,
        "inspectorId": element.departmentUserId
      });
    }
    var map = {
      "inspectionId": 0,
      "inspectorId": storeUserData.getInt(USER_ID),
      "createdBy": storeUserData.getInt(USER_ID),
      "inspectionTaskId": taskId ?? 0,
      "entityId": widget.entityId,
      "outletId": !widget.newAdded ? outletModel?.outletId ?? 0 : 0,
      "newOutletId": widget.newAdded ? outletModel?.outletId ?? 0 : 0,
      "location": googleAddress,
      "agentEmployeeIds": agentMap,
      "departmentEmployeeId": inspectorMap,
      "createdOn":
          DateFormat(fullDateTimeFormat).format(Utils().getCurrentGSTTime()),
      "comments": initialNotes.text.toString(),
      "finalNotes": "",
      "createdByName": "",
      "isTaskCreatedByOwn": taskId == null,
      "statusId": 5,
      "inspectionType": widget.isAgentEmployees ? 1 : 0
    };
    if (widget.taskType == 1) {
      map["Inspectiontask"] = 1;
    } else if (widget.taskType == 2) {
      map["ExpiredTask"] = 2;
    }
    print("createInspection $map");
    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/Inspection/CreateInspection", map)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      LogPrint().log("response : $value");
      var data = jsonDecode(value);
      if (data["statusCode"] == 200 && data["data"] != null) {
        setState(() {
          statusId = 5;
          tabType = 2;
          inspectorId = storeUserData.getInt(USER_ID);
          taskId ??= data["data"]["inspectionTaskId"];

          inspectionId = data["data"];
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

  Widget tabFourUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CText(
                  text: "Client Representative",
                  textColor: AppTheme.black,
                  fontFamily: AppTheme.urbanist,
                  fontSize: AppTheme.large,
                  fontWeight: FontWeight.w600,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorPrimary),
                  onPressed: () {
                    if (inspectorId == storeUserData.getInt(USER_ID) ||
                        widget.primary == true) {
                      showAddManagerSheet(null, 1);
                    }
                  },
                  child: CText(
                    text: "Add New",
                    textColor: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            ),
          ),
          ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: managerList.length,
              itemBuilder: (context, index) {
                return getManagerUI(managerList, index, 1);
              }),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CText(
                  text: "Witness",
                  textColor: AppTheme.black,
                  fontFamily: AppTheme.urbanist,
                  fontSize: AppTheme.large,
                  fontWeight: FontWeight.w600,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorPrimary),
                  onPressed: () {
                    if (inspectorId == storeUserData.getInt(USER_ID) ||
                        widget.primary == true) {
                      showAddManagerSheet(null, 2);
                    }
                  },
                  child: CText(
                    text: "Add New",
                    textColor: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            ),
          ),
          ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: witnessList.length,
              itemBuilder: (context, index) {
                return getManagerUI(witnessList, index, 2);
              }),
          Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
              child: FormTextField(
                hint: "",
                focusNode: concludeFocusNode,
                controller: concludeNotes,
                textColor: AppTheme.grayAsparagus,
                fontFamily: AppTheme.urbanist,
                title: 'Inspection Concluding Notes :',
                maxLines: 10,
                minLines: 5,
              )),
          Container(
            margin:
                const EdgeInsets.only(top: 30, right: 20, left: 20, bottom: 30),
            child: ElevatedButton(
              onPressed: () {
                if (inspectorId == storeUserData.getInt(USER_ID) ||
                    widget.primary == true) {
                  if (validateNext()) {
                    concludeFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    Utils().showYesNoAlert(
                        context: context,
                        message:
                            "Are you sure you want to finish the inspections?",
                        onYesPressed: () {
                          Navigator.of(context).pop();
                          if (widget.taskType == 2 || widget.taskType == 3) {
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
                          Navigator.of(context).pop();
                        });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor:
                    validateNext() ? AppTheme.colorPrimary : AppTheme.grey,
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
          /*    Visibility(
              visible: inspectorId != storeUserData.getInt(USER_ID),
              child: CText(
                padding: const EdgeInsets.only(left: 20, right: 20),
                text: "*Note : Only Primary Inspector is allowed to update .",
                textColor: AppTheme.red,
                fontFamily: AppTheme.Urbanist,
                fontSize: AppTheme.large,
                fontWeight: FontWeight.w600,
              )),*/
        ],
      ),
    );
  }

  Future<void> getAgents(int agentId) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context,
              "Agent/Agent/GetAssignedTaskEmployees?agentId=$agentId&mainTaskId=${widget.mainTaskId}")
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        var data = witnessFromJson(value);
        if (data.data.isNotEmpty) {
          showAEMMISheet(data.data);
        } else {
          /*    setState(() {
            if (agentId == 1) {
              isAE = false;
            } else {
              isMMI = false;
            }
          });*/
          Utils().showAlert(
              buildContext: context,
              message: data.message != null && data.message!.isNotEmpty
                  ? data.message!
                  : "No Representative Found",
              onPressed: () {
                Navigator.of(context).pop();
              });
        }
      });
    }
  }

  void submitInspection([selected]) {
    var status = 7;
    if (entity != null) {
      if (entity!.location?.category.toString().toLowerCase() == "hotel") {
        status =
            selectedMMIList.isNotEmpty || selectedAEList.isNotEmpty ? 6 : 7;
      } else {
        status = 6;
      }
    } else {
      print("submitInspection 4 ${entity?.entityName.toString()}");
      status = 6;
    }

    var map = {
      "inspectionTaskId": taskId,
      "inspectionId": inspectionId,
      "inspectorId": storeUserData.getInt(USER_ID),
      "statusId": status,
      "finalNotes": concludeNotes.text.toString(),
      // "inspectionReasonMasterId": selected
    };

    if (widget.taskType == 2 || widget.taskType == 3) {
      map["inspectionReasonMasterId"] = selected;
    }

    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/Inspection/UpdateInspection", map)
        .then((value) {
      LoadingIndicatorDialog().dismiss();
      var data = jsonDecode(value);
      if (data["statusCode"] == 200) {
        Utils().showAlert(
            buildContext: context,
            message: data["message"],
            onPressed: () {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!Get.isRegistered<HomeScreen>()) {
                  Get.offAll(() => const HomeScreen());
                }
              });
            });
      } else {
        debugPrint("Error $value");
        Utils().showAlert(
            buildContext: context,
            message: data["message"] ?? "",
            onPressed: () {
              Navigator.of(context).pop();
            });
      }
    });
  }

  void showAEMMISheet(List<WitnessData> list) {
    List<WitnessData> agent1 = [];
    agent1.addAll(selectedAEList);
    List<WitnessData> agent2 = [];
    agent2.addAll(selectedMMIList);
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppTheme.mainBackground,
      context: context,
      builder: (BuildContext buildContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter myState) {
          return Container(
            decoration: const BoxDecoration(
                color: AppTheme.mainBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            height: currentHeight - 50,
            child: Column(
              children: [
                // Sticky SAVE header
                Container(
                  width: double.infinity,
                  color: AppTheme.mainBackground,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: CText(
                        padding: const EdgeInsets.all(15),
                        textAlign: TextAlign.center,
                        text: "SAVE",
                        textColor: AppTheme.colorPrimary,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.medium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.grey),

                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        ListView.builder(
                            padding: const EdgeInsets.only(top: 10),
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                  onTap: () {
                                    myState(() {
                                      if (list[index].agentId == 1) {
                                        if (agent1.firstWhereOrNull((element) =>
                                                element.agentEmployeeId ==
                                                list[index].agentEmployeeId) !=
                                            null) {
                                          agent1.removeWhere((element) =>
                                              element.agentEmployeeId ==
                                              list[index].agentEmployeeId);
                                        } else {
                                          agent1.add(list[index]);
                                        }
                                      } else {
                                        if (agent2.firstWhereOrNull((element) =>
                                                element.agentEmployeeId ==
                                                list[index].agentEmployeeId) !=
                                            null) {
                                          agent2.removeWhere((element) =>
                                              element.agentEmployeeId ==
                                              list[index].agentEmployeeId);
                                        } else {
                                          agent2.add(list[index]);
                                        }
                                      }
                                    });
                                  },
                                  child: Card(
                                    color: AppTheme.white,
                                    margin: const EdgeInsets.only(
                                        left: 20, right: 20, bottom: 10),
                                    surfaceTintColor: AppTheme.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CText(
                                                textAlign: TextAlign.start,
                                                padding: const EdgeInsets.only(
                                                    right: 10, bottom: 5),
                                                text: list[index].agentName,
                                                textColor:
                                                    AppTheme.colorPrimary,
                                                fontFamily: AppTheme.urbanist,
                                                fontSize: AppTheme.large,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              CText(
                                                textAlign: TextAlign.start,
                                                padding: const EdgeInsets.only(
                                                    right: 10,
                                                    top: 0,
                                                    bottom: 5),
                                                text: list[index].emiratesId,
                                                textColor:
                                                    AppTheme.grayAsparagus,
                                                fontFamily: AppTheme.urbanist,
                                                fontSize: AppTheme.large,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              CText(
                                                textAlign: TextAlign.start,
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                text: list[index].phoneNo,
                                                textColor:
                                                    AppTheme.grayAsparagus,
                                                fontFamily: AppTheme.urbanist,
                                                fontSize: AppTheme.large,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ],
                                          )),
                                          list[index].agentId == 1
                                              ? agent1.firstWhereOrNull((element) =>
                                                          element
                                                              .agentEmployeeId ==
                                                          list[index]
                                                              .agentEmployeeId) !=
                                                      null
                                                  ? const Icon(
                                                      Icons.check_box,
                                                      size: 20,
                                                      color:
                                                          AppTheme.colorPrimary,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .check_box_outline_blank,
                                                      size: 20,
                                                      color: AppTheme.grey,
                                                    )
                                              : agent2.firstWhereOrNull((element) =>
                                                          element
                                                              .agentEmployeeId ==
                                                          list[index]
                                                              .agentEmployeeId) !=
                                                      null
                                                  ? const Icon(
                                                      Icons.check_box,
                                                      size: 20,
                                                      color:
                                                          AppTheme.colorPrimary,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .check_box_outline_blank,
                                                      size: 20,
                                                      color: AppTheme.grey,
                                                    ),
                                        ],
                                      ),
                                    ),
                                  ));
                            }),
                        Utils().sizeBoxHeight(height: 250)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {
        tabType = 1;
        selectedAEList.clear();
        selectedAEList.addAll(agent1);
        selectedMMIList.clear();
        selectedMMIList.addAll(agent2);
        aeNameList.clear();
        for (var element in selectedAEList) {
          aeNameList.add(element.agentName);
        }
        mmiNameList.clear();
        for (var element in selectedMMIList) {
          mmiNameList.add(element.agentName);
        }
      });
    });
  }

  String formatEmiratesID(String id) {
    // ignore: deprecated_member_use
    id = id.replaceAll(RegExp(r'\D'), '');
    if (id.length != 15) {
      throw const FormatException(
          "Invalid Emirates ID length. It should be 15 digits.");
    }
    return '${id.substring(0, 3)}-${id.substring(3, 7)}-${id.substring(7, 14)}-${id.substring(14, 15)}';
  }

  void showAddManagerSheet(RepresentativeData? model, int type) {
    var maskFormatter = MaskTextInputFormatter(
        mask: 'XXX-XXXX-XXXXXXX-X',
        // ignore: deprecated_member_use
        filter: {"X": RegExp(r'[0-9]')},
        type: MaskAutoCompletionType.lazy);
    final name = TextEditingController();
    final emiratesId = TextEditingController();
    final mobileNumber = TextEditingController();
    final roleName = TextEditingController();
    final notes = TextEditingController();
    final node1 = FocusNode();
    final node2 = FocusNode();
    final node3 = FocusNode();
    final node4 = FocusNode();
    final node5 = FocusNode();
    imageAttach = "";
    if (model != null) {
      setState(() {
        name.text = model.name;
        emiratesId.text = formatEmiratesID(model.emiratesId);
        mobileNumber.text = model.phoneNo.replaceAll("+9715", "");
        roleName.text = model.roleName ?? "";
        notes.text = model.notes ?? "";
      });
    }
    showModalBottomSheet(
        enableDrag: false,
        isDismissible: false,
        context: context,
        backgroundColor: AppTheme.mainBackground,
        isScrollControlled: true,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter myState) {
            return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                    color: AppTheme.mainBackground,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        topLeft: Radius.circular(15))),
                height: currentHeight - 50,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context)
                        .viewInsets
                        .bottom, // Adjust padding based on keyboard
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        children: [
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
                      FormTextField(
                        onChange: (value) {
                          myState(() {});
                        },
                        focusNode: node1,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              // ignore: deprecated_member_use
                              RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$')),
                        ],
                        controller: name,
                        hint: "",
                        value: name.text,
                        title: 'Name :',
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.grayAsparagus,
                        inputType: TextInputType.text,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FormTextField(
                        onChange: (value) {
                          myState(() {
                            LogPrint().log(emiratesId.text);
                          });
                        },
                        inputFormatters: [
                          maskFormatter,
                        ],
                        controller: emiratesId,
                        focusNode: node2,
                        hint: "XXX-XXXX-XXXXXXX-X",
                        value: emiratesId.text,
                        title: 'Emirates ID :',
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.grayAsparagus,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FormMobileTextField(
                        onChange: (value) {
                          myState(() {});
                        },
                        controller: mobileNumber,
                        focusNode: node3,
                        hint: "",
                        value: mobileNumber.text,
                        title: 'Mobile Number :',
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(8),
                        ],
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.grayAsparagus,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FormTextField(
                        controller: roleName,
                        onChange: (value) {
                          myState(() {});
                        },
                        hint: "",
                        focusNode: node4,
                        value: roleName.text,
                        title: 'Role :',
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.grayAsparagus,
                        inputType: TextInputType.text,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FormTextField(
                        controller: notes,
                        onChange: (value) {
                          myState(() {});
                        },
                        hint: "",
                        focusNode: node5,
                        value: notes.text,
                        title: notesTitle,
                        minLines: 2,
                        maxLines: 5,
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.grayAsparagus,
                        inputType: TextInputType.text,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FormTextField(
                        hint: "",
                        value: "Attach",
                        hideIcon: true,
                        title: 'Upload EmiratesId Photo',
                        minLines: 2,
                        maxLines: 5,
                        inputBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        textColor: AppTheme.colorPrimary,
                        inputType: TextInputType.text,
                        onTap: () {
                          node1.unfocus();
                          node2.unfocus();
                          node3.unfocus();
                          node4.unfocus();
                          node5.unfocus();
                          requestCameraPermissions(
                              "image", null, type == 1 ? 4 : 5, myState);
                        },
                      ),
                      imageAttach.isNotEmpty
                          ? Container(
                              margin: EdgeInsets.only(
                                  bottom: currentWidth > SIZE_600 ? 20 : 10,
                                  top: currentWidth > SIZE_600 ? 20 : 10,
                                  left: currentWidth > SIZE_600 ? 15 : 10,
                                  right: currentWidth > SIZE_600 ? 15 : 10),
                              width: 150,
                              height: 150,
                              child:
                                  Image.network(imageAttach, fit: BoxFit.cover),
                            )
                          : Container(),
                      const SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              if (name.text.isEmpty) {
                                Utils().showAlert(
                                    buildContext: buildContext,
                                    message: "Please enter name",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else if (emiratesId.text.isEmpty ||
                                  emiratesId.text.length != 18) {
                                Utils().showAlert(
                                    buildContext: buildContext,
                                    message: "Please enter valid emiratesID",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else if (mobileNumber.text.isEmpty ||
                                  mobileNumber.text.length != 8) {
                                Utils().showAlert(
                                    buildContext: buildContext,
                                    message:
                                        "Please enter valid contact number",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else if (roleName.text.isEmpty) {
                                Utils().showAlert(
                                    buildContext: buildContext,
                                    message: "Please enter role",
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    });
                              } else {
                                if (model == null) {
                                  Navigator.of(context).pop();
                                  addRepresentative(RepresentativeData(
                                          entityRepresentativeId: 0,
                                          inspectionId: inspectionId,
                                          typeId: type,
                                          name: name.text.toString(),
                                          emiratesId: emiratesId.text
                                              .toString()
                                              .replaceAll("-", ""),
                                          phoneNo: "+9715${mobileNumber.text}",
                                          roleId: 0,
                                          roleName: roleName.text.toString(),
                                          notes: notes.text.toString())
                                      .toJson());
                                } else {
                                  Navigator.of(context).pop();
                                  updateRepresentative(RepresentativeData(
                                          entityRepresentativeId:
                                              model.entityRepresentativeId,
                                          inspectionId: inspectionId,
                                          typeId: type,
                                          name: name.text.toString(),
                                          emiratesId: emiratesId.text
                                              .toString()
                                              .replaceAll("-", ""),
                                          phoneNo: "+9715${mobileNumber.text}",
                                          roleId: 0,
                                          roleName: roleName.text.toString(),
                                          notes: notes.text.toString())
                                      .toJson());
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: name.text.isNotEmpty &&
                                      emiratesId.text.isNotEmpty &&
                                      mobileNumber.text.isNotEmpty &&
                                      roleName.text.isNotEmpty &&
                                      emiratesId.text.length == 18 &&
                                      mobileNumber.text.length == 8
                                  ? AppTheme.colorPrimary
                                  : AppTheme.paleGray,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: CText(
                              text: model == null ? "Add" : "Update",
                              textColor: AppTheme.textPrimary,
                              fontSize: AppTheme.large,
                              fontFamily: AppTheme.urbanist,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Utils().sizeBoxHeight(height: 250)
                    ],
                  ),
                ));
          });
        }).whenComplete(() {
      setState(() {
        tabType = 4;
      });
    });
  }

  void updateRepresentative(Map<String, dynamic> fields) {
    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/EntityRepresentative/Update", fields)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      LogPrint().log("response : $value");
      var data = jsonDecode(value);
      if (data["statusCode"] == 200) {
        getInspectionRepresentative();
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

  void addRepresentative(Map<String, dynamic> fields) {
    LoadingIndicatorDialog().show(context);
    Api()
        .callAPI(context, "Mobile/EntityRepresentative/Create", fields)
        .then((value) async {
      LoadingIndicatorDialog().dismiss();
      LogPrint().log("response : $value");
      var data = jsonDecode(value);
      if (data["statusCode"] == 200) {
        getInspectionRepresentative();
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

  Future<void> deleteRepresentative(int id) async {
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      LoadingIndicatorDialog().show(context);
      Api()
          .getAPI(context,
              "Mobile/EntityRepresentative/Delete?productDetailsId=$id")
          .then((value) async {
        LoadingIndicatorDialog().dismiss();
        LogPrint().log("response : $value");
        var data = jsonDecode(value);
        if (data["statusCode"] == 200) {
          getInspectionRepresentative();
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

  Future<void> getInspectionRepresentative() async {
    setState(() {
      managerList.clear();
      witnessList.clear();
    });
    if (await Utils().hasNetwork(context, setState)) {
      if (!mounted) return;
      Api()
          .getAPI(context,
              "Mobile/EntityRepresentative/GetInspectionDetail?inspectionId=$inspectionId")
          .then((value) async {
        LogPrint().log("response : $value");
        var data = representativeFromJson(value);
        if (data.data.isNotEmpty) {
          setState(() {
            for (var element in data.data) {
              if (element.typeId == 1) {
                managerList.add(element);
              } else if (element.typeId == 2) {
                witnessList.add(element);
              }
            }
          });
        } else {
          if (data.message != null && data.message!.isNotEmpty) {
            Utils().showAlert(
                buildContext: context,
                message: data.message!,
                onPressed: () {
                  Navigator.of(context).pop();
                });
          }
        }
      });
    }
  }

  Widget getManagerUI(List<RepresentativeData> list, int index, int type) {
    return Card(
      color: AppTheme.white,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      surfaceTintColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CText(
                    textAlign: TextAlign.start,
                    text: list[index].name,
                    textColor: AppTheme.colorPrimary,
                    fontFamily: AppTheme.urbanist,
                    fontSize: AppTheme.large,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (inspectorId == storeUserData.getInt(USER_ID) ||
                          widget.primary == true) {
                        Get.to(SignRepresentative(
                          model: list[index],
                          type: type,
                          inspectionId: inspectionId,
                          entityId: widget.entityId,
                        ));
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: CText(
                      textAlign: TextAlign.start,
                      text: "E-Sign",
                      textColor: AppTheme.colorAccent,
                      fontFamily: AppTheme.urbanist,
                      fontSize: AppTheme.large,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, top: 0, bottom: 5),
              text: "Role : ${list[index].roleName}",
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10, bottom: 5),
              text: "Emirates ID : ${formatEmiratesID(list[index].emiratesId)}",
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            CText(
              textAlign: TextAlign.start,
              padding: const EdgeInsets.only(right: 10),
              text: "Contact Number : ${list[index].phoneNo}",
              textColor: AppTheme.grayAsparagus,
              fontFamily: AppTheme.urbanist,
              fontSize: AppTheme.large,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            Row(
              children: [
                Expanded(
                  child: CText(
                    textAlign: TextAlign.start,
                    padding: const EdgeInsets.only(right: 10, top: 5),
                    text: "$notesTitle ${list[index].notes}",
                    textColor: AppTheme.grayAsparagus,
                    fontFamily: AppTheme.urbanist,
                    fontSize: AppTheme.large,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (inspectorId == storeUserData.getInt(USER_ID) ||
                        widget.primary == true) {
                      showAddManagerSheet(list[index], type);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: CText(
                    textAlign: TextAlign.start,
                    text: "EDIT",
                    textColor: AppTheme.colorPrimary,
                    fontFamily: AppTheme.urbanist,
                    fontSize: AppTheme.large,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  width: 0.5,
                  height: AppTheme.large,
                  color: AppTheme.grey,
                ),
                IconButton(
                    onPressed: () {
                      if (inspectorId == storeUserData.getInt(USER_ID) ||
                          widget.primary == true) {
                        Utils().showYesNoAlert(
                            context: context,
                            message:
                                "Are you sure you want to delete the record?",
                            onYesPressed: () {
                              Navigator.of(context).pop();
                              deleteRepresentative(
                                  list[index].entityRepresentativeId);
                            },
                            onNoPressed: () {
                              Navigator.of(context).pop();
                            });
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.red,
                      size: 20,
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget tabThreeUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Utils().sizeBoxHeight(height: 25),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (await Utils().hasNetwork(context, setState)) {
                    requestCameraPermissions("video", null, 9, setState);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(left: 20, right: 5, top: 10),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  elevation: 2,
                  child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.center,
                      height: (MediaQuery.of(context).size.width - 50) / 2,
                      width: (MediaQuery.of(context).size.width - 50) / 2,
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
                    requestCameraPermissions("image", null, 9, setState);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(left: 5, right: 20, top: 10),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  elevation: 2,
                  child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.center,
                      height: (MediaQuery.of(context).size.width - 50) / 2,
                      width: (MediaQuery.of(context).size.width - 50) / 2,
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
          Utils().sizeBoxHeight(),
          Visibility(
              visible: detail != null && detail!.attachments.isNotEmpty,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(AllAttachmentsScreen(patrolId: inspectionId));
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: AppTheme.colorPrimary,
                    minimumSize: const Size(200, 55),
                  ),
                  child: CText(
                    text: "Load All Images",
                    textColor: AppTheme.white,
                    fontSize: AppTheme.large,
                    fontFamily: AppTheme.urbanist,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void openImageVideoOption(productId) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
              backgroundColor: AppTheme.white,
              surfaceTintColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Material(
                  color: Colors.transparent,
                  child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.white),
                      child: Column(children: [
                        CText(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            text: "Select Option",
                            textAlign: TextAlign.center,
                            fontSize: AppTheme.large,
                            fontWeight: FontWeight.bold,
                            textColor: AppTheme.black),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  requestCameraPermissions(
                                      "video", productId, 1, setState);
                                },
                                child: CText(
                                  text: "Video",
                                  textColor: AppTheme.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.of(dialogContext).pop();
                                  requestCameraPermissions(
                                      "image", productId, 1, setState);
                                },
                                child: CText(
                                  text: "Image",
                                  textColor: AppTheme.black,
                                ),
                              ),
                            ]),
                        const SizedBox(
                          height: 20,
                        )
                      ]))));
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
            "video",
            info.path!);
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
        if (inspectionId != 0) {
          uploadImage(
              http.MultipartFile.fromBytes(
                'file',
                compressedBytes,
                filename: Utils().getFileName(xFile.path.split("/").last),
              ),
              productId,
              categoryId,
              myState,
              "image",
              file.path);
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
      StateSetter myState, String type, String filePath) {
    List<http.MultipartFile> listMedia = [];
    listMedia.add(media);
    var map = {
      "InspectionId": inspectionId.toString(),
    };
    if (productId != null) {
      map.addAll({"ProductDetailsId": productId.toString()});
    }
    if (categoryId != null) {
      map.addAll({"CategoryId": categoryId.toString()});
    }
    Api()
        .callAPIWithFiles(
            context, "Mobile/InspectionDocument/Create", map, listMedia)
        .then((value) {
      LoadingIndicatorDialog().dismiss();
      LogPrint().log(value);
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
          if (categoryId == 9) {
            if (type == "image") {
              image.add(filePath);
            }
            setState(() {
              attachedLink = json["data"];
            });

            showAttachmentDialog(attachedLink);
          } else {
            if (categoryId == 1) {
              myState(() {
                attachedProduct = json["data"];
              });
              showAttachmentDialog(attachedProduct);
            } else {
              myState(() {
                imageAttach = json["data"];
              });
            }
          }
          Utils().showSnackBar(context, "Uploaded successfully.");
          getInspectionDetail();
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

  bool validateNext() {
    if (tabType == 1) {
      if ((widget.outletData != null && outletModel == null) ||
          googleAddress.isEmpty ||
          inspectorNameList.isEmpty) {
        return false;
      }
    }
    if (tabType == 4) {
      if (concludeNotes.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  void getReasonListing() async {
    var result = await context.apiDio
        .get("api/Department/InspectionReasonMaster/InspectionReasonDropDown");
    if (result.isSuccess) {
      reasonList = (result.data["data"] as List).cast<Map<String, dynamic>>();
      setState(() {});
    }
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

class CustomRangeTextInputFormatter extends TextInputFormatter {
  final int maxValue;

  CustomRangeTextInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == '') {
      return newValue;
    }
    int value = int.parse(newValue.text);
    if (value > maxValue) {
      return oldValue; // Reject the new value if it's greater than maxValue
    }
    return newValue;
  }
}

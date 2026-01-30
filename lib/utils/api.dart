import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:patrol_system/utils/utils.dart';
import '../encrypteddecrypted/encrypted_http_client.dart';
import '../encrypteddecrypted/encryption_config.dart';
import '../utils/constants.dart' as constants;
import '../utils/store_user_data.dart';

class Api {
  var version = 'api';
  var storeUserData = StoreUserData();
  var contentTypeKey = "Content-Type";
  var acceptKey = "Accept";

  Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers;
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      headers = {
        'Accept-Language': "EN",
        'Authorization': storeUserData.getString(constants.USER_TOKEN),
        acceptKey: "text/plain",
        contentTypeKey: "application/json"
      };
    } else {
      headers = {
        acceptKey: "text/plain",
        contentTypeKey: "application/json",
      };
    }
    print("headers : $headers");
    return headers;
  }

  callAPI(BuildContext context, String function,
      Map<String, dynamic>? fields) async {
    _logTokenIfPresent();
    final url = Uri.parse('${constants.baseUrl}$version/$function');
    final headers = await getHeaders();
    final requiresEncryption = EncryptionConfig.requiresEncryption(
      url.toString(),
      headers: headers,
      method: 'POST',
    );

    final response = await _makeApiCall(
      url,
      headers,
      fields,
      requiresEncryption,
    );

    _logResponse(response, fields);
    if (!context.mounted) return;
    return _handleApiResponse(response, context);
  }

  void _logTokenIfPresent() {
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      print("token  ${storeUserData.getString(constants.USER_TOKEN)}");
    }
  }

  Future<http.Response> _makeApiCall(
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic>? fields,
    bool requiresEncryption,
  ) async {
    if (requiresEncryption) {
      print("API URL is :- $url");
      final encryptedClient = EncryptedHttpClient();
      return await encryptedClient.post(
        url,
        headers: headers,
        body: jsonEncode(fields),
      );
    }
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(fields),
    );
  }

  void _logResponse(http.Response response, Map<String, dynamic>? fields) {
    print("${response.request!.url} ${response.statusCode}");
    print("fields : ${jsonEncode(fields)}");
  }

  String? _handleApiResponse(http.Response response, BuildContext context) {
    if (_isSuccessStatusCode(response.statusCode)) {
      return response.body;
    }
    if (response.statusCode == 500) {
      return _handleServerError(context);
    }
    return _handleOtherErrors(response, context);
  }

  bool _isSuccessStatusCode(int statusCode) {
    return statusCode == 200 || statusCode == 400;
  }

  String _handleServerError(BuildContext context) {
    if (!context.mounted) return "{\"message\":\"Internal Server Error\"}";
    Navigator.of(context).pop();
    Utils().showAlert(
      buildContext: context,
      message: "Internal Server Error",
      onPressed: () {},
    );
    return "{\"message\":\"Internal Server Error\"}";
  }

  String? _handleOtherErrors(http.Response response, BuildContext context) {
    if (isValidJson(response.body)) {
      return _handleValidJsonError(response, context);
    }
    return _handleInvalidJsonError(response, context);
  }

  String _handleValidJsonError(http.Response response, BuildContext context) {
    if (!context.mounted) return response.body;
    Utils().showAlert(
      buildContext: context,
      message: jsonDecode(response.body)["message"],
      onPressed: () {},
    );
    return response.body;
  }

  String? _handleInvalidJsonError(http.Response response, BuildContext context) {
    if (!context.mounted) return null;
    Utils().showAlert(
      buildContext: context,
      title: "StatusCode : ${response.statusCode}",
      message: "Response Null",
      onPressed: () {
        Get.back();
      },
    );
    return null;
  }

  bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  callAPIWithFiles(BuildContext context, String function,
      Map<String, String> fields, List<http.MultipartFile> files) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse('${constants.baseUrl}$version/$function'));
    request.fields.addAll(fields);
    final headers = await getHeaders();
    headers.remove(contentTypeKey);
    request.headers.addAll(headers);
    request.files.addAll(files);

    var response = await request.send();
    print("${response.request!.url} ${response.statusCode}");
    if (response.statusCode == 200) {
      var jsonResponse = await response.stream.bytesToString();
      return jsonResponse;
      // handle the JSON response here
    } else {
      return 'error';
    }
  }

  callAPIWithFile(BuildContext context, String function,
      Map<String, String> fields, http.MultipartFile files) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse('${constants.baseUrl}$version/$function'));
    request.fields.addAll(fields);
    final headers = await getHeaders();
    headers.remove(contentTypeKey);
    request.headers.addAll(headers);
    request.files.add(files);

    var response = await request.send();
    print(request.fields);
    print(files);
    print("${response.request!.url} ${response.statusCode}");

    if (response.statusCode == 200) {
      var jsonResponse = await response.stream.bytesToString();
      print(jsonResponse);
      return jsonResponse;
      // handle the JSON response here
    } else {
      return 'error';
    }
  }

  getAPI(BuildContext context, String function) async {
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      print("token  ${storeUserData.getString(constants.USER_TOKEN)}");
    }

    final url = Uri.parse('${constants.baseUrl}$version/$function');
    final headers = await getHeaders();

    // Check if encryption is required for this endpoint
    final requiresEncryption = EncryptionConfig.requiresEncryption(
      url.toString(),
      headers: headers,
      method: 'GET',
    );

    http.Response response;

    if (requiresEncryption) {
      // Use encrypted HTTP client for this endpoint
      final encryptedClient = EncryptedHttpClient();
      response = await encryptedClient.get(url, headers: headers);
    } else {
      // Use normal HTTP client
      response = await http.get(url, headers: headers);
    }

    print("${response.request!.url.toString()} ${response.statusCode}");

    if (response.statusCode == 200) {
      return response.body;
    } else {
      if (response.statusCode == 401) {
        if (!context.mounted) return;
        Utils().showAlert(
            buildContext: context,
            message: jsonDecode(response.body)["message"],
            onPressed: () {
              var deviceToken = StoreUserData().getString(constants.USER_FCM);
              StoreUserData().clearData();
              StoreUserData().setString(constants.USER_FCM, deviceToken);
              Navigator.pop(context);
              /*  Navigator.of(context).pushAndRemoveUntil(
                Utils().createRoute(const Login()),
                (route) => false, // This will clear the navigation stack.
              );*/
            });
        return "error";
      }
      if (response.statusCode != 422) {
        if (!context.mounted) return;
        Utils().showAlert(
            buildContext: context,
            message: jsonDecode(response.body)["message"],
            onPressed: () {
              Navigator.pop(context);
            });
      }

      return response.body;
    }
  }
}

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:patrol_system/utils/utils.dart';

import '../encrypteddecrypted/encrypted_http_client.dart';
import '../encrypteddecrypted/encryption_config.dart';
import '../utils/constants.dart' as constants;
import '../utils/store_user_data.dart';

class Api {
  var version = 'api';
  var storeUserData = StoreUserData();

  Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers;
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      headers = {
        'Accept-Language': "EN",
        'Authorization': storeUserData.getString(constants.USER_TOKEN),
        'Accept': "*/*",
        "Content-Type":"application/json"
      };
    } else {
      headers = {
        'accept': "text/plain",
        'Content-Type': "application/json",
      };
    }
    print("headers : $headers");
    return headers;
  }

  callAPI(BuildContext context, String function,
      Map<String, dynamic> fields) async {
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      print("token  ${storeUserData.getString(constants.USER_TOKEN)}");
    }
    
    final url = Uri.parse('${constants.baseUrl}$version/$function');
    final headers = await getHeaders();
    
    // Check if encryption is required for this endpoint
    final requiresEncryption = EncryptionConfig.requiresEncryption(
      url.toString(),
      headers: headers,
      method: 'POST',
    );


    http.Response response;
    
    if (requiresEncryption) {
      print("API URL is :- $url");
      // Use encrypted HTTP client for this endpoint
      final encryptedClient = EncryptedHttpClient();
      response = await encryptedClient.post(
        url,
        headers: headers,
        body: jsonEncode(fields),
      );

    } else {
      // Use normal HTTP client
      response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(fields),
      );
    }
    
    print("${response.request!.url} ${response.statusCode}");
    print("fields : ${jsonEncode(fields)}");

    if (response.statusCode == 200 || response.statusCode == 400) {
      return response.body;
    } else if (response.statusCode == 500) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      Utils().showAlert(
          buildContext: context,
          message: "Internal Server Error",
          onPressed: () {
            Navigator.of(context).pop();
          });
      return "{\"message\":\"Internal Server Error\"}";
    } else {
      if (isValidJson(response.body)) {
        if (!context.mounted) return;
        Utils().showAlert(
            buildContext: context,
            message: jsonDecode(response.body)["message"],
            onPressed: () {
              Navigator.of(context).pop();
            });
        return response.body;
      } else {
        if (!context.mounted) return;
        Utils().showAlert(
            buildContext: context,
            title: "StatusCode : ${response.statusCode}",
            message: "Response Null",
            onPressed: () {
              Navigator.of(context).pop();
            });
        return null;
      }
    }
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
    headers.remove('Content-Type');
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
    headers.remove('Content-Type');
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:patrol_system/model/profile_model.dart';
import 'package:patrol_system/pages/version_two/home_screen.dart';
import 'package:patrol_system/utils/api_service_dio.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/store_user_data.dart';

import '../controls/text.dart';
import '../controls/text_field.dart';
import '../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var isPassword = false;
  var isLoading = false;
  var storeUserData = StoreUserData();
  final _encryptAndDecrypt = EncryptAndDecrypt();

  final _userName = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _agentPassword = TextEditingController();

  // New: Track which login type is selected
  String loginType = "CID"; // options: "CID" or "Agent"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mainBackground,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Container(
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 50,
                ),
                height: 45,
                width: 45,
                decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: AppTheme.black,
                  size: 18,
                )),
          ),
          Center(
            child: SingleChildScrollView(
                child: Column(
              // mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CText(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  text: "Login to your \nAccount",
                  textColor: AppTheme.black,
                  fontFamily: AppTheme.urbanist,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(
                  height: 20,
                ),
                // Login Type Selection using Radio Buttons
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Radio<String>(
                            value: "CID",
                            groupValue: loginType,
                            activeColor: AppTheme.colorPrimary,
                            onChanged: (value) {
                              setState(() {
                                loginType = value!;
                              });
                            },
                          ),
                          const Text("CID Login",
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Radio<String>(
                            value: "Agent",
                            groupValue: loginType,
                            activeColor: AppTheme.colorPrimary,
                            onChanged: (value) {
                              setState(() {
                                loginType = value!;
                              });
                            },
                          ),
                          const Text("Agent Login",
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Show fields based on login type
                if (loginType == "CID") ...[
                  _buildTextField(
                      icon: "user.png",
                      hint: "Username",
                      controller: _userName,
                      obscureText: false),
                  const SizedBox(height: 20),
                  _buildTextField(
                      icon: "lock.png",
                      hint: "Password",
                      controller: _password,
                      obscureText: !isPassword,
                      showPasswordToggle: true),
                ] else ...[
                  _buildTextField(
                      icon: "email.png",
                      hint: "Email",
                      controller: _email,
                      obscureText: false),
                  const SizedBox(height: 20),
                  _buildTextField(
                      icon: "lock.png",
                      hint: "Password",
                      controller: _agentPassword,
                      obscureText: !isPassword,
                      showPasswordToggle: true),
                ],
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () async {
                      if ((loginType == "CID" &&
                              (_userName.text.isEmpty ||
                                  _password.text.isEmpty)) ||
                          (loginType == "Agent" &&
                              (_email.text.isEmpty ||
                                  _agentPassword.text.isEmpty))) {
                        Utils().showAlert(
                            buildContext: context,
                            title: "Alert",
                            message: "Please fill all the information.",
                            onPressed: () {
                              Navigator.of(context).pop();
                            });
                      } else {
                        if (await Utils().hasNetwork(context, setState)) {
                          setState(() {
                            isLoading = true;
                          });
                          if (loginType == "CID") {
                            login();
                          } else {
                            loginAgent();
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppTheme.colorPrimary,
                      minimumSize: const Size.fromHeight(63),
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                            color: AppTheme.white,
                          ))
                        : CText(
                            text: "Login",
                            textColor: AppTheme.white,
                            fontSize: AppTheme.big,
                            fontFamily: AppTheme.poppins,
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                ),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String icon,
      required String hint,
      required TextEditingController controller,
      required bool obscureText,
      bool showPasswordToggle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 63,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Image.asset(
            "$ASSET_PATH$icon",
            height: 17,
            width: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CTextField(
              obscureText: obscureText,
              textColor: AppTheme.textColor,
              hint: hint,
              fontSize: AppTheme.medium,
              maxLines: 1,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.poppins,
              controller: controller,
              focusedBorder: InputBorder.none,
              inputBorder: InputBorder.none,
            ),
          ),
          if (showPasswordToggle)
            IconButton(
              onPressed: () {
                setState(() {
                  isPassword = !isPassword;
                });
              },
              icon: Icon(
                isPassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> login() async {
    try {
      final payload = jsonEncode({
        "userName": _userName.text.toString(),
        "password": _password.text.toString()
      });

      final response = await _performEncryptedRequest(
        endpoint: '${baseUrl}api/Department/User/Login',
        payload: payload,
      );

      if (response == null) {
        _handleError("An error occurred. Please try again.");
        return;
      }

      if (response.statusCode != 200) {
        _handleError("Please enter valid credentials.");
        return;
      }

      final responseData = jsonDecode(response.body);
      final statusCode = responseData["statusCode"];
      final encryptedData = responseData["data"];
      final message = responseData["message"] ?? "";
      print("object $encryptedData");
      if (statusCode != 200 ||
          encryptedData == null ||
          encryptedData is! String) {
        _handleError(
            message.isNotEmpty ? message : "Please enter valid credentials.");
        return;
      }

      final decryptedData =
          await _encryptAndDecrypt.decryption(payload: encryptedData);
      debugPrint("decryptedData $decryptedData");
      if (decryptedData.isEmpty) {
        _handleError("Please enter valid credentials.");
        return;
      }

      final profileData = profileFromJson(decryptedData);
      if (profileData.data == null) {
        _handleError("Please enter valid credentials.");
        return;
      }

      storeUserData.setString(
          USER_TOKEN, "Bearer ${profileData.data!.accessToken}");
      _handleSuccessfulLogin(
        userId: profileData.data!.departmentUserMasterId,
        designationId: profileData.data!.designationId,
        userName: profileData.data!.userName,
        name: profileData.data!.name,
        mobileNumber: profileData.data!.mobileNumber,
        badgeNumber: profileData.data!.badgeNumber,
        isAgentLogin: false,
      );
    } catch (_) {
      _handleError("An error occurred. Please try again.");
    }
  }

  Future<void> loginAgent() async {
    try {
      final payload = jsonEncode({
        "emailId": _email.text.toString(),
        "password": _agentPassword.text.toString(),
        "agentId": "1",
      });

      print("Original Payload $payload");

      final response = await _performEncryptedRequest(
        endpoint: '${baseUrl}api/Agent/Employee/Login',
        payload: payload,
      );

      /* if (kDebugMode) {
        print("encrypted response ${response?.body}");
        print("encryptedPayload ${response?.request?.url}");
      }*/
      if (response == null) {
        _handleError("An error occurred. Please try again.");
        return;
      }

      debugPrint(" LOGIN:- ${response.body}");
      if (response.statusCode != 200) {
        _handleError("Please enter valid credentials.");
        return;
      }

      final responseData = jsonDecode(response.body);
      final statusCode = responseData["statusCode"];
      final encryptedData = responseData["data"];
      final message = responseData["message"] ?? "";


      if (statusCode != 200 ||
          encryptedData == null ||
          encryptedData is! String) {
        _handleError(
            message.isNotEmpty ? message : "Please enter valid credentials.");
        return;
      }


      final decryptedData =
          await _encryptAndDecrypt.decryption(payload: encryptedData);

      if (decryptedData.isEmpty) {
        _handleError("Please enter valid credentials.");
        return;
      }

      final data = jsonDecode(decryptedData);
      if (data == null) {
        _handleError("Please enter valid credentials.");
        return;
      }

      storeUserData.setString(
          USER_TOKEN, "Bearer ${data["AccessToken"]}");

      _handleSuccessfulLogin(
        userId: data["AgentEmployeeId"],
        designationId: data["AgentId"],
        userName: data["AgentName"],
        name: data["AgentName"],
        badgeNumber: "0",
        isAgentLogin: true,
      );
    } catch (_) {
      _handleError("An error occurred. Please try again.");
    }
  }

  Future<http.Response?> _performEncryptedRequest({
    required String endpoint,
    required String payload,
  }) async {
    try {
      final encryptedPayload = await _encryptAndDecrypt.encryption(
        payload: payload,
        urlEncode: false,
      );

      if (kDebugMode) {
        print("encryptedPayload $encryptedPayload");
      }
      return await http.post(
        Uri.parse(endpoint),
        headers: {
          'accept': "text/plain",
          'Content-Type': "application/json-patch+json",
        },
        body: jsonEncode(encryptedPayload),
      );
    } catch (_) {
      return null;
    }
  }

  void _handleSuccessfulLogin({
    required int userId,
    required int designationId,
    required String userName,
    required String name,
    String? mobileNumber,
    required String badgeNumber,
    required bool isAgentLogin,
  }) {
    setState(() {
      isLoading = false;
      storeUserData.setInt(USER_ID, userId);
      storeUserData.setInt(USER_DESIGNATION_ID, designationId);
      storeUserData.setString(USER_NAME, userName);
      storeUserData.setString(NAME, name);
      if (mobileNumber != null) {
        storeUserData.setString(USER_MOBILE, mobileNumber);
      }
      storeUserData.setString(USER_BADGE_NUMBER, badgeNumber);
      storeUserData.setBoolean(IS_AGENT_LOGIN, isAgentLogin);
      unawaited(ApiServiceDio.instance.fcmTokenSend());
      Get.offAll(transition: Transition.rightToLeft, const HomeScreen());
    });
  }

  void _handleError(String message) {
    setState(() {
      isLoading = false;
    });
    Utils().showAlert(
      buildContext: context,
      message: message,
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}

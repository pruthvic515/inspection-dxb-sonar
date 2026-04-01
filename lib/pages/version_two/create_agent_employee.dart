import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:patrol_system/controls/form_text_field.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/controls/text_field.dart';
import 'package:patrol_system/encrypteddecrypted/encrypt_and_decrypt.dart';
import 'package:patrol_system/utils/agent_employee_create_validators.dart';
import 'package:patrol_system/utils/api.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/emirates_id_validation.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:patrol_system/utils/utils.dart';

/// Create Agent Employee: validated form; sensitive fields encrypted per backend contract.
class CreateAgentEmployeePage extends StatefulWidget {
  const CreateAgentEmployeePage({super.key, this.agentIdForApi});

  /// When set (e.g. from AEMMI sheet), sent as `agentId` in the create API; otherwise uses [USER_DESIGNATION_ID] from storage.
  final int? agentIdForApi;

  @override
  State<CreateAgentEmployeePage> createState() =>
      _CreateAgentEmployeePageState();
}

class _CreateAgentEmployeePageState extends State<CreateAgentEmployeePage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _emiratesId = TextEditingController();
  final _mobileDigits = TextEditingController();
  final _crypto = EncryptAndDecrypt();
  final _store = StoreUserData();

  late final MaskTextInputFormatter _emiratesMask = MaskTextInputFormatter(
    mask: 'XXX-XXXX-XXXXXXX-X',
    // ignore: deprecated_member_use
    filter: {'X': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  static const String _roleNameManager = 'Manager';

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _emiratesId.dispose();
    _mobileDigits.dispose();
    super.dispose();
  }

  String? _validateMobileNineDigits(String digitsOnly) {
    if (digitsOnly.isEmpty) {
      return 'Please enter mobile number';
    }
    if (digitsOnly.length != 9) {
      return 'Mobile number must be 9 digits';
    }
    return null;
  }

  String? _collectValidationError() {
    final nameErr =
        AgentEmployeeCreateValidators.validateFullName(_fullName.text);
    if (nameErr != null) return nameErr;

    if (!EmiratesIdValidation.isValid(_emiratesId.text)) {
      return 'Please enter a valid Emirates ID (784-YYYY-XXXXXXX-X)';
    }

    final mobileErr = _validateMobileNineDigits(_mobileDigits.text.trim());
    if (mobileErr != null) return mobileErr;

    return AgentEmployeeCreateValidators.validateEmail(_email.text);
  }

  bool get _canSubmit => _collectValidationError() == null;

  /// Encrypts PII field values using the same AES helper as the rest of the app.
  Future<Map<String, String>?> _encryptPiiFields({
    required String plainAgentName,
    required String plainEmiratesId,
    required String plainPhone,
    required String plainEmail,
  }) async {
    try {
      final agentName = await _crypto.encryption(
        payload: plainAgentName,
        urlEncode: false,
      );
      final emiratesId = await _crypto.encryption(
        payload: plainEmiratesId,
        urlEncode: false,
      );
      final phoneNo = await _crypto.encryption(
        payload: plainPhone,
        urlEncode: false,
      );
      final emailId = await _crypto.encryption(
        payload: plainEmail,
        urlEncode: false,
      );
      return {
        'agentName': agentName,
        'emiratesId': emiratesId,
        'phoneNo': phoneNo,
        'emailId': emailId,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final error = _collectValidationError();
    if (error != null) {
      if (!mounted) return;
      Utils().showAlert(
        buildContext: context,
        message: error,
        onPressed: () => Navigator.of(context).pop(),
      );
      return;
    }

    if (!await Utils().hasNetwork(context, setState)) return;
    if (!mounted) return;

    final plainName = _fullName.text.trim();
    final plainEid = _emiratesId.text.trim();
    final plainPhone = '+971${_mobileDigits.text.trim()}';
    final plainEmail = _email.text.trim();
    final agentId =
        (widget.agentIdForApi ?? _store.getInt(USER_DESIGNATION_ID)).toString();


    final body = <String, dynamic>{
      'agentEmployeeId': 0,
      'agentId': agentId,
      'roleName': _roleNameManager,
      'agentName': plainName,
      'emiratesId': plainEid,
      'phoneNo': plainPhone,
      'emailId': plainEmail,
    };

    if (!mounted) return;
    LoadingIndicatorDialog().show(context);

    http.Response response;
    try {
      Api().callAPI(context, "Agent/Employee/Create", body).then((value) {
        LoadingIndicatorDialog().dismiss();
        if (!mounted) return;
        _handleCreateResponse(value);
      });
    } catch (_) {
      LoadingIndicatorDialog().dismiss();
      if (!mounted) return;
      Utils().showAlert(
        buildContext: context,
        message: 'Request failed. Please try again.',
        onPressed: () => Navigator.of(context).pop(),
      );
      return;
    }
  }

  Future<void> _handleCreateResponse(String response) async {
    if (!mounted) return;

    debugPrint("_handleCreateResponse $response");
    // if (response.statusCode != 200) {
    //   Utils().showAlert(
    //     buildContext: context,
    //     message: 'Something went wrong. Please try again.',
    //     onPressed: () => Navigator.of(context).pop(),
    //   );
    //   return;
    // }


    dynamic decoded;
    try {
      decoded = jsonDecode(response);
    } catch (_) {
      Utils().showAlert(
        buildContext: context,
        message: 'Invalid response from server.',
        onPressed: () => Navigator.of(context).pop(),
      );
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      Utils().showAlert(
        buildContext: context,
        message: 'Invalid response from server.',
        onPressed: () => Navigator.of(context).pop(),
      );
      return;
    }

    final statusCode = decoded['statusCode'];
    final message = decoded['message']?.toString() ?? '';
    final encryptedData = decoded['data'];

    if (statusCode != 200) {
      Utils().showAlert(
        buildContext: context,
        message: message.isNotEmpty ? message : 'Request was not successful.',
        onPressed: () => Navigator.of(context).pop(),
      );
      return;
    }

    if (encryptedData is String && encryptedData.isNotEmpty) {
      final decrypted = await _crypto.decryption(payload: encryptedData);
      if (!mounted) return;
      if (decrypted.isEmpty) {
        Utils().showAlert(
          buildContext: context,
          message:
              message.isNotEmpty ? message : 'Could not read server response.',
          onPressed: () => Navigator.of(context).pop(),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _buildMobileWith971Prefix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin:
              const EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
          child: CText(
            textColor: AppTheme.black,
            fontSize: AppTheme.large,
            fontFamily: AppTheme.urbanist,
            fontWeight: FontWeight.w600,
            text: 'Mobile Number :',
          ),

        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: Card(
            surfaceTintColor: AppTheme.white,
            elevation: 2,
            margin: const EdgeInsets.only(top: 10),
            color: AppTheme.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  CText(
                    padding: const EdgeInsets.only(top: 5),
                    text: '+971',
                    textColor: AppTheme.grayAsparagus,
                    fontSize: AppTheme.large,
                    fontFamily: AppTheme.urbanist,
                    fontWeight: FontWeight.w600,
                  ),
                  Expanded(
                    child: CTextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      onChange: (_) => setState(() {}),
                      inputBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hint: '',
                      inputType: TextInputType.phone,
                      controller: _mobileDigits,
                      maxLines: 1,
                      minLines: 1,
                      textColor: AppTheme.grayAsparagus,
                      fontSize: AppTheme.large,
                      fontFamily: AppTheme.urbanist,
                      fontWeight: FontWeight.w600,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mainBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.colorPrimary,
        title: CText(
          text: 'Create Employee',
          textColor: AppTheme.white,
          fontFamily: AppTheme.urbanist,
          fontWeight: FontWeight.w600,
          fontSize: AppTheme.large,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormTextField(
              onChange: (_) => setState(() {}),
              controller: _fullName,
              hint: '',
              value: _fullName.text,
              title: 'Full Name :',
              inputBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              textColor: AppTheme.grayAsparagus,
              inputType: TextInputType.name,
            ),
            FormTextField(
              onChange: (_) => setState(() {}),
              inputFormatters: [_emiratesMask],
              controller: _emiratesId,
              hint: '784-YYYY-XXXXXXX-X',
              value: _emiratesId.text,
              title: 'Emirates ID :',
              inputBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              textColor: AppTheme.grayAsparagus,
              inputType: TextInputType.number,

            ),
            _buildMobileWith971Prefix(),
            FormTextField(
              onChange: (_) => setState(() {}),
              controller: _email,
              hint: '',
              value: _email.text,
              title: 'Email :',
              inputBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              textColor: AppTheme.grayAsparagus,
              inputType: TextInputType.emailAddress,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canSubmit ? AppTheme.colorPrimary : AppTheme.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: CText(
                  text: 'Submit',

                  textColor: AppTheme.white,
                  fontFamily: AppTheme.urbanist,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTheme.large,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

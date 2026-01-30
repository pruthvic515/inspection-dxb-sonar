import 'package:flutter/material.dart';
import 'package:patrol_system/controls/text_field_password.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart' as constants;
import '../utils/constants.dart';
import 'text.dart';

class FormPasswordTextField extends StatelessWidget {
  String title;
  String? hint = '';
  String? value = '';
  TextEditingController? controller;
  TextInputType? inputType = TextInputType.name;
  bool? enabled;
  VoidCallback? onTap;
  int? maxLines;
  Color? textColor;
  double? fontSize;
  FontWeight? fontWeight;
  String? fontFamily;

  // isPassword: !_isPasswordVisible,
  // controller: _passwordCtl,
  IconButton? suffixIcon;
  bool? isPassword;
  TextAlign? textAlign;
  InputBorder? inputBorder;

  FormPasswordTextField(
      {super.key,
      required this.title,
      this.hint,
      this.value,
      this.enabled,
      this.controller,
      this.onTap,
      this.inputType,
      this.textAlign,
      this.fontSize,
      this.fontWeight,
      this.inputBorder,
      this.fontFamily,
      this.suffixIcon,
      this.isPassword,
      this.textColor,
      this.maxLines});

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    hint = hint ?? "";
    final isLargeScreen = currentWidth > SIZE_600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(isLargeScreen),
        onTap == null
            ? _buildEditableField(isLargeScreen)
            : _buildReadOnlyField(isLargeScreen),
      ],
    );
  }

  Widget _buildTitle(bool isLargeScreen) {
    final topMargin = isLargeScreen ? 20.0 : 10.0;
    final horizontalMargin = isLargeScreen ? 15.0 : 10.0;

    return Container(
      margin: EdgeInsets.only(
        top: topMargin,
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: CText(
        textColor: textColor ?? AppTheme.black,
        fontSize: fontSize ?? AppTheme.large,
        fontFamily: fontFamily ?? AppTheme.urbanist,
        fontWeight: fontWeight ?? FontWeight.w300,
        text: title,
      ),
    );
  }

  Widget _buildEditableField(bool isLargeScreen) {
    final horizontalMargin = isLargeScreen ? 15.0 : 10.0;
    final topMargin = isLargeScreen ? 15.0 : 10.0;
    final borderRadius = isLargeScreen ? 10.0 : 5.0;

    return Container(
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(top: topMargin),
        color: AppTheme.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        child: CTextFieldPassword(
          inputBorder: inputBorder,
          enabled: enabled,
          hint: hint,
          inputType: inputType,
          textAlign: textAlign ?? TextAlign.start,
          controller: controller,
          textColor: textColor ?? AppTheme.black,
          fontSize: fontSize ?? AppTheme.large,
          fontFamily: fontFamily ?? AppTheme.poppins,
          fontWeight: fontWeight ?? FontWeight.w300,
          isPassword: isPassword,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(bool isLargeScreen) {
    final horizontalMargin = isLargeScreen ? 15.0 : 10.0;
    final displayText = (value == null || value!.isEmpty) ? hint! : value!;
    final fontSizeValue = isLargeScreen ? AppTheme.medium : AppTheme.small;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          bottom: BorderSide(width: 1, color: AppTheme.grey),
        ),
      ),
      width: double.infinity,
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: InkWell(
        highlightColor: AppTheme.transparent,
        splashColor: AppTheme.transparent,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                child: CText(
                  fontFamily: AppTheme.poppins,
                  fontSize: fontSizeValue,
                  text: displayText,
                ),
              ),
            ),
            Image.asset(
              '${constants.ASSET_PATH}right_arrow.png',
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}

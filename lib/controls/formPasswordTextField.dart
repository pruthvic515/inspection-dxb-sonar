import 'package:flutter/material.dart';
import 'package:patrol_system/controls/textfieldpassword.dart';

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
    var currentWidth = MediaQuery.of(context).size.width;
    hint = hint ?? "";
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
                top: currentWidth > SIZE_600 ? 20 : 10,
                left: currentWidth > SIZE_600 ? 15 : 10,
                right: currentWidth > SIZE_600 ? 15 : 10),
            child: CText(
              textColor: textColor ?? AppTheme.black,
              fontSize: fontSize ?? AppTheme.large,
              fontFamily: fontFamily ?? AppTheme.Urbanist,
              fontWeight: fontWeight ?? FontWeight.w300,
              text: title,
              // fontWeight: FontWeight.w400,
              // textColor: AppTheme.black,
              // fontSize: currentWidth > SIZE_600 ? 16 : 12
            ),
          ),
          onTap == null
              ? Container(
                  margin: EdgeInsets.only(
                      left: currentWidth > SIZE_600 ? 15 : 10,
                      right: currentWidth > SIZE_600 ? 15 : 10),
                  child: Card(
                      elevation: 0,
                      margin: EdgeInsets.only(
                          top: currentWidth > SIZE_600 ? 15 : 10),
                      color: AppTheme.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(
                              currentWidth > SIZE_600 ? 10 : 5))),
                      child: CTextFieldPassword(
                        inputBorder: inputBorder,
                        enabled: enabled,
                        hint: hint,
                        inputType: inputType,
                        textAlign:
                            textAlign == null ? TextAlign.start : textAlign!,
                        controller: controller,
                        // maxLines: maxLines ?? 1,
                        textColor: textColor ?? AppTheme.black,
                        fontSize: fontSize ?? AppTheme.large,
                        fontFamily: fontFamily ?? AppTheme.Poppins,
                        fontWeight: fontWeight ?? FontWeight.w300,
                        isPassword: isPassword,
                        suffixIcon: suffixIcon,
                      )))
              : Container(
                  decoration: const BoxDecoration(
                      color: AppTheme.white,
                      border: Border(
                          bottom: BorderSide(width: 1, color: AppTheme.grey))),
                  width: double.infinity,
                  margin: EdgeInsets.only(
                      left: currentWidth > SIZE_600 ? 15 : 10,
                      right: currentWidth > SIZE_600 ? 15 : 10),
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
                              fontFamily: AppTheme.Poppins,
                              fontSize: currentWidth > SIZE_600
                                  ? AppTheme.medium
                                  : AppTheme.small,
                              text: value == null || value!.isEmpty
                                  ? hint!
                                  : value!,
                            ),
                          ),
                        ),
                        Image.asset('${constants.ASSET_PATH}right_arrow.png',
                            height: 15)
                      ],
                    ),
                  ),
                ),
        ]);
  }
}

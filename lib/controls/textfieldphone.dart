import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/color_const.dart';

class CTextFieldPhone extends StatelessWidget {
  String? hint = "";
  Color? textColor;
  double? fontSize;
  FontWeight? fontWeight;
  TextEditingController? controller;
  TextInputType? inputType = TextInputType.name;
  TextAlign? textAlign;
  List<TextInputFormatter>? inputFormatters;
  bool? enabled;
  int? maxLines;
  int? maxLength;
  TextInputAction? textInputAction;
  InputBorder? inputBorder;
  Function(String)? onSubmitted;
  int? minLines;
  ValueChanged<String>? onChange;
  String? fontFamily;

  CTextFieldPhone(
      {super.key,
      required this.hint,
      this.textColor,
      this.fontSize,
      this.fontWeight,
      this.controller,
      this.inputType,
      this.textAlign,
      this.inputFormatters,
      this.enabled,
      this.maxLines,
      this.textInputAction,
      this.onSubmitted,
      this.inputBorder,
      this.minLines,
      this.maxLength,
      this.onChange,
      this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLength: maxLength,
      onChanged: onChange,
      minLines: minLines,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      controller: controller,
      cursorColor: AppTheme.orange,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(2),
      inputFormatters: inputFormatters,
      textAlign: textAlign == null ? TextAlign.start : textAlign!,
      style: TextStyle(
          fontFamily: fontFamily == null ? AppTheme.Poppins : fontFamily!,
          fontWeight: fontWeight == null ? FontWeight.w300 : fontWeight!,
          color: textColor ?? AppTheme.black,
          fontSize: fontSize ?? AppTheme.medium),
      keyboardType: inputType,
      decoration: InputDecoration(
          border: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.green),
            borderRadius: BorderRadius.circular(5.0),
          ),
          contentPadding:
              const EdgeInsets.only(top: 5.0, left: 80, right: 5, bottom: 5.0),
          hintText: hint,
          counterText: "",
          hintStyle: TextStyle(
              fontFamily: fontFamily == null ? AppTheme.Poppins : fontFamily!,
              fontWeight: fontWeight == null ? FontWeight.w300 : fontWeight!,
              color: textColor ?? AppTheme.black,
              fontSize: fontSize ?? AppTheme.medium)),
      enabled: enabled,
    );
  }
}

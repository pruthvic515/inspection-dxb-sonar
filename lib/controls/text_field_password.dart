import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_const.dart';

class CTextFieldPassword extends StatelessWidget {
  String? hint = "";
  Color? textColor;
  double? fontSize;
  FontWeight? fontWeight;
  TextEditingController? controller;
  TextInputType? inputType = TextInputType.name;
  TextAlign? textAlign;
  List<TextInputFormatter>? inputFormatters;
  bool? enabled;

  // int? maxLines;
  int? maxLength;
  TextInputAction? textInputAction;
  InputBorder? inputBorder;
  Function(String)? onSubmitted;
  int? minLines;
  ValueChanged<String>? onChange;
  String? fontFamily;
  IconButton? suffixIcon;
  bool? isPassword;

  CTextFieldPassword(
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
      this.textInputAction,
      this.onSubmitted,
      this.inputBorder,
      this.minLines,
      this.maxLength,
      this.onChange,
      this.suffixIcon,
      this.isPassword,
      this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword!,
      maxLength: maxLength,
      onChanged: onChange,
      minLines: minLines,
      cursorColor: AppTheme.orange,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(2),
      textInputAction: textInputAction,
      // maxLines: maxLines,
      onSubmitted: onSubmitted,
      controller: controller,
      inputFormatters: inputFormatters,
      textAlign: textAlign == null ? TextAlign.start : textAlign!,
      style: TextStyle(
          fontFamily: fontFamily == null ? AppTheme.poppins : fontFamily!,
          fontWeight: fontWeight == null ? FontWeight.w300 : fontWeight!,
          color: textColor ?? AppTheme.black,
          fontSize: fontSize ?? AppTheme.medium),
      keyboardType: inputType,
      decoration: InputDecoration(
          border: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.teal),
            borderRadius: BorderRadius.circular(5.0),
          ),
          contentPadding: const EdgeInsets.all(5.0),
          hintText: hint,
          counterText: "",
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(
              fontFamily: fontFamily == null ? AppTheme.poppins : fontFamily!,
              fontWeight: fontWeight == null ? FontWeight.w300 : fontWeight!,
              color: textColor ?? AppTheme.black,
              fontSize: fontSize ?? AppTheme.medium)),
      enabled: enabled,
    );
  }
}

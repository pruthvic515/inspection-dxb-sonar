import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_const.dart';

class CTextField extends StatefulWidget {
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
  InputBorder? focusedBorder;
  Function(String)? onSubmitted;
  int? minLines;
  ValueChanged<String>? onChange;
  String? fontFamily;
  TextCapitalization? textCapitalization = TextCapitalization.none;
  FocusNode? focusNode;
  bool? obscureText;

  CTextField({
    super.key,
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
    this.textCapitalization,
    this.textInputAction,
    this.onSubmitted,
    this.inputBorder,
    this.focusedBorder,
    this.minLines,
    this.maxLength,
    this.onChange,
    this.fontFamily,
    this.focusNode,
    this.obscureText,
  });

  @override
  State<CTextField> createState() => _CTextFieldState();
}

class _CTextFieldState extends State<CTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: widget.obscureText ?? false,
      focusNode: widget.focusNode,
      maxLength: widget.maxLength,
      onChanged: widget.onChange,
      minLines: widget.minLines,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      onSubmitted: widget.onSubmitted,
      controller: widget.controller,
      cursorRadius: const Radius.circular(2),
      cursorColor: AppTheme.colorPrimary,
      // change cursor color
      cursorWidth: 2,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign == null ? TextAlign.start : widget.textAlign!,
      style: TextStyle(
          fontFamily:
              widget.fontFamily == null ? AppTheme.poppins : widget.fontFamily!,
          fontWeight:
              widget.fontWeight == null ? FontWeight.w300 : widget.fontWeight!,
          color: widget.textColor ?? AppTheme.black,
          fontSize: widget.fontSize ?? AppTheme.medium),
      keyboardType: widget.inputType,
      decoration: InputDecoration(
          filled: false,
          border: widget.inputBorder,
          focusedBorder: widget.focusedBorder ??
              OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.black),
                borderRadius: BorderRadius.circular(5.0),
              ),
          contentPadding: const EdgeInsets.all(5.0),
          hintText: widget.hint,
          counterText: "",
          hintStyle: TextStyle(
              fontFamily: widget.fontFamily == null
                  ? AppTheme.poppins
                  : widget.fontFamily!,
              fontWeight: widget.fontWeight == null
                  ? FontWeight.w300
                  : widget.fontWeight!,
              color: widget.textColor ?? AppTheme.black,
              fontSize: widget.fontSize ?? AppTheme.medium)),
      enabled: widget.enabled,
    );
  }
}

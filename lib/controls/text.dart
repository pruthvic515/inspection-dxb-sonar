import 'package:flutter/material.dart';

import '../utils/color_const.dart';

class CText extends StatelessWidget {
  String text;
  Color? textColor;
  Color? backgroundColor;
  double? fontSize;
  FontWeight? fontWeight;
  TextAlign? textAlign;
  EdgeInsetsGeometry? padding;
  TextOverflow? overflow;
  int? maxLines;
  String? fontFamily;
  TextDecoration? decoration;
  List<Shadow>? shadows;

  CText({
    super.key,
    required this.text,
    this.textColor,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.padding,
    this.overflow,
    this.maxLines,
    this.fontFamily,
    this.shadows,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding == null ? EdgeInsets.zero : padding!,
      child: Text(text,
          overflow: overflow,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
          textAlign: textAlign ?? TextAlign.start,
          style: TextStyle(
              decoration: decoration ?? decoration,
              fontWeight: fontWeight ?? fontWeight,
              fontFamily: fontFamily ?? AppTheme.Urbanist,
              backgroundColor: backgroundColor,
              color: textColor ?? AppTheme.black,
              shadows: shadows ?? shadows,
              fontSize: fontSize ?? AppTheme.medium)),
    );
  }
}

import 'package:flutter/material.dart';
import '../controls/text.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart';

class CButton extends StatelessWidget {
  String text;
  VoidCallback function;
  Color? textColor;
  double? fontSize;
  FontWeight? fontWeight;
  Color? color;
  double? elevation;

  CButton(
      {super.key,
      required this.text,
      required this.function,
      this.textColor,
      this.fontSize,
      this.fontWeight,
      this.elevation,
      this.color});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: elevation == null ? 3.0 : elevation!,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      padding:
          EdgeInsets.all(MediaQuery.of(context).size.width > SIZE_600 ? 10 : 5),
      onPressed: function,
      color: color == null ? AppTheme.colorPrimary : color!,
      splashColor: AppTheme.colorPrimary,
      disabledColor: AppTheme.grey,
      disabledTextColor: AppTheme.black,
      child: CText(
        text: text,
        textColor: textColor == null ? AppTheme.white : textColor!,
        fontWeight: fontWeight == null ? FontWeight.w500 : fontWeight!,
        fontSize: fontSize == null ? AppTheme.medium : fontSize!,
      ),
    );
  }
}

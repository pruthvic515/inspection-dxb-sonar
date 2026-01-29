import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controls/text_field.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart' as constants;
import '../utils/constants.dart';
import 'text.dart';

class FormTextField extends StatelessWidget {
  String title;
  String? hint = '';
  String? value = '';
  TextEditingController? controller;
  TextInputType? inputType = TextInputType.name;
  bool? enabled;
  VoidCallback? onTap;
  int? maxLines;
  int? minLines;
  Color? textColor;
  double? fontSize;
  FontWeight? fontWeight;
  String? fontFamily;
  InputBorder? inputBorder;
  InputBorder? focusedBorder;
  FocusNode? focusNode;
  ValueChanged<String>? onChange;
  List<TextInputFormatter>? inputFormatters;
  Color? cardColor;
  bool? hideIcon;
  Widget? titleWidget;

  FormTextField(
      {super.key,
      required this.title,
      this.hint,
      this.value,
      this.enabled,
      this.controller,
      this.onTap,
      this.inputType,
      this.fontSize,
      this.fontWeight,
      this.fontFamily,
      this.textColor,
      this.minLines,
      this.maxLines,
      this.inputBorder,
      this.focusedBorder,
      this.focusNode,
      this.onChange,
      this.inputFormatters,
      this.cardColor,
      this.hideIcon,
      this.titleWidget});

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
    final margin = isLargeScreen ? 20.0 : 10.0;
    final horizontalMargin = isLargeScreen ? 15.0 : 10.0;

    return Container(
      margin: EdgeInsets.only(
        bottom: margin,
        top: margin,
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CText(
              textColor: AppTheme.black,
              fontSize: fontSize ?? AppTheme.large,
              fontFamily: fontFamily ?? AppTheme.urbanist,
              fontWeight: fontWeight ?? FontWeight.w600,
              text: title,
            ),
          ),
          titleWidget ?? Container(),
        ],
      ),
    );
  }

  Widget _buildEditableField(bool isLargeScreen) {
    final horizontalMargin = isLargeScreen ? 15.0 : 10.0;
    final topMargin = isLargeScreen ? 15.0 : 10.0;
    final padding = isLargeScreen ? 10.0 : 5.0;
    final textCapitalization = inputType == TextInputType.name
        ? TextCapitalization.words
        : TextCapitalization.none;

    return Container(
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      child: Card(
        surfaceTintColor: cardColor ?? AppTheme.white,
        elevation: 2,
        margin: EdgeInsets.only(top: topMargin),
        color: cardColor ?? AppTheme.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: CTextField(
            inputFormatters: inputFormatters,
            onChange: onChange,
            focusedBorder: focusedBorder ?? InputBorder.none,
            inputBorder: inputBorder ?? InputBorder.none,
            enabled: enabled,
            hint: hint,
            focusNode: focusNode,
            inputType: inputType,
            controller: controller,
            maxLines: maxLines ?? 1,
            minLines: minLines ?? 1,
            textColor: textColor ?? AppTheme.textColor,
            fontSize: fontSize ?? AppTheme.large,
            fontFamily: fontFamily ?? AppTheme.urbanist,
            fontWeight: fontWeight ?? FontWeight.w600,
            textCapitalization: textCapitalization,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(bool isLargeScreen) {
    final margin = isLargeScreen ? 15.0 : 10.0;
    final displayText = (value == null || value!.isEmpty) ? hint! : value!;
    final arrowIcon = _buildArrowIcon();

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        top: margin,
        left: margin,
        right: margin,
      ),
      surfaceTintColor: cardColor ?? AppTheme.white,
      color: cardColor ?? AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: CText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                  textColor: textColor ?? AppTheme.textColor,
                  fontSize: fontSize ?? AppTheme.large,
                  fontFamily: fontFamily ?? AppTheme.urbanist,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  text: displayText,
                ),
              ),
              arrowIcon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrowIcon() {
    if (hideIcon == true) {
      return Container();
    }

    return Image.asset(
      '${constants.ASSET_PATH}arrow_down.png',
      height: 15,
      color: AppTheme.colorPrimary,
      width: 15,
    );
  }
}

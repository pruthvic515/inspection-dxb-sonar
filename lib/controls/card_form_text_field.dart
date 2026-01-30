import 'package:flutter/material.dart';
import '../controls/text_field.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart' as constants;
import '../utils/layout_values.dart';
import 'text.dart';

class CardFormTextField extends StatelessWidget {
  String title;
  String? hint = '';
  String? value = '';
  TextEditingController? controller;
  TextInputType? inputType = TextInputType.name;
  bool? enabled;
  VoidCallback? onTap;
  int? maxLines;
  int? minLine;
  Color? textColor;
  Color? formTextColor;
  double? fontSize;
  double? formTextFontSize;
  FontWeight? fontWeight;
  FontWeight? formTextFontWeight;
  String? formTextFontFamily;
  String? fontFamily;
  bool? isShowDropDownArrow;

  CardFormTextField({
    super.key,
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
    this.maxLines,
    this.minLine,
    this.formTextColor,
    this.formTextFontSize,
    this.formTextFontWeight,
    this.formTextFontFamily,
    this.isShowDropDownArrow,
  });

  @override
  Widget build(BuildContext context) {
    var currentWidth = MediaQuery.of(context).size.width;
    final layout = LayoutValues.fromWidth(currentWidth);

    hint = hint ?? "";
    final displayText = (value == null || value!.isEmpty) ? hint! : value!;
    final textCapitalization = inputType == TextInputType.name
        ? TextCapitalization.words
        : TextCapitalization.none;
    final arrowIcon = isShowDropDownArrow == true
        ? Image.asset(
            '${constants.ASSET_PATH}arrow_down.png',
            height: 25,
            width: 20,
          )
        : const SizedBox();
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
                bottom: layout.vertical,
                top: layout.vertical,
                left: layout.horizontal,
                right: layout.horizontal),
            child: CText(
              textColor: textColor ?? AppTheme.black,
              fontSize: fontSize ?? AppTheme.large,
              fontFamily: fontFamily ?? AppTheme.urbanist,
              fontWeight: fontWeight ?? FontWeight.w700,
              text: title,
              // fontWeight: FontWeight.w400,
              // textColor: AppTheme.black,
              // fontSize: currentWidth > SIZE_600 ? 16 : 12
            ),
          ),
          onTap == null
              ? Container(
                  margin: EdgeInsets.only(
                      left: layout.horizontal, right: layout.horizontal),
                  child: Card(
                      elevation: 2,
                      surfaceTintColor: AppTheme.white,
                      color: AppTheme.white,
                      margin: EdgeInsets.only(top: layout.cardTop),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 15, left: 10, top: 5, right: 10),
                        child: CTextField(
                          inputBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabled: enabled,
                          hint: hint,
                          inputType: inputType,
                          controller: controller,
                          maxLines: maxLines ?? 1,
                          minLines: minLine ?? 1,
                          textColor: formTextColor ?? AppTheme.textColor,
                          fontSize: formTextFontSize ?? AppTheme.large,
                          fontFamily: formTextFontFamily ?? AppTheme.urbanist,
                          fontWeight: formTextFontWeight ?? FontWeight.w600,
                          textCapitalization: textCapitalization,
                        ),
                      )))
              : Container(
                  margin: EdgeInsets.only(
                      left: layout.horizontal, right: layout.horizontal),
                  child: Card(
                    elevation: 2,
                    margin: EdgeInsets.only(top: layout.cardTop),
                    surfaceTintColor: AppTheme.white,
                    color: AppTheme.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: InkWell(
                      highlightColor: AppTheme.transparent,
                      splashColor: AppTheme.transparent,
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 25, left: 10, top: 15, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: CText(
                                textColor: formTextColor ?? AppTheme.textColor,
                                fontSize: formTextFontSize ?? AppTheme.large,
                                fontFamily:
                                    formTextFontFamily ?? AppTheme.urbanist,
                                fontWeight:
                                    formTextFontWeight ?? FontWeight.w600,
                                text: displayText,
                              ),
                            ),
                            arrowIcon,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ]);
  }
}

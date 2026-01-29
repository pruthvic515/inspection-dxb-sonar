import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controls/text_field.dart';
import '../utils/color_const.dart';
import '../utils/constants.dart' as constants;
import '../utils/constants.dart';
import 'text.dart';

class FormMobileTextField extends StatelessWidget {
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

  FormMobileTextField(
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
      this.hideIcon});

  @override
  Widget build(BuildContext context) {
    var currentWidth = MediaQuery.of(context).size.width;
    hint = hint ?? "";
    /*  if (controller == null) {
      controller = TextEditingController();
      controller!.text = value ?? "";
    }*/

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
                bottom: currentWidth > SIZE_600 ? 20 : 10,
                top: currentWidth > SIZE_600 ? 20 : 10,
                left: currentWidth > SIZE_600 ? 15 : 10,
                right: currentWidth > SIZE_600 ? 15 : 10),
            child: CText(
              textColor: AppTheme.black,
              fontSize: fontSize ?? AppTheme.large,
              fontFamily: fontFamily ?? AppTheme.urbanist,
              fontWeight: fontWeight ?? FontWeight.w600,
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
                      surfaceTintColor: cardColor ?? AppTheme.white,
                      elevation: 2,
                      margin: EdgeInsets.only(
                          top: currentWidth > SIZE_600 ? 15 : 10),
                      color: cardColor ?? AppTheme.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: currentWidth > SIZE_600 ? 10 : 5),
                        child: Row(
                          children: [
                            CText(
                              padding: const EdgeInsets.only(top: 5),
                              text: "+9715",
                              textColor: textColor ?? AppTheme.textColor,
                              fontSize: fontSize ?? AppTheme.large,
                              fontFamily: fontFamily ?? AppTheme.urbanist,
                              fontWeight: fontWeight ?? FontWeight.w600,
                            ),
                            Expanded(
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
                              textCapitalization:
                                  inputType == TextInputType.name
                                      ? TextCapitalization.words
                                      : TextCapitalization.none,
                            ))
                          ],
                        ),
                      )))
              : Card(
                  elevation: 2,
                  margin: EdgeInsets.only(
                      top: currentWidth > SIZE_600 ? 15 : 10,
                      left: currentWidth > SIZE_600 ? 15 : 10,
                      right: currentWidth > SIZE_600 ? 15 : 10),
                  surfaceTintColor: cardColor ?? AppTheme.white,
                  color: cardColor ?? AppTheme.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
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
                              text: value == null || value!.isEmpty
                                  ? hint!
                                  : value!,
                            ),
                          ),
                          hideIcon == null || hideIcon != true
                              ? Image.asset(
                                  '${constants.ASSET_PATH}arrow_down.png',
                                  height: 15,
                                  color: AppTheme.colorPrimary,
                                  width: 15,
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
        ]);
  }
}

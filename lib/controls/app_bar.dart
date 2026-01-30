import 'package:flutter/material.dart';
import '../controls/text.dart';
import '../utils/color_const.dart';

class CAppBar extends StatelessWidget implements PreferredSizeWidget {
  String? title = "";

  CAppBar({
    this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.white,
      title: CText(
          text: title == null ? "" : title!,
          textColor: AppTheme.black,
          fontSize: AppTheme.large,
          fontWeight: FontWeight.w700),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

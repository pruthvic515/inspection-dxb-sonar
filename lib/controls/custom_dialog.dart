import 'package:flutter/material.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/color_const.dart';

class CustomDialog extends StatelessWidget {
  String? title;
  String message;
  VoidCallback onOkPressed;

  
  CustomDialog(
      {super.key,
      this.title,
      required this.message,
      required this.onOkPressed});


  @override
  Widget build(BuildContext context) {
    if (title != null && title!.isNotEmpty) {
      return Dialog(
        backgroundColor: AppTheme.transparent,
        surfaceTintColor: AppTheme.transparent,
        elevation: 0.0,
        shadowColor: AppTheme.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title!,
                maxLines: 5,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.big_20,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                message,
                maxLines: 5,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppTheme.large),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: onOkPressed,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorPrimary),
                child: CText(
                  text: "OK",
                  textColor: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      );
    }
    return Dialog(
      backgroundColor: AppTheme.white,
      surfaceTintColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20.0),
            Text(
              message,
              maxLines: 5,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTheme.large),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onOkPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorPrimary),
              child: CText(
                text: "OK",
                textColor: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:patrol_system/controls/text.dart';

import '../utils/color_const.dart';

class CustomYesNoDialog extends StatelessWidget {
  String? title;
  String message;
  VoidCallback onYesPressed;
  VoidCallback onNoPressed;

  CustomYesNoDialog(
      {super.key,
      this.title,
      required this.message,
      required this.onYesPressed,
      required this.onNoPressed});

  @override
  Widget build(BuildContext context) {
    if (title != null && title!.isNotEmpty) {
      return Dialog(
        backgroundColor: AppTheme.white,
        surfaceTintColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.big_20,
                    color: AppTheme.colorPrimary),
              ),
              const SizedBox(height: 20.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppTheme.large),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorPrimary),
                      onPressed: onYesPressed,
                      child: CText(text: "Yes",textColor: AppTheme.white,),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: onNoPressed,
                      child: CText(text: "Cancel"),
                    ),
                  ),
                ],
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTheme.large),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorPrimary),
                    onPressed: onYesPressed,
                    child: CText(text: "Yes",textColor: AppTheme.white,),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: onNoPressed,
                    child: CText(text: "No"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

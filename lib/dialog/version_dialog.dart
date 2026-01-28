import 'package:flutter/material.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/color_const.dart';

class VersionDialog extends StatefulWidget {
  const VersionDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<VersionDialog> createState() => _VersionDialogState();
}

class _VersionDialogState extends State<VersionDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
            width: width,
            padding: EdgeInsets.only(
              left: 24,
              top: 24,
              right: 15,
              bottom: 15,
            ),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.text_primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: CText(
                    text: 'Update Required',
                    fontFamily: AppTheme.Urbanist,
                    fontWeight: FontWeight.w700,
                    fontSize: width * .05,
                    textColor: AppTheme.black,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: width * .04),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "We have released a new update for our mobile app. Kindly ",
                          style: TextStyle(
                            fontFamily: AppTheme.Urbanist,
                            fontWeight: FontWeight.w600,
                            fontSize: width * .05,
                            color: AppTheme.black,
                          ),
                        ),
                        TextSpan(
                          text: "DELETE",
                          style: TextStyle(
                            fontFamily: AppTheme.Urbanist,
                            fontWeight: FontWeight.w800, // Bold
                            fontSize: width * .05,
                            color: Colors.red, // Red color
                          ),
                        ),
                        TextSpan(
                          text:
                              " the existing app and install the latest version.",
                          style: TextStyle(
                            fontFamily: AppTheme.Urbanist,
                            fontWeight: FontWeight.w600,
                            fontSize: width * .05,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// title
                /*   Container(
                  margin: EdgeInsets.only(top: width * .02),
                  child: CText(
                    text:
                        "Please update to the latest version of this app from Playstore or Appstore .",
                    fontFamily: AppTheme.Urbanist,
                    fontWeight: FontWeight.w700,
                    fontSize: width * .038,
                    textColor: AppTheme.black,
                  ),
                ),*/
                SizedBox(height: height * 0.024),
              ],
            )),
      ),
    );
  }
}

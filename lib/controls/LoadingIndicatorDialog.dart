import 'package:flutter/material.dart';

import '../controls/text.dart';
import '../utils/color_const.dart';

class LoadingIndicatorDialog {
  static final LoadingIndicatorDialog _singleton =
      LoadingIndicatorDialog._internal();
  late BuildContext _context;
  bool isDisplayed = false;

  factory LoadingIndicatorDialog() {
    return _singleton;
  }

  LoadingIndicatorDialog._internal();

  show(BuildContext context, {String text = 'Loading...'}) {
    print("object isDisplayed $isDisplayed");
    if (isDisplayed) {
      return;
    }
    Future.delayed(Duration.zero, () {
      showDialog<void>(
          context: context,
          barrierColor: AppTheme.transBlack,
          barrierDismissible: false,
          builder: (BuildContext context) {
            _context = context;
            isDisplayed = true;
            return WillPopScope(
                child: SimpleDialog(
                  backgroundColor: AppTheme.transparent,
                  elevation: 0,
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding:
                                EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 3.0,
                              color: AppTheme.black,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: CText(
                              text: text,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                onWillPop: () async => false);
          });
    });
  }

  dismiss() {
    if (isDisplayed) {
      Navigator.of(_context).pop();
      isDisplayed = false;
    }
  }
}

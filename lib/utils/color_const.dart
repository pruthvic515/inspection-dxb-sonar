import 'package:flutter/material.dart';

class AppTheme {
  // static const Color colorPrimary = Color(0xff3259F3);
  // static const Color colorPrimary = Color(0xff98BCF7);
  static const Color colorPrimary =  Color(0xff016ABC); // CID_USER Login
  static const Color status_6 =  Color(0xffFCD972); // Agent USER  login
  static const Color colorAccent = Color(0xff056C1C);
  static const Color statusBar = Color(0xffffffff);
  static const Color black = Color(0xFF000000);
  static const Color dotColor = Color(0xffA5D7C3);
  static const Color orange = Color(0xffff9100);
  static const Color gold = Color(0xffab9144);
  static const Color white = Color(0xffFFFFFF);
  static const Color text_6 = Color(0xffBA8E23);
  static const Color lGray = Color(0xffF4F4F4);
  static const Color red = Color(0xffFF3939);
  static const Color green = Color(0xff37a000);
  static const Color transBlack = Color(0x88000000);
  static const Color transparent = Color(0xffffffffff);
  static const Color lightBlack = Color(0xff241606);
  static const Color text_color = Color(0xff465647);
  static const Color darkGray = Color(0xff545F71);
  static const Color transparent_black = Color(0xff12000000);
  static const Color pink = Color(0xFFFFC0CB);
  static const Color purple = Color(0xFF800080);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color indigo = Color(0xE81B31A2);
  static const Color blue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF03A9F4);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color teal = Color(0xFF009688);

  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color lime = Color(0xFFCDDC39);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color amber = Color(0xFFFFC107);
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color brown = Color(0xFF795548);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color main_background = Color(0xffF2F3F6);
  static const Color blue_dark = Color(0xFF2158E4);
  static const Color blue_light = Color(0xFF6C7DB7);
  static const Color silver_two = Color(0xFFb9bdc7);
  static const Color pale_gray = Color(0xFFE8E9EC);
  static const Color ice_blue = Color(0xFFFAFCFF);
  static const Color back_background = Color(0xFFD3D1D8);
  static const Color border = Color(0xFFC2C3CB);
  static const Color text_color_two = Color(0xFF354863);
  static const Color text_color_red = Color(0xFFD44638);
  static const Color brick = Color(0xFFA6001C);
  static const Color text_color_gray = Color(0xFF858597);
  static const Color gray_Asparagus = Color(0xFF465647);
  static const Color light_blue = Color(0xFFBBDEFB);

  // Status colors (based on Status ID mapping)
  // 1  - Pending                       -> #DCBA7A
  // 2  - Accepted                      -> #1972A2
  // 3  - Rejected                      -> #8A3A6B
  // 4  - WaitingForAgentConfirmation   -> #1972A2
  // 5  - InProgress                    -> #1972A2
  // 6  - ProceedForAgentFeedback       -> #1972A2
  // 7  - ReadyForDepartmentView        -> #75A74D
  // 8  - FineIssued                    -> #8A3A6B
  // 9  - WarningIssued                 -> #8A3A6B
  // 10 - CancelInspection              -> #8A3A6B
  // 11 - Completed                     -> #75A74D
  // 12 - TaskClosed                    -> #8A3A6B
  // 14 - NoComments                    -> #8A3A6B
  // 15 - IssueSuspend                  -> #8A3A6B
  // 16 - FineSuspend                   -> #8A3A6B
  // 17 - CustomerAppealed              -> #8A3A6B
  // 18 - WaitingForAgentAppealResponse -> #8A3A6B
  // 19 - CustomerAppealUnderReview     -> #8A3A6B
  static const Color statusPending = Color(0xFFDCBA7A); // 1
  static const Color statusBlue = Color(0xFF1972A2); // 2,4,5,6
  static const Color statusGreen = Color(0xFF75A74D); // 7,11
  static const Color statusPurple = Color(0xFF8A3A6B); // 3,8,9,10,12,14-19

  static const Color title_gray = Color(0xFF6F757E);
  static const Color text_black = Color(0xFF121212);
  static const Color text_primary = Color(0xFFFFFFFF);
  static const Color freezed = Color(0xFFFF4500);
  static const Color closed = Color(0xFFE73927);
  static const Color cancelled = Color(0xFFCF0106);
  static const Color expired = Color(0xFFA021F0);
  static const Color active = Color(0xFF01644C);

  static const double tiny = 10;
  static const double small = 12;
  static const double thirteen = 13;
  static const double medium = 14;
  static const double large = 16;
  static const double big = 18;
  static const double big_20 = 20;

  static const String Urbanist = "Urbanist";
  static const String Poppins = "Poppins";

  /// Returns the color for a given status ID based on the unified mapping.
  static Color getStatusColor(int statusId) {
    switch (statusId) {
      case 1:
        return statusPending;
      case 2:
      case 4:
      case 5:
      case 6:
        return statusBlue;
      case 7:
      case 11:
        return statusGreen;
      case 3:
      case 8:
      case 9:
      case 10:
      case 12:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
        return statusPurple;
      default:
        // Fallback to primary color for any unknown / unmapped status.
        return colorPrimary;
    }
  }
}

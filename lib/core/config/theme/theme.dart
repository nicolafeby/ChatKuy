import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData getLightAppTheme() {
  return _getAppTheme(Brightness.light);
}

ThemeData getDarkAppTheme() {
  return _getAppTheme(Brightness.dark);
}

ThemeData _getAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColor.primaryColor,
    brightness: brightness,
  );
  final surfaceColor = isDark ? const Color(0xFF111B21) : Colors.white;
  final scaffoldColor = isDark ? const Color(0xFF0B141A) : Colors.white;

  return ThemeData(
    colorScheme: colorScheme,
    inputDecorationTheme: InputDecorationTheme(
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(10.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColor.primaryColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => Icon(
        Icons.arrow_back_ios,
      ).paddingOnly(left: 4.w),
    ),
    appBarTheme: AppBarTheme(
      // titleSpacing: 0,
      backgroundColor: surfaceColor,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: surfaceColor,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      elevation: 10,
      selectedItemColor: AppColor.primaryColor,
      unselectedItemColor: colorScheme.onSurfaceVariant,
    ),
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: GoogleFonts.roboto().fontFamily,
    tabBarTheme: TabBarThemeData(
      labelColor: AppColor.primaryColor,
      indicatorColor: AppColor.primaryColor,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
    ),
  );
}

import 'package:chatkuy/core/constants/color.dart';
import 'package:chatkuy/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (_, __) {
        return GetMaterialApp(
          navigatorKey: Get.key,
          theme: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primaryColor),
                borderRadius: BorderRadius.circular(10.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primaryColor),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              elevation: 10,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            fontFamily: GoogleFonts.wellfleet().fontFamily,
          ),
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouteName.BASE_SCREEN,
          getPages: AppRoute.pages,
        );
      },
    );
  }
}

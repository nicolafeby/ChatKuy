import 'package:chatkuy/core/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return GetMaterialApp(
          theme: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              // enabledBorder: OutlineInputBorder(
              //   borderSide: BorderSide(color: Colors.teal),
              // ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primaryColor),
                borderRadius: BorderRadius.circular(10.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primaryColor),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            appBarTheme: AppBarTheme(backgroundColor: Colors.white),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            fontFamily: GoogleFonts.wellfleet().fontFamily,
          ),
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouteName.login,
          routes: AppRoute.getMapRouteScreen(context),
        );
      },
    );
  }
}

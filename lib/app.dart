import 'package:chatkuy/core/config/theme/theme.dart';
import 'package:chatkuy/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
          theme: getAppTheme(),
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouteName.BASE_SCREEN,
          getPages: AppRoute.pages,
        );
      },
    );
  }
}

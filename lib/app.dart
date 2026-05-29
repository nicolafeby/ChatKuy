import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:chatkuy/core/config/language/language_controller.dart';
import 'package:chatkuy/core/config/theme/theme.dart';
import 'package:chatkuy/core/config/theme/theme_controller.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/data/models/app_update_info.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/routes/app_routes.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';
import 'package:chatkuy/ui/update/update_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialCallArgument,
    this.initialUpdateInfo,
  });

  final CallArgument? initialCallArgument;
  final AppUpdateInfo? initialUpdateInfo;

  @override
  Widget build(BuildContext context) {
    InitialRouteArgument.call = initialCallArgument;
    final fallbackInitialRoute = initialCallArgument == null ? AppRouteName.BASE_SCREEN : AppRouteName.CALL_SCREEN;
    var shouldShowUpdate = initialUpdateInfo?.shouldShowUpdate == true;

    if (kDebugMode) {
      shouldShowUpdate = false;
    } else if (shouldShowUpdate) {
      InitialRouteArgument.appUpdate = AppUpdateScreenArgument(
        updateInfo: initialUpdateInfo!,
        nextRouteName: fallbackInitialRoute,
      );
    }

    return ScreenUtilInit(
      builder: (_, screenUtilChild) {
        final themeController = getIt<ThemeController>();
        final languageController = getIt<LanguageController>();

        return ListenableBuilder(
          listenable: Listenable.merge([themeController, languageController]),
          builder: (context, _) => GetMaterialApp(
            navigatorKey: Get.key,
            translations: AppTranslations(),
            locale: languageController.locale,
            fallbackLocale: const Locale('id', 'ID'),
            theme: getLightAppTheme(),
            darkTheme: getDarkAppTheme(),
            themeMode: themeController.themeMode,
            title: AppStrings.appName,
            debugShowCheckedModeBanner: kDebugMode ? true : false,
            initialRoute: shouldShowUpdate ? AppRouteName.APP_UPDATE_SCREEN : fallbackInitialRoute,
            getPages: AppRoute.pages,
            home: screenUtilChild,
            builder: (_, getChild) => SafeArea(
              top: false,
              bottom: true,
              child: getChild ?? SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

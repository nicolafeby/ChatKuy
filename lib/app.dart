import 'package:chatkuy/core/config/theme/theme.dart';
import 'package:chatkuy/core/navigation/initial_route_argument.dart';
import 'package:chatkuy/routes/app_routes.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialVoiceCallArgument,
  });

  final VoiceCallArgument? initialVoiceCallArgument;

  @override
  Widget build(BuildContext context) {
    InitialRouteArgument.voiceCall = initialVoiceCallArgument;

    return ScreenUtilInit(
      builder: (_, screenUtilChild) {
        return GetMaterialApp(
          navigatorKey: Get.key,
          theme: getAppTheme(),
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          initialRoute: initialVoiceCallArgument == null
              ? AppRouteName.BASE_SCREEN
              : AppRouteName.VOICE_CALL_SCREEN,
          getPages: AppRoute.pages,
          home: screenUtilChild,
          builder: (_, getChild) => SafeArea(
            top: false,
            bottom: true,
            child: getChild ?? SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

import 'package:get/get.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';

class AppStrings {
  AppStrings._();
  static const appName = 'ChatKuy';
  static String get somethingWentWrong =>
      AppTranslationKey.somethingWentWrong.tr;
  static String get noData => AppTranslationKey.noData.tr;
  static String get retry => AppTranslationKey.retry.tr;
  static const emailNotVerified = 'email-not-verified';
  static String get oopsTerjadiKesalahan => AppTranslationKey.oopsError.tr;
  static String get userNotFound => AppTranslationKey.userNotFound.tr;
  static const dummyNetworkImage = 'https://dummyimage.com/300';
  static const fcmToken = 'fcmToken';
}

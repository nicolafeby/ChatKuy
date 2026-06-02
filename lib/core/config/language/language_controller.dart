import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends ChangeNotifier {
  LanguageController(this._storageRepository);

  final SecureStorageRepository _storageRepository;

  Locale _locale = const Locale('id', 'ID');

  Locale get locale => _locale;

  bool get isIndonesian => _locale.languageCode == 'id';

  Future<void> init() async {
    final storedLanguageCode = await _storageRepository.getLanguageCode();
    _locale = _localeFromLanguageCode(storedLanguageCode);
  }

  Future<void> toggleLanguage() async {
    final nextLocale =
        isIndonesian ? const Locale('en', 'US') : const Locale('id', 'ID');
    await setLocale(nextLocale);
  }

  Future<void> setLocale(Locale value) async {
    if (_locale == value) return;

    _locale = value;
    await _storageRepository.setLanguageCode(value.languageCode);
    Get.updateLocale(value);
    notifyListeners();
  }

  Locale _localeFromLanguageCode(String? languageCode) {
    return languageCode == 'en'
        ? const Locale('en', 'US')
        : const Locale('id', 'ID');
  }
}

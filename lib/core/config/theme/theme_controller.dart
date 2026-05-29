import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._storageRepository);

  final SecureStorageRepository _storageRepository;

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    final storedTheme = await _storageRepository.getThemeModeName();
    _themeMode = storedTheme == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final nextThemeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextThemeMode);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;

    _themeMode = value;
    await _storageRepository.setThemeModeName(value.name);
    notifyListeners();
  }
}

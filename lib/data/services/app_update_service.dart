import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/models/app_update_info.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  AppUpdateService(this._remoteConfig);

  static const minimumRequiredAppVersionKey = 'minimum_required_app_version';
  static const minimumRequiredBuildNumberKey = 'minimum_required_build_number';
  static const recommendedAppVersionKey = 'recommended_app_version';
  static const recommendedBuildNumberKey = 'recommended_build_number';
  static const appTesterUrlKey = 'app_tester_url';

  static const defaultAppTesterUrl =
      'https://appdistribution.firebase.google.com/testerapps';

  final FirebaseRemoteConfig _remoteConfig;
  bool _isConfigured = false;

  Future<AppUpdateInfo> checkForUpdate() async {
    await _configureRemoteConfig();

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      await AppErrorLogger.recordError(
        error,
        stackTrace,
        reason: 'Failed to fetch app update Remote Config',
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final minimumRequiredVersion =
        _remoteConfig.getString(minimumRequiredAppVersionKey).trim();
    final minimumRequiredBuildNumber =
        _remoteConfig.getInt(minimumRequiredBuildNumberKey);
    final recommendedVersion =
        _remoteConfig.getString(recommendedAppVersionKey).trim();
    final recommendedBuildNumber =
        _remoteConfig.getInt(recommendedBuildNumberKey);
    final appTesterUrl = _remoteConfig.getString(appTesterUrlKey).trim();

    final isBelowMinimumVersion =
        _isLowerVersion(packageInfo.version, minimumRequiredVersion);
    final isBelowMinimumBuild = minimumRequiredBuildNumber > 0 &&
        currentBuildNumber < minimumRequiredBuildNumber;
    final isBelowRecommendedVersion =
        _isLowerVersion(packageInfo.version, recommendedVersion);
    final isBelowRecommendedBuild = recommendedBuildNumber > 0 &&
        currentBuildNumber < recommendedBuildNumber;

    final type = isBelowMinimumVersion || isBelowMinimumBuild
        ? AppUpdateType.required
        : isBelowRecommendedVersion || isBelowRecommendedBuild
            ? AppUpdateType.optional
            : AppUpdateType.none;

    return AppUpdateInfo(
      type: type,
      currentVersion: packageInfo.version,
      currentBuildNumber: currentBuildNumber,
      minimumRequiredVersion: minimumRequiredVersion,
      minimumRequiredBuildNumber: minimumRequiredBuildNumber,
      recommendedVersion: recommendedVersion,
      recommendedBuildNumber: recommendedBuildNumber,
      appTesterUrl: appTesterUrl.isEmpty ? defaultAppTesterUrl : appTesterUrl,
    );
  }

  Future<void> _configureRemoteConfig() async {
    if (_isConfigured) return;

    await _remoteConfig.setDefaults({
      minimumRequiredAppVersionKey: '',
      minimumRequiredBuildNumberKey: 0,
      recommendedAppVersionKey: '',
      recommendedBuildNumberKey: 0,
      appTesterUrlKey: defaultAppTesterUrl,
    });

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );

    _isConfigured = true;
  }

  bool _isLowerVersion(String currentVersion, String targetVersion) {
    if (targetVersion.trim().isEmpty) return false;

    final currentParts = _parseVersion(currentVersion);
    final targetParts = _parseVersion(targetVersion);
    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < maxLength; i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final target = i < targetParts.length ? targetParts[i] : 0;

      if (current < target) return true;
      if (current > target) return false;
    }

    return false;
  }

  List<int> _parseVersion(String version) {
    return version
        .split(RegExp(r'[.+-]'))
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}

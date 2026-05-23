enum AppUpdateType {
  none,
  optional,
  required,
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.type,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.minimumRequiredVersion,
    required this.minimumRequiredBuildNumber,
    required this.recommendedVersion,
    required this.recommendedBuildNumber,
    required this.appTesterUrl,
  });

  final AppUpdateType type;
  final String currentVersion;
  final int currentBuildNumber;
  final String minimumRequiredVersion;
  final int minimumRequiredBuildNumber;
  final String recommendedVersion;
  final int recommendedBuildNumber;
  final String appTesterUrl;

  bool get isUpdateRequired => type == AppUpdateType.required;
  bool get isOptionalUpdate => type == AppUpdateType.optional;
  bool get shouldShowUpdate => type != AppUpdateType.none;

  bool get hasMinimumRequiredVersion =>
      minimumRequiredVersion.trim().isNotEmpty;
  bool get hasRecommendedVersion => recommendedVersion.trim().isNotEmpty;

  String get currentBuildNumberText => currentBuildNumber.toString();
  String get minimumRequiredBuildNumberText =>
      minimumRequiredBuildNumber.toString();
  String get recommendedBuildNumberText => recommendedBuildNumber.toString();
}

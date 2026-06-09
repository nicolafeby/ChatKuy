import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:get/get.dart';

class ErrorTicketVisibility {
  const ErrorTicketVisibility._();

  static bool shouldShowForMessage(String? message) {
    final normalizedMessage = _normalize(message);
    if (normalizedMessage == null) return true;

    return _genericMessages().contains(normalizedMessage);
  }

  static String? visibleTicketId({
    required String? ticketId,
    required String? message,
  }) {
    if (ticketId == null || ticketId.isEmpty) return null;
    return shouldShowForMessage(message) ? ticketId : null;
  }

  static Set<String> _genericMessages() {
    return {
      _normalize(AppTranslationKey.appIssueMessage.tr),
      _normalize(AppTranslationKey.tryAgainError.tr),
      _normalize(AppTranslationKey.somethingWentWrong.tr),
      _normalize(AppTranslationKey.text(AppTranslationKey.appIssueMessage)),
      _normalize(AppTranslationKey.text(AppTranslationKey.tryAgainError)),
      _normalize(AppTranslationKey.text(AppTranslationKey.somethingWentWrong)),
      _normalize(_idGenericMessage(AppTranslationKey.appIssueMessage)),
      _normalize(_idGenericMessage(AppTranslationKey.tryAgainError)),
      _normalize(_idGenericMessage(AppTranslationKey.somethingWentWrong)),
      _normalize(_enGenericMessage(AppTranslationKey.appIssueMessage)),
      _normalize(_enGenericMessage(AppTranslationKey.tryAgainError)),
      _normalize(_enGenericMessage(AppTranslationKey.somethingWentWrong)),
    }.whereType<String>().toSet();
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.toLowerCase();
  }

  static String _idGenericMessage(String key) {
    const messages = {
      AppTranslationKey.appIssueMessage:
          'Maaf, terjadi kendala pada aplikasi. Silakan coba lagi dalam beberapa saat.',
      AppTranslationKey.tryAgainError: 'Terjadi kesalahan, silakan coba lagi',
      AppTranslationKey.somethingWentWrong: 'Terjadi kesalahan',
    };

    return messages[key] ?? key;
  }

  static String _enGenericMessage(String key) {
    const messages = {
      AppTranslationKey.appIssueMessage:
          'Sorry, the app ran into a problem. Please try again in a moment.',
      AppTranslationKey.tryAgainError: 'Something went wrong, please try again',
      AppTranslationKey.somethingWentWrong: 'Something went wrong',
    };

    return messages[key] ?? key;
  }
}

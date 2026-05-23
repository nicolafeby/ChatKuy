import 'dart:developer' as developer;

import 'package:chatkuy/core/widgets/error_bottomsheet_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AppErrorLogger {
  const AppErrorLogger._();

  static String? latestErrorTicketId;

  static Future<void> setUserId(String? uid) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
    } catch (_) {}
  }

  static Future<void> logMessage(
    String message, {
    Map<String, Object?> context = const {},
  }) async {
    final sanitizedContext = _sanitizeContext(context);
    final contextText = sanitizedContext.isEmpty ? '' : ' | $sanitizedContext';

    developer.log('$message$contextText', name: 'ChatKuy');

    try {
      await FirebaseCrashlytics.instance.log('$message$contextText');
    } catch (_) {}
  }

  static Future<String> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
    bool showBottomSheet = true,
  }) async {
    final ticketId = _createTicketId(error);
    latestErrorTicketId = ticketId;
    final sanitizedContext = _sanitizeContext({
      ...context,
      'error_ticket_id': ticketId,
      if (error is FirebaseException) 'firebase_code': error.code,
      if (error is FirebaseException) 'firebase_plugin': error.plugin,
      if (error is FirebaseAuthException && error.email != null) 'auth_email_hash': error.email.hashCode,
    });

    developer.log(
      '$reason | error_ticket_id=$ticketId',
      name: 'ChatKuy',
      error: error,
      stackTrace: stackTrace,
    );

    if (showBottomSheet) {
      _showErrorBottomSheet(ticketId);
    }

    try {
      for (final entry in sanitizedContext.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(
          entry.key,
          entry.value?.toString() ?? '',
        );
      }

      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '$reason | error_ticket_id=$ticketId',
        fatal: fatal,
        printDetails: kDebugMode,
      );
    } catch (_) {}

    return ticketId;
  }

  static Map<String, Object?> _sanitizeContext(Map<String, Object?> context) {
    final sanitized = <String, Object?>{};

    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('password') || key.contains('token') || key.contains('secret')) {
        continue;
      }

      sanitized[entry.key] = entry.value;
    }

    return sanitized;
  }

  static String _createTicketId(Object error) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final hash = identityHashCode(error).toRadixString(16).toUpperCase();
    return 'ERR-$timestamp-$hash';
  }

  static void _showErrorBottomSheet(String ticketId) {
    if (Get.context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (Get.context == null || Get.isBottomSheetOpen == true) return;

        Get.bottomSheet(
          ErrorBottomsheetWidget(
            ticketId: ticketId,
            message: 'Maaf, terjadi kendala pada aplikasi. Silakan coba lagi dalam beberapa saat.',
          ),
          isScrollControlled: true,
        );
      });
    });
  }
}

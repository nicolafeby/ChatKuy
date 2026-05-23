import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppErrorLogger {
  const AppErrorLogger._();

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

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    final sanitizedContext = _sanitizeContext({
      ...context,
      if (error is FirebaseException) 'firebase_code': error.code,
      if (error is FirebaseException) 'firebase_plugin': error.plugin,
      if (error is FirebaseAuthException && error.email != null) 'auth_email_hash': error.email.hashCode,
    });

    developer.log(
      reason,
      name: 'ChatKuy',
      error: error,
      stackTrace: stackTrace,
    );

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
        reason: reason,
        fatal: fatal,
        printDetails: kDebugMode,
      );
    } catch (_) {}
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
}

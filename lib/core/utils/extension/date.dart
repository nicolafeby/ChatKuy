import 'package:chatkuy/core/config/language/app_translations.dart';

extension DateTimeExtension on DateTime {
  /// Format: HH:mm (contoh: 09:30)
  String get hhmm {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get daysAndTime {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');

    return '$chatDayLabel, $hour:$minute';
  }

  /// Cek apakah tanggal sama (tanpa memperhatikan jam)
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  int daysFromNow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    return today.difference(date).inDays;
  }

  String get chatDayLabel {
    final diff = daysFromNow();

    if (diff == 0) {
      return AppTranslationKey.text(AppTranslationKey.today);
    }

    if (diff == 1) {
      return AppTranslationKey.text(AppTranslationKey.yesterday);
    }

    if (diff >= 2 && diff <= 6) {
      return _weekdayName(weekday);
    }

    return '$day ${_monthName(month)} $year';
  }

  String _weekdayName(int w) {
    return AppTranslationKey.text('weekday$w');
  }

  String _monthName(int m) {
    return AppTranslationKey.text('month$m');
  }

  /// Format tanggal untuk chat:
  /// - Hari ini  → Hari ini
  /// - Kemarin   → Kemarin
  /// - Selain itu → dd/MM/yyyy
  String get chatFormat {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (isSameDay(now)) {
      return AppTranslationKey.text(AppTranslationKey.today);
    }

    if (isSameDay(yesterday)) {
      return AppTranslationKey.text(AppTranslationKey.yesterday);
    }

    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }
}

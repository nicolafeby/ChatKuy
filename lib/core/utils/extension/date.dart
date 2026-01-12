extension DateTimeExtension on DateTime {
  /// Format: HH:mm (contoh: 09:30)
  String get hhmm {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
      return 'Hari ini';
    }

    if (diff == 1) {
      return 'Kemarin';
    }

    if (diff >= 2 && diff <= 6) {
      return _weekdayName(weekday);
    }

    return '$day ${_monthName(month)} $year';
  }

  String _weekdayName(int w) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[w - 1];
  }

  String _monthName(int m) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Augustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[m - 1];
  }

  /// Format tanggal untuk chat:
  /// - Hari ini  → Hari ini
  /// - Kemarin   → Kemarin
  /// - Selain itu → dd/MM/yyyy
  String get chatFormat {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (isSameDay(now)) {
      return 'Hari ini';
    }

    if (isSameDay(yesterday)) {
      return 'Kemarin';
    }

    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }
}

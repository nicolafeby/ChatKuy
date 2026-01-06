extension DateTimeExtension on DateTime {
  /// Format: HH:mm (contoh: 09:30)
  String get hhmm {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Cek apakah tanggal sama (tanpa memperhatikan jam)
  bool isSameDay(DateTime other) {
    return year == other.year &&
        month == other.month &&
        day == other.day;
  }

  /// Format tanggal untuk chat:
  /// - Hari ini  → HH:mm
  /// - Selain itu → dd/MM/yyyy
  String get chatFormat {
    final now = DateTime.now();

    if (isSameDay(now)) {
      return hhmm;
    }

    return '${day.toString().padLeft(2, '0')}/'
           '${month.toString().padLeft(2, '0')}/'
           '$year';
  }
}

import 'package:chatkuy/core/utils/converter/timestamp_converter.dart';
import 'package:chatkuy/core/utils/error_ticket_visibility.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> coreUtilsTest() async {
  group('DateTimeExtension', () {
    test('formats hhmm with leading zero', () {
      expect(DateTime(2024, 1, 1, 9, 5).hhmm, '09:05');
    });

    test('formats old dates with month name and time', () {
      expect(
        DateTime(2024, 1, 1, 9, 5).daysAndTime,
        '1 Januari 2024, 09:05',
      );
    });

    test('chatFormat returns dd/MM/yyyy for old date', () {
      expect(DateTime(2024, 1, 1).chatFormat, '01/01/2024');
    });
  });

  group('TimestampConverter', () {
    test('converts between Timestamp and DateTime', () {
      const converter = TimestampConverter();
      final date = DateTime(2024, 1, 1, 9, 5);
      final timestamp = converter.toJson(date);

      expect(timestamp, isA<Timestamp>());
      expect(converter.fromJson(timestamp), date);
    });
  });

  group('UserModelFields', () {
    test('contains firestore field names', () {
      expect(UserModelFields.id, 'id');
      expect(UserModelFields.name, 'name');
      expect(UserModelFields.email, 'email');
      expect(UserModelFields.username, 'username');
      expect(UserModelFields.photoUrl, 'photoUrl');
      expect(UserModelFields.isEmailVerified, 'isEmailVerified');
      expect(UserModelFields.isOnline, 'isOnline');
      expect(UserModelFields.lastOnlineAt, 'lastOnlineAt');
    });
  });

  group('ErrorTicketVisibility', () {
    test('shows ticket for generic error messages only', () {
      expect(
        ErrorTicketVisibility.visibleTicketId(
          ticketId: 'ERR-123',
          message:
              'Maaf, terjadi kendala pada aplikasi. Silakan coba lagi dalam beberapa saat.',
        ),
        'ERR-123',
      );

      expect(
        ErrorTicketVisibility.visibleTicketId(
          ticketId: 'ERR-123',
          message: 'Akun sudah dihapus atau sedang dalam proses penghapusan',
        ),
        isNull,
      );
    });
  });
}

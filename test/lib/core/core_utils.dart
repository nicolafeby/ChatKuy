import 'package:chatkuy/core/utils/converter/timestamp_converter.dart';
import 'package:chatkuy/core/utils/chat_message_presentation.dart';
import 'package:chatkuy/core/utils/error_ticket_visibility.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:chatkuy/core/utils/mention_parser.dart';
import 'package:chatkuy/data/models/call_notification_payload.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
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

  group('ChatMessagePresentation', () {
    test('uses one label mapping for previews and room summaries', () {
      expect(ChatMessagePresentation.typeLabel(MessageType.image), 'Foto');
      expect(
        ChatMessagePresentation.resolveText(null, MessageType.audio),
        'Pesan suara',
      );
      expect(
        ChatMessagePresentation.resolveText('  Halo  ', MessageType.text),
        'Halo',
      );
    });
  });

  group('MentionParser', () {
    final users = [
      UserModel(
        id: 'andi',
        name: 'Andi Wijaya',
        username: 'andiw',
        email: 'andi@example.com',
        isEmailVerified: true,
        fcmToken: '',
      ),
    ];

    test('finds active mention at the cursor', () {
      expect(MentionParser.activeQuery('Halo @and', 9), 'and');
      expect(MentionParser.activeQuery('email@and', 9), isNull);
    });

    test('matches users by display name or username', () {
      expect(
        MentionParser.mentionedUsers(text: 'Hai @andiw', users: users)
            .map((user) => user.id),
        ['andi'],
      );
    });
  });

  group('Call notification payload', () {
    const call = {
      'callId': 'call-1',
      'roomId': 'room-1',
      'callerId': 'user-1',
      'type': 'video_call',
    };

    test('parses valid typed payload and rejects incomplete payload', () {
      final payload = CallNotificationPayload.tryParse(call);
      expect(payload?.callId, 'call-1');
      expect(payload?.isVideoCall, isTrue);
      expect(CallNotificationPayload.tryParse({'callId': 'call-1'}), isNull);
    });

    test('extracts nested CallKit payload', () {
      expect(
        CallKitPayloadExtractor.extract({
          'body': {'extra': call}
        }),
        call,
      );
    });
  });
}

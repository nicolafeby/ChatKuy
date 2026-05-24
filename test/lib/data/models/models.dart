import 'package:chatkuy/data/models/app_update_info.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/edit_profile_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/data/models/user_presence_model.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> modelsTest() async {
  group('AppUpdateInfo', () {
    test('exposes update type flags and text values', () {
      const info = AppUpdateInfo(
        type: AppUpdateType.optional,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
        minimumRequiredVersion: '',
        minimumRequiredBuildNumber: 0,
        recommendedVersion: '1.1.0',
        recommendedBuildNumber: 2,
        appTesterUrl: 'https://example.com',
      );

      expect(info.isUpdateRequired, isFalse);
      expect(info.isOptionalUpdate, isTrue);
      expect(info.shouldShowUpdate, isTrue);
      expect(info.hasMinimumRequiredVersion, isFalse);
      expect(info.hasRecommendedVersion, isTrue);
      expect(info.currentBuildNumberText, '1');
      expect(info.minimumRequiredBuildNumberText, '0');
      expect(info.recommendedBuildNumberText, '2');
    });
  });

  group('EditProfileModel', () {
    test('copyWith updates selected fields and keeps others', () {
      const model = EditProfileModel(
        name: 'Alya',
        email: 'alya@example.com',
        gender: Gender.female,
        username: 'alya',
      );

      final updated = model.copyWith(name: 'Alya Putri');

      expect(updated.name, 'Alya Putri');
      expect(updated.email, model.email);
      expect(updated.gender, model.gender);
      expect(updated.username, model.username);
    });
  });

  group('UserModel', () {
    test('copyWith updates selected fields and keeps identity data', () {
      final lastOnlineAt = DateTime(2024, 1, 1);
      final user = UserModel(
        id: 'user-1',
        name: 'Alya',
        email: 'alya@example.com',
        isEmailVerified: false,
        isOnline: false,
        fcmToken: 'old-token',
      );

      final updated = user.copyWith(
        isEmailVerified: true,
        isOnline: true,
        lastOnlineAt: lastOnlineAt,
        fcmToken: 'new-token',
      );

      expect(updated.id, user.id);
      expect(updated.name, user.name);
      expect(updated.email, user.email);
      expect(updated.isEmailVerified, isTrue);
      expect(updated.isOnline, isTrue);
      expect(updated.lastOnlineAt, lastOnlineAt);
      expect(updated.fcmToken, 'new-token');
    });
  });

  group('ChatMessageModel', () {
    test('copyWith updates media/status fields and keeps message metadata', () {
      final createdAt = DateTime(2024, 1, 1);
      final message = ChatMessageModel(
        id: 'message-1',
        roomId: 'room-1',
        senderId: 'user-1',
        text: 'Halo',
        createdAt: createdAt,
        createdAtClient: createdAt,
        deliveredTo: {'user-2': true},
        readBy: {},
        status: MessageStatus.pending,
        type: MessageType.image,
        localImagePath: '/tmp/local.png',
      );

      final updated = message.copyWith(
        status: MessageStatus.sent,
        imageUrl: 'https://example.com/image.png',
      );

      expect(updated.id, message.id);
      expect(updated.roomId, message.roomId);
      expect(updated.senderId, message.senderId);
      expect(updated.text, message.text);
      expect(updated.status, MessageStatus.sent);
      expect(updated.localImagePath, message.localImagePath);
      expect(updated.imageUrl, 'https://example.com/image.png');
    });

    test('toJson excludes local-only status field', () {
      final date = DateTime(2024, 1, 1);
      final message = ChatMessageModel(
        id: 'message-1',
        roomId: 'room-1',
        senderId: 'user-1',
        createdAt: date,
        createdAtClient: date,
        deliveredTo: {},
        readBy: {},
        status: MessageStatus.failed,
        type: MessageType.text,
      );

      final json = message.toJson();

      expect(json['id'], 'message-1');
      expect(json['status'], isNull);
    });
  });

  group('UserPresenceModel', () {
    test('serializes to and from json', () {
      final lastOnlineAt = DateTime(2024, 1, 1, 9, 5);
      final model = UserPresenceModel(
        isOnline: true,
        lastOnlineAt: lastOnlineAt,
      );

      final json = model.toJson();
      final parsed = UserPresenceModel.fromJson(json);

      expect(parsed.isOnline, isTrue);
      expect(parsed.lastOnlineAt, lastOnlineAt);
    });
  });
}

import 'dart:io';

import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/core/helpers/image_saver_helper.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:chatkuy/ui/chat/chat_room/widget/chat_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> chatAppbarWidgetTest() async {
  group('ChatAppbarWidget', () {
    testWidgets('shows target user name and online status', (tester) async {
      await _pumpChatAppbar(
        tester,
        userData: _user(isOnline: true),
      );

      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows typing status before online status', (tester) async {
      await _pumpChatAppbar(
        tester,
        userData: _user(isOnline: true),
        isTyping: true,
      );

      expect(find.text('Sedang mengetik ...'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('shows last online time when user is offline', (tester) async {
      await _pumpChatAppbar(
        tester,
        userData: _user(
          isOnline: false,
          lastOnlineAt: DateTime(2024, 1, 1, 9, 5),
        ),
      );

      expect(find.text('1 Januari 2024, 09:05'), findsOneWidget);
    });

    testWidgets('calls voice and video call callbacks', (tester) async {
      var voiceCallTapCount = 0;
      var videoCallTapCount = 0;

      await _pumpChatAppbar(
        tester,
        userData: _user(isOnline: true),
        onCallTap: () => voiceCallTapCount++,
        onVideoCallTap: () => videoCallTapCount++,
      );

      await tester.tap(find.byTooltip('Telepon suara'));
      await tester.tap(find.byTooltip('Panggilan video'));

      expect(voiceCallTapCount, 1);
      expect(videoCallTapCount, 1);
    });
  });
}

Future<void> _pumpChatAppbar(
  WidgetTester tester, {
  required UserModel userData,
  bool isTyping = false,
  VoidCallback? onCallTap,
  VoidCallback? onVideoCallTap,
}) {
  final store = ChatRoomStore(
    chatRepository: _FakeChatRepository(),
    userRepository: _FakeUserRepository(),
  );

  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          home: Scaffold(
            appBar: ChatAppbarWidget(
              store: store,
              userData: userData,
              isTyping: isTyping,
              onCallTap: onCallTap,
              onVideoCallTap: onVideoCallTap,
            ),
          ),
        );
      },
    ),
  );
}

UserModel _user({
  bool? isOnline,
  DateTime? lastOnlineAt,
}) {
  return UserModel(
    id: 'user-1',
    name: 'Alya',
    email: 'alya@example.com',
    isEmailVerified: true,
    isOnline: isOnline,
    lastOnlineAt: lastOnlineAt,
    fcmToken: 'token-1',
  );
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<String> createOrGetRoom({
    required String currentUid,
    required String targetUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markDelivered({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markRead({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetUnread({
    required String roomId,
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    String? targetUid,
    String? text,
    String? imageUrl,
    File? imageFile,
    String? videoUrl,
    File? videoFile,
    String? fileUrl,
    File? file,
    String? fileName,
    int? fileSize,
    String? fileExtension,
    String? contactName,
    String? contactPhone,
    String? audioUrl,
    File? audioFile,
    String? localAudioPath,
    int? audioDurationSeconds,
    required MessageType type,
    String? clientMessageId,
    String? localImagePath,
    String? localVideoPath,
    String? localFilePath,
    ChatMessageModel? replyToMessage,
    String? replyToSenderName,
    List<String> mentionedUserIds = const [],
    List<String> mentionedUserNames = const [],
    void Function(int progress)? onUploadProgress,
  }) {
    throw UnimplementedError();
  }

  @override
  String directRoomId({
    required String currentUid,
    required String targetUid,
  }) {
    return '${currentUid}_$targetUid';
  }

  @override
  Future<String> createGroupRoom({
    required String currentUid,
    required String name,
    required List<String> memberUids,
    String? photoUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<ChatRoomModel> watchRoom({required String roomId}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<UserModel>> watchGroupMembers({required String roomId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> inviteGroupMembers({
    required String roomId,
    required String adminUid,
    required List<String> memberUids,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> promoteGroupAdmin({
    required String roomId,
    required String adminUid,
    required String memberUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeGroupMember({
    required String roomId,
    required String adminUid,
    required String memberUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateGroupInfo({
    required String roomId,
    required String adminUid,
    String? name,
    String? photoUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> setTyping({
    required String roomId,
    required String uid,
    required bool isTyping,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LocalImageModel> uploadImage({
    required File file,
    required String roomId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ChatRoomModel>> watchChatRooms({
    required String uid,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages({
    required String roomId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<Map<String, bool>> watchTyping({
    required String roomId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserModel> getUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(UserModel user) {
    throw UnimplementedError();
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    throw UnimplementedError();
  }
}

import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/data/repositories/local_notification_repository.dart';
import 'package:chatkuy/data/repositories/notification_repository.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/data/services/auth_service.dart';
import 'package:chatkuy/data/services/chat_service.dart';
import 'package:chatkuy/data/services/chat_user_list_service.dart';
import 'package:chatkuy/data/services/friend_service.dart';
import 'package:chatkuy/data/services/local_notification_service.dart';
import 'package:chatkuy/data/services/notification_service.dart';
import 'package:chatkuy/data/services/presence_service.dart';
import 'package:chatkuy/data/services/request_friend_service.dart';
import 'package:chatkuy/data/services/secure_storage_service.dart';
import 'package:chatkuy/data/services/user_service.dart';
import 'package:chatkuy/stores/chat/chat_list/chat_user_list_store.dart';
import 'package:chatkuy/stores/chat/chat_room/chat_room_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final getIt = GetIt.I;

void setupDI() {
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);

  // getIt.registerLazySingleton<NotificationRepository>(
  //   () => getIt<NotificationService>(),
  // );

  // getIt.registerLazySingleton<PresenceService>(
  //   () => PresenceService(
  //     FirebaseAuth.instance,
  //     FirebaseFirestore.instance,
  //   ),
  // );

  // getIt.registerLazySingleton<PresenceRepository>(
  //   () => getIt<PresenceService>(),
  // );

  registerService();
  registerStore();
}

void registerService() {
  getIt.registerLazySingleton<AuthRepository>(() => AuthService(FirebaseAuth.instance, FirebaseFirestore.instance));

  getIt.registerLazySingleton<UserRepository>(() => UserService(FirebaseFirestore.instance));

  getIt.registerLazySingleton<SecureStorageRepository>(() => SecureStorageService());

  getIt.registerLazySingleton<PresenceService>(
    () => PresenceService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    ),
  );

  getIt.registerLazySingleton<PresenceRepository>(
    () => getIt<PresenceService>(),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    ),
  );

  getIt.registerLazySingleton<FriendRepository>(
    () => FriendService(FirebaseAuth.instance, FirebaseFirestore.instance),
  );

  getIt.registerLazySingleton<FriendRequestRepository>(
    () => FriendRequestService(FirebaseAuth.instance, FirebaseFirestore.instance),
  );

  getIt.registerLazySingleton<ChatUserListRepository>(
    () => ChatUserListService(FirebaseFirestore.instance),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationService(messaging: FirebaseMessaging.instance),
  );

  getIt.registerLazySingleton<LocalNotificationRepository>(
    () => LocalNotificationService(),
  );
}

void registerStore() {
  getIt.registerFactory<ChatUserListStore>(
    () => ChatUserListStore(
      repository: getIt<ChatUserListRepository>(),
    ),
  );

  getIt.registerFactory<ChatRoomStore>(
    () => ChatRoomStore(
      chatRepository: getIt<ChatRepository>(),
      userRepository: getIt<UserRepository>(),
    ),
  );
}

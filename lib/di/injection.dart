import 'package:chatkuy/data/datasources/chat_firebase_datasource.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final getIt = GetIt.I;

void setupDI() {
  // =========================
  // Firebase
  // =========================
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // =========================
  // Datasources
  // =========================
  getIt.registerLazySingleton<ChatFirebaseDatasource>(
    () => ChatFirebaseDatasource(
      getIt<FirebaseFirestore>(),
    ),
  );

  // =========================
  // Repositories
  // =========================
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(
      getIt<ChatFirebaseDatasource>(),
    ),
  );

  // // =========================
  // // Stores (MobX)
  // // =========================
  // getIt.registerFactory<ChatRoomStore>(
  //   () => ChatRoomStore(
  //     getIt<ChatRepository>(),
  //   ),
  // );
}

import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:chatkuy/data/services/auth_service.dart';
import 'package:chatkuy/data/services/secure_storage_service.dart';
import 'package:chatkuy/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final getIt = GetIt.I;

void setupDI() {
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  getIt.registerLazySingleton<AuthRepository>(() => AuthService(FirebaseAuth.instance, FirebaseFirestore.instance));

  getIt.registerLazySingleton<UserRepository>(() => UserService(FirebaseFirestore.instance));

  getIt.registerLazySingleton<SecureStorageRepository>(() => SecureStorageService());
}

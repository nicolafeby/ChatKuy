// ignore_for_file: unused_import

import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatkuy/data/services/auth_service.dart';
import 'package:chatkuy/data/models/user_model.dart';
import 'package:chatkuy/core/config/env_config.dart';

import 'auth_service.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  CollectionReference,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
  Query,
  QuerySnapshot,
])
Future<void> authServiceTest() async {
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late AuthService service;

  late MockUser mockUser;
  late MockUserCredential mockCredential;
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> snapshot;

  late MockQuery<Map<String, dynamic>> usersQuery;
  late MockQuerySnapshot<Map<String, dynamic>> querySnapshot;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    service = AuthService(auth, firestore);

    mockUser = MockUser();
    mockCredential = MockUserCredential();
    usersCollection = MockCollectionReference();
    userDoc = MockDocumentReference();
    snapshot = MockQueryDocumentSnapshot();
    usersQuery = MockQuery();
    querySnapshot = MockQuerySnapshot();
  });

  test('LOGIN SUCCESS', () async {
    when(mockUser.uid).thenReturn('uid-1');
    when(mockUser.emailVerified).thenReturn(true);
    when(mockUser.email).thenReturn('test@mail.com');

    when(mockCredential.user).thenReturn(mockUser);

    when(auth.signInWithEmailAndPassword(
      email: 'test@mail.com',
      password: '123456',
    )).thenAnswer((_) async => mockCredential);

    // ---------- Firestore where(username) ----------
    when(firestore.collection(EnvConfig.usersCollection)).thenReturn(usersCollection);

    when(usersCollection.where(
      UserModelFields.username,
      isEqualTo: anyNamed('isEqualTo'),
    )).thenReturn(usersQuery);

    when(usersQuery.limit(1)).thenReturn(usersQuery);
    when(usersQuery.get()).thenAnswer((_) async => querySnapshot);

    when(querySnapshot.docs).thenReturn([snapshot]);

    // ---------- Firestore doc(uid) ----------
    when(usersCollection.doc('uid-1')).thenReturn(userDoc);
    when(userDoc.get()).thenAnswer((_) async => snapshot);

    when(snapshot.id).thenReturn('uid-1');
    when(snapshot.data()).thenReturn({
      'name': 'Test User',
      'email': 'test@mail.com',
      'username': 'username',
      'photoUrl': null,
      'isEmailVerified': true,
      'isOnline': false,
      'lastOnlineAt': null,
    });

    final result = await service.login(
      username: 'username',
      password: '123456',
    );

    expect(result, isA<UserModel>());
    expect(result.id, 'uid-1');
    expect(result.name, 'Test User');
  });

  test('REGISTER SUCCESS', () async {
    when(mockUser.uid).thenReturn('uid-2');
    when(mockUser.emailVerified).thenReturn(false);
    when(mockUser.sendEmailVerification()).thenAnswer((_) async {});

    when(mockCredential.user).thenReturn(mockUser);

    when(auth.createUserWithEmailAndPassword(
      email: 'new@mail.com',
      password: '123456',
    )).thenAnswer((_) async => mockCredential);

    when(firestore.collection(EnvConfig.usersCollection)).thenReturn(usersCollection);

    when(usersCollection.doc('uid-2')).thenReturn(userDoc);
    when(userDoc.set(any)).thenAnswer((_) async {});

    final result = await service.register(
      email: 'new@mail.com',
      password: '123456',
      name: 'New User',
      username: 'username',
    );

    expect(result.id, 'uid-2');
    expect(result.name, 'New User');

    verify(mockUser.sendEmailVerification()).called(1);
    verify(userDoc.set(any)).called(1);
  });

  test('LOGOUT', () async {
    when(auth.signOut()).thenAnswer((_) async {});

    await service.logout();

    verify(auth.signOut()).called(1);
  });
}

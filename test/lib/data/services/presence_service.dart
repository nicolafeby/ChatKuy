import 'package:chatkuy/data/services/presence_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'presence_service.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  CollectionReference,
  DocumentReference,
])
Future<void> presenceServiceTest() async {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDoc;

  late PresenceService service;

  const uid = 'uid-1';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(uid);

    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.doc(uid)).thenReturn(mockDoc);
    when(mockDoc.update(any)).thenAnswer((_) async {});

    service = PresenceService(mockAuth, mockFirestore);
  });

  test('init() should set online and register lifecycle observer', () async {
    service.init();

    verify(mockDoc.update(argThat(
      containsPair('isOnline', true),
    ))).called(1);
  });

  test('setOnline updates firestore with isOnline=true', () async {
    await service.setOnline();

    verify(mockDoc.update(argThat(
      containsPair('isOnline', true),
    ))).called(1);
  });

  test('setOffline updates firestore with isOnline=false', () async {
    await service.setOffline();

    verify(mockDoc.update(argThat(
      containsPair('isOnline', false),
    ))).called(1);
  });

  test('resumed lifecycle should call setOnline', () async {
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    verify(mockDoc.update(argThat(
      containsPair('isOnline', true),
    ))).called(1);
  });

  test('paused lifecycle should call setOffline', () async {
    service.didChangeAppLifecycleState(AppLifecycleState.paused);

    verify(mockDoc.update(argThat(
      containsPair('isOnline', false),
    ))).called(1);
  });

  test('inactive lifecycle should call setOffline', () async {
    service.didChangeAppLifecycleState(AppLifecycleState.inactive);

    verify(mockDoc.update(argThat(
      containsPair('isOnline', false),
    ))).called(1);
  });

  test('should do nothing if user is null', () async {
    when(mockAuth.currentUser).thenReturn(null);

    await service.setOnline();
    await service.setOffline();
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    verifyNever(mockFirestore.collection(any));
  });
}

import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  User,
  WriteBatch,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>,
  DocumentSnapshot<Map<String, dynamic>>,
  Query<Map<String, dynamic>>,
  QuerySnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
  SnapshotMetadata,
])
import 'chat_service.mocks.dart';

Future<void> chatServiceTest() async {
  late MockFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late ChatService service;

  late MockUser mockUser;
  late MockWriteBatch mockBatch;

  // Chat room
  late MockCollectionReference<Map<String, dynamic>> roomsCollection;
  late MockDocumentReference<Map<String, dynamic>> roomDoc;

  // Messages
  late MockCollectionReference<Map<String, dynamic>> messagesCollection;
  late MockDocumentReference<Map<String, dynamic>> messageDocRef;
  late MockQuery<Map<String, dynamic>> messageQuery;
  late MockQuerySnapshot<Map<String, dynamic>> messageQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> messageSnapshot;

  // Users
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockDocumentSnapshot<Map<String, dynamic>> userSnapshot;
  late MockSnapshotMetadata mockMetadata;

  setUp(() {
    firestore = MockFirebaseFirestore();
    auth = MockFirebaseAuth();
    service = ChatService(auth, firestore);

    mockUser = MockUser();
    mockBatch = MockWriteBatch();

    roomsCollection = MockCollectionReference();
    roomDoc = MockDocumentReference();

    messagesCollection = MockCollectionReference();
    messageDocRef = MockDocumentReference();
    messageQuery = MockQuery();
    messageQuerySnapshot = MockQuerySnapshot();
    messageSnapshot = MockQueryDocumentSnapshot();

    usersCollection = MockCollectionReference();
    userDoc = MockDocumentReference();
    userSnapshot = MockDocumentSnapshot();
    mockMetadata = MockSnapshotMetadata();
  });

  // ==========================================================
  // WATCH MESSAGES
  // ==========================================================
  test('watchMessages emits list of ChatMessageModel', () async {
    when(firestore.collection(FirebaseCollections.chatRooms)).thenReturn(roomsCollection);

    when(roomsCollection.doc('room-1')).thenReturn(roomDoc);

    when(roomDoc.collection(FirestoreCollection.messages)).thenReturn(messagesCollection);

    when(messagesCollection.orderBy(MessageField.createdAtClient)).thenReturn(messageQuery);

    when(
      messageQuery.snapshots(includeMetadataChanges: true),
    ).thenAnswer((_) => Stream.value(messageQuerySnapshot));

    when(messageQuerySnapshot.docs).thenReturn([messageSnapshot]);

    when(messageSnapshot.id).thenReturn('msg-1');

    when(mockMetadata.hasPendingWrites).thenReturn(false);
    when(messageSnapshot.metadata).thenReturn(mockMetadata);

    when(messageSnapshot.data()).thenReturn({
      MessageField.senderId: 'user-1',
      MessageField.text: 'Hello',
      MessageField.createdAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
      MessageField.createdAtClient: Timestamp.fromDate(DateTime(2025, 1, 1)),
      MessageField.deliveredTo: {},
      MessageField.readBy: {},
    });

    final result = await service.watchMessages(roomId: 'room-1').first;

    expect(result.length, 1);
    expect(result.first.id, 'msg-1');
    expect(result.first.text, 'Hello');
  });

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================
  test('sendMessage writes message and updates room using batch', () async {
    when(auth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user-1');

    when(firestore.collection(FirebaseCollections.chatRooms)).thenReturn(roomsCollection);

    when(roomsCollection.doc('room-1')).thenReturn(roomDoc);

    when(roomDoc.collection(FirestoreCollection.messages)).thenReturn(messagesCollection);

    when(messagesCollection.doc()).thenReturn(messageDocRef);

    when(firestore.batch()).thenReturn(mockBatch);

    // 🔥 mock users/{uid}
    when(firestore.collection('users')).thenReturn(usersCollection);

    when(usersCollection.doc('user-1')).thenReturn(userDoc);

    when(userDoc.get()).thenAnswer((_) async => userSnapshot);

    when(userSnapshot.data()).thenReturn({
      FriendField.name: 'Budi',
    });

    when(mockBatch.commit()).thenAnswer((_) async {});

    await service.sendMessage(
      roomId: 'room-1',
      text: 'Hi',
    );

    verify(mockBatch.set(
      messageDocRef,
      argThat(allOf(
        containsPair(MessageField.text, 'Hi'),
        containsPair(MessageField.senderId, 'user-1'),
        containsPair(MessageField.senderName, 'Budi'),
      )),
    )).called(1);

    verify(mockBatch.update(
      roomDoc,
      argThat(containsPair(ChatRoomField.lastMessage, 'Hi')),
    )).called(1);

    verify(mockBatch.commit()).called(1);
  });

  // ==========================================================
  // MARK READ
  // ==========================================================
  test('markRead updates readBy on message document', () async {
    when(firestore.collection(FirebaseCollections.chatRooms)).thenReturn(roomsCollection);

    when(roomsCollection.doc('room-1')).thenReturn(roomDoc);

    when(roomDoc.collection(FirestoreCollection.messages)).thenReturn(messagesCollection);

    when(messagesCollection.doc('msg-1')).thenReturn(messageDocRef);

    when(messageDocRef.update(any)).thenAnswer((_) async {});

    await service.markRead(
      roomId: 'room-1',
      messageId: 'msg-1',
      uid: 'user-1',
    );

    verify(messageDocRef.update({
      '${MessageField.readBy}.user-1': true,
    })).called(1);
  });
}

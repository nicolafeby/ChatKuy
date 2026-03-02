import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseStorage,
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
  late MockFirebaseStorage firebaseStorage;
  late ChatService service;

  late MockUser mockUser;
  late MockWriteBatch mockBatch;

  late MockCollectionReference<Map<String, dynamic>> roomsCollection;
  late MockDocumentReference<Map<String, dynamic>> roomDoc;

  late MockCollectionReference<Map<String, dynamic>> messagesCollection;
  late MockDocumentReference<Map<String, dynamic>> messageDocRef;
  late MockQuery<Map<String, dynamic>> messageQuery;
  late MockQuerySnapshot<Map<String, dynamic>> messageQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> messageSnapshot;

  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockDocumentSnapshot<Map<String, dynamic>> userSnapshot;
  late MockSnapshotMetadata mockMetadata;
  late MockDocumentSnapshot<Map<String, dynamic>> roomSnapshot;

  setUp(() {
    firestore = MockFirebaseFirestore();
    auth = MockFirebaseAuth();
    firebaseStorage = MockFirebaseStorage();
    service = ChatService(auth, firestore, firebaseStorage);

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
    roomSnapshot = MockDocumentSnapshot();
  });

  // ==========================================================
  // WATCH MESSAGES
  // ==========================================================
  test('watchMessages emits updated list after firestore snapshot', () async {
    when(firestore.collection(FirebaseCollections.chatRooms)).thenReturn(roomsCollection);

    when(roomsCollection.doc('room-1')).thenReturn(roomDoc);

    when(roomDoc.collection(FirestoreCollection.messages)).thenReturn(messagesCollection);

    when(messagesCollection.orderBy(MessageField.createdAtClient)).thenReturn(messageQuery);

    when(messageQuery.snapshots(includeMetadataChanges: true)).thenAnswer((_) => Stream.value(messageQuerySnapshot));

    when(messageQuerySnapshot.docs).thenReturn([messageSnapshot]);

    when(messageSnapshot.id).thenReturn('msg-1');

    when(mockMetadata.hasPendingWrites).thenReturn(false);
    when(messageSnapshot.metadata).thenReturn(mockMetadata);

    when(messageSnapshot.data()).thenReturn({
      MessageField.senderId: 'user-1',
      MessageField.text: 'Hello',
      MessageField.imageUrl: null,
      MessageField.type: 'text',
      MessageField.deliveredTo: {},
      MessageField.readBy: {},
    });

    // skip emission pertama (local)
    final result = await service.watchMessages(roomId: 'room-1').skip(1).first;

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
    when(messageDocRef.id).thenReturn('msg-1');

    when(firestore.batch()).thenReturn(mockBatch);

    when(roomDoc.get()).thenAnswer((_) async => roomSnapshot);
    when(roomSnapshot.data()).thenReturn({
      ChatRoomField.participants: ['user-1', 'user-2'],
    });

    when(firestore.collection(FirebaseCollections.users)).thenReturn(usersCollection);

    when(usersCollection.doc('user-1')).thenReturn(userDoc);
    when(userDoc.get()).thenAnswer((_) async => userSnapshot);
    when(userSnapshot.data()).thenReturn({
      FriendField.name: 'Budi',
    });

    when(mockBatch.commit()).thenAnswer((_) async {});

    await service.sendMessage(
      roomId: 'room-1',
      text: 'Hi',
      type: MessageType.text,
    );

    verify(mockBatch.set(
      messageDocRef,
      argThat(predicate<Map<String, dynamic>>((data) =>
          data[MessageField.text] == 'Hi' &&
          data[MessageField.senderId] == 'user-1' &&
          data[MessageField.senderName] == 'Budi' &&
          data[MessageField.type] == 'text')),
    )).called(1);

    verify(mockBatch.update(
      roomDoc,
      argThat(predicate<Map<String, dynamic>>((data) =>
          data[ChatRoomField.lastMessage] == 'Hi' &&
          data[ChatRoomField.lastSenderId] == 'user-1' &&
          data.containsKey('${ChatRoomField.unreadCount}.user-1') &&
          data.containsKey('${ChatRoomField.unreadCount}.user-2'))),
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

import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
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
  Query<Map<String, dynamic>>,
  QuerySnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
])
import 'chat_service.mocks.dart';

void chatServiceTest() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockFirebaseAuth;
  late ChatService service;

  late MockCollectionReference<Map<String, dynamic>> mockRoomsCollection;
  late MockDocumentReference<Map<String, dynamic>> mockRoomDoc;
  late MockCollectionReference<Map<String, dynamic>> mockMessagesCollection;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> mockMessageDoc;
  late MockDocumentReference<Map<String, dynamic>> mockMessageDocRef;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFirebaseAuth = MockFirebaseAuth();
    service = ChatService(mockFirebaseAuth, mockFirestore);

    mockRoomsCollection = MockCollectionReference();
    mockRoomDoc = MockDocumentReference();
    mockMessagesCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockMessageDoc = MockQueryDocumentSnapshot();
    mockMessageDocRef = MockDocumentReference();
  });

  test('watchMessages emits list of ChatMessageModel', () async {
    when(mockFirestore.collection(FirestoreCollection.chatRooms)).thenReturn(mockRoomsCollection);

    when(mockRoomsCollection.doc('room-1')).thenReturn(mockRoomDoc);

    when(mockRoomDoc.collection(FirestoreCollection.messages)).thenReturn(mockMessagesCollection);

    when(mockMessagesCollection.orderBy(MessageField.createdAt)).thenReturn(mockQuery);

    when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

    when(mockQuerySnapshot.docs).thenReturn([mockMessageDoc]);

    when(mockMessageDoc.id).thenReturn('msg-1');
    when(mockMessageDoc.data()).thenReturn({
      MessageField.senderId: 'user-1',
      MessageField.text: 'Hello',
      MessageField.createdAt: Timestamp.fromDate(DateTime(2025)),
    });

    final result = await service.watchMessages(roomId: 'room-1').first;

    expect(result.length, 1);
    expect(result.first.id, 'msg-1');
    expect(result.first.text, 'Hello');
  });

  test('sendMessage uses batch set & update', () async {
    final mockUser = MockUser();
    final mockBatch = MockWriteBatch();

    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user-1');

    when(mockFirestore.collection(FirestoreCollection.chatRooms)).thenReturn(mockRoomsCollection);

    when(mockRoomsCollection.doc('room-1')).thenReturn(mockRoomDoc);

    when(mockRoomDoc.collection(FirestoreCollection.messages)).thenReturn(mockMessagesCollection);

    when(mockMessagesCollection.doc()).thenReturn(mockMessageDocRef);

    when(mockFirestore.batch()).thenReturn(mockBatch);

    when(mockBatch.commit()).thenAnswer((_) async {});

    await service.sendMessage(
      roomId: 'room-1',
      text: 'Hi',
    );

    verify(mockBatch.set(
      mockMessageDocRef,
      argThat(
        containsPair(MessageField.text, 'Hi'),
      ),
    )).called(1);

    verify(mockBatch.update(
      mockRoomDoc,
      argThat(
        containsPair(ChatRoomField.lastMessage, 'Hi'),
      ),
    )).called(1);

    verify(mockBatch.commit()).called(1);
  });

  test('markAsRead updates unread count', () async {
    when(mockFirestore.collection(FirestoreCollection.chatRooms)).thenReturn(mockRoomsCollection);

    when(mockRoomsCollection.doc('room-1')).thenReturn(mockRoomDoc);

    when(mockRoomDoc.update(any)).thenAnswer((_) async {});

    await service.markAsRead(
      roomId: 'room-1',
      uid: 'user-1',
    );

    verify(mockRoomDoc.update({
      '${ChatRoomField.unreadCount}.user-1': 0,
    })).called(1);
  });
}

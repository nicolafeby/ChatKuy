import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/data/models/message_model.dart';
import 'package:chatkuy/data/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'chat_service.mocks.dart';

void chatServiceTest() {
  late MockFirebaseFirestore mockFirestore;
  late ChatService service;

  late MockCollectionReference<Map<String, dynamic>> mockRoomsCollection;
  late MockDocumentReference<Map<String, dynamic>> mockRoomDoc;
  late MockCollectionReference<Map<String, dynamic>> mockMessagesCollection;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> mockMessageDoc;
  late MockDocumentReference<Map<String, dynamic>> mockAddedDocRef;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    service = ChatService(mockFirestore);

    mockRoomsCollection = MockCollectionReference();
    mockRoomDoc = MockDocumentReference();
    mockMessagesCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockMessageDoc = MockQueryDocumentSnapshot();
    mockAddedDocRef = MockDocumentReference();
  });

  group('ChatService.watchMessages', () {
    test('emit list of MessageModel', () async {
      when(mockFirestore.collection(EnvConfig.chatRoomsCollection)).thenReturn(mockRoomsCollection);

      when(mockRoomsCollection.doc('room-1')).thenReturn(mockRoomDoc);

      when(mockRoomDoc.collection(EnvConfig.messagesCollection)).thenReturn(mockMessagesCollection);

      when(mockMessagesCollection.orderBy('createdAt')).thenReturn(mockQuery);

      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      when(mockQuerySnapshot.docs).thenReturn([mockMessageDoc]);

      when(mockMessageDoc.id).thenReturn('msg-1');

      when(mockMessageDoc.data()).thenReturn({
        'senderId': 'user-1',
        'text': 'Hello',
        'createdAt': Timestamp.now(),
      });

      final stream = service.watchMessages('room-1');
      final result = await stream.first;

      expect(result, isA<List<MessageModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'msg-1');
      expect(result.first.text, 'Hello');
    });
  });

  group('ChatService.sendMessage', () {
    test('add message to firestore', () async {
      final message = MessageModel(
        id: '',
        senderId: 'user-1',
        text: 'Hi',
        createdAt: DateTime.now(),
      );

      when(mockFirestore.collection(EnvConfig.chatRoomsCollection)).thenReturn(mockRoomsCollection);

      when(mockRoomsCollection.doc('room-1')).thenReturn(mockRoomDoc);

      when(mockRoomDoc.collection(EnvConfig.messagesCollection)).thenReturn(mockMessagesCollection);

      when(mockMessagesCollection.add(any)).thenAnswer((_) async => mockAddedDocRef);

      await service.sendMessage('room-1', message);

      verify(mockMessagesCollection.add(message.toJson())).called(1);
    });
  });
}

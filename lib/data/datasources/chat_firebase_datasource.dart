import 'package:chatkuy/core/constants/firebase_collections.dart';
import 'package:chatkuy/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFirebaseDatasource {
  final FirebaseFirestore firestore;

  ChatFirebaseDatasource(this.firestore);

  Future<List<MessageModel>> getMessages(String roomId) async {
    final snapshot = await firestore
        .collection(FirebaseCollections.chatRooms)
        .doc(roomId)
        .collection(FirebaseCollections.messages)
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      return MessageModel.fromJson(doc.data()).copyWith(id: doc.id);
    }).toList();
  }

  Future<void> sendMessage(
    String roomId,
    MessageModel message,
  ) {
    return firestore
        .collection(FirebaseCollections.chatRooms)
        .doc(roomId)
        .collection(FirebaseCollections.messages)
        .add(message.toJson());
  }
}

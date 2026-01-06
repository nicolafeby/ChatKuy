import 'package:chatkuy/core/config/env_config.dart';
import 'package:chatkuy/data/models/message_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService implements ChatRepository {
  ChatService(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Stream<List<MessageModel>> watchMessages(String roomId) {
    return firestore
        .collection(EnvConfig.chatRoomsCollection)
        .doc(roomId)
        .collection(EnvConfig.messagesCollection)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel
                .fromJson(doc.data())
                .copyWith(id: doc.id);
          }).toList();
        });
  }

  @override
  Future<void> sendMessage(String roomId, MessageModel message) {
    return firestore
        .collection(EnvConfig.chatRoomsCollection)
        .doc(roomId)
        .collection(EnvConfig.messagesCollection)
        .add(message.toJson());
  }
}

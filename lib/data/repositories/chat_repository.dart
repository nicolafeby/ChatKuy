import 'package:chatkuy/data/datasources/chat_firebase_datasource.dart';
import 'package:chatkuy/data/models/message_model.dart';

class ChatRepository {
  final ChatFirebaseDatasource datasource;

  ChatRepository(this.datasource);

  Future<List<MessageModel>> getMessages(String roomId) {
    return datasource.getMessages(roomId);
  }

  Future<void> sendMessage(
    String roomId,
    MessageModel message,
  ) {
    return datasource.sendMessage(roomId, message);
  }
}


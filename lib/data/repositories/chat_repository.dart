import 'package:chatkuy/data/models/message_model.dart';

abstract class ChatRepository {
  Stream<List<MessageModel>> watchMessages(String roomId);
  Future<void> sendMessage(String roomId, MessageModel message);
}

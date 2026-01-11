import 'package:chatkuy/data/models/chat_user_item_model.dart';

abstract class ChatUserListRepository {
  Stream<List<ChatUserItemModel>> watchChatUsers({
    required String myUid,
  });
}

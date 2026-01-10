import 'package:chatkuy/data/models/chat_room_model.dart';
import 'package:chatkuy/data/repositories/auth_repository.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:mobx/mobx.dart';

part 'chat_list_store.g.dart';

class ChatListStore = _ChatListStore with _$ChatListStore;

abstract class _ChatListStore with Store {
  _ChatListStore({
    required this.chatRepository,
    required this.authRepository,
  }) {
    getUid();
  }

  final ChatRepository chatRepository;
  final AuthRepository authRepository;

  @observable
  String? uid;

  // -------------------------------
  // STATE
  // -------------------------------
  @observable
  ObservableStream<List<ChatRoomModel>>? chatRooms;

  void getUid() {
    uid = authRepository.currentUid;
  }

  // -------------------------------
  // ACTIONS
  // -------------------------------
  @action
  void init(String uid) {
    if (chatRooms != null) return;
    chatRooms = chatRepository.watchChatRooms(uid: uid).asObservable();
  }

  @action
  void dispose() {
    chatRooms = null;
  }
}

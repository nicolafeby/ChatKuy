import 'dart:async';

import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:mobx/mobx.dart';
import 'package:chatkuy/data/models/chat_user_item_model.dart';

part 'chat_user_list_store.g.dart';

class ChatUserListStore = _ChatUserListStore with _$ChatUserListStore;

abstract class _ChatUserListStore with Store {
  _ChatUserListStore({required this.repository}) {
    _getUid();
  }

  final ChatUserListRepository repository;

  StreamSubscription<List<ChatUserItemModel>>? _subscription;

  // -----------------------------
  // STATE
  // -----------------------------
  @observable
  ObservableList<ChatUserItemModel> chatUsers = ObservableList<ChatUserItemModel>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  // -----------------------------
  // ACTION
  // -----------------------------
  @action
  void watchChatUsers(String myUid) {
    isLoading = true;
    errorMessage = null;

    _subscription?.cancel();
    _subscription = repository.watchChatUsers(myUid: myUid).listen((users) {
      chatUsers
        ..clear()
        ..addAll(users);
      isLoading = false;
    }, onError: (e) {
      errorMessage = e.toString();
      isLoading = false;
    });
  }

  String? currentUid;

  void _getUid() async {
    currentUid = await getIt<SecureStorageRepository>().getUserId();
  }

  @action
  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

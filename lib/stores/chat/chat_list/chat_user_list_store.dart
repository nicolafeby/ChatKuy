import 'dart:async';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  ObservableList<ChatUserItemModel> chatUsers =
      ObservableList<ChatUserItemModel>();

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
    currentUid = myUid;

    _subscription?.cancel();
    _subscription = repository.watchChatUsers(myUid: myUid).listen((users) {
      chatUsers
        ..clear()
        ..addAll(users);
      isLoading = false;
    }, onError: (e, stackTrace) {
      if (_isExpectedLogoutStreamError(e)) {
        isLoading = false;
        return;
      }

      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Chat user list stream failed',
        context: {'current_uid': myUid},
      );
      errorMessage = e.toString();
      isLoading = false;
    });
  }

  bool _isExpectedLogoutStreamError(Object error) {
    return FirebaseAuth.instance.currentUser == null &&
        error is FirebaseException &&
        error.code == 'permission-denied';
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

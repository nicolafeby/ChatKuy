import 'dart:async';

import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/models/chat_message_model.dart';
import 'package:chatkuy/data/repositories/chat_user_list_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
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

  @observable
  String searchQuery = '';

  @computed
  List<ChatUserItemModel> get filteredChatUsers {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return chatUsers;

    return chatUsers.where((item) {
      final name = item.user.name.toLowerCase();
      final email = item.user.email.toLowerCase();
      final lastMessage = item.lastMessage?.toLowerCase() ?? '';
      final matchingMessage = matchedMessageText(item)?.toLowerCase() ?? '';

      return name.contains(query) ||
          email.contains(query) ||
          lastMessage.contains(query) ||
          matchingMessage.contains(query);
    }).toList();
  }

  List<ChatSearchResult> get searchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final results = <ChatSearchResult>[];

    for (final item in chatUsers) {
      final matchingMessages = _matchingMessages(item, query);

      for (final message in matchingMessages) {
        results.add(
          ChatSearchResult(
            item: item,
            message: message,
            previewText: _searchableMessageText(message),
          ),
        );
      }

      final name = item.user.name.toLowerCase();
      final email = item.user.email.toLowerCase();
      final lastMessage = item.lastMessage?.toLowerCase() ?? '';
      final hasProfileMatch = name.contains(query) || email.contains(query);
      final hasLastMessageMatch = lastMessage.contains(query);

      if (matchingMessages.isEmpty &&
          (hasProfileMatch || hasLastMessageMatch)) {
        results.add(
          ChatSearchResult(
            item: item,
            message: null,
            previewText: item.lastMessage?.isNotEmpty == true
                ? item.lastMessage!
                : item.user.email,
          ),
        );
      }
    }

    results.sort((a, b) {
      final aDate = a.message?.createdAtClient ?? a.item.lastMessageAt;
      final bDate = b.message?.createdAtClient ?? b.item.lastMessageAt;
      return (bDate ?? DateTime(0)).compareTo(aDate ?? DateTime(0));
    });

    return results;
  }

  String? matchedMessageText(ChatUserItemModel item) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return null;

    final matchingMessages = _matchingMessages(item, query);
    if (matchingMessages.isEmpty) return null;

    return _searchableMessageText(matchingMessages.first);
  }

  List<ChatMessageModel> _matchingMessages(
    ChatUserItemModel item,
    String query,
  ) {
    if (!Hive.isBoxOpen('chat_messages')) return const [];

    final messages = Hive.box<ChatMessageModel>('chat_messages')
        .values
        .where(
          (message) =>
              message.roomId == item.roomId &&
              (currentUid == null || message.deletedFor[currentUid] != true),
        )
        .toList()
      ..sort((a, b) => b.createdAtClient.compareTo(a.createdAtClient));

    return messages
        .where(
          (message) =>
              _searchableMessageText(message).toLowerCase().contains(query),
        )
        .toList();
  }

  // -----------------------------
  // ACTION
  // -----------------------------
  @action
  void setSearchQuery(String value) {
    searchQuery = value;
  }

  @action
  void clearSearch() {
    searchQuery = '';
  }

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

  String _searchableMessageText(ChatMessageModel message) {
    final text = message.text?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (message.type == MessageType.image) return 'Foto';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.call) return 'Panggilan';
    return '';
  }

  @action
  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

class ChatSearchResult {
  const ChatSearchResult({
    required this.item,
    required this.message,
    required this.previewText,
  });

  final ChatUserItemModel item;
  final ChatMessageModel? message;
  final String previewText;
}

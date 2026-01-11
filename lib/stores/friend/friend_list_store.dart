import 'dart:async';

import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/repositories/chat_repository.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:chatkuy/data/repositories/secure_storage_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:mobx/mobx.dart';

part 'friend_list_store.g.dart';

class FriendListStore = _FriendListStore with _$FriendListStore;

abstract class _FriendListStore with Store {
  _FriendListStore({
    required this.friendRepository,
    required this.chatRepository,
  }) {
    init();
    listenFriends();
  }

  final FriendRepository friendRepository;
  final ChatRepository chatRepository;

  StreamSubscription<List<FriendModel>>? _subscription;

  List<FriendModel> _allFriends = [];

  // ======================
  // STATE
  // ======================

  @observable
  ObservableList<FriendModel> friends = ObservableList<FriendModel>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  String searchQuery = '';

  @observable
  String? roomId;

  @observable
  String? currentUid;

  // ======================
  // INIT
  // ======================

  Future<void> init() async {
    currentUid = await getIt<SecureStorageRepository>().getUserId();
  }

  // ======================
  // STREAM FRIENDS
  // ======================

  @action
  void listenFriends() {
    _subscription?.cancel();

    isLoading = true;
    errorMessage = null;

    _subscription = friendRepository.streamFriends().listen(
      (data) {
        _allFriends = data;
        _applySearch();
        isLoading = false;
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
      },
    );
  }

  // ======================
  // SEARCH
  // ======================

  @action
  void searchFriends(String query) {
    searchQuery = query;
    _applySearch();
  }

  @action
  void _applySearch() {
    final q = searchQuery.trim().toLowerCase();

    final filtered = q.isEmpty
        ? _allFriends
        : _allFriends.where((friend) {
            final user = friend.user;

            return user.name.toLowerCase().contains(q) ||
                (user.username?.toLowerCase().contains(q) ?? false);
          }).toList();

    friends
      ..clear()
      ..addAll(filtered);
  }

  // ======================
  // OPEN CHAT
  // ======================

  @action
  Future<void> openChat({
    required String targetUid,
  }) async {
    if (currentUid == null) return;

    isLoading = true;
    errorMessage = null;

    try {
      roomId = await chatRepository.createOrGetRoom(
        currentUid: currentUid!,
        targetUid: targetUid,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  // ======================
  // CLEANUP
  // ======================

  void dispose() {
    _subscription?.cancel();
  }
}

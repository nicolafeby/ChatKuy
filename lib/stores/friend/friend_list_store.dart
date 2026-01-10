import 'dart:async';

import 'package:chatkuy/data/models/friend_model.dart';
import 'package:chatkuy/data/repositories/friend_repository.dart';
import 'package:mobx/mobx.dart';

part 'friend_list_store.g.dart';

class FriendListStore = _FriendListStore with _$FriendListStore;

abstract class _FriendListStore with Store {
  _FriendListStore({required this.friendRepository});

  final FriendRepository friendRepository;

  StreamSubscription<List<FriendModel>>? _subscription;

  List<FriendModel> _allFriends = [];

  @observable
  ObservableList<FriendModel> friends = ObservableList<FriendModel>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  String searchQuery = '';

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
            return friend.username.toLowerCase().contains(q) ||
                (friend.displayName?.toLowerCase().contains(q) ?? false);
          }).toList();

    friends
      ..clear()
      ..addAll(filtered);
  }

  void dispose() {
    _subscription?.cancel();
  }
}

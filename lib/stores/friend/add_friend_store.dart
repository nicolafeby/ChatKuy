import 'package:chatkuy/core/utils/app_error_logger.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:mobx/mobx.dart';

part 'add_friend_store.g.dart';

class AddFriendStore = _AddFriendStore with _$AddFriendStore;

abstract class _AddFriendStore with Store {
  _AddFriendStore({required this.repository});

  final FriendRequestRepository repository;

  // ======================
  // STATE
  // ======================
  @observable
  String username = '';

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  // ======================
  // COMPUTED
  // ======================
  @computed
  bool get canSubmit => username.trim().isNotEmpty && !isLoading;

  // ======================
  // ACTIONS
  // ======================
  @action
  void setUsername(String value) {
    username = value;
    errorMessage = null;
  }

  @action
  Future<bool> addFriend() async {
    if (!canSubmit) {
      errorMessage = 'Username tidak boleh kosong';
      return false;
    }

    try {
      isLoading = true;
      errorMessage = null;

      await repository.sendFriendRequestByUsername(username.trim());
      return true;
    } catch (e, stackTrace) {
      AppErrorLogger.recordError(
        e,
        stackTrace,
        reason: 'Send friend request failed',
        context: {'username_length': username.trim().length},
      );
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  void reset() {
    username = '';
    errorMessage = null;
    isLoading = false;
  }
}

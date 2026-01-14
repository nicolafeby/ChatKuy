import 'package:chatkuy/data/models/request_friend_model.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:mobx/mobx.dart';

part 'friend_request_store.g.dart';

class FriendRequestStore = _FriendRequestStore with _$FriendRequestStore;

abstract class _FriendRequestStore with Store {
  _FriendRequestStore({required this.repository});

  final FriendRequestRepository repository;

  // ==============================
  // STREAMS
  // ==============================

  @observable
  ObservableStream<List<FriendRequestModel>>? incomingRequests;

  @observable
  ObservableStream<List<FriendRequestModel>>? outgoingRequests;

  // ==============================
  // COMPUTED
  // ==============================

  @computed
  bool get hasIncoming => incomingRequests?.value?.isNotEmpty == true;

  @computed
  bool get hasOutgoing => outgoingRequests?.value?.isNotEmpty == true;

  // ==============================
  // ACTIONS
  // ==============================

  @action
  void listenIncoming() {
    incomingRequests = ObservableStream(
      repository.streamIncomingFriendRequests(),
    );
  }

  @action
  void listenOutgoing() {
    outgoingRequests = ObservableStream(
      repository.streamOutgoingFriendRequests(),
    );
  }

  @action
  void init() {
    listenIncoming();
    listenOutgoing();
  }

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  /// requestId yang sedang diproses
  @observable
  String? processingRequestId;

  /// ==============================
  /// ACTION
  /// ==============================

  @action
  Future<void> accept({
    required String requestId,
    required String fromUid,
  }) async {
    isLoading = true;
    processingRequestId = requestId;
    errorMessage = null;

    try {
      await repository.acceptFriendRequest(
        requestId: requestId,
        fromUid: fromUid,
      );
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      processingRequestId = null;
    }
  }

  @action
  Future<void> cancelFriendRequest({required String targetUid}) async {
    isLoading = true;
    errorMessage = null;

    try {
      await repository.cancelFriendRequest(targetUid: targetUid);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> rejectFriendRequest({
    required String senderUid,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      await repository.rejectFriendRequest(senderUid: senderUid);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  /// ==============================
  /// HELPERS
  /// ==============================

  bool isProcessing(String requestId) => processingRequestId == requestId;

  @action
  void dispose() {
    incomingRequests = null;
    outgoingRequests = null;
  }
}

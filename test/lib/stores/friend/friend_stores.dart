import 'dart:async';

import 'package:chatkuy/data/models/request_friend_model.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/stores/friend/add_friend_store.dart';
import 'package:chatkuy/stores/friend/friend_request/friend_request_store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> friendStoresTest() async {
  group('AddFriendStore', () {
    test('blocks empty username', () async {
      final store = AddFriendStore(repository: _FakeFriendRequestRepository());

      final result = await store.addFriend();

      expect(result, isFalse);
      expect(store.errorMessage, 'Username tidak boleh kosong');
      expect(store.canSubmit, isFalse);
    });

    test('trims username and sends friend request', () async {
      final repository = _FakeFriendRequestRepository();
      final store = AddFriendStore(repository: repository);

      store.setUsername('  alya  ');
      final result = await store.addFriend();

      expect(result, isTrue);
      expect(repository.sentUsernames, ['alya']);
      expect(store.isLoading, isFalse);
      expect(store.errorMessage, isNull);
    });

    test('stores clean error message on failure', () async {
      final store = AddFriendStore(
        repository: _FakeFriendRequestRepository(
          sendError: Exception('Username tidak ditemukan'),
        ),
      );

      store.setUsername('unknown');
      final result = await store.addFriend();

      expect(result, isFalse);
      expect(store.errorMessage, 'Username tidak ditemukan');
      expect(store.isLoading, isFalse);
    });

    test('reset restores initial state', () {
      final store = AddFriendStore(repository: _FakeFriendRequestRepository());

      store.setUsername('alya');
      store.errorMessage = 'error';
      store.isLoading = true;

      store.reset();

      expect(store.username, '');
      expect(store.errorMessage, isNull);
      expect(store.isLoading, isFalse);
    });
  });

  group('FriendRequestStore', () {
    testWidgets('registers incoming and outgoing request streams',
        (tester) async {
      final repository = _FakeFriendRequestRepository();
      final store = FriendRequestStore(repository: repository);
      addTearDown(repository.dispose);

      store.init();
      await tester.pump();

      expect(store.incomingRequests, isNotNull);
      expect(store.outgoingRequests, isNotNull);
      expect(store.hasIncoming, isFalse);
      expect(store.hasOutgoing, isFalse);

      store.dispose();
      expect(store.incomingRequests, isNull);
      expect(store.outgoingRequests, isNull);
    });

    test('accept marks request as processing and clears it afterward',
        () async {
      final repository = _FakeFriendRequestRepository();
      final store = FriendRequestStore(repository: repository);

      final future = store.accept(requestId: 'request-1', fromUid: 'from-1');

      expect(store.isLoading, isTrue);
      expect(store.isProcessing('request-1'), isTrue);

      await future;

      expect(repository.acceptedRequests, ['request-1:from-1']);
      expect(store.isLoading, isFalse);
      expect(store.processingRequestId, isNull);
      expect(store.errorMessage, isNull);
    });

    test('cancel and reject call repository', () async {
      final repository = _FakeFriendRequestRepository();
      final store = FriendRequestStore(repository: repository);

      await store.cancelFriendRequest(targetUid: 'target-1');
      await store.rejectFriendRequest(senderUid: 'sender-1');

      expect(repository.cancelledTargets, ['target-1']);
      expect(repository.rejectedSenders, ['sender-1']);
      expect(store.isLoading, isFalse);
    });
  });
}

class _FakeFriendRequestRepository implements FriendRequestRepository {
  _FakeFriendRequestRepository({this.sendError});

  final Object? sendError;
  final sentUsernames = <String>[];
  final acceptedRequests = <String>[];
  final cancelledTargets = <String>[];
  final rejectedSenders = <String>[];
  final incomingController =
      StreamController<List<FriendRequestModel>>.broadcast();
  final outgoingController =
      StreamController<List<FriendRequestModel>>.broadcast();

  void emitIncoming(List<FriendRequestModel> requests) {
    incomingController.add(requests);
  }

  void emitOutgoing(List<FriendRequestModel> requests) {
    outgoingController.add(requests);
  }

  void dispose() {
    incomingController.close();
    outgoingController.close();
  }

  @override
  Future<void> acceptFriendRequest({
    required String fromUid,
    required String requestId,
  }) async {
    acceptedRequests.add('$requestId:$fromUid');
  }

  @override
  Future<void> cancelFriendRequest({required String targetUid}) async {
    cancelledTargets.add(targetUid);
  }

  @override
  Future<void> rejectFriendRequest({required String senderUid}) async {
    rejectedSenders.add(senderUid);
  }

  @override
  Future<void> sendFriendRequestByUsername(String username) async {
    if (sendError != null) throw sendError!;
    sentUsernames.add(username);
  }

  @override
  Stream<List<FriendRequestModel>> streamIncomingFriendRequests() {
    return incomingController.stream;
  }

  @override
  Stream<List<FriendRequestModel>> streamOutgoingFriendRequests() {
    return outgoingController.stream;
  }
}

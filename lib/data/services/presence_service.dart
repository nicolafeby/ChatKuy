import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/models/user_presence_model.dart';
import 'package:chatkuy/data/repositories/presence_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver implements PresenceRepository {
  PresenceService(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  User? get _firebaseUser => auth.currentUser;
  DateTime? _lastPresenceWriteAt;
  bool? _lastPresenceOnline;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    setOnline();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_firebaseUser == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;

      case AppLifecycleState.inactive:
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setOffline();
        break;
    }
  }

  @override
  Future<void> setOnline() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    if (_shouldSkipPresenceWrite(true)) return;

    var isOnlineStatusVisible = true;
    try {
      final userDoc = await firestore.collection(FirebaseCollections.users).doc(uid).get();
      isOnlineStatusVisible = userDoc.data()?['isOnlineStatusVisible'] as bool? ?? true;
    } catch (_) {
      isOnlineStatusVisible = true;
    }

    if (!isOnlineStatusVisible) {
      await setOffline();
      return;
    }

    final presence = UserPresenceModel(
      isOnline: true,
      lastOnlineAt: DateTime.now(),
    );

    await firestore.collection(FirebaseCollections.users).doc(uid).update(presence.toJson());
    _markPresenceWritten(true);
  }

  @override
  Future<void> setOffline() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    if (_shouldSkipPresenceWrite(false)) return;

    final presence = UserPresenceModel(
      isOnline: false,
      lastOnlineAt: DateTime.now(),
    );

    await firestore.collection(FirebaseCollections.users).doc(uid).update(presence.toJson());
    _markPresenceWritten(false);
  }

  bool _shouldSkipPresenceWrite(bool nextOnline) {
    final lastWriteAt = _lastPresenceWriteAt;
    if (_lastPresenceOnline != nextOnline || lastWriteAt == null) {
      return false;
    }

    return DateTime.now().difference(lastWriteAt) < const Duration(seconds: 15);
  }

  void _markPresenceWritten(bool isOnline) {
    _lastPresenceOnline = isOnline;
    _lastPresenceWriteAt = DateTime.now();
  }
}

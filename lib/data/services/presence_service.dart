import 'dart:developer';

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

  void init() {
    WidgetsBinding.instance.addObserver(this);
    setOnline();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('Lifecycle: $state');

    if (_firebaseUser == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
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

    final presence = UserPresenceModel(
      isOnline: true,
      lastOnlineAt: DateTime.now(),
    );

    await firestore.collection('users').doc(uid).update(presence.toJson());
  }

  @override
  Future<void> setOffline() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;

    final presence = UserPresenceModel(
      isOnline: false,
      lastOnlineAt: DateTime.now(),
    );

    await firestore.collection('users').doc(uid).update(presence.toJson());
  }
}

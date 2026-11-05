const { setGlobalOptions } = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

const ACCOUNT_STATUS_PENDING_DELETE = 'pending_delete';
const ACCOUNT_STATUS_DELETED = 'deleted';
const DELETE_BATCH_LIMIT = 450;

function callKitAvatarUrl(value) {
  if (!value || typeof value !== 'string') {
    return '';
  }

  return value.startsWith('https://')
    ? value
    : '';
}

async function clearInvalidFcmToken(uid, token, error) {
  const code = error?.code || '';
  const isInvalidToken =
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token';

  if (!uid || !token || !isInvalidToken) {
    return;
  }

  const userRef = admin.firestore().collection('users').doc(uid);
  const userSnap = await userRef.get();

  if (userSnap.exists && userSnap.data().fcmToken === token) {
    await userRef.update({ fcmToken: '' });
    logger.info('🧹 Cleared invalid FCM token:', uid);
  }
}

function firestoreDate(value) {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate();
  }

  return null;
}

function isChatMutedForUser(room, uid) {
  const mutedUntil = room?.mutedUntil || {};
  const mutedUntilForUser = firestoreDate(mutedUntil[uid]);

  if (!mutedUntilForUser) {
    return false;
  }

  return mutedUntilForUser.getTime() > Date.now();
}

function publicProfileFromUser(uid, user) {
  if (user.accountStatus === ACCOUNT_STATUS_DELETED) {
    return {
      id: uid,
      name: 'Deleted User',
      isDeleted: true,
    };
  }

  return {
    id: uid,
    name: user.name || '',
    username: user.username || '',
    photoUrl: user.photoUrl || null,
    gender: user.gender || null,
    isEmailVerified: user.isEmailVerified === true,
    isOnline: user.isOnlineStatusVisible === false ? false : user.isOnline === true,
    lastOnlineAt: user.isOnlineStatusVisible === false
      ? null
      : user.lastOnlineAt || null,
    email: user.isEmailVisible === true ? user.email || '' : '',
    birthDate: user.isBirthDateVisible === true ? user.birthDate || null : null,
    isEmailVisible: user.isEmailVisible === true,
    isBirthDateVisible: user.isBirthDateVisible === true,
    isOnlineStatusVisible: user.isOnlineStatusVisible === true,
  };
}

exports.syncPublicProfile = onDocumentWritten('users/{uid}', async (event) => {
  const publicRef = admin.firestore()
    .collection('public_profiles')
    .doc(event.params.uid);

  if (!event.data?.after.exists) {
    await publicRef.delete();
    return;
  }

  await publicRef.set(
    publicProfileFromUser(event.params.uid, event.data.after.data())
  );
});

async function commitBatchIfNeeded(batchState, force = false) {
  if (batchState.count === 0 || (!force && batchState.count < DELETE_BATCH_LIMIT)) {
    return;
  }

  await batchState.batch.commit();
  batchState.batch = admin.firestore().batch();
  batchState.count = 0;
}

async function queueDelete(batchState, ref) {
  batchState.batch.delete(ref);
  batchState.count += 1;
  await commitBatchIfNeeded(batchState);
}

async function deleteQuery(query) {
  const batchState = {
    batch: admin.firestore().batch(),
    count: 0,
  };

  const snap = await query.get();
  for (const doc of snap.docs) {
    await queueDelete(batchState, doc.ref);
  }

  await commitBatchIfNeeded(batchState, true);
}

async function deleteCollection(collectionRef) {
  await deleteQuery(collectionRef);
}

async function cleanupFriendData(db, uid) {
  const ownFriendsSnap = await db
    .collection('users')
    .doc(uid)
    .collection('friends')
    .get();

  const batchState = {
    batch: db.batch(),
    count: 0,
  };

  for (const doc of ownFriendsSnap.docs) {
    const friendUid = doc.data().uid || doc.id;
    await queueDelete(batchState, doc.ref);
    if (friendUid) {
      await queueDelete(
        batchState,
        db.collection('users').doc(friendUid).collection('friends').doc(uid)
      );
    }
  }

  await commitBatchIfNeeded(batchState, true);

  await deleteQuery(
    db.collectionGroup('friend_requests').where('fromUid', '==', uid)
  );
  await deleteQuery(
    db.collectionGroup('friend_requests').where('toUid', '==', uid)
  );
  await deleteQuery(
    db.collectionGroup('outgoing_friend_requests').where('fromUid', '==', uid)
  );
  await deleteQuery(
    db.collectionGroup('outgoing_friend_requests').where('toUid', '==', uid)
  );

  await deleteCollection(
    db.collection('users').doc(uid).collection('friend_requests')
  );
  await deleteCollection(
    db.collection('users').doc(uid).collection('outgoing_friend_requests')
  );
}

async function detachUserFromChatData(db, uid) {
  const roomSnap = await db
    .collection('chat_rooms')
    .where('participants', 'array-contains', uid)
    .get();

  for (const roomDoc of roomSnap.docs) {
    await db.runTransaction(async (transaction) => {
      const freshRoom = await transaction.get(roomDoc.ref);
      if (!freshRoom.exists) return;

      const room = freshRoom.data();
      const participants = (room.participants || []).filter(
        (participantUid) => participantUid !== uid
      );
      let admins = (room.admins || []).filter(
        (adminUid) => adminUid !== uid
      );

      if (room.isGroup === true && admins.length === 0 && participants.length > 0) {
        admins = [participants[0]];
      }

      const update = {
        participants,
        [`unreadCount.${uid}`]: admin.firestore.FieldValue.delete(),
        [`typing.${uid}`]: admin.firestore.FieldValue.delete(),
        [`mutedUntil.${uid}`]: admin.firestore.FieldValue.delete(),
        [`archivedFor.${uid}`]: admin.firestore.FieldValue.delete(),
        [`deletedChatListFor.${uid}`]: true,
      };

      if (room.isGroup === true) {
        update.admins = admins;
      }

      transaction.update(roomDoc.ref, update);
    });
  }
}

async function cleanupCallData(db, uid) {
  const callSnap = await db
    .collection('calls')
    .where('participants', 'array-contains', uid)
    .get();

  for (const callDoc of callSnap.docs) {
    await deleteCollection(callDoc.ref.collection('caller_candidates'));
    await deleteCollection(callDoc.ref.collection('callee_candidates'));
    await callDoc.ref.update({
      participants: admin.firestore.FieldValue.arrayRemove(uid),
      deletedParticipantIds: admin.firestore.FieldValue.arrayUnion(uid),
      status: 'ended',
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

exports.onAccountDeletionRequested = onDocumentUpdated(
  'users/{uid}',
  async (event) => {
    if (!event.data) {
      logger.error('❌ account deletion event.data is null');
      return;
    }

    const uid = event.params.uid;
    const before = event.data.before.data();
    const after = event.data.after.data();
    const username = after.username;

    if (
      before.accountStatus === after.accountStatus ||
      after.accountStatus !== ACCOUNT_STATUS_PENDING_DELETE
    ) {
      return;
    }

    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);

    logger.info('🧹 Account deletion cleanup started:', uid);

    await userRef.set(
      {
        accountStatus: ACCOUNT_STATUS_DELETED,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        name: 'Deleted User',
        username: admin.firestore.FieldValue.delete(),
        email: admin.firestore.FieldValue.delete(),
        pendingEmail: admin.firestore.FieldValue.delete(),
        photoUrl: admin.firestore.FieldValue.delete(),
        fcmToken: '',
        isOnline: false,
        birthDate: admin.firestore.FieldValue.delete(),
        gender: admin.firestore.FieldValue.delete(),
      },
      { merge: true }
    );

    if (username) {
      await db.collection('usernames').doc(username).delete();
    }

    await cleanupFriendData(db, uid);
    await detachUserFromChatData(db, uid);
    await cleanupCallData(db, uid);

    await deleteCollection(userRef.collection('friends'));
    await deleteCollection(userRef.collection('friend_requests'));
    await deleteCollection(userRef.collection('outgoing_friend_requests'));

    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') {
        throw error;
      }
    }

    logger.info('✅ Account deletion cleanup completed:', uid);
  }
);

exports.onNewMessage = onDocumentCreated(
  'chat_rooms/{roomId}/messages/{messageId}',
  async (event) => {
    logger.info('🔥 FUNCTION TRIGGERED');

    if (!event.data) {
      logger.error('❌ event.data is null');
      return;
    }

    const message = event.data.data();

    const senderId = message.senderId;
    if (!senderId) {
      logger.error('❌ senderId missing');
      return;
    }

    // 🔥 Ambil chat room
    const roomSnap = await admin
      .firestore()
      .collection('chat_rooms')
      .doc(event.params.roomId)
      .get();

    if (!roomSnap.exists) {
      logger.error('❌ chat_room not found');
      return;
    }

    const room = roomSnap.data();
    const participants = room.participants || [];
    logger.info('👥 Participants:', participants);

    const receiverIds = participants.filter((uid) => uid !== senderId);
    if (receiverIds.length === 0) {
      logger.error('❌ receivers not resolved');
      return;
    }

    const receiverSnaps = await admin.firestore().getAll(
      ...receiverIds.map((uid) =>
        admin.firestore().collection('users').doc(uid)
      )
    );
    const recipients = receiverSnaps
      .map((snap) => ({
        uid: snap.id,
        token: snap.exists ? snap.data().fcmToken : null,
      }))
      .filter((recipient) => recipient.token);

    if (recipients.length === 0) {
      logger.info('No chat notification recipients with an FCM token');
      return;
    }

    const payloads = recipients.map(({uid, token}) => {
      const isMuted = isChatMutedForUser(room, uid);
      const payload = {
        token,
        data: {
          type: 'chat',
          roomId: event.params.roomId,
          messageId: event.params.messageId,
          receiverId: uid,
          senderId: message.senderId ?? '',
          senderName: message.senderName ?? '',
          text: message.text ?? '',
        },
        android: {priority: 'high'},
        apns: {
          payload: {
            aps: isMuted ? {'content-available': 1} : {sound: 'default'},
          },
        },
      };

      if (!isMuted) {
        payload.notification = {
          title: message.senderName || 'Pesan Baru',
          body: message.text || 'Ada pesan baru',
        };
        payload.android.notification = {channelId: 'chat_notification'};
      }
      return payload;
    });

    const response = await admin.messaging().sendEach(payloads);
    await Promise.all(response.responses.map((result, index) => {
      if (result.success) return null;
      const recipient = recipients[index];
      return clearInvalidFcmToken(
        recipient.uid,
        recipient.token,
        result.error
      );
    }));
    logger.info('✅ Chat notifications sent', {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
);

exports.onNewVoiceCall = onDocumentCreated(
  'calls/{callId}',
  async (event) => {
    if (!event.data) {
      logger.error('❌ call event.data is null');
      return;
    }

    const call = event.data.data();
    const callerId = call.callerId;
    const calleeId = call.calleeId;

    if (!callerId || !calleeId) {
      logger.error('❌ callerId/calleeId missing');
      return;
    }

    const participants = Array.isArray(call.participants)
      ? call.participants
      : [];
    const roomId = call.roomId;
    const roomSnap = roomId
      ? await admin.firestore().collection('chat_rooms').doc(roomId).get()
      : null;
    const roomParticipants = roomSnap?.exists
      ? roomSnap.data().participants || []
      : [];
    const hasValidCallBinding = callerId !== calleeId &&
      participants.length === 2 &&
      participants.includes(callerId) &&
      participants.includes(calleeId) &&
      roomParticipants.includes(callerId) &&
      roomParticipants.includes(calleeId);

    if (!hasValidCallBinding) {
      logger.error('❌ rejected call with inconsistent participants', {
        callId: event.params.callId,
      });
      return;
    }

    const calleeSnap = await admin
      .firestore()
      .collection('users')
      .doc(calleeId)
      .get();

    if (!calleeSnap.exists) {
      logger.error('❌ callee user not found');
      return;
    }

    const fcmToken = calleeSnap.data().fcmToken;
    if (!fcmToken) {
      logger.error('❌ callee fcmToken missing');
      return;
    }

    const callerSnap = await admin
      .firestore()
      .collection('users')
      .doc(callerId)
      .get();
    const callerData = callerSnap.exists ? callerSnap.data() : {};
    const callerName = call.callerName || callerData.name || 'ChatKuy';
    const callerPhotoUrl = callKitAvatarUrl(callerData.photoUrl);

    try {
      const response = await admin.messaging().send({
        token: fcmToken,
        data: {
          type: 'voice_call',
          callId: event.params.callId,
          roomId: call.roomId || '',
          callerId: callerId,
          callerName: callerName,
          callerPhotoUrl: callerPhotoUrl,
          title: callerName,
          body: 'Panggilan suara masuk',
        },
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              contentAvailable: true,
              sound: 'default',
            },
          },
        },
      });

      logger.info('✅ Voice call FCM sent:', response);
    } catch (error) {
      await clearInvalidFcmToken(calleeId, fcmToken, error);
      throw error;
    }
  }
);

exports.onVoiceCallStatusUpdated = onDocumentUpdated(
  'calls/{callId}',
  async (event) => {
    if (!event.data) {
      logger.error('❌ call update event.data is null');
      return;
    }

    const before = event.data.before.data();
    const after = event.data.after.data();
    const beforeStatus = before.status;
    const afterStatus = after.status;
    const closedStatuses = ['declined', 'ended', 'missed'];

    if (
      beforeStatus === afterStatus ||
      !closedStatuses.includes(afterStatus)
    ) {
      return;
    }

    const participantIds = (after.participants || []).filter(Boolean);
    if (participantIds.length === 0) {
      logger.error('❌ call participants missing');
      return;
    }

    const userSnaps = await admin.firestore().getAll(
      ...participantIds.map((uid) =>
        admin.firestore().collection('users').doc(uid)
      )
    );

    const messages = userSnaps
      .map((snap) => (snap.exists ? snap.data().fcmToken : null))
      .filter(Boolean)
      .map((token) => ({
        token,
        data: {
          type: 'voice_call_ended',
          callId: event.params.callId,
          status: afterStatus,
        },
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              contentAvailable: true,
            },
          },
        },
      }));

    if (messages.length === 0) {
      logger.error('❌ no fcmToken found for call participants');
      return;
    }

    const response = await admin.messaging().sendEach(messages);
    logger.info('✅ Voice call ended FCM sent:', response);
  }
);

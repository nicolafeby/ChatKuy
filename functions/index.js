const { setGlobalOptions } = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
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

  return value.startsWith('http://') || value.startsWith('https://')
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

function storagePathFromDownloadUrl(value) {
  if (!value || typeof value !== 'string') {
    return null;
  }

  try {
    const url = new URL(value);
    const marker = '/o/';
    const markerIndex = url.pathname.indexOf(marker);

    if (markerIndex >= 0) {
      return decodeURIComponent(url.pathname.substring(markerIndex + marker.length));
    }

    const pathParts = url.pathname.split('/').filter(Boolean);
    if (pathParts.length > 1) {
      return decodeURIComponent(pathParts.slice(1).join('/'));
    }
  } catch (error) {
    logger.warn('⚠️ Failed to parse storage URL', {
      error: error?.message,
    });
  }

  return null;
}

async function deleteStorageFileFromUrl(bucket, url) {
  const storagePath = storagePathFromDownloadUrl(url);
  if (!storagePath) {
    return;
  }

  try {
    await bucket.file(storagePath).delete({ ignoreNotFound: true });
  } catch (error) {
    logger.warn('⚠️ Failed to delete storage file', {
      storagePath,
      error: error?.message,
    });
  }
}

async function cleanupMessageStorage(bucket, message) {
  await Promise.all([
    deleteStorageFileFromUrl(bucket, message.imageUrl),
    deleteStorageFileFromUrl(bucket, message.videoUrl),
    deleteStorageFileFromUrl(bucket, message.fileUrl),
    deleteStorageFileFromUrl(bucket, message.audioUrl),
  ]);
}

async function deleteRoomMessagesAndStorage(roomRef, bucket) {
  const batchState = {
    batch: admin.firestore().batch(),
    count: 0,
  };
  const snap = await roomRef.collection('messages').get();

  for (const doc of snap.docs) {
    await cleanupMessageStorage(bucket, doc.data());
    await queueDelete(batchState, doc.ref);
  }

  await commitBatchIfNeeded(batchState, true);
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

async function cleanupChatData(db, uid) {
  const bucket = admin.storage().bucket();
  const roomSnap = await db
    .collection('chat_rooms')
    .where('participants', 'array-contains', uid)
    .get();

  for (const roomDoc of roomSnap.docs) {
    await deleteRoomMessagesAndStorage(roomDoc.ref, bucket);
    await roomDoc.ref.delete();
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
    await callDoc.ref.delete();
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

    await cleanupFriendData(db, uid);
    await cleanupChatData(db, uid);
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

    await userRef.delete();

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
    logger.info('📩 Message:', message);

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

    // 🔥 Tentukan receiver (selain sender)
    const receiverId = participants.find(
      (uid) => uid !== senderId
    );

    if (!receiverId) {
      logger.error('❌ receiverId not resolved');
      return;
    }

    logger.info('👤 Receiver ID:', receiverId);

    // 🔥 Ambil FCM token
    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(receiverId)
      .get();

    if (!userSnap.exists) {
      logger.error('❌ receiver user not found');
      return;
    }

    const fcmToken = userSnap.data().fcmToken;
    logger.info('📱 FCM Token:', fcmToken);

    if (!fcmToken) {
      logger.error('❌ fcmToken missing');
      return;
    }

    const isMuted = isChatMutedForUser(room, receiverId);
    logger.info('🔕 Chat muted for receiver:', isMuted);

    const payload = {
      token: fcmToken,

      // 📦 Dipakai Flutter (navigasi + delivered marker)
      data: {
        type: 'chat',
        roomId: event.params.roomId,
        messageId: event.params.messageId,
        receiverId: receiverId,
        senderId: message.senderId ?? '',
        senderName: message.senderName ?? '',
        text: message.text ?? '',
      },

      // 🤖 Android config
      android: {
        priority: 'high',
      },

      // 🍎 iOS silent delivery for muted chats.
      apns: {
        payload: {
          aps: isMuted
            ? {
                'content-available': 1,
              }
            : {
                sound: 'default',
              },
        },
      },
    };

    if (!isMuted) {
      payload.notification = {
        title: message.senderName || 'Pesan Baru',
        body: message.text || 'Ada pesan baru',
      };

      payload.android.notification = {
        channelId: 'chat_notification', // HARUS sama dengan Flutter
      };
    }

    // 🔔 Kirim notif
    try {
      const response = await admin.messaging().send(payload);

      logger.info('✅ FCM sent:', response);
    } catch (error) {
      await clearInvalidFcmToken(receiverId, fcmToken, error);
      throw error;
    }
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

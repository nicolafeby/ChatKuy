const { setGlobalOptions } = require('firebase-functions/v2');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

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

    const participants = roomSnap.data().participants || [];
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

    // 🔔 Kirim notif
    try {
      const response = await admin.messaging().send({
        token: fcmToken,

        // 🔔 Dipakai OS (background / terminated)
        notification: {
          title: message.senderName || 'Pesan Baru',
          body: message.text || 'Ada pesan baru',
        },

        // 📦 Dipakai Flutter (navigasi)
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
          notification: {
            channelId: 'chat_notification', // HARUS sama dengan Flutter
          },
        },

        // 🍎 iOS config
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });

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

const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

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

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(calleeId)
      .get();

    if (!userSnap.exists) {
      logger.error('❌ callee user not found');
      return;
    }

    const fcmToken = userSnap.data().fcmToken;
    if (!fcmToken) {
      logger.error('❌ callee fcmToken missing');
      return;
    }

    const callerName = call.callerName || 'ChatKuy';

    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: callerName,
        body: 'Panggilan suara masuk',
      },
      data: {
        type: 'voice_call',
        callId: event.params.callId,
        roomId: call.roomId || '',
        callerId: callerId,
        callerName: callerName,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_notification',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    logger.info('✅ Voice call FCM sent:', response);
  }
);

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
        title: 'Pesan baru',
        body: message.text || 'Ada pesan baru',
      },

      // 📦 Dipakai Flutter (navigasi)
      data: {
        type: 'chat',
        roomId: event.params.roomId,
        senderId: message.senderId ?? '',
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



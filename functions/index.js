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
    logger.info('📩 Message data:', message);

    const receiverId = message.receiverId;
    logger.info('👤 Receiver ID:', receiverId);

    if (!receiverId) {
      logger.error('❌ receiverId is missing');
      return;
    }

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(receiverId)
      .get();

    if (!userSnap.exists) {
      logger.error('❌ user not found:', receiverId);
      return;
    }

    const userData = userSnap.data();
    const fcmToken = userData.fcmToken;

    logger.info('📱 FCM Token:', fcmToken);

    if (!fcmToken) {
      logger.error('❌ fcmToken missing');
      return;
    }

    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Pesan baru',
        body: message.text || '',
      },
      data: {
        type: 'chat',
        roomId: event.params.roomId,
        senderId: message.senderId,
      },
    });

    logger.info('✅ FCM sent:', response);
  }
);

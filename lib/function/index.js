exports.onNewMessage = functions.firestore
  .document('chat_rooms/{roomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {

    const message = snap.data();
    const receiverId = message.receiverId;

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(receiverId)
      .get();

    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return;

    const payload = {
      token: fcmToken,
      notification: {
        title: 'Pesan baru',
        body: message.text,
      },
      data: {
        type: 'chat',
        roomId: context.params.roomId,
        senderId: message.senderId,
      },
    };

    console.log('🔥 New message received:', message);

    await admin.messaging().send(payload);
  });

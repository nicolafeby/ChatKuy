const fs = require('node:fs');
const path = require('node:path');
const {after, before, beforeEach, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');

let testEnv;

function authenticated(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, {
    email_verified: true,
    ...claims,
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-chatkuy',
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', '..', 'firestore.rules'),
        'utf8'
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', '..', 'storage.rules'),
        'utf8'
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), {
      id: 'alice',
      email: 'alice@example.com',
      username: 'alice',
      name: 'Alice',
      fcmToken: 'private-token',
    });
    await setDoc(doc(db, 'public_profiles/alice'), {
      id: 'alice',
      username: 'alice',
      name: 'Alice',
    });
    await setDoc(doc(db, 'public_profiles/bob'), {
      id: 'bob',
      username: 'bob',
      name: 'Bob',
    });
    await setDoc(doc(db, 'chat_rooms/room-1'), {
      participants: ['alice', 'bob'],
      lastMessage: '',
      lastMessageAt: new Date(0),
      lastSenderId: '',
      unreadCount: {alice: 0, bob: 0},
      readBy: {},
    });
    await setDoc(doc(db, 'chat_rooms/room-1/messages/message-1'), {
      senderId: 'alice',
      senderName: 'Alice',
      type: 'text',
      text: 'hello',
      createdAt: new Date(),
      createdAtClient: new Date(),
      deliveredTo: {},
      readBy: {},
      deletedFor: {},
      reactions: {},
      deletedForEveryone: false,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('private user document is owner-only', async () => {
  const aliceDb = authenticated('alice').firestore();
  const bobDb = authenticated('bob').firestore();
  const guestDb = testEnv.unauthenticatedContext().firestore();

  await assertSucceeds(getDoc(doc(aliceDb, 'users/alice')));
  await assertFails(getDoc(doc(bobDb, 'users/alice')));
  await assertFails(getDoc(doc(guestDb, 'users/alice')));
});

test('public profiles allow targeted get but reject bulk listing', async () => {
  const aliceDb = authenticated('alice').firestore();

  await assertSucceeds(getDoc(doc(aliceDb, 'public_profiles/bob')));
  await assertFails(getDocs(collection(aliceDb, 'public_profiles')));
});

test('non-participant cannot read a room or its messages', async () => {
  const malloryDb = authenticated('mallory').firestore();

  await assertFails(getDoc(doc(malloryDb, 'chat_rooms/room-1')));
  await assertFails(
    getDoc(doc(malloryDb, 'chat_rooms/room-1/messages/message-1'))
  );
});

test('unverified accounts cannot access shared chat data', async () => {
  const unverifiedDb = testEnv.authenticatedContext('alice', {
    email_verified: false,
  }).firestore();

  await assertFails(getDoc(doc(unverifiedDb, 'chat_rooms/room-1')));
  await assertFails(
    getDoc(doc(unverifiedDb, 'chat_rooms/room-1/messages/message-1'))
  );
});

test('participant may only update their own message-state entry', async () => {
  const bobDb = authenticated('bob').firestore();
  const messageRef = doc(
    bobDb,
    'chat_rooms/room-1/messages/message-1'
  );

  await assertSucceeds(updateDoc(messageRef, {'readBy.bob': true}));
  await assertFails(updateDoc(messageRef, {'readBy.alice': true}));
});

test('sender may update an image-message summary but may not impersonate', async () => {
  const aliceDb = authenticated('alice').firestore();
  const roomRef = doc(aliceDb, 'chat_rooms/room-1');

  await assertSucceeds(updateDoc(roomRef, {
    imageUrl: 'https://example.test/image.png',
    lastMessage: 'Foto',
    lastMessageAt: serverTimestamp(),
    lastSenderId: 'alice',
    type: 'image',
  }));
  await assertFails(updateDoc(roomRef, {
    lastMessage: 'forged',
    lastMessageAt: serverTimestamp(),
    lastSenderId: 'bob',
  }));
});

test('account deletion requires authentication from the last five minutes', async () => {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const freshDb = authenticated('alice', {
    auth_time: nowSeconds,
  }).firestore();
  const staleDb = authenticated('alice', {
    auth_time: nowSeconds - 600,
  }).firestore();
  const deletionUpdate = {
    accountStatus: 'pending_delete',
    deletionRequestedAt: serverTimestamp(),
    fcmToken: '',
    isOnline: false,
  };

  await assertFails(updateDoc(doc(staleDb, 'users/alice'), deletionUpdate));
  await assertSucceeds(updateDoc(doc(freshDb, 'users/alice'), deletionUpdate));
});

test('username reservation cannot be overwritten', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'usernames/alice'), {uid: 'alice'});
  });
  const bobDb = authenticated('bob').firestore();

  await assertFails(setDoc(doc(bobDb, 'usernames/alice'), {uid: 'bob'}));
  await assertSucceeds(setDoc(doc(bobDb, 'usernames/bob'), {uid: 'bob'}));
});

test('friend links require a matching pending friend request', async () => {
  const aliceDb = authenticated('alice').firestore();
  await assertFails(setDoc(doc(aliceDb, 'users/alice/friends/bob'), {
    uid: 'bob',
    requestId: 'request-1',
    createdAt: serverTimestamp(),
  }));

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users/alice/friend_requests/request-1'),
      {fromUid: 'bob', toUid: 'alice', status: 'pending'}
    );
  });
  const batch = writeBatch(aliceDb);
  batch.set(doc(aliceDb, 'users/alice/friends/bob'), {
    uid: 'bob', requestId: 'request-1', createdAt: serverTimestamp(),
  });
  batch.set(doc(aliceDb, 'users/bob/friends/alice'), {
    uid: 'alice', requestId: 'request-1', createdAt: serverTimestamp(),
  });
  batch.delete(doc(aliceDb, 'users/alice/friend_requests/request-1'));
  await assertSucceeds(batch.commit());
});

test('friend request metadata must match public profiles', async () => {
  const bobDb = authenticated('bob').firestore();
  const validBatch = writeBatch(bobDb);
  validBatch.set(doc(bobDb, 'users/alice/friend_requests/valid-request'), {
    fromUid: 'bob', toUid: 'alice', username: 'bob', displayName: 'Bob',
    status: 'pending', createdAt: serverTimestamp(),
  });
  validBatch.set(doc(bobDb, 'users/bob/outgoing_friend_requests/valid-request'), {
    fromUid: 'bob', toUid: 'alice', username: 'alice', displayName: 'Alice',
    status: 'pending', createdAt: serverTimestamp(),
  });
  await assertSucceeds(validBatch.commit());

  const forgedBatch = writeBatch(bobDb);
  forgedBatch.set(doc(bobDb, 'users/alice/friend_requests/forged-request'), {
    fromUid: 'bob', toUid: 'alice', username: 'alice', displayName: 'Alice',
    status: 'pending', createdAt: serverTimestamp(),
  });
  forgedBatch.set(doc(bobDb, 'users/bob/outgoing_friend_requests/forged-request'), {
    fromUid: 'bob', toUid: 'alice', username: 'alice', displayName: 'Alice',
    status: 'pending', createdAt: serverTimestamp(),
  });
  await assertFails(forgedBatch.commit());
});

test('call creation must match the room caller and callee', async () => {
  const aliceDb = authenticated('alice').firestore();
  const baseCall = {
    roomId: 'room-1',
    callerId: 'alice',
    calleeId: 'bob',
    callerName: 'Alice',
    calleeName: 'Bob',
    type: 'voice',
    participants: ['alice', 'bob'],
    status: 'calling',
    videoUpgradeStatus: 'none',
    createdAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(doc(aliceDb, 'calls/valid-call'), baseCall));
  await assertFails(setDoc(doc(aliceDb, 'calls/spoofed-call'), {
    ...baseCall,
    calleeId: 'mallory',
  }));
});

test('call candidates may only be written by the matching call role', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'calls/call-1'), {
      roomId: 'room-1',
      callerId: 'alice',
      calleeId: 'bob',
      participants: ['alice', 'bob'],
      type: 'voice',
      status: 'calling',
      videoUpgradeStatus: 'none',
    });
  });
  const aliceDb = authenticated('alice').firestore();
  const bobDb = authenticated('bob').firestore();
  const candidate = {
    candidate: 'candidate-data',
    sdpMid: '0',
    sdpMLineIndex: 0,
    createdAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(
    doc(aliceDb, 'calls/call-1/caller_candidates/candidate-1'),
    candidate
  ));
  await assertFails(setDoc(
    doc(bobDb, 'calls/call-1/caller_candidates/candidate-2'),
    candidate
  ));
});

test('storage permits room participants and rejects outsiders', async () => {
  const image = new Uint8Array([137, 80, 78, 71]);
  const aliceStorage = authenticated('alice').storage();
  const malloryStorage = authenticated('mallory').storage();
  const aliceImage = ref(
    aliceStorage,
    'chat_images/room-1/alice/example.png'
  );
  const malloryImage = ref(
    malloryStorage,
    'chat_images/room-1/mallory/blocked.png'
  );

  await assertSucceeds(uploadBytes(aliceImage, image, {contentType: 'image/png'}));
  await assertSucceeds(getBytes(aliceImage));
  await assertFails(
    uploadBytes(malloryImage, image, {contentType: 'image/png'})
  );
});

test('a participant cannot overwrite or delete another uploader attachment', async () => {
  const image = new Uint8Array([137, 80, 78, 71]);
  const aliceStorage = authenticated('alice').storage();
  const bobStorage = authenticated('bob').storage();
  const aliceImage = ref(
    aliceStorage,
    'chat_images/room-1/alice/protected.png'
  );
  const sameImageAsBob = ref(
    bobStorage,
    'chat_images/room-1/alice/protected.png'
  );

  await assertSucceeds(uploadBytes(aliceImage, image, {contentType: 'image/png'}));
  await assertFails(uploadBytes(
    sameImageAsBob,
    new Uint8Array([1]),
    {contentType: 'image/png'}
  ));
  await assertFails(deleteObject(sameImageAsBob));
});

test('storage rejects a mismatched media content type', async () => {
  const aliceStorage = authenticated('alice').storage();
  const invalidImage = ref(
    aliceStorage,
    'chat_images/room-1/alice/not-an-image.txt'
  );

  await assertFails(
    uploadBytes(invalidImage, new Uint8Array([1]), {contentType: 'text/plain'})
  );
});

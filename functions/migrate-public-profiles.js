const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');

initializeApp();

function publicProfileFromUser(uid, user) {
  return {
    id: uid,
    name: user.accountStatus === 'deleted' ? 'Deleted User' : user.name || '',
    username: user.accountStatus === 'deleted' ? '' : user.username || '',
    photoUrl: user.accountStatus === 'deleted' ? null : user.photoUrl || null,
    gender: user.accountStatus === 'deleted' ? null : user.gender || null,
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
    isDeleted: user.accountStatus === 'deleted',
  };
}

async function migrate() {
  const db = getFirestore();
  const users = await db.collection('users').get();
  const usernameOwners = new Map();

  for (const user of users.docs) {
    const username = user.data().username;
    if (!username) continue;
    const existingOwner = usernameOwners.get(username);
    if (existingOwner && existingOwner !== user.id) {
      throw new Error(
        `Duplicate username "${username}" belongs to ${existingOwner} and ${user.id}`
      );
    }
    usernameOwners.set(username, user.id);
  }

  let batch = db.batch();
  let count = 0;
  let writesInBatch = 0;

  for (const user of users.docs) {
    batch.set(
      db.collection('public_profiles').doc(user.id),
      publicProfileFromUser(user.id, user.data())
    );
    writesInBatch += 1;
    const username = user.data().username;
    if (username) {
      batch.set(db.collection('usernames').doc(username), {uid: user.id});
      writesInBatch += 1;
    }
    count += 1;

    if (writesInBatch >= 400) {
      await batch.commit();
      batch = db.batch();
      writesInBatch = 0;
    }
  }

  if (writesInBatch > 0) {
    await batch.commit();
  }

  console.log(`Migrated ${count} public profiles.`);
}

migrate().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

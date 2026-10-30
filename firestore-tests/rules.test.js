// Security rule tests for Note With Us. Run with `npm test` (starts the
// Firestore emulator, runs these, and shuts it down).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  addDoc,
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  increment,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Seeds data with rules disabled.
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const past = () => Timestamp.fromMillis(Date.now() - 60_000);
const future = () => Timestamp.fromMillis(Date.now() + 86_400_000);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-note-with-us',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

describe('signed-out visitors (guest mode)', () => {
  test('can read public notes and their replies, nothing else', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'postsMain/p1'), { ownerId: 'alice', text: 'hi', reactions: {} });
      await setDoc(doc(f, 'postsMain/p1/comments/c1'), { ownerId: 'bob', text: 'yo' });
      await setDoc(doc(f, 'circlePosts/c1'), { ownerId: 'alice', audience: ['alice'] });
      await setDoc(doc(f, 'postsOnlyMe/alice/myPost/n1'), { ownerId: 'alice' });
      await setDoc(doc(f, 'users/alice/favorites/x'), { noteId: 'p1' });
    });
    await assertSucceeds(getDocs(query(collection(db(), 'postsMain'), orderBy('time', 'desc'), limit(80))));
    await assertSucceeds(getDoc(doc(db(), 'postsMain/p1')));
    await assertSucceeds(getDocs(collection(db(), 'postsMain/p1/comments')));
    await assertFails(getDoc(doc(db(), 'users/alice')));
    await assertFails(getDocs(collection(db(), 'users')));
    await assertFails(getDoc(doc(db(), 'circlePosts/c1')));
    await assertFails(getDoc(doc(db(), 'postsOnlyMe/alice/myPost/n1')));
    await assertFails(getDoc(doc(db(), 'users/alice/favorites/x')));
    await assertFails(getDoc(doc(db(), 'capsules/x')));
  });

  test('cannot write anything', async () => {
    await seed((f) => setDoc(doc(f, 'postsMain/p1'), { ownerId: 'alice', text: 'hi', reactions: {} }));
    await assertFails(setDoc(doc(db(), 'users/alice'), { username: 'x' }));
    await assertFails(addDoc(collection(db(), 'postsMain'), { ownerId: '', text: 'x' }));
    await assertFails(updateDoc(doc(db(), 'postsMain/p1'), { 'reactions.x': '❤️' }));
    await assertFails(addDoc(collection(db(), 'postsMain/p1/comments'), { ownerId: '', text: 'x' }));
    await assertFails(deleteDoc(doc(db(), 'postsMain/p1')));
  });
});

describe('profiles', () => {
  test('anyone signed in can read profiles; only you can write yours', async () => {
    await seed((f) => setDoc(doc(f, 'users/alice'), { uId: 'alice', username: 'Alice' }));
    await assertSucceeds(getDocs(collection(db('bob'), 'users')));
    await assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { bio: 'hi' }));
    await assertFails(updateDoc(doc(db('bob'), 'users/alice'), { bio: 'hacked' }));
    await assertSucceeds(setDoc(doc(db('carol'), 'users/carol'), { uId: 'carol' }));
    await assertFails(deleteDoc(doc(db('bob'), 'users/alice')));
  });
});

describe('favorites', () => {
  test('only the owner can see and change their favorites', async () => {
    const fav = { audience: 'everyone', ownerId: 'bob', noteId: 'p1', savedAt: Timestamp.now() };
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice/favorites/everyone_bob_p1'), fav));
    await assertSucceeds(getDocs(collection(db('alice'), 'users/alice/favorites')));
    await assertFails(getDocs(collection(db('bob'), 'users/alice/favorites')));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/favorites/x'), fav));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'users/alice/favorites/everyone_bob_p1')));
  });

  test('saving a favorite does not unlock someone\'s private note', async () => {
    await seed((f) => setDoc(doc(f, 'postsOnlyMe/bob/myPost/secret'), { text: 'mine' }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice/favorites/private_bob_secret'),
      { audience: 'private', ownerId: 'bob', noteId: 'secret', savedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(db('alice'), 'postsOnlyMe/bob/myPost/secret')));
  });
});

describe('direct messages', () => {
  const message = (from, to) => ({ senderId: from, receiverId: to, message: 'hey', time: 'now' });

  // Alice and Bob are in each other's circle; Carol is not.
  beforeEach(() => seed(async (f) => {
    await setDoc(doc(f, 'circles/alice'), { members: ['bob'] });
    await setDoc(doc(f, 'circles/bob'), { members: ['alice'] });
  }));

  test('sender can write both copies of the conversation', async () => {
    const f = db('alice');
    const batch = writeBatch(f);
    batch.set(doc(f, 'users/alice/chats/bob'), { userId: 'bob' }, { merge: true });
    batch.set(doc(f, 'users/bob/chats/alice'), { userId: 'alice' }, { merge: true });
    batch.set(doc(collection(f, 'users/alice/chats/bob/messages')), message('alice', 'bob'));
    batch.set(doc(collection(f, 'users/bob/chats/alice/messages')), message('alice', 'bob'));
    await assertSucceeds(batch.commit());
  });

  test('old app style: add message into the other person\'s thread', async () => {
    await assertSucceeds(
      addDoc(collection(db('alice'), 'users/bob/chats/alice/messages'), message('alice', 'bob')));
  });

  test('people outside your circle cannot message you', async () => {
    await assertFails(
      addDoc(collection(db('carol'), 'users/bob/chats/carol/messages'), message('carol', 'bob')));
    await assertFails(setDoc(doc(db('carol'), 'users/bob/chats/carol'), { userId: 'carol' }));
  });

  test('after leaving a circle, messaging stops', async () => {
    await seed((f) => setDoc(doc(f, 'circles/bob'), { members: [] }));
    await assertFails(
      addDoc(collection(db('alice'), 'users/bob/chats/alice/messages'), message('alice', 'bob')));
  });

  test('cannot read someone else\'s messages or impersonate a sender', async () => {
    await assertFails(getDocs(collection(db('carol'), 'users/bob/chats/alice/messages')));
    await assertFails(
      addDoc(collection(db('carol'), 'users/bob/chats/alice/messages'), message('alice', 'bob')));
    await assertFails(
      addDoc(collection(db('carol'), 'users/bob/chats/alice/messages'), message('carol', 'bob')));
  });

  test('blocked people cannot message you', async () => {
    await seed((f) => setDoc(doc(f, 'blocks/bob'), { blocked: ['alice'] }));
    await assertFails(
      addDoc(collection(db('alice'), 'users/bob/chats/alice/messages'), message('alice', 'bob')));
    await assertFails(setDoc(doc(db('alice'), 'users/bob/chats/alice'), { userId: 'alice' }));
  });
});

describe('public notes (postsMain)', () => {
  const post = { ownerId: 'alice', text: 'hi', likes: [], reactions: {}, commentCount: 0 };

  beforeEach(() => seed((f) => setDoc(doc(f, 'postsMain/p1'), post)));

  test('everyone signed in can read; only the author can create as themselves', async () => {
    await assertSucceeds(getDocs(collection(db('bob'), 'postsMain')));
    await assertSucceeds(addDoc(collection(db('bob'), 'postsMain'), { ...post, ownerId: 'bob' }));
    await assertFails(addDoc(collection(db('bob'), 'postsMain'), post));
  });

  test('others can react with their own reaction only', async () => {
    await assertSucceeds(updateDoc(doc(db('bob'), 'postsMain/p1'), { 'reactions.bob': '❤️' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'postsMain/p1'), { 'reactions.bob': deleteField() }));
    await assertFails(updateDoc(doc(db('bob'), 'postsMain/p1'), { 'reactions.carol': '😂' }));
  });

  test('old app style like: rewriting the whole post with only likes changed', async () => {
    await assertSucceeds(setDoc(doc(db('bob'), 'postsMain/p1'), {
      ...post,
      likes: [{ ownerId: 'bob', ownerName: 'Bob', ownerImage: '' }],
    }));
  });

  test('others cannot edit text or delete', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'postsMain/p1'), { text: 'changed' }));
    await assertFails(deleteDoc(doc(db('bob'), 'postsMain/p1')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'postsMain/p1')));
  });

  test('replies: post as yourself, author can remove any reply', async () => {
    const f = db('bob');
    const batch = writeBatch(f);
    batch.set(doc(f, 'postsMain/p1/comments/c1'), { ownerId: 'bob', text: 'nice' });
    batch.update(doc(f, 'postsMain/p1'), { commentCount: increment(1) });
    await assertSucceeds(batch.commit());
    await assertFails(setDoc(doc(db('bob'), 'postsMain/p1/comments/c2'), { ownerId: 'carol', text: 'x' }));
    await assertFails(deleteDoc(doc(db('carol'), 'postsMain/p1/comments/c1')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'postsMain/p1/comments/c1')));
  });
});

describe('circle notes (circlePosts)', () => {
  const post = { ownerId: 'alice', audience: ['alice', 'bob'], text: 'family only', reactions: {}, commentCount: 0 };

  beforeEach(() => seed((f) => setDoc(doc(f, 'circlePosts/c1'), post)));

  test('only the audience can read, including through the feed query', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'circlePosts/c1')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'circlePosts'), where('audience', 'array-contains', 'bob'))));
    await assertFails(getDoc(doc(db('carol'), 'circlePosts/c1')));
    await assertFails(getDocs(collection(db('carol'), 'circlePosts')));
  });

  test('author must include themselves in the audience', async () => {
    await assertSucceeds(addDoc(collection(db('alice'), 'circlePosts'), post));
    await assertFails(addDoc(collection(db('alice'), 'circlePosts'), { ...post, audience: ['bob'] }));
    await assertFails(addDoc(collection(db('carol'), 'circlePosts'), post));
  });

  test('audience can react; outsiders cannot', async () => {
    await assertSucceeds(updateDoc(doc(db('bob'), 'circlePosts/c1'), { 'reactions.bob': '🥹' }));
    await assertFails(updateDoc(doc(db('carol'), 'circlePosts/c1'), { 'reactions.carol': '🥹' }));
    await assertFails(updateDoc(doc(db('bob'), 'circlePosts/c1'), { audience: arrayUnion('carol') }));
  });

  test('replies are visible to the audience only', async () => {
    await assertSucceeds(setDoc(doc(db('bob'), 'circlePosts/c1/comments/r1'), { ownerId: 'bob', text: '❤️' }));
    await assertSucceeds(getDocs(collection(db('alice'), 'circlePosts/c1/comments')));
    await assertFails(getDocs(collection(db('carol'), 'circlePosts/c1/comments')));
    await assertFails(setDoc(doc(db('carol'), 'circlePosts/c1/comments/r2'), { ownerId: 'carol', text: 'hi' }));
  });
});

describe('private journal (postsOnlyMe)', () => {
  test('only the owner can archive their notes', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'postsOnlyMe/alice/myPost/n2'), { ownerId: 'alice', text: 'x' }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'postsOnlyMe/alice/myPost/n2'), { archived: true }));
    await assertFails(updateDoc(doc(db('bob'), 'postsOnlyMe/alice/myPost/n2'), { archived: false }));
  });

  test('only the owner can pin their notes', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'postsOnlyMe/alice/myPost/n1'), { ownerId: 'alice', text: 'x' }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'postsOnlyMe/alice/myPost/n1'), { pinned: true }));
    await assertFails(updateDoc(doc(db('bob'), 'postsOnlyMe/alice/myPost/n1'), { pinned: false }));
  });

  test('only the owner can read or write', async () => {
    await assertSucceeds(addDoc(collection(db('alice'), 'postsOnlyMe/alice/myPost'), { ownerId: 'alice', text: 'secret' }));
    await assertSucceeds(getDocs(collection(db('alice'), 'postsOnlyMe/alice/myPost')));
    await assertFails(getDocs(collection(db('bob'), 'postsOnlyMe/alice/myPost')));
    await assertFails(addDoc(collection(db('bob'), 'postsOnlyMe/alice/myPost'), { text: 'x' }));
  });
});

describe('time capsules', () => {
  const capsule = (unlockAt, extra = {}) => ({
    ownerId: 'alice', recipientId: 'bob', text: '', opened: false, mood: 'love', unlockAt, ...extra,
  });

  // Alice is in Bob's circle, so she may send him capsules.
  beforeEach(() => seed((f) => setDoc(doc(f, 'circles/bob'), { members: ['alice'] })));

  test('capsules go only to yourself or someone whose circle you are in', async () => {
    await assertSucceeds(setDoc(doc(db('carol'), 'capsules/self'),
      capsule(future(), { ownerId: 'carol', recipientId: 'carol' })));
    await assertFails(setDoc(doc(db('carol'), 'capsules/c2'),
      capsule(future(), { ownerId: 'carol', recipientId: 'bob' })));
    await seed((f) => setDoc(doc(f, 'blocks/bob'), { blocked: ['alice'] }));
    await assertFails(setDoc(doc(db('alice'), 'capsules/blocked'), capsule(future())));
  });

  const seedCapsule = (unlockAt) => seed(async (f) => {
    await setDoc(doc(f, 'capsules/k1'), capsule(unlockAt));
    await setDoc(doc(f, 'capsules/k1/sealed/content'), { text: 'Happy birthday!' });
  });

  test('author seals a capsule with the text in the sealed document', async () => {
    const f = db('alice');
    const batch = writeBatch(f);
    batch.set(doc(f, 'capsules/new'), capsule(future()));
    batch.set(doc(f, 'capsules/new/sealed/content'), { text: 'see you in a year' });
    await assertSucceeds(batch.commit());
  });

  test('cannot put the text on the capsule or seal one as someone else', async () => {
    await assertFails(setDoc(doc(db('alice'), 'capsules/x'), capsule(future(), { text: 'leaked' })));
    await assertFails(setDoc(doc(db('carol'), 'capsules/x'), capsule(future())));
  });

  test('recipient sees a locked capsule but cannot read its text early', async () => {
    await seedCapsule(future());
    await assertSucceeds(getDocs(query(collection(db('bob'), 'capsules'), where('recipientId', '==', 'bob'))));
    await assertFails(getDoc(doc(db('bob'), 'capsules/k1/sealed/content')));
    await assertFails(updateDoc(doc(db('bob'), 'capsules/k1'), { opened: true, text: 'Happy birthday!' }));
    await assertSucceeds(getDoc(doc(db('alice'), 'capsules/k1/sealed/content')));
  });

  test('after unlocking, recipient reads it and marks it opened with the real text', async () => {
    await seedCapsule(past());
    await assertSucceeds(getDoc(doc(db('bob'), 'capsules/k1/sealed/content')));
    await assertFails(updateDoc(doc(db('bob'), 'capsules/k1'), { opened: true, text: 'fake' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'capsules/k1'), { opened: true, text: 'Happy birthday!' }));
  });

  test('strangers can neither see nor read capsules', async () => {
    await seedCapsule(past());
    await assertFails(getDoc(doc(db('carol'), 'capsules/k1')));
    await assertFails(getDoc(doc(db('carol'), 'capsules/k1/sealed/content')));
    await assertFails(getDocs(query(collection(db('carol'), 'capsules'), where('recipientId', '==', 'bob'))));
  });

  test('author or recipient can delete', async () => {
    await seedCapsule(future());
    await assertFails(deleteDoc(doc(db('carol'), 'capsules/k1')));
    const f = db('bob');
    const batch = writeBatch(f);
    batch.delete(doc(f, 'capsules/k1/sealed/content'));
    batch.delete(doc(f, 'capsules/k1'));
    await assertSucceeds(batch.commit());
  });
});

describe('circle capsules (groupCapsules)', () => {
  const group = (unlockAt, extra = {}) => ({
    ownerId: 'alice', ownerName: 'Alice', title: 'New Year', createdAt: Timestamp.now(),
    unlockAt, members: ['alice', 'bob', 'carol'], written: [], ...extra,
  });
  const letter = (uid, extra = {}) => ({ ownerId: uid, ownerName: uid, text: `hi from ${uid}`, mood: 'joy', ...extra });

  beforeEach(() => seed((f) => setDoc(doc(f, 'circles/alice'), { members: ['bob', 'carol'] })));

  test('the creator starts one with people from their own circle', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'groupCapsules/g1'), group(future())));
    await assertFails(setDoc(doc(db('alice'), 'groupCapsules/g2'),
      group(future(), { members: ['alice', 'bob', 'dave'] })));
    await assertFails(setDoc(doc(db('bob'), 'groupCapsules/g3'), group(future())));
    await assertFails(setDoc(doc(db('alice'), 'groupCapsules/g4'), group(future(), { written: ['bob'] })));
    await assertFails(setDoc(doc(db('alice'), 'groupCapsules/g5'), group(future(), { title: '' })));
    await assertFails(setDoc(doc(db('alice'), 'groupCapsules/g6'), group(future(), { members: ['alice'] })));
  });

  test('only members can see it', async () => {
    await seed((f) => setDoc(doc(f, 'groupCapsules/g1'), group(future())));
    await assertSucceeds(getDoc(doc(db('bob'), 'groupCapsules/g1')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'groupCapsules'), where('members', 'array-contains', 'bob'))));
    await assertFails(getDoc(doc(db('dave'), 'groupCapsules/g1')));
  });

  test('a member writes their own letter and ticks themselves off, in one batch', async () => {
    await seed((f) => setDoc(doc(f, 'groupCapsules/g1'), group(future())));
    const f = db('bob');
    const batch = writeBatch(f);
    batch.set(doc(f, 'groupCapsules/g1/entries/bob'), letter('bob'));
    batch.update(doc(f, 'groupCapsules/g1'), { written: arrayUnion('bob') });
    await assertSucceeds(batch.commit());
    await assertSucceeds(updateDoc(doc(f, 'groupCapsules/g1/entries/bob'), { text: 'rewritten' }));
  });

  test('nobody writes for someone else or ticks someone else off', async () => {
    await seed((f) => setDoc(doc(f, 'groupCapsules/g1'), group(future())));
    await assertFails(setDoc(doc(db('bob'), 'groupCapsules/g1/entries/carol'), letter('carol')));
    await assertFails(setDoc(doc(db('bob'), 'groupCapsules/g1/entries/bob'), letter('carol')));
    await assertFails(setDoc(doc(db('dave'), 'groupCapsules/g1/entries/dave'), letter('dave')));
    await assertFails(updateDoc(doc(db('bob'), 'groupCapsules/g1'), { written: arrayUnion('carol') }));
    await assertFails(updateDoc(doc(db('bob'), 'groupCapsules/g1'), { title: 'Mine now' }));
  });

  test('letters stay private until it opens, then everyone reads them all', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'groupCapsules/locked'), group(future()));
      await setDoc(doc(f, 'groupCapsules/locked/entries/bob'), letter('bob'));
      await setDoc(doc(f, 'groupCapsules/open'), group(past()));
      await setDoc(doc(f, 'groupCapsules/open/entries/bob'), letter('bob'));
    });
    await assertSucceeds(getDoc(doc(db('bob'), 'groupCapsules/locked/entries/bob')));
    await assertFails(getDoc(doc(db('alice'), 'groupCapsules/locked/entries/bob')));
    await assertFails(getDocs(collection(db('carol'), 'groupCapsules/locked/entries')));
    await assertSucceeds(getDocs(collection(db('carol'), 'groupCapsules/open/entries')));
    await assertSucceeds(getDoc(doc(db('alice'), 'groupCapsules/open/entries/bob')));
    await assertFails(getDoc(doc(db('dave'), 'groupCapsules/open/entries/bob')));
  });

  test('no letters after it has opened', async () => {
    await seed((f) => setDoc(doc(f, 'groupCapsules/g1'), group(past())));
    await assertFails(setDoc(doc(db('bob'), 'groupCapsules/g1/entries/bob'), letter('bob')));
    await assertFails(updateDoc(doc(db('bob'), 'groupCapsules/g1'), { written: arrayUnion('bob') }));
  });

  test('the creator can delete a sealed capsule by clearing each member\'s letter id', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'groupCapsules/g1'), group(future()));
      await setDoc(doc(f, 'groupCapsules/g1/entries/bob'), letter('bob'));
    });
    // Listing the letters is refused while it is sealed...
    await assertFails(getDocs(collection(db('alice'), 'groupCapsules/g1/entries')));
    // ...so the app deletes them by id, which is allowed (even ones that don't exist).
    const f = db('alice');
    const batch = writeBatch(f);
    for (const m of ['alice', 'bob', 'carol']) batch.delete(doc(f, `groupCapsules/g1/entries/${m}`));
    batch.delete(doc(f, 'groupCapsules/g1'));
    await assertSucceeds(batch.commit());
  });

  test('only the creator deletes the capsule; members take back their own letter', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'groupCapsules/g1'), group(future()));
      await setDoc(doc(f, 'groupCapsules/g1/entries/bob'), letter('bob'));
    });
    await assertFails(deleteDoc(doc(db('bob'), 'groupCapsules/g1')));
    await assertFails(deleteDoc(doc(db('carol'), 'groupCapsules/g1/entries/bob')));
    await assertSucceeds(deleteDoc(doc(db('bob'), 'groupCapsules/g1/entries/bob')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'groupCapsules/g1')));
  });
});

describe('ask my circle (circleAsks)', () => {
  const ask = (extra = {}) => ({
    ownerId: 'alice', ownerName: 'Alice', text: 'Best memory with me?',
    createdAt: Timestamp.now(), members: ['bob', 'carol'], answered: [], ...extra,
  });
  const answer = (uid, extra = {}) => ({ ownerId: uid, ownerName: uid, ownerImage: '', text: `from ${uid}`, time: Timestamp.now(), ...extra });

  beforeEach(() => seed((f) => setDoc(doc(f, 'circles/alice'), { members: ['bob', 'carol'] })));

  test('ask people from your own circle', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'circleAsks/a1'), ask()));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a2'), ask({ members: ['bob', 'dave'] })));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a3'), ask({ members: [] })));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a4'), ask({ members: ['alice', 'bob'] })));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a5'), ask({ text: '' })));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a6'), ask({ answered: ['bob'] })));
    await assertFails(setDoc(doc(db('bob'), 'circleAsks/a7'), ask()));
  });

  test('only the asker and the people asked can see it', async () => {
    await seed((f) => setDoc(doc(f, 'circleAsks/a1'), ask()));
    await assertSucceeds(getDoc(doc(db('alice'), 'circleAsks/a1')));
    await assertSucceeds(getDoc(doc(db('bob'), 'circleAsks/a1')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'circleAsks'), where('members', 'array-contains', 'bob'))));
    await assertFails(getDoc(doc(db('dave'), 'circleAsks/a1')));
  });

  test('answers are private: only the asker reads them all', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'circleAsks/a1'), ask());
      await setDoc(doc(f, 'circleAsks/a1/answers/bob'), answer('bob'));
      await setDoc(doc(f, 'circleAsks/a1/answers/carol'), answer('carol'));
    });
    await assertSucceeds(getDocs(collection(db('alice'), 'circleAsks/a1/answers')));
    await assertSucceeds(getDoc(doc(db('bob'), 'circleAsks/a1/answers/bob')));
    await assertFails(getDoc(doc(db('bob'), 'circleAsks/a1/answers/carol')));
    await assertFails(getDocs(collection(db('bob'), 'circleAsks/a1/answers')));
    await assertFails(getDoc(doc(db('dave'), 'circleAsks/a1/answers/bob')));
  });

  test('a person answers once for themselves and ticks themselves off', async () => {
    await seed((f) => setDoc(doc(f, 'circleAsks/a1'), ask()));
    const f = db('bob');
    const batch = writeBatch(f);
    batch.set(doc(f, 'circleAsks/a1/answers/bob'), answer('bob'));
    batch.update(doc(f, 'circleAsks/a1'), { answered: arrayUnion('bob') });
    await assertSucceeds(batch.commit());
    await assertSucceeds(updateDoc(doc(f, 'circleAsks/a1/answers/bob'), { text: 'changed my mind' }));
  });

  test('nobody answers for someone else, or when not asked', async () => {
    await seed((f) => setDoc(doc(f, 'circleAsks/a1'), ask()));
    await assertFails(setDoc(doc(db('bob'), 'circleAsks/a1/answers/carol'), answer('carol')));
    await assertFails(setDoc(doc(db('bob'), 'circleAsks/a1/answers/bob'), answer('carol')));
    await assertFails(setDoc(doc(db('dave'), 'circleAsks/a1/answers/dave'), answer('dave')));
    await assertFails(setDoc(doc(db('alice'), 'circleAsks/a1/answers/alice'), answer('alice')));
    await assertFails(updateDoc(doc(db('bob'), 'circleAsks/a1'), { answered: arrayUnion('carol') }));
    await assertFails(updateDoc(doc(db('bob'), 'circleAsks/a1'), { text: 'mine now' }));
  });

  test('the asker deletes the question and its answers; people take back theirs', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'circleAsks/a1'), ask());
      await setDoc(doc(f, 'circleAsks/a1/answers/bob'), answer('bob'));
      await setDoc(doc(f, 'circleAsks/a1/answers/carol'), answer('carol'));
    });
    await assertFails(deleteDoc(doc(db('bob'), 'circleAsks/a1')));
    await assertFails(deleteDoc(doc(db('bob'), 'circleAsks/a1/answers/carol')));
    await assertSucceeds(deleteDoc(doc(db('bob'), 'circleAsks/a1/answers/bob')));
    const f = db('alice');
    const batch = writeBatch(f);
    batch.delete(doc(f, 'circleAsks/a1/answers/carol'));
    batch.delete(doc(f, 'circleAsks/a1'));
    await assertSucceeds(batch.commit());
  });
});

describe('shared notebooks', () => {
  const notebook = (extra = {}) => ({
    ownerId: 'alice', title: 'Us', members: ['alice', 'bob'],
    memberNames: { alice: 'Alice', bob: 'Bob' }, createdAt: Timestamp.now(),
    lastWriterId: '', entryCount: 0, ...extra,
  });
  const page = (uid, extra = {}) => ({ ownerId: uid, ownerName: uid, text: `page by ${uid}`, time: Timestamp.now(), ...extra });

  // Alice is in Bob's circle, so she may start a notebook with him.
  beforeEach(() => seed((f) => setDoc(doc(f, 'circles/bob'), { members: ['alice'] })));

  const write = (uid, id, extra = {}, turn = uid) => {
    const f = db(uid);
    const batch = writeBatch(f);
    batch.set(doc(f, `sharedNotebooks/${id}/entries/${uid}${Math.random()}`), page(uid, extra));
    batch.update(doc(f, `sharedNotebooks/${id}`), { lastWriterId: turn, lastTime: Timestamp.now(), entryCount: increment(1) });
    return batch.commit();
  };

  test('start one with someone who has you in their circle', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'sharedNotebooks/n1'), notebook()));
    await assertFails(setDoc(doc(db('alice'), 'sharedNotebooks/n2'),
      notebook({ members: ['alice', 'carol'] })));
    await assertFails(setDoc(doc(db('alice'), 'sharedNotebooks/n3'), notebook({ lastWriterId: 'alice' })));
    await assertFails(setDoc(doc(db('alice'), 'sharedNotebooks/n4'), notebook({ members: ['alice', 'alice'] })));
    await assertFails(setDoc(doc(db('carol'), 'sharedNotebooks/n5'), notebook()));
    await seed((f) => setDoc(doc(f, 'blocks/bob'), { blocked: ['alice'] }));
    await assertFails(setDoc(doc(db('alice'), 'sharedNotebooks/n6'), notebook()));
  });

  test('only its two people can read it', async () => {
    await seed((f) => setDoc(doc(f, 'sharedNotebooks/n1'), notebook()));
    await assertSucceeds(getDoc(doc(db('bob'), 'sharedNotebooks/n1')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'sharedNotebooks'), where('members', 'array-contains', 'bob'))));
    await assertFails(getDoc(doc(db('carol'), 'sharedNotebooks/n1')));
  });

  test('pages alternate: you cannot write twice in a row', async () => {
    await seed((f) => setDoc(doc(f, 'sharedNotebooks/n1'), notebook()));
    await assertSucceeds(write('alice', 'n1'));
    await assertFails(write('alice', 'n1'));
    await assertSucceeds(write('bob', 'n1'));
    await assertFails(write('bob', 'n1'));
    await assertSucceeds(write('alice', 'n1'));
  });

  test('a page must pass the turn, and nobody can pass it for someone else', async () => {
    await seed((f) => setDoc(doc(f, 'sharedNotebooks/n1'), notebook()));
    // A page with no turn change.
    await assertFails(setDoc(doc(db('alice'), 'sharedNotebooks/n1/entries/p1'), page('alice')));
    // A page that hands the turn to the other person's name.
    await assertFails(write('alice', 'n1', {}, 'bob'));
    // Someone else's page.
    await assertFails(write('alice', 'n1', { ownerId: 'bob' }));
    // Strangers.
    await assertFails(write('carol', 'n1'));
    // Nothing else on the notebook can change.
    await assertFails(updateDoc(doc(db('alice'), 'sharedNotebooks/n1'), { title: 'Mine', lastWriterId: 'alice' }));
  });

  test('the page count can only go up by one, with a real time', async () => {
    await seed((f) => setDoc(doc(f, 'sharedNotebooks/n1'), notebook()));
    const n = doc(db('alice'), 'sharedNotebooks/n1');
    await assertFails(updateDoc(n, { lastWriterId: 'alice', lastTime: Timestamp.now(), entryCount: 9999 }));
    await assertFails(updateDoc(n, { lastWriterId: 'alice', lastTime: 'yesterday', entryCount: increment(1) }));
    await assertSucceeds(updateDoc(n, { lastWriterId: 'alice', lastTime: Timestamp.now(), entryCount: increment(1) }));
  });

  test('both people read pages; strangers do not', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'sharedNotebooks/n1'), notebook({ lastWriterId: 'alice' }));
      await setDoc(doc(f, 'sharedNotebooks/n1/entries/p1'), page('alice'));
    });
    await assertSucceeds(getDocs(collection(db('bob'), 'sharedNotebooks/n1/entries')));
    await assertSucceeds(getDocs(collection(db('alice'), 'sharedNotebooks/n1/entries')));
    await assertFails(getDocs(collection(db('carol'), 'sharedNotebooks/n1/entries')));
  });

  test('either person can delete the notebook and its pages', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'sharedNotebooks/n1'), notebook({ lastWriterId: 'alice' }));
      await setDoc(doc(f, 'sharedNotebooks/n1/entries/p1'), page('alice'));
    });
    await assertFails(deleteDoc(doc(db('carol'), 'sharedNotebooks/n1')));
    const f = db('bob');
    const batch = writeBatch(f);
    batch.delete(doc(f, 'sharedNotebooks/n1/entries/p1'));
    batch.delete(doc(f, 'sharedNotebooks/n1'));
    await assertSucceeds(batch.commit());
  });
});

describe('circle requests', () => {
  const request = (from, to) => ({ from, to, fromName: from, fromImage: '', createdAt: Timestamp.now() });

  test('send as yourself, with the right id', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'circleRequests/alice_bob'), request('alice', 'bob')));
    await assertFails(setDoc(doc(db('carol'), 'circleRequests/alice_bob'), request('alice', 'bob')));
    await assertFails(setDoc(doc(db('alice'), 'circleRequests/alice_alice'), request('alice', 'alice')));
    await assertFails(setDoc(doc(db('alice'), 'circleRequests/x'), request('alice', 'bob')));
  });

  test('cannot request someone who blocked you', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'blocks/bob'), { blocked: ['alice'] }));
    await assertFails(setDoc(doc(db('alice'), 'circleRequests/alice_bob'), request('alice', 'bob')));
  });

  test('only the two people can see or delete a request', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'circleRequests/alice_bob'), request('alice', 'bob')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'circleRequests'), where('to', '==', 'bob'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'circleRequests'), where('from', '==', 'alice'))));
    await assertFails(getDoc(doc(db('carol'), 'circleRequests/alice_bob')));
    await assertFails(deleteDoc(doc(db('carol'), 'circleRequests/alice_bob')));
    await assertSucceeds(deleteDoc(doc(db('bob'), 'circleRequests/alice_bob')));
  });

  test('accepting joins both circles in one batch', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'circleRequests/alice_bob'), request('alice', 'bob')));
    const f = db('bob');
    const batch = writeBatch(f);
    batch.set(doc(f, 'circles/bob'), { members: arrayUnion('alice') }, { merge: true });
    batch.set(doc(f, 'circles/alice'), { members: arrayUnion('bob') }, { merge: true });
    batch.delete(doc(f, 'circleRequests/alice_bob'));
    await assertSucceeds(batch.commit());
  });

  test('nobody can add themselves to a circle without a request', async () => {
    await assertFails(setDoc(doc(db('carol'), 'circles/alice'), { members: arrayUnion('carol') }, { merge: true }));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'circles/alice'), { members: ['bob'] }));
    await assertFails(setDoc(doc(db('carol'), 'circles/alice'), { members: ['bob', 'carol'] }));
    await assertFails(setDoc(doc(db('carol'), 'circles/alice'), { members: [] }));
  });

  test('a member can leave someone else\'s circle', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'circles/alice'), { members: ['bob', 'dave'] }));
    await assertSucceeds(setDoc(doc(db('bob'), 'circles/alice'), { members: arrayRemove('bob') }, { merge: true }));
  });
});

describe('circles, blocks, reports, old features', () => {
  test('circles and blocks are private to their owner', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'circles/alice'), { members: ['bob'] }));
    await assertFails(getDoc(doc(db('bob'), 'circles/alice')));
    await assertSucceeds(setDoc(doc(db('alice'), 'blocks/alice'), { blocked: ['carol'] }));
    await assertFails(getDoc(doc(db('carol'), 'blocks/alice')));
  });

  test('reports can be filed as yourself but never read', async () => {
    await assertSucceeds(addDoc(collection(db('bob'), 'reportUser/alice/report'), { reportUser: 'bob' }));
    await assertFails(addDoc(collection(db('bob'), 'reportUser/alice/report'), { reportUser: 'carol' }));
    await assertFails(getDocs(collection(db('alice'), 'reportUser/alice/report')));
    await assertSucceeds(addDoc(collection(db('bob'), 'reportPostUser/alice/report'), { reportUser: 'bob' }));
  });

  test('old album and reminder features still work for their owner', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'imagesUser/alice'), { image: [] }));
    await assertSucceeds(getDoc(doc(db('bob'), 'imagesUser/alice')));
    await assertFails(setDoc(doc(db('bob'), 'imagesUser/alice'), { image: [] }));
    await assertSucceeds(setDoc(doc(db('alice'), 'reminder/alice'), { isRinging: false }));
    await assertFails(getDoc(doc(db('bob'), 'reminder/alice')));
  });

  test('unknown collections are denied', async () => {
    await assertFails(setDoc(doc(db('alice'), 'anythingElse/x'), { a: 1 }));
  });
});

describe('account deletion', () => {
  test('a user can remove all of their own data', async () => {
    await seed(async (f) => {
      await setDoc(doc(f, 'users/alice'), { uId: 'alice' });
      await setDoc(doc(f, 'postsMain/p1'), { ownerId: 'alice', text: 'x' });
      await setDoc(doc(f, 'circlePosts/c1'), { ownerId: 'alice', audience: ['alice'] });
      await setDoc(doc(f, 'postsOnlyMe/alice/myPost/j1'), { text: 'x' });
      await setDoc(doc(f, 'users/alice/chats/bob'), { userId: 'bob' });
      await setDoc(doc(f, 'circles/alice'), { members: [] });
    });
    const f = db('alice');
    const batch = writeBatch(f);
    for (const path of ['postsMain/p1', 'circlePosts/c1', 'postsOnlyMe/alice/myPost/j1',
      'users/alice/chats/bob', 'circles/alice', 'blocks/alice', 'imagesUser/alice',
      'reminder/alice', 'users/alice']) {
      batch.delete(doc(f, path));
    }
    await assertSucceeds(batch.commit());
  });
});

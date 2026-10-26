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

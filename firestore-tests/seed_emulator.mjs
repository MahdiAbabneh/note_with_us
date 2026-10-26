// Creates the accounts in emulator-test-accounts.json inside the local
// Auth and Firestore emulators (never the live project).
// Usage: node seed_emulator.mjs   (with the emulators running)
import { readFileSync, writeFileSync } from 'node:fs';

const project = 'myapp-e68ac';
const { accounts } = JSON.parse(readFileSync('emulator-test-accounts.json', 'utf8'));
const authUrl = 'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator';
const docUrl = (path) =>
  `http://localhost:8080/v1/projects/${project}/databases/(default)/documents/${path}`;

const str = (v) => ({ stringValue: v });
const ids = {};
for (const a of accounts) {
  const res = await fetch(authUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: a.email, password: a.password, returnSecureToken: true }),
  });
  const body = await res.json();
  if (!body.localId) throw new Error(`sign-up failed for ${a.email}: ${JSON.stringify(body)}`);
  const uid = body.localId;
  ids[a.email] = uid;
  const profile = await fetch(docUrl(`users/${uid}`), {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({
      fields: {
        uId: str(uid), username: str(a.name), email: str(a.email), image: str(''),
        token: str(''), dateOfBirth: str('1/15/1998'), phoneNumber: str(''),
        gender: str(a.gender), location: str(''), bio: str(''), theme: str('origin'),
        darkMood: { booleanValue: false },
      },
    }),
  });
  if (!profile.ok) throw new Error(`profile failed: ${await profile.text()}`);
  console.log(`created ${a.name} (${uid})`);
}
writeFileSync('.emulator-ids.json', JSON.stringify(ids, null, 2));

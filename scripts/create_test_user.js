#!/usr/bin/env node
/**
 * Creates a test Firebase Auth user with emailVerified: true.
 *
 * Usage:
 *   node scripts/create_test_user.js
 *
 * Auth options (pick one):
 *   A) Application Default Credentials — run first:
 *        gcloud auth application-default login
 *   B) Service-account key file — set env var:
 *        GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json node scripts/create_test_user.js
 */

const admin = require('firebase-admin');
const readline = require('readline');

function ask(rl, question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

async function promptUser() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  console.log('\n🍺  BeerEr — Create Test Firebase User\n');

  const email = (await ask(rl, '  Email        : ')).trim();
  const password = (await ask(rl, '  Password     : ')).trim();
  const displayName = (await ask(rl, '  Display name : ')).trim();

  rl.close();

  if (!email || !password) {
    console.error('❌ Email and password are required.');
    process.exit(1);
  }

  return { email, password, displayName: displayName || undefined };
}

async function main() {
  const TEST_USER = { ...(await promptUser()), emailVerified: true };

  admin.initializeApp();

  try {
    const userRecord = await admin.auth().createUser(TEST_USER);
    console.log('\n✅ Test user created successfully');
    console.log('   UID:     ', userRecord.uid);
    console.log('   Email:   ', userRecord.email);
    console.log('   Verified:', userRecord.emailVerified);
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      console.log('ℹ️  User already exists — updating password & emailVerified…');
      const existing = await admin.auth().getUserByEmail(TEST_USER.email);
      const updated = await admin.auth().updateUser(existing.uid, {
        emailVerified: true,
        password: TEST_USER.password,
        displayName: TEST_USER.displayName,
      });
      console.log('\n✅ Existing user updated');
      console.log('   UID:     ', updated.uid);
      console.log('   Email:   ', updated.email);
      console.log('   Verified:', updated.emailVerified);
    } else {
      console.error('❌ Error:', err.message);
      process.exit(1);
    }
  }
}

main();

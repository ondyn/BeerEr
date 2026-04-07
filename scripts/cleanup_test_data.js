#!/usr/bin/env node
/**
 * Cleans up Firestore test/mock data and soft-deleted user data.
 *
 * What it does:
 *   1. Identifies removable users:
 *      a) Test user profiles whose IDs match populate_mock_data.js (user-*-0XX).
 *      b) Any user profile with a non-empty `deleted_at` field (soft-deleted).
 *   2. Deletes those user profile documents.
 *   3. For each kegSession:
 *      - If ALL participant_ids are removable users → deletes the session,
 *        its manualUsers subcollection, related pours, and jointAccounts.
 *      - If SOME participant_ids are removable → removes only those UIDs
 *        from the participant_ids array (no other data is touched).
 *   4. Does NOT touch Firebase Authentication — only Firestore documents.
 *
 * Usage:
 *   # Dry run (default) — shows what would be deleted, changes nothing:
 *   node scripts/cleanup_test_data.js
 *
 *   # Actually delete:
 *   node scripts/cleanup_test_data.js --delete
 *
 * Auth: Application Default Credentials or GOOGLE_APPLICATION_CREDENTIALS.
 */

const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// ---------------------------------------------------------------------------
// The well-known test user UIDs from populate_mock_data.js.
// ---------------------------------------------------------------------------
const TEST_USER_IDS = [
  'user-tomas-001',
  'user-petra-002',
  'user-martin-003',
  'user-lucie-004',
  'user-jakub-005',
  'user-anna-006',
  'user-ondra-007',
  'user-eva-008',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Delete all documents in a collection/query, in batches of 450. */
async function deleteQueryBatched(query, dryRun, label) {
  const snap = await query.get();
  if (snap.empty) return 0;

  let count = 0;
  const docs = snap.docs;

  if (dryRun) {
    for (const doc of docs) {
      console.log(`      [dry-run] would delete ${label}/${doc.id}`);
    }
    return docs.length;
  }

  for (let i = 0; i < docs.length; i += 450) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + 450);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    count += chunk.length;
  }
  return count;
}

/** Delete all documents in a subcollection of a given doc ref. */
async function deleteSubcollection(parentRef, subcollectionName, dryRun, label) {
  const collRef = parentRef.collection(subcollectionName);
  return deleteQueryBatched(collRef, dryRun, label);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const dryRun = !process.argv.includes('--delete');

  console.log(`\n🍺  Beerer — Firestore Test & Deleted-User Data Cleanup`);
  console.log(`    Mode: ${dryRun ? '🔍 DRY RUN (pass --delete to actually remove data)' : '🗑️  DELETE'}\n`);

  // -----------------------------------------------------------------------
  // 0. Discover soft-deleted users (deleted_at is set)
  // -----------------------------------------------------------------------
  const removableUserIds = new Set(TEST_USER_IDS);
  const softDeletedIds = [];

  console.log('🔍 Scanning for soft-deleted users (deleted_at != null)…');
  const allUsersSnap = await db.collection('users').get();
  for (const doc of allUsersSnap.docs) {
    const data = doc.data();
    if (data.deleted_at) {
      softDeletedIds.push(doc.id);
      removableUserIds.add(doc.id);
      console.log(`   Found: users/${doc.id} (${data.nickname || data.email || doc.id}) — deleted_at: ${data.deleted_at.toDate ? data.deleted_at.toDate().toISOString() : data.deleted_at}`);
    }
  }
  if (softDeletedIds.length === 0) {
    console.log('   None found.');
  }

  // -----------------------------------------------------------------------
  // 1. Delete test user profile documents
  // -----------------------------------------------------------------------
  console.log('\n👤 Test user profiles:');
  let usersDeleted = 0;
  for (const uid of TEST_USER_IDS) {
    const ref = db.collection('users').doc(uid);
    const snap = await ref.get();
    if (!snap.exists) {
      console.log(`   ⏭  users/${uid} — not found, skipping`);
      continue;
    }
    if (dryRun) {
      console.log(`   [dry-run] would delete users/${uid} (${snap.data().nickname || snap.data().email || uid})`);
    } else {
      await ref.delete();
      console.log(`   ✅ deleted users/${uid}`);
    }
    usersDeleted++;
  }

  // -----------------------------------------------------------------------
  // 1b. Delete soft-deleted user profile documents
  // -----------------------------------------------------------------------
  if (softDeletedIds.length > 0) {
    console.log('\n👤 Soft-deleted user profiles:');
    for (const uid of softDeletedIds) {
      const ref = db.collection('users').doc(uid);
      if (dryRun) {
        console.log(`   [dry-run] would delete users/${uid}`);
      } else {
        await ref.delete();
        console.log(`   ✅ deleted users/${uid}`);
      }
      usersDeleted++;
    }
  }

  // -----------------------------------------------------------------------
  // 2. Process keg sessions
  // -----------------------------------------------------------------------
  console.log('\n🍺 Keg sessions:');
  const sessionsSnap = await db.collection('kegSessions').get();

  let sessionsFullyDeleted = 0;
  let sessionsTrimmed = 0;
  let poursDeleted = 0;
  let jointAccountsDeleted = 0;
  let manualUsersDeleted = 0;

  for (const sessionDoc of sessionsSnap.docs) {
    const data = sessionDoc.data();
    const participantIds = data.participant_ids || [];
    const sessionId = sessionDoc.id;

    const testParticipants = participantIds.filter((id) => removableUserIds.has(id));
    const realParticipants = participantIds.filter((id) => !removableUserIds.has(id));

    if (testParticipants.length === 0) {
      // No removable users in this session — skip entirely.
      continue;
    }

    if (realParticipants.length === 0) {
      // ALL participants are removable → delete entire session + related data.
      console.log(`\n   🗑️  Session "${data.beer_name || sessionId}" (${sessionId})`);
      console.log(`      All ${participantIds.length} participant(s) are removable — full delete`);

      // 2a. Delete pours for this session
      const poursQuery = db.collection('pours').where('session_id', '==', sessionId);
      const pc = await deleteQueryBatched(poursQuery, dryRun, 'pours');
      poursDeleted += pc;
      if (pc > 0) console.log(`      ${dryRun ? '[dry-run] would delete' : '✅ deleted'} ${pc} pour(s)`);

      // 2b. Delete joint accounts for this session
      const jaQuery = db.collection('jointAccounts').where('session_id', '==', sessionId);
      const jc = await deleteQueryBatched(jaQuery, dryRun, 'jointAccounts');
      jointAccountsDeleted += jc;
      if (jc > 0) console.log(`      ${dryRun ? '[dry-run] would delete' : '✅ deleted'} ${jc} joint account(s)`);

      // 2c. Delete manualUsers subcollection
      const mc = await deleteSubcollection(sessionDoc.ref, 'manualUsers', dryRun, `kegSessions/${sessionId}/manualUsers`);
      manualUsersDeleted += mc;
      if (mc > 0) console.log(`      ${dryRun ? '[dry-run] would delete' : '✅ deleted'} ${mc} manual user(s)`);

      // 2d. Delete the session document itself
      if (dryRun) {
        console.log(`      [dry-run] would delete kegSessions/${sessionId}`);
      } else {
        await sessionDoc.ref.delete();
        console.log(`      ✅ deleted kegSessions/${sessionId}`);
      }
      sessionsFullyDeleted++;

    } else {
      // Mixed session — remove only removable UIDs from participant_ids.
      console.log(`\n   ✂️  Session "${data.beer_name || sessionId}" (${sessionId})`);
      console.log(`      ${testParticipants.length} removable user(s) among ${participantIds.length} participants — trimming`);
      console.log(`      Removing: ${testParticipants.join(', ')}`);
      console.log(`      Keeping:  ${realParticipants.join(', ')}`);

      if (dryRun) {
        console.log(`      [dry-run] would update participant_ids`);
      } else {
        await sessionDoc.ref.update({
          participant_ids: realParticipants,
        });
        console.log(`      ✅ updated participant_ids`);
      }
      sessionsTrimmed++;
    }
  }

  // -----------------------------------------------------------------------
  // 3. Summary
  // -----------------------------------------------------------------------
  console.log('\n' + '─'.repeat(60));
  console.log(`📊 Summary${dryRun ? ' (DRY RUN — nothing was changed)' : ''}:`);
  console.log(`   👤 User profiles removed:       ${usersDeleted} (${TEST_USER_IDS.length} test + ${softDeletedIds.length} soft-deleted)`);
  console.log(`   🍺 Sessions fully deleted:      ${sessionsFullyDeleted}`);
  console.log(`   ✂️  Sessions trimmed:             ${sessionsTrimmed}`);
  console.log(`   🫗 Pours deleted:               ${poursDeleted}`);
  console.log(`   👥 Joint accounts deleted:      ${jointAccountsDeleted}`);
  console.log(`   🎭 Manual users deleted:        ${manualUsersDeleted}`);
  console.log('');

  if (dryRun) {
    console.log('💡 To actually delete, run:');
    console.log('   node scripts/cleanup_test_data.js --delete\n');
  } else {
    console.log('✅ Cleanup complete.\n');
  }
}

main().catch((err) => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});

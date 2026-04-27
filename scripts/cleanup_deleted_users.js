#!/usr/bin/env node
/**
 * Cleans up Firestore data for fully-deleted users and orphaned sessions.
 *
 * A "deleted user" is any user document with `suspended: true` or a non-null
 * `deleted_at` field (soft-deleted via the in-app account deletion flow).
 *
 * What this script does — in order:
 *   1. Finds all deleted user IDs.
 *   2. Iterates every kegSession:
 *      a) If ALL participant_ids are deleted users → deletes the session,
 *         its manualUsers subcollection, all related pours, and all
 *         jointAccounts for that session.
 *      b) If SOME participants are deleted → only removes those UIDs from
 *         participant_ids (session data is otherwise preserved).
 *   3. After session processing, deletes any deleted-user documents that are
 *      no longer participants in ANY remaining session.
 *   4. Deletes any jointAccount documents whose session no longer exists or
 *      whose member_user_ids are all deleted users (and they aren't already
 *      deleted above in step 2a).
 *
 * Usage:
 *   # Dry run (default) — prints what would be deleted, changes nothing:
 *   node scripts/cleanup_deleted_users.js
 *
 *   # Actually delete:
 *   node scripts/cleanup_deleted_users.js --apply
 *
 * Auth: Application Default Credentials (run `gcloud auth application-default login`
 * or set GOOGLE_APPLICATION_CREDENTIALS).
 */

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'ondyn-beerer' });

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Batch-delete all docs returned by a query/collection ref. */
async function deleteQueryBatched(queryOrRef, dryRun, label) {
  const snap = await queryOrRef.get();
  if (snap.empty) return 0;
  const docs = snap.docs;
  if (dryRun) {
    for (const doc of docs) {
      console.log(`      [dry-run] would delete ${label}/${doc.id}`);
    }
    return docs.length;
  }
  let deleted = 0;
  for (let i = 0; i < docs.length; i += 450) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + 450);
    for (const doc of chunk) batch.delete(doc.ref);
    await batch.commit();
    deleted += chunk.length;
  }
  return deleted;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const dryRun = !process.argv.includes('--apply');

  console.log('\n🍺  Beerer — Deleted-User Orphan Cleanup');
  console.log(`    Mode: ${dryRun ? '🔍 DRY RUN (pass --apply to actually remove data)' : '🗑️  APPLY'}\n`);

  // -------------------------------------------------------------------------
  // Step 1: Identify all deleted users (suspended or deleted_at set).
  // -------------------------------------------------------------------------
  console.log('🔍 Step 1: Scanning users collection for deleted accounts…');
  const allUsersSnap = await db.collection('users').get();

  /** @type {Set<string>} */
  const deletedUserIds = new Set();
  for (const doc of allUsersSnap.docs) {
    const data = doc.data();
    if (data.suspended === true || data.deleted_at) {
      deletedUserIds.add(doc.id);
      const deletedWhen = data.deleted_at
        ? (data.deleted_at.toDate ? data.deleted_at.toDate().toISOString() : data.deleted_at)
        : 'n/a (suspended)';
      console.log(`   ⚠️  users/${doc.id} — "${data.nickname || data.email || doc.id}" — deleted_at: ${deletedWhen}`);
    }
  }
  if (deletedUserIds.size === 0) {
    console.log('   ✅ No deleted users found. Nothing to do.');
    process.exit(0);
  }
  console.log(`   → ${deletedUserIds.size} deleted user(s) found.\n`);

  // -------------------------------------------------------------------------
  // Step 2: Process keg sessions.
  // -------------------------------------------------------------------------
  console.log('🍺 Step 2: Processing keg sessions…');
  const sessionsSnap = await db.collection('kegSessions').get();

  /** Sessions that survived (still have at least one active participant). */
  const survivingSessionIds = new Set();
  /** Sessions that were fully deleted. */
  const deletedSessionIds = new Set();

  let totalPoursDeleted = 0;
  let totalManualUsersDeleted = 0;
  let totalJointAccountsDeleted = 0;
  let totalSessionsDeleted = 0;
  let totalSessionsTrimmed = 0;

  for (const sessionDoc of sessionsSnap.docs) {
    const data = sessionDoc.data();
    const sessionId = sessionDoc.id;
    const beerName = data.beer_name || sessionId;
    const participantIds = Array.isArray(data.participant_ids) ? data.participant_ids : [];

    const deletedParticipants = participantIds.filter((id) => deletedUserIds.has(id));
    const activeParticipants = participantIds.filter((id) => !deletedUserIds.has(id));

    if (deletedParticipants.length === 0) {
      // No deleted users in this session at all.
      survivingSessionIds.add(sessionId);
      continue;
    }

    if (activeParticipants.length === 0) {
      // ── All participants are deleted → full session delete ──────────────
      console.log(`\n   🗑️  Session "${beerName}" (${sessionId}) — all ${participantIds.length} participant(s) deleted → full delete`);

      // 2a. Pours for this session.
      const poursDeleted = await deleteQueryBatched(
        db.collection('pours').where('session_id', '==', sessionId),
        dryRun,
        `pours[session_id=${sessionId}]`,
      );
      console.log(`      pours deleted: ${poursDeleted}`);
      totalPoursDeleted += poursDeleted;

      // 2b. manualUsers subcollection.
      const manualUsersDeleted = await deleteQueryBatched(
        sessionDoc.ref.collection('manualUsers'),
        dryRun,
        `kegSessions/${sessionId}/manualUsers`,
      );
      console.log(`      manualUsers deleted: ${manualUsersDeleted}`);
      totalManualUsersDeleted += manualUsersDeleted;

      // 2c. jointAccounts for this session.
      const jointAccountsDeleted = await deleteQueryBatched(
        db.collection('jointAccounts').where('session_id', '==', sessionId),
        dryRun,
        `jointAccounts[session_id=${sessionId}]`,
      );
      console.log(`      jointAccounts deleted: ${jointAccountsDeleted}`);
      totalJointAccountsDeleted += jointAccountsDeleted;

      // 2d. The session document itself.
      if (dryRun) {
        console.log(`      [dry-run] would delete kegSessions/${sessionId}`);
      } else {
        await sessionDoc.ref.delete();
        console.log(`      ✅ deleted kegSessions/${sessionId}`);
      }
      totalSessionsDeleted++;
      deletedSessionIds.add(sessionId);

    } else {
      // ── Some participants are deleted → trim participant_ids only ────────
      console.log(`\n   ✂️  Session "${beerName}" (${sessionId}) — removing ${deletedParticipants.length} deleted participant(s), keeping ${activeParticipants.length}`);
      console.log(`      Removing: [${deletedParticipants.join(', ')}]`);

      if (!dryRun) {
        await sessionDoc.ref.update({
          participant_ids: activeParticipants,
        });
        console.log(`      ✅ participant_ids updated`);
      } else {
        console.log(`      [dry-run] would update participant_ids to [${activeParticipants.join(', ')}]`);
      }
      survivingSessionIds.add(sessionId);
      totalSessionsTrimmed++;
    }
  }

  // -------------------------------------------------------------------------
  // Step 3: Delete user documents that are no longer in ANY surviving session.
  // -------------------------------------------------------------------------
  console.log('\n👤 Step 3: Deleting user documents with no surviving sessions…');

  // Build a set of deleted-user IDs that are still referenced in a surviving session.
  /** @type {Set<string>} */
  const stillReferencedDeletedUsers = new Set();

  if (survivingSessionIds.size > 0) {
    // Re-read surviving sessions to capture the now-trimmed participant_ids.
    // We do a fresh fetch only for surviving sessions to stay within limits.
    const survivingSessionsArr = [...survivingSessionIds];
    for (let i = 0; i < survivingSessionsArr.length; i += 30) {
      const chunk = survivingSessionsArr.slice(i, i + 30);
      const snap = await db.collection('kegSessions')
        .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
        .get();
      for (const doc of snap.docs) {
        const participants = Array.isArray(doc.data().participant_ids) ? doc.data().participant_ids : [];
        for (const uid of participants) {
          if (deletedUserIds.has(uid)) {
            stillReferencedDeletedUsers.add(uid);
          }
        }
      }
    }
  }

  let totalUsersDeleted = 0;
  for (const uid of deletedUserIds) {
    if (stillReferencedDeletedUsers.has(uid)) {
      console.log(`   ⏭  users/${uid} — still referenced in a surviving session, skipping`);
      continue;
    }
    if (dryRun) {
      console.log(`   [dry-run] would delete users/${uid}`);
    } else {
      await db.collection('users').doc(uid).delete();
      console.log(`   ✅ deleted users/${uid}`);
    }
    totalUsersDeleted++;
  }
  if (totalUsersDeleted === 0 && stillReferencedDeletedUsers.size === 0) {
    console.log('   (none to delete)');
  }

  // -------------------------------------------------------------------------
  // Step 4: Clean up any remaining orphaned jointAccounts.
  //         (Catches accounts whose session was deleted in step 2 but that
  //          weren't caught by the session_id query — e.g. missing session doc.)
  // -------------------------------------------------------------------------
  console.log('\n🤝 Step 4: Scanning for orphaned jointAccounts…');
  const allAccountsSnap = await db.collection('jointAccounts').get();
  let orphanAccountsDeleted = 0;

  for (const accountDoc of allAccountsSnap.docs) {
    const data = accountDoc.data();
    const sessionId = data.session_id;

    // Already deleted in step 2?
    if (deletedSessionIds.has(sessionId)) continue;

    // Does the referenced session still exist?
    const sessionSnap = await db.collection('kegSessions').doc(sessionId).get();
    if (!sessionSnap.exists) {
      console.log(`   🗑️  jointAccounts/${accountDoc.id} — session ${sessionId} no longer exists`);
      if (dryRun) {
        console.log(`      [dry-run] would delete jointAccounts/${accountDoc.id}`);
      } else {
        await accountDoc.ref.delete();
        console.log(`      ✅ deleted jointAccounts/${accountDoc.id}`);
      }
      orphanAccountsDeleted++;
      continue;
    }

    // Are all member_user_ids deleted users?
    const memberIds = Array.isArray(data.member_user_ids) ? data.member_user_ids : [];
    const activeMembers = memberIds.filter((id) => !deletedUserIds.has(id));
    if (memberIds.length > 0 && activeMembers.length === 0) {
      console.log(`   🗑️  jointAccounts/${accountDoc.id} — all members are deleted users`);
      if (dryRun) {
        console.log(`      [dry-run] would delete jointAccounts/${accountDoc.id}`);
      } else {
        await accountDoc.ref.delete();
        console.log(`      ✅ deleted jointAccounts/${accountDoc.id}`);
      }
      orphanAccountsDeleted++;
    }
  }
  if (orphanAccountsDeleted === 0) {
    console.log('   ✅ No orphaned jointAccounts found.');
  }

  // -------------------------------------------------------------------------
  // Step 5: Integrity — delete pours whose session_id no longer exists.
  // -------------------------------------------------------------------------
  console.log('\n🔎 Step 5: Integrity check — pours with no matching kegSession…');
  const allPoursSnap = await db.collection('pours').get();
  let orphanPoursDeleted = 0;

  // Collect all existing session IDs (including those still in Firestore now).
  const existingSessionIds = new Set(
    (await db.collection('kegSessions').select().get()).docs.map((d) => d.id),
  );

  for (const pourDoc of allPoursSnap.docs) {
    const sessionId = pourDoc.data().session_id;
    if (!sessionId || (!existingSessionIds.has(sessionId) && !deletedSessionIds.has(sessionId))) {
      console.log(`   🗑️  pours/${pourDoc.id} — session_id "${sessionId}" does not exist`);
      if (dryRun) {
        console.log(`      [dry-run] would delete pours/${pourDoc.id}`);
      } else {
        await pourDoc.ref.delete();
        console.log(`      ✅ deleted pours/${pourDoc.id}`);
      }
      orphanPoursDeleted++;
    }
  }
  if (orphanPoursDeleted === 0) {
    console.log('   ✅ No orphaned pours found.');
  }

  // -------------------------------------------------------------------------
  // Step 6: Integrity — delete kegSessions whose participants don't exist.
  //         (None of the participant_ids resolve to a real user document.)
  //         Sessions already deleted in step 2 are skipped.
  // -------------------------------------------------------------------------
  console.log('\n🔎 Step 6: Integrity check — kegSessions with no existing participants…');

  // Build set of all real user IDs currently in Firestore (re-use allUsersSnap).
  const existingUserIds = new Set(allUsersSnap.docs.map((d) => d.id));

  let ghostSessionsDeleted = 0;

  for (const sessionDoc of sessionsSnap.docs) {
    const sessionId = sessionDoc.id;

    // Already deleted in step 2.
    if (deletedSessionIds.has(sessionId)) continue;

    const participantIds = Array.isArray(sessionDoc.data().participant_ids)
      ? sessionDoc.data().participant_ids
      : [];

    if (participantIds.length === 0) {
      // No participants at all — treat as ghost.
      console.log(`   🗑️  kegSessions/${sessionId} ("${sessionDoc.data().beer_name || sessionId}") — no participants`);
    } else {
      const existingParticipants = participantIds.filter((id) => existingUserIds.has(id));
      if (existingParticipants.length > 0) continue; // At least one real user.
      console.log(`   🗑️  kegSessions/${sessionId} ("${sessionDoc.data().beer_name || sessionId}") — all ${participantIds.length} participant(s) missing from users collection`);
    }

    // Delete pours for this ghost session.
    const ghostPoursDeleted = await deleteQueryBatched(
      db.collection('pours').where('session_id', '==', sessionId),
      dryRun,
      `pours[session_id=${sessionId}]`,
    );
    console.log(`      pours deleted: ${ghostPoursDeleted}`);
    totalPoursDeleted += ghostPoursDeleted;

    // Delete manualUsers subcollection.
    const ghostManualUsersDeleted = await deleteQueryBatched(
      sessionDoc.ref.collection('manualUsers'),
      dryRun,
      `kegSessions/${sessionId}/manualUsers`,
    );
    console.log(`      manualUsers deleted: ${ghostManualUsersDeleted}`);
    totalManualUsersDeleted += ghostManualUsersDeleted;

    // Delete jointAccounts for this session.
    const ghostJointAccountsDeleted = await deleteQueryBatched(
      db.collection('jointAccounts').where('session_id', '==', sessionId),
      dryRun,
      `jointAccounts[session_id=${sessionId}]`,
    );
    console.log(`      jointAccounts deleted: ${ghostJointAccountsDeleted}`);
    totalJointAccountsDeleted += ghostJointAccountsDeleted;

    if (dryRun) {
      console.log(`      [dry-run] would delete kegSessions/${sessionId}`);
    } else {
      await sessionDoc.ref.delete();
      console.log(`      ✅ deleted kegSessions/${sessionId}`);
    }
    ghostSessionsDeleted++;
    deletedSessionIds.add(sessionId);
  }

  if (ghostSessionsDeleted === 0) {
    console.log('   ✅ No ghost sessions found.');
  }

  // -------------------------------------------------------------------------
  // Summary
  // -------------------------------------------------------------------------
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 Summary');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const action = dryRun ? 'Would delete/update' : 'Deleted/updated';
  console.log(`   Deleted users found:           ${deletedUserIds.size}`);
  console.log(`   Orphaned pours deleted:        ${orphanPoursDeleted}`);
  console.log(`   Ghost sessions deleted:        ${ghostSessionsDeleted}`);
  console.log(`   Sessions fully deleted:         ${totalSessionsDeleted}`);
  console.log(`   Sessions trimmed (partial):     ${totalSessionsTrimmed}`);
  console.log(`   Pours deleted:                  ${totalPoursDeleted}`);
  console.log(`   Manual users deleted:           ${totalManualUsersDeleted}`);
  console.log(`   Joint accounts deleted:         ${totalJointAccountsDeleted + orphanAccountsDeleted}`);
  console.log(`   User documents deleted:         ${totalUsersDeleted}`);
  if (dryRun) {
    console.log('\n⚠️  DRY RUN — no data was modified. Pass --apply to execute.');
  } else {
    console.log('\n✅ Cleanup complete.');
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentWritten, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';

// Initialise Firebase Admin SDK
admin.initializeApp();

// Set default region
setGlobalOptions({ region: 'europe-west1' });

const db = admin.firestore();

type SupportedLanguage = 'en' | 'cs' | 'de';

type LocalisedCopy = {
  pourForYouTitle: string;
  pourForYouBody: (params: {
    pouredByName: string;
    volumeMl: number;
    beerName: string;
  }) => string;
  kegDoneTitle: string;
  kegDoneBody: (params: { beerName: string }) => string;
  kegNearlyEmptyTitle: string;
  kegNearlyEmptyBody: (params: { beerName: string; percentLeft: number }) => string;
};

const notificationCopy: Record<SupportedLanguage, LocalisedCopy> = {
  en: {
    pourForYouTitle: '🍻 Surprise pour incoming!',
    pourForYouBody: ({ pouredByName, volumeMl, beerName }) =>
      `${pouredByName} poured you ${volumeMl} ml of ${beerName}. Sip happens 😄`,
    kegDoneTitle: '🏁 Keg defeated!',
    kegDoneBody: ({ beerName }) =>
      `${beerName} is officially empty. Time for stats, glory, and maybe water 💧`,
    kegNearlyEmptyTitle: '🫗 Keg running on vibes!',
    kegNearlyEmptyBody: ({ beerName, percentLeft }) =>
      `Only ${percentLeft}% of ${beerName} left. Last-call reflexes activated!`,
  },
  cs: {
    pourForYouTitle: '🍻 Přistál ti čep!',
    pourForYouBody: ({ pouredByName, volumeMl, beerName }) =>
      `${pouredByName} ti načepoval(a) ${volumeMl} ml ${beerName}. Pivo se samo nevypije 😄`,
    kegDoneTitle: '🏁 Sud je poražen!',
    kegDoneBody: ({ beerName }) =>
      `${beerName} je oficiálně prázdný. Čas na statistiky, slávu a možná i vodu 💧`,
    kegNearlyEmptyTitle: '🫗 Sud jede na výpary!',
    kegNearlyEmptyBody: ({ beerName, percentLeft }) =>
      `Zbývá už jen ${percentLeft}% z ${beerName}. Režim posledního kola aktivován!`,
  },
  de: {
    pourForYouTitle: '🍻 Ueberraschungsbier fuer dich!',
    pourForYouBody: ({ pouredByName, volumeMl, beerName }) =>
      `${pouredByName} hat dir ${volumeMl} ml ${beerName} eingeschenkt. Prost auf Teamwork 😄`,
    kegDoneTitle: '🏁 Fass bezwungen!',
    kegDoneBody: ({ beerName }) =>
      `${beerName} ist offiziell leer. Zeit fuer Stats, Ruhm und vielleicht Wasser 💧`,
    kegNearlyEmptyTitle: '🫗 Fass auf Reserve!',
    kegNearlyEmptyBody: ({ beerName, percentLeft }) =>
      `Nur noch ${percentLeft}% von ${beerName} uebrig. Letzte-Runde-Reflexe an!`,
  },
};

function normaliseLanguage(languageRaw: unknown): SupportedLanguage {
  const language = typeof languageRaw === 'string' ? languageRaw.toLowerCase() : 'en';
  if (language === 'cs' || language === 'de' || language === 'en') {
    return language;
  }
  return 'en';
}

function messagingErrorCode(error: unknown): string {
  if (typeof error !== 'object' || error == null || !('code' in error)) {
    return 'unknown';
  }

  const { code } = error as { code?: unknown };
  return typeof code === 'string' ? code : 'unknown';
}

function isInvalidRegistrationTokenError(error: unknown): boolean {
  const code = messagingErrorCode(error);
  return (
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/registration-token-not-registered'
  );
}

async function clearStoredFcmToken(userId: string): Promise<void> {
  await db.collection('users').doc(userId).set(
    {
      preferences: {
        fcm_token: admin.firestore.FieldValue.delete(),
      },
    },
    { merge: true }
  );
}

// ---------------------------------------------------------------------------
// FCM notification — triggered when a new pour is written for another user.
//
// Sends localized push notifications (notification + data payload) so they
// are visible even when the app is backgrounded or terminated.
// ---------------------------------------------------------------------------
export const onPourCreated = onDocumentWritten('pours/{pourId}', async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;

  const pour = after.data() as {
    user_id: string;
    poured_by_id: string;
    volume_ml: number;
    session_id: string;
    undone?: boolean;
  };

  // Don't notify for undone pours or self-pours
  if (pour.undone) return;
  if (pour.user_id === pour.poured_by_id) return;

  const userSnap = await db.collection('users').doc(pour.user_id).get();
  const userData = userSnap.data();
  const prefs = userData?.preferences as Record<string, unknown> | undefined;
  const fcmToken = prefs?.fcm_token as string | undefined;
  if (!fcmToken) {
    console.info('onPourCreated: recipient has no stored FCM token', {
      userId: pour.user_id,
      pourId: event.params?.pourId ?? null,
      sessionId: pour.session_id,
    });
    return;
  }

  // Respect the user's notification preference (default: true)
  const notifyPourForMe = prefs?.notify_pour_for_me as boolean | undefined;
  if (notifyPourForMe === false) {
    console.info('onPourCreated: recipient disabled pour notifications', {
      userId: pour.user_id,
      pourId: event.params?.pourId ?? null,
      sessionId: pour.session_id,
    });
    return;
  }

  const language = normaliseLanguage(prefs?.language);
  const copy = notificationCopy[language];

  const pouredBySnap = await db.collection('users').doc(pour.poured_by_id).get();
  const pouredByName: string = pouredBySnap.data()?.nickname ?? 'Someone';

  const sessionSnap = await db.collection('kegSessions').doc(pour.session_id).get();
  const beerName: string = sessionSnap.data()?.beer_name ?? 'the keg';

  const title = copy.pourForYouTitle;
  const body = copy.pourForYouBody({
    pouredByName,
    volumeMl: pour.volume_ml,
    beerName,
  });

  try {
    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        type: 'pour_for_you',
        title,
        body,
        session_id: pour.session_id,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'beerer_default',
        },
      },
      apns: {
        payload: { aps: { sound: 'default' } },
        headers: {
          'apns-priority': '10',
        },
      },
    });

    console.info('onPourCreated: push sent', {
      userId: pour.user_id,
      pourId: event.params?.pourId ?? null,
      sessionId: pour.session_id,
      messageId,
    });
  } catch (error) {
    console.error('onPourCreated: push send failed', {
      userId: pour.user_id,
      pourId: event.params?.pourId ?? null,
      sessionId: pour.session_id,
      error,
    });

    if (isInvalidRegistrationTokenError(error)) {
      await clearStoredFcmToken(pour.user_id);
    }

    throw error;
  }
});

// ---------------------------------------------------------------------------
// FCM notification — triggered when a keg session status changes to 'done'.
// Notifies every participant who has keg-done notifications enabled.
// ---------------------------------------------------------------------------
export const onKegStatusChanged = onDocumentUpdated('kegSessions/{sessionId}', async (event) => {
  const before = event.data?.before?.data() as { status?: string } | undefined;
  const after = event.data?.after?.data() as {
    status?: string;
    beer_name?: string;
    participant_ids?: string[];
    volume_remaining_ml?: number;
    volume_total_ml?: number;
  } | undefined;

  if (!before || !after) return;

  const didTransitionToDone =
    before.status !== 'done' && after.status === 'done';

  const beforeTotal = beforeDataNumber(event.data?.before?.get('volume_total_ml'));
  const beforeRemaining = beforeDataNumber(
    event.data?.before?.get('volume_remaining_ml')
  );
  const afterTotal = beforeDataNumber(after.volume_total_ml);
  const afterRemaining = beforeDataNumber(after.volume_remaining_ml);
  const beforeRatio =
    beforeTotal > 0 ? clamp01(beforeRemaining / beforeTotal) : null;
  const afterRatio =
    afterTotal > 0 ? clamp01(afterRemaining / afterTotal) : null;

  const didCrossNearlyEmptyThreshold =
    !didTransitionToDone &&
    before.status === 'active' &&
    after.status === 'active' &&
    beforeRatio != null &&
    afterRatio != null &&
    beforeRatio > 0.1 &&
    afterRatio <= 0.1 &&
    afterRatio > 0;

  if (!didTransitionToDone && !didCrossNearlyEmptyThreshold) return;

  const participantIds = after.participant_ids ?? [];
  if (participantIds.length === 0) return;

  const beerName = after.beer_name ?? 'The keg';
  const sessionId = event.params?.sessionId ?? '';
  const percentLeft = afterRatio == null ? 0 : Math.max(0, Math.round(afterRatio * 100));

  // Fetch all participant user docs (Firestore whereIn limit: 30)
  const batches: string[][] = [];
  for (let i = 0; i < participantIds.length; i += 30) {
    batches.push(participantIds.slice(i, i + 30));
  }

  const allDocs: admin.firestore.DocumentSnapshot[] = [];
  for (const batch of batches) {
    const snap = await db
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', batch)
      .get();
    allDocs.push(...snap.docs);
  }

  const recipients: Array<{
    userId: string;
    token: string;
    message: admin.messaging.Message;
  }> = [];
  let skippedMissingToken = 0;
  let skippedByPreference = 0;

  for (const doc of allDocs) {
    const prefs = doc.data()?.preferences as Record<string, unknown> | undefined;
    const fcmToken = prefs?.fcm_token as string | undefined;
    if (!fcmToken) {
      skippedMissingToken += 1;
      continue;
    }

    const language = normaliseLanguage(prefs?.language);
    const copy = notificationCopy[language];

    let title: string | null = null;
    let body: string | null = null;

    if (didTransitionToDone) {
      const notifyKegDone = prefs?.notify_keg_done as boolean | undefined;
      if (notifyKegDone === false) {
        skippedByPreference += 1;
        continue;
      }
      title = copy.kegDoneTitle;
      body = copy.kegDoneBody({ beerName });
    } else if (didCrossNearlyEmptyThreshold) {
      const notifyNearlyEmpty = prefs?.notify_keg_nearly_empty as boolean | undefined;
      if (notifyNearlyEmpty === false) {
        skippedByPreference += 1;
        continue;
      }
      title = copy.kegNearlyEmptyTitle;
      body = copy.kegNearlyEmptyBody({
        beerName,
        percentLeft,
      });
    }

    if (title == null || body == null) continue;

    recipients.push({
      userId: doc.id,
      token: fcmToken,
      message: {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          type: didTransitionToDone ? 'keg_done' : 'keg_nearly_empty',
          title,
          body,
          session_id: sessionId,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'beerer_default',
          },
        },
        apns: {
          payload: { aps: { sound: 'default' } },
          headers: {
            'apns-priority': '10',
          },
        },
      },
    });
  }

  console.info('onKegStatusChanged: evaluated recipients', {
    sessionId,
    type: didTransitionToDone ? 'keg_done' : 'keg_nearly_empty',
    participantCount: participantIds.length,
    queuedCount: recipients.length,
    skippedMissingToken,
    skippedByPreference,
  });

  if (recipients.length === 0) return;

  // sendEach handles up to 500 messages
  const response = await admin.messaging().sendEach(
    recipients.map((recipient) => recipient.message)
  );

  const staleTokenUsers: string[] = [];
  response.responses.forEach((sendResponse, index) => {
    if (sendResponse.success) return;

    const recipient = recipients[index];
    console.error('onKegStatusChanged: push send failed', {
      sessionId,
      type: didTransitionToDone ? 'keg_done' : 'keg_nearly_empty',
      userId: recipient.userId,
      error: sendResponse.error,
    });

    if (isInvalidRegistrationTokenError(sendResponse.error)) {
      staleTokenUsers.push(recipient.userId);
    }
  });

  await Promise.all(staleTokenUsers.map((userId) => clearStoredFcmToken(userId)));

  console.info('onKegStatusChanged: send complete', {
    sessionId,
    type: didTransitionToDone ? 'keg_done' : 'keg_nearly_empty',
    successCount: response.successCount,
    failureCount: response.failureCount,
    clearedTokenCount: staleTokenUsers.length,
  });
});

function beforeDataNumber(value: unknown): number {
  return typeof value === 'number' ? value : 0;
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

// ---------------------------------------------------------------------------
// Account deletion — callable by the authenticated user.
// Soft-deletes the Firestore user record (clears personal data, marks as
// suspended, keeps email for future re-registration linking) and then
// deletes the Firebase Auth account.
// ---------------------------------------------------------------------------
export const deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be signed in');
  }

  const uid = request.auth.uid;

  // 1. Fetch the user doc to preserve the email.
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    // If user doc doesn't exist, just delete auth and return.
    await admin.auth().deleteUser(uid);
    return { success: true };
  }

  // 2. Soft-delete the Firestore user record: wipe personal data but keep
  //    email and the doc itself so pours/sessions remain consistent.
  await db.collection('users').doc(uid).update({
    nickname: 'Deleted User',
    weight_kg: 0,
    age: 0,
    gender: 'male',
    auth_provider: 'email',
    preferences: {},
    avatar_icon: admin.firestore.FieldValue.delete(),
    suspended: true,
    deleted_at: new Date().toISOString(),
  });

  // 3. Delete the Firebase Auth account.
  await admin.auth().deleteUser(uid);

  return { success: true };
});

// ---------------------------------------------------------------------------
// Re-registration relinking — callable by a newly registered user.
// When a user registers with an email that matches a suspended (soft-deleted)
// account, this function reassigns all pours, sessions, and joint accounts
// from the old UID to the new UID, then deletes the old suspended user doc.
// ---------------------------------------------------------------------------
export const relinkSuspendedAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be signed in');
  }

  const email = request.data?.email as string | undefined;
  if (!email) {
    throw new HttpsError('invalid-argument', 'email is required');
  }

  const newUid = request.auth.uid;

  // Find suspended account with matching email.
  const suspendedSnap = await db
    .collection('users')
    .where('email', '==', email)
    .where('suspended', '==', true)
    .limit(1)
    .get();

  if (suspendedSnap.empty) {
    return { relinked: false };
  }

  const oldDoc = suspendedSnap.docs[0];
  const oldUid = oldDoc.id;

  if (oldUid === newUid) {
    return { relinked: false };
  }

  // Reassign pours: user_id
  const userPours = await db
    .collection('pours')
    .where('user_id', '==', oldUid)
    .get();
  for (const doc of userPours.docs) {
    await doc.ref.update({ user_id: newUid });
  }

  // Reassign pours: poured_by_id
  const pouredByPours = await db
    .collection('pours')
    .where('poured_by_id', '==', oldUid)
    .get();
  for (const doc of pouredByPours.docs) {
    await doc.ref.update({ poured_by_id: newUid });
  }

  // Update participant_ids in sessions
  const sessions = await db
    .collection('kegSessions')
    .where('participant_ids', 'array-contains', oldUid)
    .get();
  for (const doc of sessions.docs) {
    await doc.ref.update({
      participant_ids: admin.firestore.FieldValue.arrayRemove([oldUid]),
    });
    await doc.ref.update({
      participant_ids: admin.firestore.FieldValue.arrayUnion([newUid]),
    });
  }

  // Update creator_id in sessions
  const createdSessions = await db
    .collection('kegSessions')
    .where('creator_id', '==', oldUid)
    .get();
  for (const doc of createdSessions.docs) {
    await doc.ref.update({ creator_id: newUid });
  }

  // Update joint accounts: member_user_ids
  const memberAccounts = await db
    .collection('jointAccounts')
    .where('member_user_ids', 'array-contains', oldUid)
    .get();
  for (const doc of memberAccounts.docs) {
    await doc.ref.update({
      member_user_ids: admin.firestore.FieldValue.arrayRemove([oldUid]),
    });
    await doc.ref.update({
      member_user_ids: admin.firestore.FieldValue.arrayUnion([newUid]),
    });
  }

  // Update joint accounts: creator_id
  const creatorAccounts = await db
    .collection('jointAccounts')
    .where('creator_id', '==', oldUid)
    .get();
  for (const doc of creatorAccounts.docs) {
    await doc.ref.update({ creator_id: newUid });
  }

  // Delete the old suspended user doc
  await db.collection('users').doc(oldUid).delete();

  return { relinked: true, oldUid };
});

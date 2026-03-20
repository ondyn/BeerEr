import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentWritten, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';

// Initialise Firebase Admin SDK
admin.initializeApp();

// Set default region
setGlobalOptions({ region: 'europe-west1' });

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Untappd beer search proxy
// API key is stored in Cloud Function environment config — never in the client.
// ---------------------------------------------------------------------------
export const searchUntappd = onCall({ secrets: ['UNTAPPD_API_KEY'] }, async (request) => {
  const query = request.data?.query as string | undefined;
  if (!query || query.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'query must be a non-empty string');
  }

  const apiKey = process.env.UNTAPPD_API_KEY;
  if (!apiKey) {
    throw new HttpsError('internal', 'Untappd API key not configured');
  }

  const url = `https://api.untappd.com/v4/search/beer?q=${encodeURIComponent(query)}&access_token=${apiKey}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new HttpsError('unavailable', `Untappd API error: ${res.status}`);
  }

  const json = await res.json() as { response?: { beers?: { items?: unknown[] } } };
  return json.response?.beers?.items ?? [];
});

// ---------------------------------------------------------------------------
// Settle Up export — called by the keg creator after keg is marked done.
// ---------------------------------------------------------------------------
export const exportToSettleUp = onCall(
  { secrets: ['SETTLEUP_CLIENT_ID', 'SETTLEUP_CLIENT_SECRET'] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in');
    }

    const { sessionId } = request.data as { sessionId: string };
    if (!sessionId) {
      throw new HttpsError('invalid-argument', 'sessionId is required');
    }

    // TODO: implement full Settle Up OAuth + debt creation flow
    console.info(`[exportToSettleUp] session=${sessionId} user=${request.auth.uid}`);
    return { success: true };
  }
);

// ---------------------------------------------------------------------------
// FCM notification — triggered when a new pour is written for another user.
//
// Uses data-only messages so the client can suppress display when the app
// is in the foreground.
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
  if (!fcmToken) return;

  // Respect the user's notification preference (default: true)
  const notifyPourForMe = prefs?.notify_pour_for_me as boolean | undefined;
  if (notifyPourForMe === false) return;

  const pouredBySnap = await db.collection('users').doc(pour.poured_by_id).get();
  const pouredByName: string = pouredBySnap.data()?.nickname ?? 'Someone';

  // Data-only message — the client decides whether to show a notification
  // based on foreground/background state.
  await admin.messaging().send({
    token: fcmToken,
    data: {
      type: 'pour_for_you',
      title: '🍺 Cheers!',
      body: `${pouredByName} poured you ${pour.volume_ml} ml`,
      session_id: pour.session_id,
    },
    // Android: data-only messages are delivered silently.
    // iOS: need content-available for background delivery.
    apns: {
      payload: { aps: { 'content-available': 1 } },
    },
  });
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
  } | undefined;

  if (!before || !after) return;

  // Only fire when status transitions to 'done'
  if (before.status === 'done' || after.status !== 'done') return;

  const participantIds = after.participant_ids ?? [];
  if (participantIds.length === 0) return;

  const beerName = after.beer_name ?? 'The keg';
  const sessionId = event.params?.sessionId ?? '';

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

  const messages: admin.messaging.Message[] = [];
  for (const doc of allDocs) {
    const prefs = doc.data()?.preferences as Record<string, unknown> | undefined;
    const fcmToken = prefs?.fcm_token as string | undefined;
    if (!fcmToken) continue;

    // Respect the user's preference (default: true)
    const notifyKegDone = prefs?.notify_keg_done as boolean | undefined;
    if (notifyKegDone === false) continue;

    messages.push({
      token: fcmToken,
      data: {
        type: 'keg_done',
        title: '🎉 Keg empty!',
        body: `${beerName} is done. Check the final stats!`,
        session_id: sessionId,
      },
      apns: {
        payload: { aps: { 'content-available': 1 } },
      },
    });
  }

  if (messages.length > 0) {
    // sendEach handles up to 500 messages
    await admin.messaging().sendEach(messages);
  }
});

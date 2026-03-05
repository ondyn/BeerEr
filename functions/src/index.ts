import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
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
// ---------------------------------------------------------------------------
export const onPourCreated = onDocumentWritten('pours/{pourId}', async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;

  const pour = after.data() as {
    user_id: string;
    poured_by_id: string;
    volume_ml: number;
    session_id: string;
  };

  // Only notify when someone else poured the beer
  if (pour.user_id === pour.poured_by_id) return;

  const userSnap = await db.collection('users').doc(pour.user_id).get();
  const fcmToken: string | undefined = userSnap.data()?.preferences?.fcm_token;
  if (!fcmToken) return;

  const pouredBySnap = await db.collection('users').doc(pour.poured_by_id).get();
  const pouredByName: string = pouredBySnap.data()?.nickname ?? 'Someone';

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: '🍺 Cheers!',
      body: `${pouredByName} poured you ${pour.volume_ml} ml`,
    },
    data: { session_id: pour.session_id },
  });
});

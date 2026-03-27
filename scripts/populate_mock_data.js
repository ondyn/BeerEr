#!/usr/bin/env node
/**
 * Populates Firestore with realistic mock data for Google Play Store screenshots.
 *
 * Creates:
 *   - 8 Firebase Auth users (with emailVerified: true)
 *   - 8 Firestore user profiles
 *   - 5 active keg sessions in different states (created, active, paused)
 *   - 5 finished ("done") keg sessions with pours & joint accounts
 *   - Pours distributed across users
 *   - Joint accounts for some sessions
 *   - Manual (guest) users in some sessions
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json node scripts/populate_mock_data.js
 *
 * Or with Application Default Credentials:
 *   gcloud auth application-default login
 *   node scripts/populate_mock_data.js
 */

const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// ---------------------------------------------------------------------------
// Avatar icon code points (from kAvatarIcons in avatar_icon.dart)
// ---------------------------------------------------------------------------
const AVATAR_SPORTS_BAR  = 0xf68d;   // Icons.sports_bar
const AVATAR_LOCAL_BAR   = 0xe3e1;   // Icons.local_bar
const AVATAR_WINE_BAR    = 0xf0e0;   // Icons.wine_bar
const AVATAR_NIGHTLIFE   = 0xf02a;   // Icons.nightlife
const AVATAR_CELEBRATION = 0xf0b1;   // Icons.celebration
const AVATAR_STAR        = 0xe5f9;   // Icons.star
const AVATAR_BOLT        = 0xf0e7;   // Icons.bolt
const AVATAR_ROCKET      = 0xf0e4;   // Icons.rocket_launch

// ---------------------------------------------------------------------------
// Users — realistic Czech/international names for a beer party context
// ---------------------------------------------------------------------------
const USERS = [
  {
    uid: 'user-tomas-001',
    email: 'tomas.novak@beerer.app',
    password: 'Test1234!',
    displayName: 'Tomáš Novák',
    profile: {
      nickname: 'Tomáš',
      email: 'tomas.novak@beerer.app',
      weight_kg: 85,
      age: 32,
      gender: 'male',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_SPORTS_BAR,
    },
  },
  {
    uid: 'user-petra-002',
    email: 'petra.svobodova@beerer.app',
    password: 'Test1234!',
    displayName: 'Petra Svobodová',
    profile: {
      nickname: 'Petra',
      email: 'petra.svobodova@beerer.app',
      weight_kg: 62,
      age: 28,
      gender: 'female',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_WINE_BAR,
    },
  },
  {
    uid: 'user-martin-003',
    email: 'martin.kovar@beerer.app',
    password: 'Test1234!',
    displayName: 'Martin Kovář',
    profile: {
      nickname: 'Martin',
      email: 'martin.kovar@beerer.app',
      weight_kg: 92,
      age: 35,
      gender: 'male',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_LOCAL_BAR,
    },
  },
  {
    uid: 'user-lucie-004',
    email: 'lucie.kralova@beerer.app',
    password: 'Test1234!',
    displayName: 'Lucie Králová',
    profile: {
      nickname: 'Lucka',
      email: 'lucie.kralova@beerer.app',
      weight_kg: 58,
      age: 26,
      gender: 'female',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_CELEBRATION,
    },
  },
  {
    uid: 'user-jakub-005',
    email: 'jakub.dvorak@beerer.app',
    password: 'Test1234!',
    displayName: 'Jakub Dvořák',
    profile: {
      nickname: 'Kuba',
      email: 'jakub.dvorak@beerer.app',
      weight_kg: 78,
      age: 30,
      gender: 'male',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_BOLT,
    },
  },
  {
    uid: 'user-anna-006',
    email: 'anna.nemcova@beerer.app',
    password: 'Test1234!',
    displayName: 'Anna Němcová',
    profile: {
      nickname: 'Anička',
      email: 'anna.nemcova@beerer.app',
      weight_kg: 55,
      age: 24,
      gender: 'female',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_STAR,
    },
  },
  {
    uid: 'user-ondra-007',
    email: 'ondrej.horak@beerer.app',
    password: 'Test1234!',
    displayName: 'Ondřej Horák',
    profile: {
      nickname: 'Ondra',
      email: 'ondrej.horak@beerer.app',
      weight_kg: 88,
      age: 34,
      gender: 'male',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_ROCKET,
    },
  },
  {
    uid: 'user-eva-008',
    email: 'eva.prochazkova@beerer.app',
    password: 'Test1234!',
    displayName: 'Eva Procházková',
    profile: {
      nickname: 'Evička',
      email: 'eva.prochazkova@beerer.app',
      weight_kg: 60,
      age: 29,
      gender: 'female',
      auth_provider: 'email',
      preferences: { allow_pour_for_me: true },
      avatar_icon: AVATAR_NIGHTLIFE,
    },
  },
];

// The "main" user — the one who will be logged in for screenshots.
const MAIN_USER = USERS[0]; // Tomáš

// ---------------------------------------------------------------------------
// Helper: create a Firestore Timestamp from an offset in hours from "now"
// ---------------------------------------------------------------------------
function ts(hoursAgo) {
  const d = new Date();
  d.setHours(d.getHours() - hoursAgo);
  return admin.firestore.Timestamp.fromDate(d);
}

function tsFromDate(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

// ---------------------------------------------------------------------------
// 5 ACTIVE keg sessions (various states)
// ---------------------------------------------------------------------------
const ACTIVE_SESSIONS = [
  // 1) Active — Saturday BBQ party, half-consumed, good activity
  {
    id: 'session-active-001',
    data: {
      creator_id: MAIN_USER.uid,
      beer_name: 'Pilsner Urquell',
      untappd_beer_id: null,
      volume_total_ml: 50000,         // 50 L keg
      volume_remaining_ml: 28500,     // ~43% consumed
      keg_price: 2890,                // CZK
      alcohol_percent: 4.4,
      predefined_volumes_ml: [500, 400, 300],
      start_time: ts(3),              // started 3 hours ago
      status: 'active',
      join_link: 'beerer://join/session-active-001',
      participant_ids: [
        USERS[0].uid, USERS[1].uid, USERS[2].uid,
        USERS[3].uid, USERS[4].uid, USERS[5].uid,
      ],
      brewery: 'Plzeňský Prazdroj',
      beer_style: 'Czech Pilsner',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '11.99°',
      fermentation: 'Bottom',
      malt: 'Moravian Barley',
    },
  },
  // 2) Active — just started, almost full keg
  {
    id: 'session-active-002',
    data: {
      creator_id: USERS[2].uid,       // Martin created
      beer_name: 'Kozel Černý',
      untappd_beer_id: null,
      volume_total_ml: 30000,
      volume_remaining_ml: 28500,
      keg_price: 1690,
      alcohol_percent: 3.8,
      predefined_volumes_ml: [500, 300],
      start_time: ts(0.5),            // started 30 min ago
      status: 'active',
      join_link: 'beerer://join/session-active-002',
      participant_ids: [
        USERS[2].uid, USERS[0].uid, USERS[6].uid,
      ],
      brewery: 'Velkopopovický Kozel',
      beer_style: 'Dark Lager',
      beer_type: 'Lager',
      beer_group: 'Tmavé',
      degree_plato: '10°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 3) Paused — rain break at garden party
  {
    id: 'session-active-003',
    data: {
      creator_id: USERS[4].uid,       // Kuba created
      beer_name: 'Bernard 12°',
      untappd_beer_id: null,
      volume_total_ml: 50000,
      volume_remaining_ml: 35200,
      keg_price: 3150,
      alcohol_percent: 5.0,
      predefined_volumes_ml: [500, 400, 300],
      start_time: ts(5),
      status: 'paused',
      join_link: 'beerer://join/session-active-003',
      participant_ids: [
        USERS[4].uid, USERS[0].uid, USERS[1].uid,
        USERS[5].uid, USERS[7].uid,
      ],
      brewery: 'Rodinný pivovar Bernard',
      beer_style: 'Czech Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '12°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 4) Created (not yet tapped) — preparing for evening
  {
    id: 'session-active-004',
    data: {
      creator_id: MAIN_USER.uid,
      beer_name: 'Staropramen Nefiltovaný',
      untappd_beer_id: null,
      volume_total_ml: 30000,
      volume_remaining_ml: 30000,
      keg_price: 1850,
      alcohol_percent: 4.8,
      predefined_volumes_ml: [500, 300],
      start_time: null,
      status: 'created',
      join_link: 'beerer://join/session-active-004',
      participant_ids: [USERS[0].uid],
      brewery: 'Pivovary Staropramen',
      beer_style: 'Unfiltered Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '11°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 5) Active — nearly empty, lots of pours
  {
    id: 'session-active-005',
    data: {
      creator_id: USERS[6].uid,       // Ondra created
      beer_name: 'Matuška California',
      untappd_beer_id: null,
      volume_total_ml: 30000,
      volume_remaining_ml: 3200,       // almost empty!
      keg_price: 3900,
      alcohol_percent: 5.3,
      predefined_volumes_ml: [400, 300, 200],
      start_time: ts(6),
      status: 'active',
      join_link: 'beerer://join/session-active-005',
      participant_ids: [
        USERS[6].uid, USERS[0].uid, USERS[1].uid,
        USERS[2].uid, USERS[3].uid, USERS[4].uid,
        USERS[5].uid, USERS[7].uid,
      ],
      brewery: 'Pivovar Matuška',
      beer_style: 'American Pale Ale',
      beer_type: 'Ale',
      beer_group: 'Světlé',
      degree_plato: '12.5°',
      fermentation: 'Top',
      malt: 'Pale Ale Malt',
    },
  },
];

// ---------------------------------------------------------------------------
// 5 FINISHED ("done") keg sessions — for history & bill review screenshots
// ---------------------------------------------------------------------------
const DONE_SESSIONS = [
  // 1) Done — Last weekend BBQ, fully consumed
  {
    id: 'session-done-001',
    data: {
      creator_id: MAIN_USER.uid,
      beer_name: 'Gambrinus 11°',
      untappd_beer_id: null,
      volume_total_ml: 50000,
      volume_remaining_ml: 0,
      keg_price: 2290,
      alcohol_percent: 4.3,
      predefined_volumes_ml: [500, 300],
      start_time: ts(7 * 24 + 4),     // 7 days ago + 4h
      status: 'done',
      join_link: 'beerer://join/session-done-001',
      participant_ids: [
        USERS[0].uid, USERS[1].uid, USERS[2].uid,
        USERS[3].uid, USERS[4].uid,
      ],
      brewery: 'Plzeňský Prazdroj',
      beer_style: 'Czech Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '11°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 2) Done — Birthday party 2 weeks ago
  {
    id: 'session-done-002',
    data: {
      creator_id: USERS[1].uid,       // Petra hosted
      beer_name: 'Budvar Original',
      untappd_beer_id: null,
      volume_total_ml: 30000,
      volume_remaining_ml: 1200,
      keg_price: 2190,
      alcohol_percent: 5.0,
      predefined_volumes_ml: [500, 400, 300],
      start_time: ts(14 * 24 + 6),
      status: 'done',
      join_link: 'beerer://join/session-done-002',
      participant_ids: [
        USERS[1].uid, USERS[0].uid, USERS[2].uid,
        USERS[5].uid, USERS[6].uid, USERS[7].uid,
      ],
      brewery: 'Budějovický Budvar',
      beer_style: 'Czech Pilsner',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '12°',
      fermentation: 'Bottom',
      malt: 'Moravian Barley',
    },
  },
  // 3) Done — House warming 3 weeks ago
  {
    id: 'session-done-003',
    data: {
      creator_id: USERS[4].uid,       // Kuba hosted
      beer_name: 'Svijany Máz 11°',
      untappd_beer_id: null,
      volume_total_ml: 50000,
      volume_remaining_ml: 4500,
      keg_price: 2450,
      alcohol_percent: 4.8,
      predefined_volumes_ml: [500, 400, 300],
      start_time: ts(21 * 24 + 2),
      status: 'done',
      join_link: 'beerer://join/session-done-003',
      participant_ids: [
        USERS[4].uid, USERS[0].uid, USERS[1].uid,
        USERS[2].uid, USERS[3].uid, USERS[5].uid,
        USERS[6].uid, USERS[7].uid,
      ],
      brewery: 'Pivovar Svijany',
      beer_style: 'Czech Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '11°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 4) Done — Office Friday drinks a month ago
  {
    id: 'session-done-004',
    data: {
      creator_id: MAIN_USER.uid,
      beer_name: 'Radegast Ryze Hořká 12',
      untappd_beer_id: null,
      volume_total_ml: 30000,
      volume_remaining_ml: 0,
      keg_price: 1790,
      alcohol_percent: 5.1,
      predefined_volumes_ml: [500, 300],
      start_time: ts(30 * 24 + 5),
      status: 'done',
      join_link: 'beerer://join/session-done-004',
      participant_ids: [
        USERS[0].uid, USERS[2].uid, USERS[3].uid,
        USERS[6].uid,
      ],
      brewery: 'Pivovar Radegast',
      beer_style: 'Czech Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '12°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
  // 5) Done — New Year party
  {
    id: 'session-done-005',
    data: {
      creator_id: USERS[6].uid,       // Ondra hosted
      beer_name: 'Krušovice 12°',
      untappd_beer_id: null,
      volume_total_ml: 50000,
      volume_remaining_ml: 2800,
      keg_price: 2690,
      alcohol_percent: 5.0,
      predefined_volumes_ml: [500, 400, 300],
      start_time: ts(60 * 24),         // ~2 months ago
      status: 'done',
      join_link: 'beerer://join/session-done-005',
      participant_ids: [
        USERS[6].uid, USERS[0].uid, USERS[1].uid,
        USERS[2].uid, USERS[3].uid, USERS[4].uid,
        USERS[5].uid, USERS[7].uid,
      ],
      brewery: 'Královský pivovar Krušovice',
      beer_style: 'Czech Lager',
      beer_type: 'Lager',
      beer_group: 'Světlé',
      degree_plato: '12°',
      fermentation: 'Bottom',
      malt: null,
    },
  },
];

// ---------------------------------------------------------------------------
// Pour generator — creates realistic pour distributions
// ---------------------------------------------------------------------------
function generatePours(sessionId, participantIds, sessionData) {
  const pours = [];
  const totalConsumed = sessionData.volume_total_ml - sessionData.volume_remaining_ml;
  const volumes = sessionData.predefined_volumes_ml;
  const startTime = sessionData.start_time;
  if (!startTime || totalConsumed <= 0) return pours;

  const startMs = startTime.toDate().getTime();
  const now = Date.now();
  const durationMs = now - startMs;

  // Distribute pours across participants with varied amounts
  // Heavier drinkers get more pours
  const weights = participantIds.map((_, i) => {
    // First user drinks moderately, vary by index
    const base = [1.5, 0.8, 1.2, 0.6, 1.0, 0.7, 1.3, 0.9];
    return base[i % base.length];
  });
  const totalWeight = weights.reduce((a, b) => a + b, 0);

  let volumeAssigned = 0;

  for (let i = 0; i < participantIds.length; i++) {
    const userId = participantIds[i];
    const userShare = totalConsumed * (weights[i] / totalWeight);
    let userVolume = 0;

    while (userVolume + volumes[0] <= userShare) {
      // Pick a random predefined volume
      const vol = volumes[Math.floor(Math.random() * volumes.length)];
      if (userVolume + vol > userShare) break;

      // Random time within the session duration
      const pourTimeMs = startMs + Math.random() * durationMs;

      // 80% self-pour, 20% poured by someone else
      const pouredBy = Math.random() < 0.8
        ? userId
        : participantIds[Math.floor(Math.random() * participantIds.length)];

      pours.push({
        session_id: sessionId,
        user_id: userId,
        poured_by_id: pouredBy,
        volume_ml: vol,
        timestamp: admin.firestore.Timestamp.fromMillis(pourTimeMs),
        undone: false,
      });

      userVolume += vol;
    }

    volumeAssigned += userVolume;
  }

  // Sort pours by timestamp
  pours.sort((a, b) => a.timestamp.toMillis() - b.timestamp.toMillis());

  return pours;
}

// ---------------------------------------------------------------------------
// Joint accounts for finished sessions
// ---------------------------------------------------------------------------
const JOINT_ACCOUNTS = [
  // Session done-001: two couples
  {
    session_id: 'session-done-001',
    group_name: 'Novákovi 👨‍👩‍👧',
    creator_id: USERS[0].uid,
    member_user_ids: [USERS[0].uid, USERS[1].uid],
    avatar_icon: AVATAR_CELEBRATION,
  },
  {
    session_id: 'session-done-001',
    group_name: 'Kovářovi 🏠',
    creator_id: USERS[2].uid,
    member_user_ids: [USERS[2].uid, USERS[3].uid],
    avatar_icon: AVATAR_NIGHTLIFE,
  },
  // Session done-003: large housewarming — one family group
  {
    session_id: 'session-done-003',
    group_name: 'Dvořákovi + Lucka',
    creator_id: USERS[4].uid,
    member_user_ids: [USERS[4].uid, USERS[3].uid, USERS[5].uid],
    avatar_icon: AVATAR_STAR,
  },
  // Session done-005: New Year — couples
  {
    session_id: 'session-done-005',
    group_name: 'Horákovi 🎆',
    creator_id: USERS[6].uid,
    member_user_ids: [USERS[6].uid, USERS[7].uid],
    avatar_icon: AVATAR_ROCKET,
  },
  {
    session_id: 'session-done-005',
    group_name: 'Tomáš & Petra',
    creator_id: USERS[0].uid,
    member_user_ids: [USERS[0].uid, USERS[1].uid],
    avatar_icon: AVATAR_SPORTS_BAR,
  },
  // Active session-active-001: one joint account
  {
    session_id: 'session-active-001',
    group_name: 'Grill Team 🔥',
    creator_id: USERS[0].uid,
    member_user_ids: [USERS[0].uid, USERS[2].uid, USERS[4].uid],
    avatar_icon: AVATAR_BOLT,
  },
];

// ---------------------------------------------------------------------------
// Manual (guest) users for some sessions
// ---------------------------------------------------------------------------
const MANUAL_USERS = [
  {
    session_id: 'session-active-001',
    nickname: 'Pepa (guest)',
  },
  {
    session_id: 'session-done-003',
    nickname: 'Uncle Mirek',
  },
];

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log('\n🍺  Beerer — Populating mock data for screenshots\n');

  // --- 1. Create Auth users ---
  console.log('👤 Creating Firebase Auth users…');
  for (const u of USERS) {
    try {
      await auth.createUser({
        uid: u.uid,
        email: u.email,
        password: u.password,
        displayName: u.displayName,
        emailVerified: true,
      });
      console.log(`   ✅ Created ${u.displayName} (${u.uid})`);
    } catch (err) {
      if (err.code === 'auth/uid-already-exists' || err.code === 'auth/email-already-exists') {
        // Update existing
        try {
          await auth.updateUser(u.uid, {
            email: u.email,
            password: u.password,
            displayName: u.displayName,
            emailVerified: true,
          });
          console.log(`   ♻️  Updated ${u.displayName} (${u.uid})`);
        } catch (updateErr) {
          console.log(`   ⚠️  Could not update ${u.displayName}: ${updateErr.message}`);
        }
      } else {
        console.log(`   ⚠️  Could not create ${u.displayName}: ${err.message}`);
      }
    }
  }

  // --- 2. Create Firestore user profiles ---
  console.log('\n📄 Writing user profiles to Firestore…');
  const batch1 = db.batch();
  for (const u of USERS) {
    batch1.set(db.collection('users').doc(u.uid), u.profile);
  }
  await batch1.commit();
  console.log(`   ✅ ${USERS.length} user profiles written.`);

  // --- 3. Create keg sessions ---
  console.log('\n🍺 Creating keg sessions…');
  const allSessions = [...ACTIVE_SESSIONS, ...DONE_SESSIONS];
  const batch2 = db.batch();
  for (const s of allSessions) {
    batch2.set(db.collection('kegSessions').doc(s.id), s.data);
  }
  await batch2.commit();
  console.log(`   ✅ ${allSessions.length} sessions created (${ACTIVE_SESSIONS.length} active, ${DONE_SESSIONS.length} done).`);

  // --- 4. Generate and write pours ---
  console.log('\n🫗 Generating pours…');
  let totalPours = 0;

  for (const s of allSessions) {
    const pours = generatePours(s.id, s.data.participant_ids, s.data);
    if (pours.length === 0) continue;

    // Write in batches of 500 (Firestore limit)
    for (let i = 0; i < pours.length; i += 450) {
      const chunk = pours.slice(i, i + 450);
      const pourBatch = db.batch();
      for (const p of chunk) {
        pourBatch.set(db.collection('pours').doc(), p);
      }
      await pourBatch.commit();
    }

    totalPours += pours.length;
    console.log(`   🍺 ${s.data.beer_name}: ${pours.length} pours`);
  }
  console.log(`   ✅ ${totalPours} total pours written.`);

  // --- 5. Create joint accounts ---
  console.log('\n👥 Creating joint accounts…');
  const batch3 = db.batch();
  for (const ja of JOINT_ACCOUNTS) {
    batch3.set(db.collection('jointAccounts').doc(), ja);
  }
  await batch3.commit();
  console.log(`   ✅ ${JOINT_ACCOUNTS.length} joint accounts created.`);

  // --- 6. Create manual (guest) users ---
  console.log('\n🎭 Creating manual (guest) users…');
  for (const mu of MANUAL_USERS) {
    const ref = db
      .collection('kegSessions')
      .doc(mu.session_id)
      .collection('manualUsers')
      .doc();
    await ref.set({
      session_id: mu.session_id,
      nickname: mu.nickname,
    });

    // Also add some pours for the guest
    const session = allSessions.find(s => s.id === mu.session_id);
    if (session && session.data.start_time) {
      const startMs = session.data.start_time.toDate().getTime();
      const guestPours = [
        { volume_ml: 500, offset: 0.3 },
        { volume_ml: 500, offset: 0.6 },
        { volume_ml: 300, offset: 0.8 },
      ];
      const guestBatch = db.batch();
      for (const gp of guestPours) {
        const pourTime = startMs + gp.offset * (Date.now() - startMs);
        guestBatch.set(db.collection('pours').doc(), {
          session_id: mu.session_id,
          user_id: ref.id,
          poured_by_id: session.data.creator_id,
          volume_ml: gp.volume_ml,
          timestamp: admin.firestore.Timestamp.fromMillis(pourTime),
          undone: false,
        });
      }
      await guestBatch.commit();
    }

    console.log(`   ✅ Guest "${mu.nickname}" in session ${mu.session_id}`);
  }

  // --- Done ---
  console.log('\n🎉 Mock data population complete!');
  console.log(`\n📱 To take screenshots, log in as:`);
  console.log(`   Email:    ${MAIN_USER.email}`);
  console.log(`   Password: ${MAIN_USER.password}`);
  console.log('');
}

main().catch((err) => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});

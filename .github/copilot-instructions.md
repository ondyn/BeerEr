# GitHub Copilot Instructions for BeerEr

## Project Overview
**BeerEr** is a cross-platform mobile application (iOS & Android) for tracking beer consumption from a keg at a party. It calculates per-user statistics, estimates keg depletion, and helps settle costs among groups.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — single codebase for iOS & Android |
| Backend / Database | Firebase Firestore (real-time, offline-persistent) |
| Serverless Logic | Firebase Cloud Functions (Node.js/TypeScript) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Beer Data | Untappd API (via Cloud Function, key never exposed client-side) |
| Cost Settlement | Settle Up API (`https://api.settleup.io/`) |
| Auth | Firebase Auth — email/password (with email verification) + social providers |

---

## Architecture Principles

1. **Real-time first** — All pour actions write to Firestore; all clients subscribe to live updates via snapshots.
2. **Firestore transactions for pours** — Every pour must use a transaction to prevent the keg volume from going negative under concurrent writes.
3. **Firebase offline persistence** — V1 offline support relies entirely on Firestore's built-in offline queue. Do NOT build a custom P2P/hotspot sync layer.
4. **Secrets stay server-side** — Untappd and Settle Up API keys must only live in Cloud Function environment config, never in Flutter code.
5. **Privacy by design** — Weight, age, and BAC data are opt-in to share; calculate BAC on the user's device only, never store the calculated BAC value in Firestore.

---

## Firestore Data Model

```
users/{user_id}
  nickname: string
  weight_kg: number
  age: number
  gender: "male" | "female"
  auth_provider: string
  preferences: map          # visibility settings, last pour volume, etc.

kegSessions/{session_id}
  creator_id: string
  beer_name: string
  untappd_beer_id: string?  # null for free-text kegs
  volume_total_ml: number
  volume_remaining_ml: number
  price_per_liter: number
  alcohol_percent: number
  predefined_volumes_ml: number[]
  start_time: timestamp
  status: "active" | "paused" | "done"

pours/{pour_id}
  session_id: string
  user_id: string           # whose beer this is
  poured_by_id: string      # may differ from user_id (poured for someone else)
  volume_ml: number
  timestamp: timestamp
  undone: boolean           # soft-delete for undo support

jointAccounts/{account_id}
  session_id: string
  group_name: string
  member_user_ids: string[]
```

---

## Key Features & Behaviour

### Keg Lifecycle
- **Create** → fill details (optionally search Untappd) → **Tap Keg** (sets `start_time`, status → `active`)
- **Pause** (`untap unfinished keg`) → status `paused`; no pours allowed while paused
- **Resume** (`tap keg` again) → status `active`
- **Done** (`keg done`, triggered by any user) → status `done`; pours frozen; history visible

### Pouring
- "I got beer" — user logs own pour; volume defaults to last used, changeable from predefined list or free input
- "Pour for someone else" — switch to user list → tap user → log pour (notifies that user via FCM)
- **Undo** — soft-delete (`undone: true`) within a short grace period; reverses keg volume via transaction

### Statistics (calculated client-side)
- Time drinking current beer / time since last beer
- Average drinking rate
- BAC estimate (Widmark formula, computed on device from local weight/age/gender)
- Estimated keg volume remaining
- Predicted time until keg empty (based on rolling consumption rate)
- Total cost for the session / per joint account

### Sharing & Joining
- Session creator shares a deep link, WhatsApp/message/mail intent, or QR code
- Joining sets a display nickname (pre-filled from profile) and visibility preferences

### Settle Up Integration
- After keg is done, creator can export per-joint-account costs via Settle Up API (Cloud Function)

---

## Development Environment

### Flutter via FVM
Flutter is managed with **FVM (Flutter Version Manager)**. The project pins `stable` in `.fvmrc`.
`fvm` is **not** on the global `PATH` — always invoke Flutter and Dart through the local SDK symlink:

```zsh
# Flutter
.fvm/flutter_sdk/bin/flutter <command>

# Dart
.fvm/flutter_sdk/bin/dart <command>

# Examples
.fvm/flutter_sdk/bin/flutter pub get
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter run
.fvm/flutter_sdk/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

If `fvm` is on PATH (after a full shell reload or global install), the short form also works:
```zsh
fvm flutter <command>
fvm dart <command>
```

### Code generation
Models use `freezed` + `json_serializable`; providers use `riverpod_generator`. After editing any annotated file, regenerate:
```zsh
.fvm/flutter_sdk/bin/flutter pub run build_runner build --delete-conflicting-outputs
```
Generated files (`*.g.dart`, `*.freezed.dart`) are **gitignored** — never edit them by hand.

### Running tests
```zsh
# All tests
.fvm/flutter_sdk/bin/flutter test

# Single file
.fvm/flutter_sdk/bin/flutter test test/bac_calculator_test.dart --reporter expanded
```

### Linting & formatting
```zsh
# Analyse
.fvm/flutter_sdk/bin/flutter analyze

# Format (line length 80, enforced by CI)
.fvm/flutter_sdk/bin/dart format lib/ test/
```

### Cloud Functions (TypeScript)
```zsh
cd functions
npm install          # first time
npm run build        # compile TS → lib/
npm run lint         # eslint
```
Secrets (`UNTAPPD_API_KEY`, `SETTLEUP_CLIENT_ID`, `SETTLEUP_CLIENT_SECRET`) live in Firebase Function environment config — **never** hardcode them.

### Firebase setup (first time)
```zsh
# Install FlutterFire CLI once
dart pub global activate flutterfire_cli

# Connect to Firebase project (generates lib/firebase_options.dart)
flutterfire configure
```
`lib/firebase_options.dart` is **gitignored** — each developer runs `flutterfire configure` locally.

---

## Coding Conventions

- **Language**: Dart for Flutter; TypeScript for Cloud Functions
- **State management**: `riverpod` with code-gen (`@riverpod` annotation + `riverpod_generator`)
- **Naming**: `snake_case` for Firestore fields; `camelCase` for Dart variables/functions; `PascalCase` for classes/widgets
- **Error handling**: Always handle Firestore `FirebaseException`; show user-friendly snackbars/dialogs
- **Transactions**: Any write that changes `volume_remaining_ml` MUST go through `runTransaction`
- **Tests**: Unit-test BAC calculation logic and Firestore transaction helpers; widget-test critical flows (pour, undo)
- **Localisation**: All user-facing strings go in `lib/l10n/app_en.arb`; use `AppLocalizations` — never hardcode strings
- **Responsible drinking**: Include "Drink Responsibly" copy in BAC-related UI; comply with App Store / Play Store guidelines

---

## External APIs

| API | Usage | Auth |
|-----|-------|------|
| Untappd | Search beers by name when creating a keg | API key in Cloud Function env |
| Settle Up | Export costs after keg is done | OAuth token stored server-side |
| Firebase Auth | User sign-up / sign-in | Firebase project config |

---

## Things to Avoid

- Do NOT store BAC values in Firestore
- Do NOT put Untappd or Settle Up credentials in Flutter source code
- Do NOT allow pours (write to Firestore) while keg `status === "paused"` or `"done"`
- Do NOT skip Firestore transactions for operations that modify `volume_remaining_ml`
- Do NOT build a custom offline sync layer; rely on Firebase offline persistence

---

## Repository Structure

```
BeerEr/
├── .fvm/                  # FVM config (fvm_config.json pinned to stable)
├── .github/
│   └── copilot-instructions.md
├── android/               # Android host app (generated)
├── ios/                   # iOS host app (generated)
├── functions/             # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   └── index.ts       # searchUntappd, exportToSettleUp, onPourCreated
│   ├── tsconfig.json
│   ├── eslint.config.mjs
│   └── package.json
├── lib/
│   ├── main.dart          # Entry point — Firebase init + ProviderScope
│   ├── app.dart           # BeerErApp widget (MaterialApp.router)
│   ├── router.dart        # go_router setup (@riverpod)
│   ├── firebase_options.dart  # GITIGNORED — run `flutterfire configure`
│   ├── models/            # Freezed data classes (user, keg_session, pour, joint_account)
│   ├── repositories/      # Firestore access layer (user_repository, keg_repository)
│   ├── providers/         # Riverpod providers (auth_provider, …)
│   ├── screens/           # One sub-folder per screen (home/, keg/, pour/, …)
│   ├── widgets/           # Shared reusable widgets
│   ├── utils/             # Pure Dart helpers (bac_calculator, …)
│   └── l10n/              # ARB files (app_en.arb, …)
├── test/
│   ├── bac_calculator_test.dart
│   └── widget_test.dart
├── analysis_options.yaml  # Strict lint config
├── pubspec.yaml
├── .fvmrc                 # FVM version pin ({"flutter": "stable"})
├── DESIGN.md
└── README.md
```

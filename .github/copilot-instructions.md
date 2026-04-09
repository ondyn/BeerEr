# GitHub Copilot Instructions for BeerEr

## Project Overview

**BeerEr** is a cross-platform mobile application (iOS & Android) for tracking beer consumption from a keg at a party. It calculates per-user statistics, estimates keg depletion, and helps settle costs among groups.

**Firebase project:** `ondyn-beerer`
**Repository:** `github.com/ondyn/BeerEr` (branch: `main`)

---

## Tech Stack

| Layer | Technology | Version / Notes |
|-------|-----------|-----------------|
| Frontend | Flutter (Dart) | SDK `^3.11.1`, pinned `stable` via FVM |
| State management | Riverpod | `flutter_riverpod ^3.1.0` + `riverpod_generator ^4.0.0` with `@riverpod` code-gen |
| Navigation | go_router | `^17.1.0` — declarative, `@riverpod`-based router with auth redirect |
| Data models | Freezed + json_serializable | `@freezed` classes; `field_rename: snake` in `build.yaml` |
| Backend / Database | Cloud Firestore | `cloud_firestore ^6.1.3` — real-time snapshots, offline persistence |
| Auth | Firebase Auth | `firebase_auth ^6.2.0` — email/password with email verification |
| Serverless | Firebase Cloud Functions v2 | TypeScript, Node 20, region `europe-west1` |
| Serverless | Firebase Cloud Functions v2 | TypeScript, Node 22, region `europe-west1` |
| Push notifications | FCM + flutter_local_notifications | Localized push payloads + local reminders; background handler for data-only fallback |
| Beer search | BeerWeb.cz API | Client-side `http` calls to `https://beerweb.cz/api/Search` (XML → parsed) |
| Charts | fl_chart | `^1.2.0` — BAC timeline charts |
| QR / sharing | qr_flutter, mobile_scanner, share_plus | Deep links: `beerer://join/{sessionId}` |
| Deep links | app_links | `^7.0.0` — handles `beerer://join/` URI scheme |
| Local storage | shared_preferences | Persists weight/age/gender locally (`LocalProfile` singleton) |
| Localisation | Flutter gen-l10n | ARB files: `en`, `cs`, `de`; `flutter.generate: true` in pubspec |
| Typography | Google Fonts | Nunito (headings), Inter (body), Roboto Mono (numbers/timers) |
| Linting | flutter_lints + custom_lint + riverpod_lint | Strict casts/inference/raw-types enabled |
| Testing | flutter_test, integration_test, mocktail, fake_cloud_firestore, firebase_auth_mocks | |

---

## Architecture

### Layered structure

```
main.dart  →  app.dart  →  router.dart  →  screens/
                                             ↕
                                          providers/  (Riverpod, @riverpod code-gen)
                                             ↕
                                         repositories/  (Firestore access)
                                             ↕
                                           models/  (Freezed data classes)
```

### Core principles

1. **Real-time first** — All UI data comes from Firestore snapshot streams via Riverpod `StreamProvider`s. Widgets use `ref.watch()` and handle `AsyncValue` states (`data`, `loading`, `error`).
2. **Firestore transactions for pours** — `addPour` and `undoPour` in `KegRepository` use `runTransaction` to atomically update `volume_remaining_ml` and the pour document. Never modify keg volume outside a transaction.
3. **Repository pattern** — Each Firestore collection has a dedicated repository class (`UserRepository`, `KegRepository`, `PourRepository`, `JointAccountRepository`). Repositories accept `FirebaseFirestore` via constructor injection for testability.
4. **Provider-based DI** — Repositories are exposed as `@riverpod` providers (e.g. `kegRepositoryProvider`). Integration tests override these with `FakeFirebaseFirestore` instances.
5. **Firebase offline persistence** — Rely entirely on Firestore's built-in offline queue. Do NOT build custom sync.
6. **Secrets stay server-side** — Any future backend credentials must live in Cloud Function secrets or another server-side configuration layer, never in Flutter code.
7. **Privacy by design** — BAC is calculated on-device only (`BacCalculator`), never stored in Firestore. Weight/age/gender are stored in the user's own doc; visibility is opt-in via preferences.
8. **Profile auto-creation** — After sign-in, the app ensures a Firestore profile exists. The `watchCurrentUser` provider auto-creates a minimal profile (nickname from Firebase Auth `displayName` → email local part → `'Beerer user'`) if the doc is missing.

---

## Firestore Data Model

### Collections

```
users/{userId}
  nickname: string
  email: string
  weight_kg: number
  age: number
  gender: "male" | "female"
  auth_provider: string
  preferences: map {
    allow_pour_for_me: bool
    show_stats: bool
    show_bac: bool
    notify_pour_for_me: bool
    notify_keg_done: bool
    notify_keg_nearly_empty: bool
    notify_bac_zero: bool
    notify_slowdown: bool
    fcm_token: string
    volume_unit: "litres" | "pints" | "us_fl_oz"
    currency: string
    decimal_separator: "dot" | "comma"
    language: "en" | "cs" | "de"
  }
  avatar_icon: number?           # Material icon codepoint

kegSessions/{sessionId}
  creator_id: string
  beer_name: string
  volume_total_ml: number
  volume_remaining_ml: number
  keg_price: number
  alcohol_percent: number
  predefined_volumes_ml: number[]
  start_time: timestamp?
  status: "created" | "active" | "paused" | "done"
  participant_ids: string[]      # array of user UIDs
  join_link: string?             # "beerer://join/{sessionId}"
  # BeerWeb.cz detail fields (all optional):
  brewery, malt, fermentation, beer_type, beer_group, beer_style, degree_plato: string?

kegSessions/{sessionId}/manualUsers/{manualUserId}
  session_id: string
  nickname: string               # guest participant (no app account)

pours/{pourId}
  session_id: string
  user_id: string                # whose beer this is (may be a manual user ID)
  poured_by_id: string           # who physically poured
  volume_ml: number
  timestamp: timestamp
  undone: boolean                # soft-delete; never hard-delete pours

jointAccounts/{accountId}
  session_id: string
  group_name: string
  creator_id: string
  member_user_ids: string[]
  avatar_icon: number?
```

### Firestore field naming

`build.yaml` configures `json_serializable` with `field_rename: snake`. All Dart model fields use `camelCase`; all Firestore document fields use `snake_case`. The `firestoreDoc()` helper in `utils/firestore_helpers.dart` injects the `id` field and converts `Timestamp` → ISO-8601 `String` before calling `fromJson`.

### Security rules

Defined in `firestore.rules`. Key patterns:
- **users**: any authenticated user can read any profile; only owner can write/delete own doc.
- **kegSessions**: any authenticated user can `get` (for join flow); `list` restricted to participants; `create` requires `creator_id == uid()`; `update` allowed for creator, participants, or a user adding themselves to `participant_ids`.
- **manualUsers** (subcollection): read by any authenticated user; create/update by session creator; delete by creator or participant (for merge).
- **pours**: read/create by session participants; `update` limited to flipping `undone` (by pourer or creator) or reassigning `user_id`/`poured_by_id` (guest merge); hard delete disabled.
- **jointAccounts**: read/create/update by session participants; delete by session creator only.

---

## Key Features & Behaviour

### Keg lifecycle (`KegStatus` enum)

| Transition | Trigger | Notes |
|-----------|---------|-------|
| → `created` | User submits create-keg form | Session doc + `join_link` written; creator added as participant |
| `created` → `active` | "Tap Keg" button | `start_time` = `FieldValue.serverTimestamp()` |
| `active` → `paused` | "Untap Keg" | No pours allowed while paused |
| `paused` → `active` | "Tap Keg" again | Resumes pouring |
| `active` → `done` | "Keg Done" (any participant) | Pours frozen; triggers `onKegStatusChanged` Cloud Function (FCM) |

### Pouring

- **"I Got Beer"** — logs pour for current user. Volume defaults to last used (from `PourRepository.getLastPour`), selectable from `predefinedVolumesMl` or free input.
- **"Pour for Someone"** — select participant from list → logs pour with `poured_by_id = currentUser`, `user_id = selectedUser`. FCM notification sent via `onPourCreated` Cloud Function.
- **Undo** — `KegRepository.undoPour()` in a transaction: sets `undone: true` and restores `volume_remaining_ml`. Snackbar uses manual `Timer` dismiss (not `SnackBar.duration`) to survive periodic widget rebuilds.
- **Bill review pours** — After keg is `done`, `addPourForReview`/`undoPourForReview` modify pours without touching `volume_remaining_ml`.

### Guest (manual) users

- Session creator can add guest participants via `KegRepository.addManualUser()`.
- Guests are stored in `kegSessions/{id}/manualUsers/{id}` subcollection.
- When a real user joins, they can merge with a guest via `KegRepository.mergeManualUser()` — reassigns all pours and deletes the guest doc in a batch write.
- Removing a guest (`removeManualUser`) soft-deletes their pours and restores keg volume in a batch.

### Statistics (`StatsCalculator` — pure Dart, client-side)

- Total / per-user volume poured
- Cost per user (by declared keg volume or by actual consumption ratio)
- Average drinking rate (ml/hour)
- Predicted time until keg empty
- Time since last pour
- Slowdown detection
- Beer count (pours / reference volume)
- Price per reference beer (0.5 l / 1 pint / 16 fl oz)
- Group (joint account) aggregate stats

### BAC estimation (`BacCalculator` — pure Dart, device-only)

- **Per-pour Widmark formula**: each pour's alcohol is metabolised independently from its timestamp. Correctly handles long pauses.
- Classic single-elapsed-time Widmark method also available.
- Helper methods: `pureAlcoholGrams`, `timeToZero`, `totalAlcoholGramsFromPours`, `estimateFromPours`.
- BAC values are **never stored in Firestore**.

### Sharing & joining

- Deep link format: `beerer://join/{sessionId}` — handled by `app_links` in `main.dart`.
- Share screen generates QR code (`qr_flutter`) and share intent (`share_plus`).
- Join screen: checks for existing profile, creates/updates user doc with nickname fallback, adds participant, optionally merges with manual user.

### Formatting preferences (`FormatPreferences`)

- Volume unit: litres, imperial pints, US fl oz
- Currency symbol (default `€`)
- Decimal separator: dot or comma
- Persisted in user's Firestore `preferences` map; provided via `formatPreferencesProvider`.

---

## Cloud Functions (TypeScript)

Located in `functions/src/index.ts`. Region: `europe-west1`. Node 22.

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onPourCreated` | `onDocumentWritten('pours/{pourId}')` | Sends localized FCM notification when someone pours for another user |
| `onKegStatusChanged` | `onDocumentUpdated('kegSessions/{sessionId}')` | Sends FCM notification to all participants when keg status → `done` |

### Cloud Functions development

```zsh
cd functions
npm install
npm run build        # tsc → lib/
npm run lint         # eslint
npm run serve        # build + firebase emulators
firebase deploy --only functions
```

## Development Environment

### Flutter via FVM

Flutter is managed with **FVM**. The project pins `stable` in `.fvmrc`.
Always invoke through the local SDK symlink:

```zsh
.fvm/flutter_sdk/bin/flutter <command>
.fvm/flutter_sdk/bin/dart <command>
```

### Code generation

Models use `freezed` + `json_serializable`; providers use `riverpod_generator`. After editing any `@freezed` class or `@riverpod` function:

```zsh
.fvm/flutter_sdk/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **gitignored** — never edit them by hand. They must exist locally for the project to compile.

### Running tests

```zsh
# All unit & widget tests
.fvm/flutter_sdk/bin/flutter test

# Single file
.fvm/flutter_sdk/bin/flutter test test/bac_calculator_test.dart --reporter expanded

# Integration tests (uses FakeFirebaseFirestore, no real backend needed)
.fvm/flutter_sdk/bin/flutter test integration_test/app_test.dart

# Screenshot integration tests (requires running emulators)
./scripts/take_screenshots.sh --drive
```

### Test infrastructure

- **Unit tests** (`test/`): `bac_calculator_test.dart` (Widmark formula), `time_formatter_test.dart` (duration/volume formatting), `pour_snackbar_test.dart` (snackbar dismiss under rebuilds), `widget_test.dart` (app smoke test).
- **Integration tests** (`integration_test/`): `keg_lifecycle_test.dart`, `join_session_test.dart`, `joint_account_test.dart`, `keg_done_flow_test.dart`, `guest_management_test.dart`. Use `FakeFirebaseFirestore` and `MockFirebaseAuth` via `helpers/test_app.dart`.
- **Screenshot tests** (`integration_test/screenshot_test.dart` + `test_driver/integration_test.dart`): Automated captures across phone/tablet emulators. Host-side driver handles permission dialogs via `adb`.
- **Mock data** (`scripts/populate_mock_data.js`): Populates Firestore with 8 users, 10 sessions, 200+ pours, joint accounts, and guests for screenshots.

### Linting & formatting

```zsh
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/dart format lib/ test/
```

`analysis_options.yaml` includes:
- `strict-casts`, `strict-inference`, `strict-raw-types` enabled
- `custom_lint` + `riverpod_lint` plugins
- `*.g.dart`, `*.freezed.dart`, `lib/l10n/**` excluded from analysis
- Key rules: `prefer_single_quotes`, `always_use_package_imports`, `avoid_dynamic_calls`, `avoid_print`, `prefer_const_constructors`, `prefer_final_locals`

### Firebase setup (first time)

```zsh
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart` is **gitignored** — each developer runs `flutterfire configure` locally. `google-services.json` and `GoogleService-Info.plist` are also gitignored.

---

## Coding Conventions

### Dart / Flutter

- **State management**: Riverpod with `@riverpod` code-gen. Providers are functional (not class-based Notifiers). Stream providers for Firestore watches; simple providers for derived state.
- **Widget types**: Use `ConsumerWidget` / `ConsumerStatefulWidget` when accessing `ref`. Plain `StatelessWidget` / `StatefulWidget` only when no providers needed.
- **Naming**: `camelCase` for Dart variables/functions; `PascalCase` for classes/widgets; `snake_case` for Firestore fields (automatic via `build.yaml` `field_rename: snake`).
- **Imports**: Always use package imports (`package:beerer/...`), enforced by `always_use_package_imports` lint rule. Each layer has a barrel file (`models.dart`, `providers.dart`, `repositories.dart`, `screens.dart`, `widgets.dart`, `utils.dart`, `theme.dart`).
- **Const constructors**: Use `const` wherever possible. Enforced by `prefer_const_constructors` lint rule.
- **Error handling**: Wrap Firestore operations in `try/catch` for `FirebaseException`. Show user-facing errors via `SnackBar` with localised messages from `AppLocalizations`.
- **Transactions**: Any write that modifies `volume_remaining_ml` **MUST** use `FirebaseFirestore.runTransaction`. The only exceptions are `addPourForReview` / `undoPourForReview` (keg is already done).

### Localisation

- All user-facing strings go in ARB files under `lib/l10n/` (`app_en.arb`, `app_cs.arb`, `app_de.arb`).
- Access via `AppLocalizations.of(context)!.keyName`.
- Never hardcode user-visible strings.
- `flutter.generate: true` in `pubspec.yaml` triggers `gen_l10n` code generation.

### Theme

- Dark theme only (`Brightness.dark`), Material 3 enabled.
- Colour palette in `BeerColors` abstract final class (amber/dark beer aesthetic).
- Typography: `BeerTheme.buildBeerTheme()` — Nunito for headings, Inter for body.
- Monospace numbers via `MonoStyle.number()` (Roboto Mono) for timers and volume displays.

### Notifications

- `NotificationService` singleton initialised in `main()`.
- FCM token saved to `users/{uid}/preferences/fcm_token` in Firestore.
- Background handler is a top-level `@pragma('vm:entry-point')` function.
- FCM notifications use localized notification payloads for background/terminated delivery; app still suppresses foreground display.
- Notification preferences (`notify_pour_for_me`, `notify_keg_done`, etc.) respected server-side.

### TypeScript (Cloud Functions)

- Strict mode, ES2020 target, CommonJS modules.
- ESLint with `typescript-eslint` recommended config.
- Firebase Functions v2 API (`onCall`, `onDocumentWritten`, `onDocumentUpdated`).
- Use `admin.firestore.FieldPath.documentId()` for batch user lookups; respect `whereIn` limit of 30.

---

## Firestore Patterns

### Adding a pour (transaction)

```dart
// KegRepository.addPour — ALWAYS use this for active kegs
Future<Pour> addPour(Pour pour) async {
  return await _db.runTransaction<Pour>((tx) async {
    final sessionSnap = await tx.get(_sessions.doc(pour.sessionId));
    final keg = KegSession.fromJson(firestoreDoc(sessionSnap.id, sessionSnap.data()!));
    if (keg.status != KegStatus.active) {
      throw StateError('Cannot pour while keg is ${keg.status.name}.');
    }
    final pourRef = _pours.doc();
    tx.set(pourRef, pour.toJson()..remove('id'));
    tx.update(_sessions.doc(pour.sessionId), {
      'volume_remaining_ml': keg.volumeRemainingMl - pour.volumeMl,
    });
    return pour.copyWith(id: pourRef.id);
  });
}
```

### Watching data with Riverpod

```dart
// Provider (generated via @riverpod)
@riverpod
Stream<KegSession?> watchSession(Ref ref, String sessionId) {
  final repo = ref.watch(kegRepositoryProvider);
  return repo.watchSession(sessionId);
}

// Widget
final sessionAsync = ref.watch(watchSessionProvider(sessionId));
return sessionAsync.when(
  data: (session) => /* build UI */,
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Timestamp handling

Firestore returns `Timestamp` objects. The `firestoreDoc()` helper converts them to ISO-8601 strings before `fromJson`:

```dart
Map<String, dynamic> firestoreDoc(String id, Map<String, dynamic> data) {
  return {
    'id': id,
    for (final e in data.entries)
      e.key: e.value is Timestamp
          ? (e.value as Timestamp).toDate().toIso8601String()
          : e.value,
  };
}
```

---

## External APIs

| API | Usage | Auth | Called from |
|-----|-------|------|-----------|
| BeerWeb.cz | Beer search during keg creation (`/api/Search?term=`) | None (public) | Flutter client (`http` package) |

---

## Things to Avoid

- **Never** store BAC values in Firestore.
- **Never** put API keys/secrets in Flutter source code.
- **Never** allow pours while keg `status` is `paused` or `done` (enforced in `addPour` transaction).
- **Never** skip Firestore transactions for operations modifying `volume_remaining_ml`.
- **Never** build custom offline sync — rely on Firestore's built-in offline persistence.
- **Never** edit generated files (`*.g.dart`, `*.freezed.dart`) by hand.
- **Never** hardcode user-facing strings — use ARB localisation. When adding new screens or modifying existing ones, always add all user-facing strings to **all three** ARB files (`app_en.arb`, `app_cs.arb`, `app_de.arb`) before submitting.
- **Never** commit `firebase_options.dart`, `google-services.json`, or `GoogleService-Info.plist`.
- **Never** use `print()` — the `avoid_print` lint rule is enabled. Use `debugPrint()` or `logger` for dev logging.
- **Never** use heredoc / here-document syntax (e.g. `cat > file << 'EOF'`) in terminal commands — it causes terminal disconnection with long content. Use a Python script or the `create_file` tool instead.
- Firebase Cloud Functions are allowed and recommended for server-side logic that needs secrets, trusted writes, or backend integrations. Keep API keys/secrets in Functions secrets and never embed them in Flutter source code.

---

## Repository Structure

```
BeerEr/
├── .fvmrc                        # {"flutter": "stable"}
├── .github/
│   └── copilot-instructions.md
├── pubspec.yaml                  # Dart ^3.11.1, all Flutter/Firebase deps
├── analysis_options.yaml         # Strict lints, custom_lint, riverpod_lint
├── build.yaml                    # json_serializable: field_rename: snake
├── firebase.json                 # Firestore rules, hosting, Flutter platform config
├── firestore.rules               # Security rules for all collections
├── android/                      # Android host app
├── ios/                          # iOS host app
├── functions/                    # Firebase Cloud Functions (TypeScript)
│   ├── src/index.ts              # onPourCreated, onKegStatusChanged, account lifecycle callables
│   ├── tsconfig.json             # strict, ES2020, CommonJS
│   ├── eslint.config.mjs
│   └── package.json              # Node 22, firebase-admin ^13, firebase-functions ^6
├── lib/
│   ├── main.dart                 # Entry: Firebase.initializeApp, NotificationService.init, ProviderScope, deep link handling
│   ├── app.dart                  # BeerErApp — MaterialApp.router with theme, locale, l10n delegates
│   ├── router.dart               # @riverpod GoRouter — auth redirect, all route definitions
│   ├── firebase_options.dart     # GITIGNORED — run `flutterfire configure`
│   ├── models/                   # @freezed data classes
│   │   ├── models.dart           #   barrel export
│   │   ├── user.dart             #   AppUser (nickname, email, weight, age, gender, preferences, avatarIcon)
│   │   ├── keg_session.dart      #   KegSession (KegStatus enum: created/active/paused/done)
│   │   ├── pour.dart             #   Pour (sessionId, userId, pouredById, volumeMl, timestamp, undone)
│   │   ├── joint_account.dart    #   JointAccount (sessionId, groupName, creatorId, memberUserIds)
│   │   └── manual_user.dart      #   ManualUser (guest participant in subcollection)
│   ├── repositories/             # Firestore access layer
│   │   ├── repositories.dart     #   barrel export
│   │   ├── user_repository.dart  #   CRUD + watchUser, watchUsers
│   │   ├── keg_repository.dart   #   Session CRUD, addPour/undoPour (transactions), manual users, merge
│   │   ├── pour_repository.dart  #   watchSessionPours, watchUserPours, getLastPour
│   │   └── joint_account_repository.dart  # CRUD + watchSessionAccounts, getAccountForUser
│   ├── providers/                # @riverpod providers
│   │   ├── providers.dart        #   barrel export
│   │   ├── auth_provider.dart    #   authStateProvider — FirebaseAuth.authStateChanges()
│   │   ├── user_providers.dart   #   watchCurrentUser (auto-creates profile if missing), watchUsers
│   │   ├── keg_session_providers.dart  # watchSession, watchAllSessions, watchDoneSessions, watchParticipantIds, watchManualUsers
│   │   ├── pour_providers.dart   #   watchSessionPours, watchUserPours
│   │   ├── joint_account_providers.dart  # watchSessionAccounts, userAccountInSession
│   │   ├── locale_provider.dart  #   appLocaleProvider — from user preferences
│   │   └── format_preferences_provider.dart  # formatPreferencesProvider — volume unit, currency, decimal
│   ├── screens/                  # One sub-folder per feature
│   │   ├── screens.dart          #   barrel export
│   │   ├── auth/                 #   welcome, sign_in, register, forgot_password
│   │   ├── home/                 #   home_screen (session list + drawer)
│   │   ├── keg/                  #   create_keg, keg_detail, keg_info, join_session, share_session,
│   │   │                         #   bill_review, joint_account_sheet, participant_detail, qr_scanner, settle_up
│   │   ├── profile/              #   profile_screen (view + edit sheet)
│   │   ├── settings/             #   settings_screen (notifications, format prefs, language, account deletion)
│   │   ├── history/              #   history_screen (past sessions)
│   │   ├── about/                #   about_screen, privacy_policy_screen
│   │   └── splash/               #   splash_screen
│   ├── services/
│   │   └── notification_service.dart  # FCM + local notifications singleton
│   ├── utils/                    # Pure Dart helpers (no Flutter/Firebase imports where possible)
│   │   ├── utils.dart            #   barrel export
│   │   ├── bac_calculator.dart   #   Widmark BAC: calculate, calculateFromPours, pureAlcoholGrams, timeToZero
│   │   ├── stats_calculator.dart #   Session stats: volumes, costs, rates, slowdown, beer count
│   │   ├── time_formatter.dart   #   Duration/volume/BAC formatting with FormatPreferences support
│   │   ├── format_preferences.dart  # VolumeUnit, DecimalSeparator, FormatPreferences
│   │   ├── firestore_helpers.dart   # firestoreDoc() — injects id, converts Timestamp → String
│   │   └── local_profile.dart    #   SharedPreferences persistence for weight/age/gender
│   ├── widgets/                  # Shared reusable widgets
│   │   ├── widgets.dart          #   barrel export
│   │   ├── keg_fill_bar.dart     #   Visual keg level indicator
│   │   ├── pour_button.dart      #   "I Got Beer" / pour actions
│   │   ├── volume_picker_sheet.dart  # Bottom sheet for pour volume selection
│   │   ├── participant_chip.dart #   User chip with avatar
│   │   ├── avatar_icon.dart      #   Material icon avatar circle
│   │   ├── avatar_picker.dart    #   Icon picker dialog
│   │   ├── session_card.dart     #   Keg session list card
│   │   ├── stat_tile.dart        #   Statistics display tile
│   │   ├── bac_banner.dart       #   BAC estimate banner with "Drink Responsibly"
│   │   └── email_verification_banner.dart
│   ├── theme/
│   │   ├── theme.dart            #   barrel export
│   │   ├── beer_theme.dart       #   BeerColors palette + buildBeerTheme() (dark, Material 3)
│   │   └── mono_style.dart       #   Roboto Mono for numbers/timers
│   └── l10n/                     # ARB localisation files
│       ├── app_en.arb            #   English (template)
│       ├── app_cs.arb            #   Czech
│       ├── app_de.arb            #   German
│       └── app_localizations*.dart  # Generated
├── test/                         # Unit & widget tests
│   ├── bac_calculator_test.dart  #   BAC formula correctness
│   ├── time_formatter_test.dart  #   Duration/volume formatting
│   ├── pour_snackbar_test.dart   #   Snackbar dismiss under rebuilds
│   └── widget_test.dart          #   App smoke test
├── integration_test/             # Integration tests (FakeFirebaseFirestore)
│   ├── app_test.dart             #   Master runner
│   ├── keg_lifecycle_test.dart   #   create → tap → pour → undo
│   ├── join_session_test.dart    #   Join, pour-for, profile creation
│   ├── joint_account_test.dart   #   Group create/join/leave
│   ├── keg_done_flow_test.dart   #   Keg done, bill review
│   ├── guest_management_test.dart  # Manual users, merge
│   ├── screenshot_test.dart      #   Automated screenshot capture
│   └── helpers/test_app.dart     #   TestApp factory with fakes + provider overrides
├── test_driver/
│   └── integration_test.dart     #   Host-side driver for screenshot tests (adb permission handling)
├── scripts/
│   ├── populate_mock_data.js     #   Populates Firestore with screenshot test data
│   ├── create_test_user.js       #   Creates a single Firebase Auth test user
│   ├── take_screenshots.sh       #   Automated screenshot capture across emulators
│   ├── generate_assets.py        #   Asset generation
│   └── SCREENSHOTS.md            #   Screenshot workflow documentation
├── web/                          # Firebase Hosting: deep link redirect, privacy policy, delete account
├── assets/images/                # App image assets
├── DESIGN.md
├── README.md
└── TODO.md
```

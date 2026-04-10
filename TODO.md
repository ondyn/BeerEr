# TODO

## now

- [x] sign-in/create account screen - add language/localization switch. ✅ Added `preAuthLocaleProvider` (Riverpod notifier) + SharedPreferences persistence via `loadLocalLanguage()`/`saveLocalLanguage()`. Language picker on welcome screen (🇬🇧/🇨🇿/🇩🇪 flags). Settings language switch also saves locally. Firestore preference takes precedence after sign-in.
- [ ] kiosk mode - rights as a keg session owner, but not showing user specific menu - nickname, profile, not in participants list. This mode will be turned on eg. on tablet which will stay next to keg to be available to record taps for every user. Think how to activate this kiosk mode. Probably during joining the session. **⚠️ NEEDS CLARIFICATION — see notes below.**
- [x] sign-in via Google provider ✅ Full `google_sign_in` implementation on both welcome and sign-in screens. Firestore profile auto-created with `auth_provider: 'google'`. ⚠️ Requires manual Firebase Console config: enable Google sign-in provider, add SHA-1 (Android), add reversed client ID to iOS URL schemes.
- [x] Firebase Cloud Functions are allowed ✅ Cloud Functions are now explicitly allowed for server-side logic (notifications, secure integrations, webhooks, callable backends).
- [x] sign in automatically ✅ Password field `onFieldSubmitted` triggers `_submit()` on sign-in screen.
- [x] remember selected volume per participant/user ✅ Added `lastVolumesMl` map to KegSession model. `addPour` transaction writes `last_volumes_ml.{userId}` atomically. Pour sheets pre-select last used volume for the target participant.
- [x] avoid using heredoc ✅ Added "Never use heredoc" rule to copilot-instructions.md.
- [x] keep in mind localization ✅ Added "Never submit without all 3 ARB files" rule to copilot-instructions.md.
- [x] keg chart (volume x time, rate x time) ✅ Created `KegVolumeChart` (step-down line chart of volume remaining) and `PourRateChart` (sliding 30-min window pour rate) in `lib/widgets/keg_chart.dart`. Displayed on keg info screen when session has started and pours exist.
- [x] gmail login ✅ Same as "sign-in via Google provider" above. Manual steps: (1) Firebase Console → Authentication → Sign-in methods → enable Google, (2) Android: `keytool -list -v -keystore ~/.android/debug.keystore` and add SHA-1 to Firebase, (3) iOS: download new GoogleService-Info.plist, add reversed client ID to URL schemes in Xcode.
- [ ] BAC and driving estimation - total across all active sessions (reverted — single-session BAC only for now)
- [ ] updated participant consumption visualization (reverted — single-session beer count only)
- [x] small resolution ✅ (1) `_AccountsSection` Row → Wrap for button overflow. (2) Bottom bar FAB labels wrapped in FittedBox. (3) `_buildCreatedBody` and `_buildPausedBody` changed from Center to SingleChildScrollView for scrollability.
- [x] currency selector during keg creation ✅ Added `currency` field (default '€') to KegSession model. Currency dropdown in step 2 of create keg screen next to price. Removed currency selector from settings. `FormatPreferences.withCurrency()` lets keg-detail UI use the session currency.
- [x] fix joint account deletion ✅ Updated `firestore.rules` to allow both session creator AND joint account creator to delete. Added try/catch with SnackBar error handling in `_leaveOrDelete()` in `joint_account_sheet.dart`.
- [x] add guest users to joint accounts ✅ Modified `_MemberPickerSheet` in `joint_account_sheet.dart` to watch `watchManualUsersProvider(sessionId)` and include guest/manual users in the member picker.
- [x] chart x-axis improvements ✅ Replaced relative minutes (`_formatMinutes`) with absolute clock times (`_formatAsClockTime`) showing "HH:mm" format. Added `_hourInterval()` for round-hour intervals (15/30/60/120/180 min). Both charts have `clipData: const FlClipData.all()` and overlap-prevention logic in `getTitlesWidget` callbacks.
- [x] fullscreen charts ✅ Created `FullscreenChartScreen` in `lib/screens/keg/fullscreen_chart_screen.dart` — landscape orientation, immersive sticky mode, back button overlay. Charts in `keg_info_screen.dart` wrapped with `GestureDetector` to navigate to fullscreen on tap.
- [x] Google sign-in profile form ✅ Created `CompleteProfileScreen` in `lib/screens/auth/complete_profile_screen.dart` with nickname, weight, age, gender fields + skip button. Added `/auth/complete-profile` route to `router.dart`. Both `welcome_screen.dart` and `sign_in_screen.dart` redirect to this screen when Google sign-in profile is new.
- [x] brewery & beer DB ✅ Implemented full pipeline:
  - **Analysis**: BeerWeb (1,482 breweries, 17,055 beers, 9 fields/beer) and AtlasPiv (615 breweries, 4,688 beers, 4 fields/beer) analyzed.
  - **Schema**: `BEER_DB_SCHEMA.md` with Firestore collections `breweries/{id}` and `beers/{id}`, denormalized `brewery_name`, `name_lower` for prefix search.
  - **Firestore rules**: Added read-only rules for `breweries` and `beers` (admin SDK write only).
  - **Import script**: `scripts/import_beer_db.py` — idempotent Python script using `firebase-admin` and `unidecode`. Imports BeerWeb first (richer data), then AtlasPiv with fuzzy name matching. Supports `--dry-run`.
  - **Editor app**: Standalone Flutter project at `beer_db_editor/` with Firebase Auth, tabbed beer/brewery search, and full CRUD forms for editing the database.
- [x] switch beer search to our DB ✅ Replaced BeerWeb.cz web scrape API in `create_keg_screen.dart` with Firestore queries against our `beers` collection. Search triggers after 3 chars with 400ms debounce. Results show "BeerName (BreweryName)" format. All beer details (alcohol, brewery, malt, fermentation, type, group, style, EPM) populated directly from Firestore docs — no external HTTP calls needed. Updated l10n labels in all 3 ARB files.
- [x] rename searchBeerOnBeerWeb ✅ Renamed ARB key `searchBeerOnBeerWeb` → `searchBeer` in all 3 ARB files (en, cs, de). Renamed Dart variables: `_beerWebSearchController` → `_beerSearchController`, `_onBeerWebSearchChanged` → `_onBeerSearchChanged` throughout `create_keg_screen.dart`.
- [x] optimize beer search algorithm ✅ Rewrote `_searchBeers` in `create_keg_screen.dart`: immediate search at 3 chars (no debounce), 600ms debounce for 4+ chars. Added `_removeDiacritics()` for Czech/German character support. Multi-word full-text search: splits query into words, uses longest word for Firestore prefix query (limit 50), filters client-side ensuring ALL words match in combined `name_lower + brewery_name`. Handles queries like "zealand ale" → "Kamenický New Zealand Pale Ale 12°".
- [x] make pour button taller ✅ Increased vertical padding from 6 to 14 in `_UnifiedParticipantRow`'s `FilledButton.styleFrom()` in `keg_detail_screen.dart`.
- [x] privacy settings ✅ Added `show_personal_info` preference (3rd privacy toggle) to profile screen. Renamed hardcoded "Statistics" section header to localized "Personal info" (`personalInfo` ARB key, all 3 locales). Added `showPersonalInfoToOthers` ARB strings (en, cs, de). Enforced all 3 privacy flags (`show_stats`, `show_bac`, `show_personal_info`) in `participant_detail_screen.dart` — `isMe` overrides all to always show own data. Created `test/privacy_settings_test.dart` with 7 widget tests covering visibility/hiding of stats card, BAC section, and personal info for own vs. other users.
- [x] live stats on user detail ✅ Converted `ParticipantDetailScreen` from `StatefulWidget` to `ConsumerStatefulWidget`. Now watches `watchSessionPoursProvider(sessionId)` via Riverpod — stats and charts update in real-time when new pours arrive. Falls back to initial `widget.pours` snapshot before provider emits.
- [x] align & fix all charts ✅ Updated participant detail charts (`_VolumeChart`, `_BacChart`) to match keg chart style: replaced `_formatRelativeMinutes` (e.g. "-278h49m") with `_formatAsClockTime` (absolute "HH:mm" format). Added `_hourInterval()` for round-hour tick alignment, `clipData: FlClipData.all()`, and overlap-prevention logic in label callbacks. Volume chart now uses `TimeFormatter.formatVolumeMl()` with preference-aware formatting. Dot rendering suppressed when > 50 pours.
- [x] fix x-axis label overlap ✅ Extended `_hourInterval()` in both `participant_detail_screen.dart` and `keg_chart.dart` to handle sessions longer than 12 hours. New thresholds: 240 min (≤24h), 480 min (≤48h), 720 min (>48h) prevent label crowding on long sessions.
- [x] fullscreen tap for participant charts ✅ Wrapped both `_VolumeChart` and `_BacChart` in `participant_detail_screen.dart` with `GestureDetector` → `FullscreenChartScreen`. Extended `FullscreenChartScreen` with optional `chartChild` parameter and `chartType` values `'participant_volume'` / `'participant_bac'` for participant-level chart titles.
- [x] extend avatar icons ✅ Expanded `kAvatarIcons` in `avatar_icon.dart` from 40 to 90 icons. Added categories: faces/people (sentiment, mood, psychology, elderly, child_care), animals (flutter_dash, pest_control), nature (forest, local_florist, terrain, water), symbols (diamond, shield, flare, auto_awesome), sports (downhill_skiing, snowboarding, hiking, kayaking, kitesurfing, paragliding, scuba_diving, sports_hockey, sports_martial_arts), travel (sailing, flight, two_wheeler, directions_car), tech (camera_alt, code, terminal, build, engineering), food (local_pizza, icecream, cake, restaurant), and misc (military_tech, emoji_objects, theater_comedy, catching_pokemon, visibility, fingerprint).
- [x] fix beer search for multi-word queries ✅ Replaced Firestore prefix query (`name_lower >= word`) with `array-contains` on new `search_terms` field. Each beer document now stores word-prefix tokens (length 2+) from the normalised name + brewery name — e.g. "zealand" produces ["ze", "zea", …, "zealand"]. This enables autocomplete-style partial-word matching: "new zea" → uses `array-contains: "zea"` then filters client-side for all words. Updated `import_beer_db.py` (`make_search_terms` function), created `migrate_search_terms.py` migration script, ran migration on 21,719 beer documents, and updated `BEER_DB_SCHEMA.md`.
- [x] Notifications - keg nearly empty, keg session done, BAC is 0, someone else pour for you. ✅ Implemented, localized, and hardened.

### Notification rules (implemented)

- Pour for you (`pour_for_you`): Sent when a new non-undone pour is created and `user_id != poured_by_id`.
- Pour for you filters: recipient must have `preferences.notify_pour_for_me != false` and a valid `preferences.fcm_token`.
- Keg nearly empty (`keg_nearly_empty`): Sent when session volume crosses from `> 10%` to `<= 10%` while status stays `active`.
- Keg nearly empty filters: participant must have `preferences.notify_keg_nearly_empty != false` and a valid FCM token.
- Keg done (`keg_done`): Sent only on status transition to `done`.
- Keg done filters: participant must have `preferences.notify_keg_done != false` and a valid FCM token.
- BAC zero (local scheduled notification): Scheduled only when user has at least one non-undone pour, BAC is `> 0`, and `preferences.notify_bac_zero != false`.
- BAC zero corner-case guard: if BAC is `0` (including start of session or no pours), existing BAC-zero notification is canceled and nothing is scheduled.
- Slowdown reminder (local notification): shown once per slowdown window, reset when slowdown condition is no longer true.
- Language selection: notification text uses the user language in `preferences.language` (`en`, `cs`, `de`; fallback `en`).
- Delivery while app is not running:
  - Cloud Functions send push notifications with `notification` payload (system-displayed in background/terminated state).
  - BAC-zero local reminder is persisted using scheduled local notifications (fires even if app is closed).

### Cloud Functions deployment (step-by-step)

1. Open terminal in project root and go to functions directory: `cd functions`
2. Install dependencies: `npm install`
3. Build TypeScript: `npm run build`
4. (Recommended) Run lint: `npm run lint`
5. Ensure Firebase CLI is logged in: `firebase login`
6. Select/check project: `firebase use ondyn-beerer`
7. Deploy functions: `firebase deploy --only functions`
8. Verify deploy output for function names and region `europe-west1`.
9. (Optional) Tail logs after deploy: `firebase functions:log --only onPourCreated,onKegStatusChanged`
10. For local verification before deploy, run emulator: `npm run serve`
- [ ] Optimize for small resolutions devices: 2340 × 1080 Samsung A16, 1640 x 720 Redmi A5
- [x] Pour button in participant list shows the volume with two decimal places, but this is not nice, if last digits are zeros. Show it without decimals if it's whole number, with one decimal if it's .5, and with two decimals only if needed (e.g. 0.75). This applies to pour buttons in participant list. ✅ Added `TimeFormatter.formatCompactLitres()` and switched participant-list pour buttons to use it, preserving the user's decimal separator while trimming unnecessary trailing zeros.

### Kiosk mode — needs clarification

The kiosk mode task is not clear enough to implement safely. Questions:
1. **Activation**: Should kiosk mode be a toggle during "Join Session" flow, or a separate entry path (e.g. special URL/QR)?
2. **Auth**: Does the kiosk tablet need its own user account, or should it work unauthenticated?
3. **UI**: Should the kiosk show the full participant list (with pour buttons for each), or a simplified "tap to pour" grid?
4. **Restrictions**: Which menu items exactly should be hidden? (e.g. profile, settings, drawer, session history)
5. **Session lock**: Should kiosk mode be locked to one session, preventing navigation to other screens?

## future

- [x] brewery&beers DB, use for autocomplete ✅ (see "brewery & beer DB" and "switch beer search to our DB" above)
- [ ] cleanup: DB will be cleared, rething about all names, database attributes, screen names, variables if it makes sense. Rename accordingly. Analyze code, if something is repeating put it into shared code. Make sure all graphics types useses same dimensions, colors and theme everywhere.

**Ideas to explore:**
- Keg session chat / reactions.
- Leaderboard (most beers, fastest drinker, etc.).
- Beer rating integration (rate the beer after the session).
- Photo gallery per session.
- Multiple kegs per session (different beers at the same party).
- Drinking games / challenges integration.
- Session templates (re-use settings from a previous session).
- Export session summary as PDF/image.
- Apple Watch / Wear OS companion for quick pour logging.
- Widget for home screen showing active session stats.
- Dark/light theme toggle.
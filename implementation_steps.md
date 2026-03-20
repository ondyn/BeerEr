# BeerEr — Implementation Steps

> Generated from `TODO.md` analysis. Each step is designed to be implemented and tested independently before moving to the next.

---

## Pre-implementation notes / Assumptions

- The codebase already has: auth flow, keg CRUD, pour logging with undo, basic keg detail screen (active/paused/done), profile, settings, about, history, share, join session, settle up export, joint accounts repo (basic CRUD), BAC calculation, stats calculation.
- `KegStatus` currently has 3 values: `active`, `paused`, `done`. TODO asks for a 4th: `created` (before first tap).
- Settings currently has "Allow pour for me", keg nearly empty, keg done toggles, volume units dropdown, and account section — but language, currency, decimal separator are missing.
- The "Participants" section on the keg detail screen is a horizontal chip row; TODO wants a vertical list with richer info.
- Joint accounts exist in data model/repo but have no UI for creation, joining, or management on the keg session screen.
- BAC is shown via `BacBanner` but only current value — no time-to-zero estimation or real-time 1-second updates.
- Notifications (FCM) are a dependency but no notification logic is implemented yet.
- All user-facing strings should use `AppLocalizations` (ARB files); many current strings are hardcoded.

---

## Step 1 — Extend keg status: add `created` state

**Goal:** Add a `created` status to `KegStatus` so a newly created keg session starts as `created` (not yet tapped), becomes `active` on "Tap Keg", can go to `paused`, and finally `done`.

**Changes:**
- `lib/models/keg_session.dart` — add `created` to `KegStatus` enum.
- `lib/repositories/keg_repository.dart` — `createSession()` should set `status: 'created'` and NOT set `start_time`. `tapKeg()` already transitions to active.
- `lib/screens/keg/keg_detail_screen.dart` — add a new body builder for `KegStatus.created` (show "Session Ready" card + "Tap Keg!" button, as in design §7.9.1). Update the `switch` to include `created`.
- `lib/screens/home/home_screen.dart` — treat `created` sessions the same as active in the list filter.
- `lib/screens/keg/create_keg_screen.dart` — ensure new sessions are created with `status: created`.
- Run `build_runner` to regenerate freezed/json code.

**Test:** Create a new keg → verify it shows "Session Ready" with "Tap Keg!" button → tap keg → verify status changes to active.

---

## Step 2 — Consolidate menu → Profile with profile button

**Goal:** Remove the profile entry from the navigation drawer (or simplify the drawer) and ensure the profile avatar button (top-right on home screen) is the primary way to reach Profile.

**Changes:**
- `lib/screens/home/home_screen.dart` — Keep profile icon button in AppBar actions (already exists). Optionally remove or grey out the `Profile` entry in `_BeerErDrawer`, or keep it as secondary access.
- Review: the profile icon in the app bar already navigates to `/profile`. Confirm it works after drawer simplification.

**Test:** Tap profile icon → lands on profile screen. Drawer still works for other items.

---

## Step 3 — Move past sessions to separate screen (from home)

**Goal:** Home screen shows only active/created/paused sessions. "Past sessions" are accessed from a separate screen via the drawer ("My Sessions" / "Past Sessions").

**Changes:**
- `lib/screens/home/home_screen.dart` — Remove the "Past sessions" section from the home list. Only show active/created/paused sessions.
- `lib/screens/history/history_screen.dart` — Already exists. Ensure it shows done sessions properly.
- `lib/screens/home/home_screen.dart` (`_BeerErDrawer`) — "My Sessions" entry already navigates to `/sessions/history`. Rename to "Past Sessions" if preferred.

**Test:** Home screen shows only active sessions. Drawer → Past Sessions shows done sessions.

---

## Step 4 — Merge Keg Level + My Stats into one Card

**Goal:** On the keg session screen (active status), combine the "KEG LEVEL" card and "My stats" card into a single card.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — `_buildActiveBody()`: merge the keg fill bar and my stats widgets into a single `Card`.

**Test:** Open an active keg → verify keg level and stats appear in one card, layout looks good.

---

## Step 5 — Participants as a vertical list with richer info

**Goal:** Replace the horizontal chip row with a vertical list of participant rows showing: name, beer count, last pour time, estimated BAC, and a "Pour for" button.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — Rewrite `_ParticipantsSection` to render a `ListView` / `Column` of participant rows instead of horizontal chips.
- Each row needs: user name, beer count (number of pours), time of last pour, estimated BAC (if user shares it), and a "Pour for" icon/button.
- This requires watching each user's pours and profile within the participants section.
- May need a new widget `participant_row.dart` in `lib/widgets/`.

**Test:** Open active keg with multiple participants → verify each participant shows as a row with correct stats and "Pour for" button works.

---

## Step 6 — Real-time 1-second timer updates for "My stats"

**Goal:** The "Current beer" and "Since last" timers in My Stats should update every second, not just on rebuild.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — Convert the stats section (or the entire active body) into a `StatefulWidget` / `ConsumerStatefulWidget` with a `Timer.periodic(Duration(seconds: 1), ...)` that calls `setState` to refresh the timers.
- Alternatively, create a `LiveTimerWidget` that wraps a duration and counts up every second.

**Test:** Open active keg → watch "Current beer" and "Since last" counters tick up every second.

---

## Step 7 — Settings: language, currency, decimal separator, units

**Goal:** Add settings for: language (locale), currency symbol, decimal dot/comma, volume units (litres/pints/US ounces).

**Changes:**
- `lib/models/user.dart` — Add fields to `preferences` map or create a dedicated `UserPreferences` model: `locale`, `currency`, `decimalSeparator`, `volumeUnit`.
- `lib/screens/settings/settings_screen.dart` — Add UI controls: language dropdown, currency text field or dropdown, decimal format toggle, volume unit dropdown (Litres / Pints / US fl. oz).
- `lib/utils/time_formatter.dart` — Extend `formatVolumeMl()` and `formatCurrency()` to respect the selected unit/currency/decimal setting.
- Create a provider that exposes current user preferences for formatting.
- Persist selections to Firestore user preferences.

**Test:** Change currency to `$` → verify all cost displays use `$`. Change volume to pints → verify volume displays in pints.

---

## Step 8 — Show per-beer price (0.5l reference price)

**Goal:** Show a "price per 0.5l beer" (or equivalent for imperial) so users can see the unit beer price.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — In the keg level/stats card, add a `StatTile` showing price per 0.5l (or per pint depending on unit setting). Calculate: `kegPrice / volumeTotalMl * 500` for 0.5l.
- `lib/utils/stats_calculator.dart` — Add `pricePerReferenceBeer()` utility.

**Test:** Create a keg with known price → verify the displayed per-beer price is correct.

---

## Step 9 — Unified snackbar/toast behaviour for pours

**Goal:** Both "I got beer" and "Pour for someone" should use the same snackbar style with undo support and auto-dismiss.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — In `_showPourSheet()` the SnackBar already has undo. In `_showPourForSheet()` it doesn't have undo — add undo action (using the returned `Pour` with id, same pattern).
- Ensure both use the same `SnackBar` duration (e.g. 5 seconds) and same styling.

**Test:** Pour for yourself → snackbar with undo, auto-dismisses after 5s. Pour for someone → same snackbar with undo.

---

## Step 10 — Joint Accounts / Groups UI

**Goal:** Implement the full joint accounts feature: create group, join existing group, leave group, view grouped participants, calculate group consumption. Rules: one group per user, one group creation per user, groups are per session, user can be solo.

**Changes:**
- `lib/models/joint_account.dart` — Already has the model. Add `creatorId` field so we know who created the group.
- `lib/repositories/joint_account_repository.dart` — Add methods: `getAccountForUser()`, `deleteAccount()`, validation that user is in only one group.
- `lib/providers/joint_account_providers.dart` — Add provider for current user's account in a session.
- Create `lib/screens/keg/joint_account_sheet.dart` — Bottom sheet for creating/joining/managing a joint account (as in design §7.14).
- `lib/screens/keg/keg_detail_screen.dart` — Add a "Participants / Accounts" tab or section. In participants list, show group badges. Add "+ Join / Create Account" action.
- `lib/utils/stats_calculator.dart` — `groupCost()` already exists. Add group consumption aggregation.

**Test:** Create a group → add members → verify group shows in participants → verify group cost is sum of member costs.

---

## Step 11 — BAC: real-time countdown, time-to-zero, show in participants list

**Goal:** 
1. BAC updates every second (not just on new pour).
2. Show estimated time when BAC will reach 0 ("ready to drive").
3. Show other participants' BAC in the participants list (if they opted in).

**Changes:**
- `lib/utils/bac_calculator.dart` — Add `timeToZero()` method: given current BAC, calculate minutes until BAC reaches 0 using metabolic rate (0.015 g/dL per hour).
- `lib/screens/keg/keg_detail_screen.dart` — Make `_BacSection` a `StatefulWidget` with a 1-second timer to recalculate BAC.
- In the participants list (Step 5), for each participant who has `show_bac: true` in preferences, compute and display their BAC (requires their weight/age/gender from user profile + their pours).
- `lib/widgets/bac_banner.dart` — Add time-to-zero display.

**Test:** Log a pour → BAC appears and ticks down over time → time-to-zero shows. Other participant with BAC visible shows their BAC in the list.

---

## Step 12 — Keg Done screen: final calculation & Revolut tip

**Goal:** When keg is done:
1. Calculate final bill based on actual total consumption (sum of all users' pours), not initial keg volume.
2. Show each user's consumption ratio and their cost.
3. Show a tip/donate card with Revolut link `revolut.me/hnyko`.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — `_buildDoneBody()`: 
  - Calculate total consumed = sum of all pours (can differ from initial keg volume).
  - For each participant, show their volume, ratio, and cost based on consumption ratio.
  - Add a "Tip the developer" card with Revolut link and `url_launcher`.
- `lib/utils/stats_calculator.dart` — Add `userCostByConsumption()` that uses actual total poured as denominator instead of `volumeTotalMl`.

**Test:** Mark keg as done → verify final stats show correct per-user costs based on actual consumption → verify Revolut link opens.

---

## Step 13 — Review Bill Split screen (creator)

**Goal:** Keg owner can review the full bill: all participants' consumption, group consumption, and add/remove beers from anyone. Prices and total consumed volume recalculate.

**Changes:**
- Create `lib/screens/keg/bill_review_screen.dart` — Shows all participants (solo + grouped), each with their pours list. Creator can add/remove pours for anyone (via the existing pour/undo mechanisms).
- `lib/router.dart` — Add route `/keg/:sessionId/review`.
- `lib/screens/keg/keg_detail_screen.dart` — In done body, add a "Review Bill" button for the creator before the Settle Up export.

**Test:** As creator of a done keg → open Review Bill → see all participants and their consumption → add a beer to someone → verify totals recalculate.

---

## Step 14 — Disable Settle Up export (comment out)

**Goal:** Comment out / hide the Settle Up export button and screen. Keep the code but make it inaccessible.

**Changes:**
- `lib/screens/keg/keg_detail_screen.dart` — Comment out or wrap the "Export to Settle Up" button in a `false` condition.
- `lib/router.dart` — Optionally comment out the `/keg/:sessionId/settle` route.

**Test:** Verify the Settle Up button no longer appears on the done keg screen.

---

## Step 15 — Notifications (FCM)

**Goal:** Implement push notifications for:
1. Someone pours on your behalf.
2. Keg is done.
3. Your estimated BAC reaches 0 (ready to drive).
4. All notifications can be enabled/disabled in user settings.

**Changes:**
- `functions/src/index.ts` — Add Cloud Functions: `onPourCreated` (notify target user when `poured_by_id != user_id`), `onKegDone` (notify all participants).
- `lib/providers/` — Create `notification_provider.dart` for FCM token management and topic subscriptions.
- `lib/screens/settings/settings_screen.dart` — Connect notification toggles to Firestore preferences and FCM topic subscription.
- `lib/main.dart` — Initialize FCM, request permissions, handle foreground/background messages.
- BAC-zero notification: schedule a local notification from the client when BAC time-to-zero is calculated.

**Test:** Pour for someone → they receive a notification. Mark keg as done → all participants get notified.

---

## Step 16 — Slowdown notification

**Goal:** If a user slows down in consumption (based on average consumption speed), send a notification. Configurable in settings.

**Changes:**
- Determine logic: compare last-N-pours rate to overall average rate. If ratio drops below threshold → trigger.
- This is best done client-side with a local scheduled check.
- `lib/screens/settings/settings_screen.dart` — Add toggle for "Slowdown reminder".
- Implement the detection logic and local notification scheduling.

**Test:** Simulate slowed consumption → verify notification fires (if enabled).

---

## Step 17 — Manual users (offline/guest participants)

**Goal:** Keg session owner can create "manual" users (for people who can't join via the app). When a real user joins, they can optionally merge with a manual user.

**Changes:**
- `lib/models/` — Add a `manual_user` concept (could be a flag on `AppUser` or a separate lightweight model stored in the session document).
- `lib/repositories/keg_repository.dart` — Add methods to create/manage manual users within a session.
- `lib/screens/keg/keg_detail_screen.dart` — For the creator, add an "Add participant manually" action.
- `lib/screens/keg/join_session_screen.dart` — On join, show list of manual users and offer to merge.

**Test:** Creator adds "Guest 1" manually → Guest 1 appears in participants → real user joins and merges with Guest 1 → pours are consolidated.

---

## Step 18 — About screen enhancements

**Goal:** 
1. Change icon to app logo (custom asset, not Material icon).
2. Add Revolut donation note with link `revolut.me/hnyko`.
3. Implement Privacy Policy (link or in-app).
4. Update `showLicensePage` with correct app info.
5. Add link to `https://responsibledrinking.eu/`.
6. Add card: "If you are using this app often, consider visiting: https://www.addictioncenter.com/addiction/addiction-in-the-eu/".

**Changes:**
- `lib/screens/about/about_screen.dart` — Replace `Icons.sports_bar` with custom logo asset. Add all the links/cards described above using `url_launcher`. Update `showLicensePage` parameters.
- `assets/images/` — Add app logo asset if not already present.

**Test:** Open About screen → verify logo, Revolut link, responsible drinking link, addiction center card, privacy policy link, and licenses page all work.

---

## Step 19 — Code cleanup: deduplicate utility functions

**Goal:** Audit all utility/helper functions (stats calculation, formatting, BAC) and ensure each is defined only once. Remove duplicated logic.

**Changes:**
- Grep for duplicated calculation patterns across screens and utils.
- Consolidate into `stats_calculator.dart`, `bac_calculator.dart`, `time_formatter.dart`.
- Ensure all screens import from `utils/` rather than computing inline.

**Test:** Run full test suite. Run `flutter analyze` — no new warnings.

---

## Step 20 — Localise all hardcoded strings

**Goal:** Move all remaining hardcoded user-facing strings to ARB files and use `AppLocalizations`.

**Changes:**
- Audit all `lib/screens/` and `lib/widgets/` for hardcoded strings.
- Add entries to `lib/l10n/app_en.arb`.
- Replace hardcoded strings with `AppLocalizations.of(context)!.keyName`.
- Run `flutter gen-l10n` (or build_runner) to regenerate.

**Test:** App runs without missing-key errors. All strings display correctly.

---

## Step 21 — Integration tests

**Goal:** Create integration tests using the `integration_test` package for critical flows.

**Changes:**
- Add `integration_test` dependency to `pubspec.yaml` (dev_dependencies).
- Create `integration_test/` directory.
- Write tests for:
  - Create keg → tap keg → pour → undo pour.
  - Join session via deep link.
  - Create joint account → add members.
  - Keg done flow with final calculation.

**Test:** Run integration tests on emulator/simulator.

---

## Step 22 — Brainstorm additional features

**Goal:** Think about and document additional features that could enhance the app.

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

**Action:** Document chosen features in a future TODO.

---

## Dependency graph (suggested order)

```
Step 1  (keg status: created)         — foundational, no deps
Step 2  (consolidate profile nav)     — standalone UI tweak
Step 3  (past sessions to drawer)     — standalone UI tweak
Step 4  (merge keg + stats card)      — standalone UI tweak
Step 9  (unified snackbar)            — standalone fix
Step 14 (disable Settle Up)           — standalone, quick
Step 19 (code cleanup)               — housekeeping

Step 5  (participants vertical list)  — before Steps 10, 11
Step 6  (1-sec timer updates)         — before Step 11
Step 7  (settings expansion)          — before Step 8
Step 8  (per-beer price)              — depends on Step 7 for units

Step 10 (joint accounts UI)           — depends on Step 5
Step 11 (BAC enhancements)            — depends on Steps 5, 6
Step 12 (keg done final calc)         — depends on Step 10
Step 13 (bill review screen)          — depends on Step 12

Step 15 (notifications)              — independent, but after core features stable
Step 16 (slowdown notification)       — depends on Step 15
Step 17 (manual users)               — independent feature
Step 18 (about screen)               — standalone UI

Step 20 (localisation)               — after all UI is finalised
Step 21 (integration tests)           — after all features are implemented
Step 22 (brainstorm)                  — anytime
```

---

## Quick wins (can be done in any order, minimal risk)

1. Step 2 — Consolidate profile navigation
2. Step 3 — Move past sessions
3. Step 4 — Merge cards
4. Step 9 — Unified snackbar
5. Step 14 — Disable Settle Up
6. Step 18 — About screen enhancements

# TODO

## now

- [x] sign-in/create account screen - add language/localization switch. ✅ Added `preAuthLocaleProvider` (Riverpod notifier) + SharedPreferences persistence via `loadLocalLanguage()`/`saveLocalLanguage()`. Language picker on welcome screen (🇬🇧/🇨🇿/🇩🇪 flags). Settings language switch also saves locally. Firestore preference takes precedence after sign-in.
- [ ] kiosk mode - rights as a keg session owner, but not showing user specific menu - nickname, profile, not in participants list. This mode will be turned on eg. on tablet which will stay next to keg to be available to record taps for every user. Think how to activate this kiosk mode. Probably during joining the session. **⚠️ NEEDS CLARIFICATION — see notes below.**
- [x] sign-in via Google provider ✅ Full `google_sign_in` implementation on both welcome and sign-in screens. Firestore profile auto-created with `auth_provider: 'google'`. ⚠️ Requires manual Firebase Console config: enable Google sign-in provider, add SHA-1 (Android), add reversed client ID to iOS URL schemes.
- [x] do not use Cloud functions ✅ Removed `cloud_functions` package from pubspec. Stubbed `exportToSettleUp` call in settle_up_screen. Added rule to copilot-instructions.md.
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

### Kiosk mode — needs clarification

The kiosk mode task is not clear enough to implement safely. Questions:
1. **Activation**: Should kiosk mode be a toggle during "Join Session" flow, or a separate entry path (e.g. special URL/QR)?
2. **Auth**: Does the kiosk tablet need its own user account, or should it work unauthenticated?
3. **UI**: Should the kiosk show the full participant list (with pour buttons for each), or a simplified "tap to pour" grid?
4. **Restrictions**: Which menu items exactly should be hidden? (e.g. profile, settings, drawer, session history)
5. **Session lock**: Should kiosk mode be locked to one session, preventing navigation to other screens?

## future

- brewery&beers DB, use for autocomplete
- cleanup: DB will be cleared, rething about all names, database attributes, screen names, variables if it makes sense. Rename accordingly. Analyze code, if something is repeating put it into shared code. Make sure all graphics types useses same dimensions, colors and theme everywhere.

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
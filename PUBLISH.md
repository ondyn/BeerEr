# Publishing Beerer to Google Play Store

> **Target audience:** First-time Play Store publisher.
> **Last updated:** 20 March 2026

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create a Google Play Developer Account](#2-create-a-google-play-developer-account)
3. [App Signing Key](#3-app-signing-key)
4. [Configure the Android Build for Release](#4-configure-the-android-build-for-release)
5. [Versioning Strategy](#5-versioning-strategy)
6. [Build the Release App Bundle](#6-build-the-release-app-bundle)
7. [Host the Privacy Policy](#7-host-the-privacy-policy)
8. [Create the App in Google Play Console](#8-create-the-app-in-google-play-console)
9. [Fill in the Store Listing](#9-fill-in-the-store-listing)
10. [App Content (Policy Compliance)](#10-app-content-policy-compliance)
11. [Upload the App Bundle & Create a Release](#11-upload-the-app-bundle--create-a-release)
12. [Review & Submit](#12-review--submit)
13. [Handling App Updates](#13-handling-app-updates)
14. [Troubleshooting & Tips](#14-troubleshooting--tips)

---

## 1. Prerequisites

- [x] Flutter project builds in release mode (`flutter build appbundle`)
- [x] Firebase project configured (`flutterfire configure`)
- [x] App icon set (already in `android/app/src/main/res/mipmap-*`)
- [ ] Google Play Developer account ($25 one-time fee)
- [ ] Upload signing key generated
- [ ] Privacy Policy hosted at a public URL
- [ ] Play Store screenshots (phone + optional tablet/Chromebook)

---

## 2. Create a Google Play Developer Account

1. Go to **https://play.google.com/console/signup**
2. Sign in with your Google account.
3. Accept the Developer Distribution Agreement.
4. Pay the **$25 one-time registration fee**.
5. Complete identity verification (takes 1–3 business days for individuals, longer for organisations).
   - You need a government-issued ID.
   - Developer name, address, phone, email.
6. Once verified, you can create apps.

> **Tip:** Use a dedicated Google account for your developer profile (e.g. `beerer.app@gmail.com`), not your personal Gmail — this keeps things professional and separable.

---

## 3. App Signing Key

Google Play requires that every app is signed with a cryptographic key.

### 3.1 Generate an Upload Key

Run from the project root (replace the values in `<…>` with your own):

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass <YOUR_STORE_PASSWORD> \
  -keypass <YOUR_KEY_PASSWORD> \
  -dname "CN=Ondrej Hnyk, OU=Beerer, O=Beerer, L=Prague, ST=Prague, C=CZ"
```

This creates `android/app/upload-keystore.jks`.

### 3.2 Create `key.properties`

Create the file `android/key.properties` (**never commit this file**):

```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3.3 Gitignore the secrets

Verify `.gitignore` contains:

```
# Signing
android/key.properties
android/app/upload-keystore.jks
*.jks
```

### 3.4 Google Play App Signing

When you upload your first AAB, Google Play will enrol you in **Play App Signing** automatically. Google holds the actual app-signing key; your upload key is only used to authenticate uploads. If you lose the upload key, you can reset it via Play Console — you can **never** lose the app-signing key that Google manages.

---

## 4. Configure the Android Build for Release

### 4.1 Reference key.properties in `build.gradle.kts`

The file `android/app/build.gradle.kts` needs to be updated to:

1. Load `key.properties`.
2. Define a `release` signing config.
3. Enable R8/ProGuard shrinking.
4. Use the release signing config (instead of debug).

See the actual changes applied in this repo (search for `signingConfigs` in `android/app/build.gradle.kts`).

### 4.2 Internet permission

Already present in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 4.3 App label

Already set in `AndroidManifest.xml`:
```xml
android:label="Beerer"
```

### 4.4 Application ID

Currently `com.beerer.beerer` in `build.gradle.kts`. This is your **permanent** package name on Google Play — it can **never** be changed after first upload.

> If you want a different ID (e.g. `com.beerer.app` or `io.beerer.app`), change it **before** your first upload. You'd also need to update `google-services.json` and Firebase console.

---

## 5. Versioning Strategy

Flutter uses a **`version`** field in `pubspec.yaml`:

```yaml
version: 1.0.0+1
#         ↑↑↑↑↑ ↑
#         name  code
```

| Field | Purpose |
|-------|---------|
| `versionName` (1.0.0) | Displayed to users in the Play Store |
| `versionCode` (+1) | Internal integer; must **strictly increase** with every upload |

### Rules:
- **Every upload** to any track (internal, closed, open, production) must have a **higher `versionCode`** than any previous upload.
- Use semantic versioning for the name: `major.minor.patch`.
- Bump strategy:
  - Bug fix → `1.0.1+2`
  - New feature → `1.1.0+3`
  - Breaking change → `2.0.0+4`

### Current version:
```yaml
version: 1.0.0+1   # First release
```

---

## 6. Build the Release App Bundle

Google Play requires an **Android App Bundle (AAB)**, not an APK.

```bash
# Clean first
.fvm/flutter_sdk/bin/flutter clean

# Get dependencies
.fvm/flutter_sdk/bin/flutter pub get

# Build the AAB
.fvm/flutter_sdk/bin/flutter build appbundle --release
```

The output file will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

### Verify the AAB locally (optional):

```bash
# Install bundletool
brew install bundletool

# Generate APKs from the AAB
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app.apks --mode=universal

# Install on a connected device
bundletool install-apks --apks=build/app.apks
```

---

## 7. Host the Privacy Policy

Google Play **requires** a publicly accessible URL for your privacy policy. Options:

### Option A — Firebase Hosting (recommended, already configured)

1. Create `web/privacy.html` with the full privacy policy text.
2. Deploy to Firebase Hosting:
   ```bash
   firebase deploy --only hosting
   ```
3. Your privacy policy URL will be:
   **`https://ondyn-beerer.web.app/privacy.html`**

### Option B — GitHub Pages

Create a `/docs/privacy.html` on the `main` branch and enable GitHub Pages.

### Option C — Any static host

Netlify, Vercel, or your own server.

> **Important:** The URL must be publicly accessible (no login required) and must match what you enter in Play Console.

---

## 8. Create the App in Google Play Console

1. Go to **https://play.google.com/console**
2. Click **"Create app"**.
3. Fill in:
   - **App name:** `Beerer`
   - **Default language:** English (United States) — or your primary language
   - **App or Game:** App
   - **Free or Paid:** Free
4. Check the declaration boxes:
   - Developer Program Policies ✓
   - US Export Laws ✓
5. Click **"Create app"**.

---

## 9. Fill in the Store Listing

Navigate to **Grow → Store presence → Main store listing**.

### 9.1 Product details

| Field | Value |
|-------|-------|
| **App name** | Beerer |
| **Short description** (max 80 chars) | Track keg beer at parties — pour, stats & split costs 🍺 |
| **Full description** (max 4000 chars) | See below |

#### Suggested full description:

```
Beerer is the ultimate keg beer tracker for parties and social events.

🍺 TAP A KEG
Set up your keg with beer name, volume, price, and alcohol content. Search from a database of beers or enter details manually.

📊 REAL-TIME STATS
See live statistics: how much beer is left, who's drinking what, average drinking rate, and estimated time until the keg runs dry.

👥 PARTY MODE
Share a join link or QR code with friends. Everyone can log their own pours or pour for others — with push notifications to keep everyone in the loop.

💰 SPLIT COSTS
At the end of the party, see exactly what everyone owes. Create joint accounts for families or groups and export costs to settle up easily.

🔒 PRIVACY FIRST
BAC estimates are calculated on your device only — never stored on any server. Weight, age, and BAC visibility are fully opt-in.

📱 WORKS OFFLINE
Built on Firebase with offline support. Log pours even without an internet connection — everything syncs automatically when you're back online.

Key features:
• Create and manage keg sessions
• Log pours with predefined or custom volumes
• Real-time keg fill level with animated progress
• BAC estimation (Widmark formula, device-only)
• Push notifications for session events
• QR code and deep link sharing
• Joint accounts for group billing
• Session history
• Dark "beer" themed design

Drink responsibly. BAC estimates are for informational purposes only.
```

### 9.2 Graphics / Screenshots

You need to prepare:

| Asset | Size | Required |
|-------|------|----------|
| **App icon** | 512 × 512 px, 32-bit PNG | ✅ Yes |
| **Feature graphic** | 1024 × 500 px | ✅ Yes (shown at top of listing) |
| **Phone screenshots** | Min 2, max 8. 16:9 or 9:16. Min 320px, max 3840px | ✅ Yes |
| **7-inch tablet screenshots** | Same specs | Optional (recommended) |
| **10-inch tablet screenshots** | Same specs | Optional (recommended) |

#### How to take screenshots:
```bash
# Run on emulator or device
.fvm/flutter_sdk/bin/flutter run --release -d <device_id>

# Take screenshot via ADB
adb -s emulator-5554 shell screencap -p /sdcard/screenshot.png
adb -s emulator-5554 pull /sdcard/screenshot.png ./screenshots/
```

**Recommended screenshots (in order):**
1. Home screen with an active keg session
2. Pour screen (volume selector)
3. Live statistics / keg fill level
4. Participant list / leaderboard
5. QR code sharing
6. Session history
7. Bill review / cost summary

> **Tip:** Use a tool like [screenshots](https://pub.dev/packages/screenshots) or [Hotpot.ai](https://hotpot.ai/store-screenshots) to add device frames and captions.

### 9.3 Categorisation

| Field | Value |
|-------|-------|
| **Application type** | Application |
| **Category** | Food & Drink |
| **Tags** | beer, party, tracker, keg, social |

---

## 10. App Content (Policy Compliance)

Navigate to **Policy and programs → App content**. You must complete **ALL** sections before you can publish.

### 10.1 Privacy Policy

- **URL:** `https://ondyn-beerer.web.app/privacy.html`
- This must match the privacy policy accessible from within the app.

### 10.2 App Access

- Choose: **"All functionality is available without special access"**
  - ❌ Unless your app requires login to access core features — in that case select "All or some functionality is restricted" and provide test credentials:
    - **Test email:** `testreviewer@beerer.app` (create a test account)
    - **Test password:** `<password>`
  - Since Beerer requires login, **you need to provide test credentials**.

> **Action required:** Create a test account specifically for Google reviewers before submitting.

### 10.3 Ads

- **Does your app contain ads?** → **No**
- Beerer does not show any advertisements.

### 10.4 Content Rating

You'll fill out the **IARC questionnaire**. For Beerer, the relevant answers are:

| Question | Answer |
|----------|--------|
| Does the app contain violence? | No |
| Does the app contain sexual content? | No |
| Does the app involve gambling? | No |
| Does the app involve controlled substances? | **Yes** — the app references alcohol |
| Does the app allow users to interact? | **Yes** — participants share a session |
| Does the app share user location? | No |
| Does the app allow user-generated content? | **Yes** — nicknames, session names |
| Does the app contain ads? | No |

> The alcohol reference will likely give you a **Teen (13+)** or **Mature (17+)** rating depending on IARC region. This is normal and expected for a beer app.

### 10.5 Target Audience

- **Target age group:** Select **18 and older** only.
- ⚠️ **Do NOT select any age group under 18.** This is a beer-tracking app.
- This means the app is **not designed for children** and avoids the Families Policy requirements.

### 10.6 News Apps

- **Is this a news app?** → **No**

### 10.7 COVID-19 Contact Tracing / Government Apps

- **No** to all.

### 10.8 Data Safety

This is one of the most important and detailed sections. You must declare what data your app collects, how it's used, and whether it's shared.

#### Data Safety Answers for Beerer:

**Does your app collect or share any of the required user data types?** → **Yes**

| Data Type | Collected | Shared | Purpose | Optional |
|-----------|-----------|--------|---------|----------|
| **Email address** | ✅ | ❌ | Account management, Authentication | Required for account |
| **Name** (nickname) | ✅ | ✅ (with session participants) | App functionality | Required |
| **User IDs** | ✅ | ❌ | App functionality, Analytics | Required |
| **Other user-generated content** (pour logs, session data) | ✅ | ✅ (with session participants) | App functionality | Required |
| **Health info** (weight, age for BAC) | ✅ | ❌ (never leaves device in calculated form) | App functionality | **Optional** |
| **App interactions** (pours, session events) | ✅ | ❌ | App functionality | Required |

**Additional declarations:**
- **Is data encrypted in transit?** → **Yes** (Firebase uses TLS)
- **Can users request data deletion?** → **Yes** (account deletion in settings)
- **Does the app follow the Families Policy?** → **No** (not a children's app)

### 10.9 Financial Features

- **Does your app provide financial features?** → **No**
  - The "Tip via Revolut" link is an external URL and not an in-app payment. Settle Up export is also external.

### 10.10 Government Apps

- **No.**

---

## 11. Upload the App Bundle & Create a Release

### 11.1 Choose a release track

| Track | Purpose |
|-------|---------|
| **Internal testing** | Up to 100 testers by email. No review needed. Instant. |
| **Closed testing** | Invite-only group. Reviewed by Google. |
| **Open testing** | Anyone can join via a link. Reviewed by Google. |
| **Production** | Public on Play Store. Reviewed by Google. |

**Recommended flow for first release:**

1. **Internal testing** first — verify everything works on real devices.
2. **Closed testing** — get feedback from friends/beta users.
3. **Production** — once confident.

### 11.2 Upload to Internal Testing

1. In Play Console → **Testing → Internal testing**
2. Click **"Create new release"**
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. Google will automatically enrol in **Play App Signing** (accept the prompt)
5. Fill in **Release name:** `1.0.0 (1)` (auto-filled from AAB usually)
6. Fill in **Release notes:**
   ```
   Initial release of Beerer — the keg beer tracker for parties!
   
   • Create and manage keg sessions
   • Log beer pours with real-time statistics
   • Share sessions via QR code or deep link
   • Joint accounts for group billing
   • BAC estimation (device-only)
   • Push notifications
   ```
7. Click **"Review release"** → **"Start rollout"**

### 11.3 Add Testers

1. Go to **Internal testing → Testers**
2. Create a new email list or use an existing one
3. Add tester email addresses (their Google account emails)
4. Share the **opt-in link** with testers

### 11.4 Promote to Production

Once testing is done:
1. Go to the internal/closed testing release
2. Click **"Promote release"** → **"Production"**
3. Or create a new production release with the same (or newer) AAB
4. Fill release notes
5. Submit for review

> **First review** typically takes **1–3 business days** (sometimes up to 7 days for new developer accounts).

---

## 12. Review & Submit

### Pre-launch Checklist

Before submitting to production, verify:

- [ ] All **App content** sections are completed (green checkmarks)
- [ ] **Store listing** is complete with all required assets
- [ ] **Pricing & distribution** is set (Free, all countries or select)
- [ ] **Content rating** questionnaire is completed
- [ ] **Data safety** form is completed
- [ ] **Privacy policy URL** is live and accessible
- [ ] **Test credentials** are provided in App Access (if login required)
- [ ] **Target audience** is 18+ only
- [ ] AAB is uploaded and release is created

### Country/Region Availability

- Default: Available in **all countries**
- You can restrict to specific countries if needed
- Consider starting with your primary market (e.g., Czechia, EU)

### Review Outcomes

| Status | Meaning |
|--------|---------|
| **In review** | Google is reviewing your app |
| **Approved** | App is live or will go live within hours |
| **Rejected** | Policy violation — read the rejection email carefully |
| **Suspended** | Serious violation — appeal if you believe it's a mistake |

Common rejection reasons for alcohol-related apps:
- Missing age gate / age verification
- Missing "drink responsibly" disclaimers
- Targeting under-18 audience
- Promoting excessive drinking

Beerer already has "Drink Responsibly" notices and is targeted at 18+ only. ✅

---

## 13. Handling App Updates

### 13.1 Version Bump Workflow

1. **Edit `pubspec.yaml`:**
   ```yaml
   # Before
   version: 1.0.0+1
   
   # After (bug fix)
   version: 1.0.1+2
   
   # After (new feature)
   version: 1.1.0+3
   ```

2. **Build:**
   ```bash
   .fvm/flutter_sdk/bin/flutter clean
   .fvm/flutter_sdk/bin/flutter pub get
   .fvm/flutter_sdk/bin/flutter build appbundle --release
   ```

3. **Upload** the new AAB to Play Console.

4. **Write release notes** (What's new) — displayed to users:
   ```
   What's new in 1.0.1:
   • Fixed crash when undoing a pour
   • Improved keg fill animation performance
   • Updated translations
   ```

5. **Choose rollout strategy:**
   - **Staged rollout:** Start with 10% → 25% → 50% → 100% over days/weeks
   - **Full rollout:** 100% immediately
   - Staged rollout is recommended for production updates — you can halt if crash rates spike.

### 13.2 Staged Rollout

1. In the Production release, set **"Rollout percentage"** to e.g. 20%
2. Monitor **Android Vitals** (crashes, ANRs) in Play Console
3. If ok → increase to 50% → 100%
4. If issues → click **"Halt rollout"** → fix → upload new version

### 13.3 Force Update (Optional)

If you need to force users to update (e.g., breaking Firestore schema change), use the [Firebase Remote Config](https://firebase.google.com/docs/remote-config) approach:
1. Store `min_required_version` in Remote Config
2. On app start, compare with current version
3. If outdated, show a blocking dialog pointing to the Play Store

### 13.4 versionCode Must Always Increase

- `versionCode` (the `+N` in pubspec.yaml) **must be strictly higher** than any previously uploaded AAB, across **all tracks** (internal, closed, open, production).
- If you upload `+2` to internal testing, you cannot upload `+2` to production — you need at least `+3` or reuse the same AAB.

### 13.5 Update Review Time

- Updates are usually reviewed **within hours** (much faster than the first submission).
- Critical bug fixes can be submitted with a note to Google via the "expedited review" option.

---

## 14. Troubleshooting & Tips

### Common Issues

| Issue | Solution |
|-------|----------|
| Build fails with signing error | Check `key.properties` paths are correct and relative to `android/app/` |
| "App not published" warning | Complete ALL sections in App content before submitting |
| AAB rejected: "Debug signed" | Make sure `signingConfig` in `build.gradle.kts` points to release, not debug |
| "Version code already used" | Bump `versionCode` in `pubspec.yaml` |
| "Privacy policy not accessible" | Ensure the URL works in incognito mode, no login required |
| Rejection: alcohol content | Verify 18+ target audience and "Drink Responsibly" messaging |

### Android Vitals

After launch, monitor:
- **Crash rate** (target < 1%)
- **ANR rate** (Application Not Responding, target < 0.5%)
- **Startup time**

Find these in Play Console → **Quality → Android vitals**.

### Useful Commands Reference

```bash
# Clean build
.fvm/flutter_sdk/bin/flutter clean && .fvm/flutter_sdk/bin/flutter pub get

# Build AAB
.fvm/flutter_sdk/bin/flutter build appbundle --release

# Build APK (for local testing, not for Play Store)
.fvm/flutter_sdk/bin/flutter build apk --release

# Check current version
grep "version:" pubspec.yaml

# List connected devices
.fvm/flutter_sdk/bin/flutter devices

# Run release mode on device
.fvm/flutter_sdk/bin/flutter run --release
```

### Key Files Summary

| File | Purpose | Git-tracked? |
|------|---------|-------------|
| `pubspec.yaml` | Version, dependencies | ✅ |
| `android/app/build.gradle.kts` | Signing config, build settings | ✅ |
| `android/key.properties` | Keystore passwords | ❌ NEVER |
| `android/app/upload-keystore.jks` | Upload signing key | ❌ NEVER |
| `web/privacy.html` | Public privacy policy page | ✅ |
| `build/app/outputs/bundle/release/app-release.aab` | Upload to Play Console | ❌ (build artifact) |

### Backup Your Signing Key!

⚠️ **CRITICAL:** Back up `upload-keystore.jks` and `key.properties` in a secure location (password manager, encrypted drive). If you lose the upload key, you can request a reset through Play Console, but it takes time and requires identity verification.

---

## Quick Start Checklist

```
□ 1. Create Google Play Developer account ($25)
□ 2. Generate upload keystore (keytool command in Section 3)
□ 3. Create android/key.properties
□ 4. Update android/app/build.gradle.kts (signing + R8)
□ 5. Deploy privacy policy to Firebase Hosting
□ 6. Build: flutter build appbundle --release
□ 7. Create app in Play Console
□ 8. Fill store listing (name, description, screenshots, icon)
□ 9. Complete App Content (privacy, access, rating, data safety, audience)
□ 10. Upload AAB to Internal Testing
□ 11. Test with real devices
□ 12. Promote to Production
□ 13. Wait for review (1-7 days)
□ 14. 🎉 App is live!
```

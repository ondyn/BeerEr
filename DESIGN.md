# BeerEr — Design Document

## 1. Product Overview

**BeerEr** is a cross-platform mobile app (iOS & Android) for tracking beer consumption from a keg at a party. It calculates per-user statistics, estimates keg depletion, and helps settle costs among groups.

---

## 2. Application Description

- Uses Firebase (Firestore) as the real-time database, available for Android and iOS.
- Users create an account (email/password with mail verification, or social auth). Profile includes nickname, weight, age, male/female.
- Any user can set up a new keg party — defining volume of keg, beer name, price, alcohol content, predefined beer volumes (e.g. 0.5 l, 0.3 l, …). The keg start time is set when the creator clicks "Tap a Keg" in keg details. Beer list is fetched from the Untappd API; free-text entry is also supported.
- After creating a keg and tapping it, the creator shares a join link (WhatsApp, message, mail, QR code) for others.
- After joining, users set a session nickname (pre-filled from profile) and visibility preferences. Each pour logs the volume; the last used volume is remembered.
- **Statistics** (always visible): time drinking current beer, time since last beer, average drinking rate, BAC estimate (Widmark formula, device-only), keg volume remaining, predicted empty time, cost so far.
- **Pause keg** ("untap unfinished keg") / **Resume** ("tap keg again") — no pours allowed while paused.
- Users can see other people's statistics unless explicitly hidden.
- Users can pour beers for others — switch to user list, tap user, log pour (that user gets a push notification).
- **Keg done** — any user can declare the keg empty; session is read-only after that (except for the creator).
- History of past keg sessions is available.
- Users can join **joint accounts/bills** (e.g. family). Statistics are aggregated per account. After keg is done, costs per account are shown.
- After keg is done, the session creator can export costs to **Settle Up** via API.
- Theme: warm amber/dark "beer" style.
- All actions sync to Firestore in real time; all clients receive live updates.

---

## 3. System Architecture (Tech Stack)

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — single codebase for iOS & Android |
| Backend / Database | Firebase Firestore (real-time, offline-persistent) |
| Serverless Logic | Firebase Cloud Functions (Node.js/TypeScript) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Beer Data | Untappd API (via Cloud Function, key never exposed client-side) |
| Cost Settlement | Settle Up API (`https://api.settleup.io/`) |
| Auth | Firebase Auth — email/password + social providers |

---

## 4. Data Schema (High-Level)

- **Users:** `user_id`, `nickname`, `weight_kg`, `age`, `gender`, `auth_provider`, `preferences`
- **KegSessions:** `session_id`, `creator_id`, `beer_name`, `untappd_beer_id`, `volume_total_ml`, `volume_remaining_ml`, `price_per_liter`, `alcohol_percent`, `predefined_volumes_ml[]`, `start_time`, `status` (active / paused / done)
- **Pours:** `pour_id`, `session_id`, `user_id`, `poured_by_id`, `volume_ml`, `timestamp`, `undone`
- **JointAccounts:** `account_id`, `session_id`, `group_name`, `member_user_ids[]`

---

## 5. Security, Privacy & Edge Cases

- **Concurrency:** Firestore transactions for every write that changes `volume_remaining_ml`.
- **Undo:** Soft-delete (`undone: true`) with short grace period; transaction reverses keg volume.
- **Privacy / GDPR:** Weight, age, BAC are opt-in to share. BAC is computed on-device only — never stored in Firestore.
- **Offline:** Firebase native offline persistence; local queue syncs when connectivity returns.
- **Responsible drinking:** "Drink Responsibly" copy required on all BAC-related UI; App Store / Play Store compliant.

---

## 6. Visual Design Language

### 6.1 Colour Palette

| Role | Colour | Hex |
|------|--------|-----|
| Primary / Brand | Amber gold | `#F5A623` |
| Primary Dark | Deep amber | `#C47D0E` |
| Background | Near-black | `#1A1208` |
| Surface | Dark brown | `#2C1F0E` |
| Surface Variant | Medium brown | `#3D2B14` |
| On Surface | Off-white | `#F5ECD7` |
| On Surface Secondary | Warm grey | `#A89880` |
| Success / Active | Foam white-green | `#9DC88D` |
| Warning / Paused | Muted orange | `#E07B39` |
| Error | Ale red | `#C0392B` |
| Overlay / Scrim | Black 60 % | `#99000000` |

### 6.2 Typography

- **Display / Headings:** `Nunito` — rounded, friendly; used for screen titles and keg names.
- **Body:** `Inter` — clean, readable; used for stats and labels.
- **Monospaced numbers:** `Roboto Mono` — used for live counters and volume numbers.

### 6.3 Iconography & Illustrations

- Material Symbols (outlined) as base icon set.
- Custom beer-themed icons: keg, beer glass, foam bubble, tap handle.
- Subtle foam-drip divider motif used between sections.
- Keg fill level shown as an animated vertical progress bar styled as a keg silhouette.

### 6.4 Motion & Feedback

- Pour button: tactile haptic feedback + amber ripple + bubble particle burst animation.
- Keg fill bar animates on every new pour.
- Snackbars for confirmations (pour logged, undo available for 5 s).
- Skeleton shimmer loaders while Firestore data loads.
- Bottom sheet modals slide up for contextual actions (volume picker, user picker).

---

## 7. Screen Inventory & Descriptions

### 7.1 Splash / Loading Screen

**Route:** `/`  
**Purpose:** Firebase initialisation, auth state check, deep-link resolution.

**Layout:**
```
┌─────────────────────────────┐
│                             │
│                             │
│        🍺  BeerEr           │  ← centred logo + wordmark (amber on dark)
│   "Count every drop"        │  ← tagline in warm grey
│                             │
│      ████████░░░  loading   │  ← amber shimmer progress bar
│                             │
└─────────────────────────────┘
```
- Automatically navigates to **Home** if authenticated, or **Welcome** if not.
- Deep link (`/join/:sessionId`) resolves here; unauthenticated users are redirected to auth first, then forwarded to Join screen after sign-in.

---

### 7.2 Welcome / Onboarding Screen

**Route:** `/welcome`  
**Purpose:** First impression for new/logged-out users.

**Layout:**
```
┌─────────────────────────────┐
│  ← (back if came from app)  │
│                             │
│   [illustrated keg + crowd] │  ← full-bleed hero illustration
│                             │
│  ┌───────────────────────┐  │
│  │  🍺  BeerEr           │  │
│  │  Track every pour.    │  │
│  │  Settle every tab.    │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────────────────┐    │
│  │   Sign in           │    │  ← primary amber button
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │   Create account    │    │  ← outlined button
│  └─────────────────────┘    │
│                             │
│                             │
└─────────────────────────────┘
```

---

### 7.3 Sign In Screen

**Route:** `/auth/sign-in`

**Layout:**
```
┌─────────────────────────────┐
│  ←                          │
│                             │
│   Sign in to BeerEr         │  ← display heading
│                             │
│  ┌─────────────────────┐    │
│  │  📧  Email          │    │  ← text field
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  🔒  Password       │    │  ← text field (obscured, toggle eye)
│  └─────────────────────┘    │
│                             │
│  Forgot password?           │  ← text link (right-aligned)
│                             │
│  ┌─────────────────────┐    │
│  │   Sign in           │    │  ← primary button (amber)
│  └─────────────────────┘    │
│                             │
│  ─────────── or ───────────  │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │  Google  │ │  Apple   │  │  ← social sign-in buttons
│  └──────────┘ └──────────┘  │
│                             │
│  No account? Register ›     │
└─────────────────────────────┘
```
- Inline validation on blur; error text below each field.
- Loading spinner overlaid on button during Firebase call.
- On success → Home.

---

### 7.4 Register Screen

**Route:** `/auth/register`

**Layout:**
```
┌─────────────────────────────┐
│  ←                          │
│                             │
│   Create account            │
│                             │
│  ┌─────────────────────┐    │
│  │  📧  Email          │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  🔒  Password       │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  🔒  Confirm pwd    │    │
│  └─────────────────────┘    │
│                             │
│  ─── Profile details ───    │  ← section divider
│                             │
│  ┌─────────────────────┐    │
│  │  🍻  Nickname       │    │
│  └─────────────────────┘    │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ Weight   │ │ Age      │  │  ← numeric fields (optional, for BAC)
│  └──────────┘ └──────────┘  │
│                             │
│  Gender:  ○ Male  ○ Female  │  ← segmented control
│                             │
│  ℹ Weight & age used only   │
│    for BAC estimation on    │
│    your device.             │  ← privacy note (small, warm grey)
│                             │
│  ┌─────────────────────┐    │
│  │   Create account    │    │
│  └─────────────────────┘    │
│                             │
│  Already have one? Sign in ›│
└─────────────────────────────┘
```
- After registration → email verification banner shown on Home.
- Weight / age fields are clearly optional.

---

### 7.5 Email Verification Banner

Shown at top of **Home** when `emailVerified == false`:
```
┌─────────────────────────────────────────────────────┐
│ ✉  Check your inbox to verify your email.  Resend › │
└─────────────────────────────────────────────────────┘
```
Amber background, dismissible after verification confirmed.

---

### 7.6 Forgot Password Screen

**Route:** `/auth/forgot-password`

Single field (email) + "Send reset link" button. Confirmation message replaces form on success.

---

### 7.7 Home Screen

**Route:** `/home`  
**Purpose:** Entry point for authenticated users; lists keg sessions and surfaces quick actions.

**Layout:**
```
┌─────────────────────────────┐
│  BeerEr          👤  [≡]   │  ← top app bar; avatar → Profile; hamburger → Drawer
├─────────────────────────────┤
│                             │
│  ┌─── ACTIVE SESSION ────┐  │  ← highlighted card (amber border)
│  │  🍺 Pilsner Urquell   │  │
│  │  ████████░░ 62% left  │  │  ← mini keg fill bar
│  │  12 people · 3 h 20 m │  │
│  │  > Open Session       │  │
│  └───────────────────────┘  │
│                             │
│  Past sessions              │  ← section header
│  ┌───────────────────────┐  │
│  │  Kozel Dark  · Done   │  │  ← session history card
│  │  Mar 1, 2026  8 people│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Heineken  · Done     │  │
│  │  Feb 14, 2026 5 people│  │
│  └───────────────────────┘  │
│                             │
│  ╔═════════════════════╗    │
│  ║  + New Keg Session  ║    │  ← FAB (amber, bottom-right)
│  ╚═════════════════════╝    │
└─────────────────────────────┘
```

**Navigation Drawer (hamburger):**
```
┌─────────────────────────────┐
│  [avatar]  Jan Novák        │
│            jan@example.com  │
├─────────────────────────────┤
│  🏠  Home                   │
│  🍺  My Sessions            │
│  👤  Profile                │
│  ⚙   Settings               │
│  ℹ   About                  │
├─────────────────────────────┤
│  🚪  Sign out               │
└─────────────────────────────┘
```

---

### 7.8 Create Keg Session Screen

**Route:** `/keg/new`

**Layout (scrollable form, 2 steps):**

**Step 1 — Beer & Volume:**
```
┌─────────────────────────────┐
│  ←  New Keg Session  1/2   │
│                             │
│  Search beer…               │  ← Untappd search field (live)
│  ┌───────────────────────┐  │
│  │  🔍  e.g. Pilsner     │  │
│  └───────────────────────┘  │
│                             │
│  Results:                   │
│  ┌───────────────────────┐  │
│  │ [label art] Pilsner   │  │  ← tappable Untappd result
│  │            Urquell    │  │
│  │            4.4 % ABV  │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ [label art] Pilsner   │  │
│  │            Zlatý Bažant│ │
│  └───────────────────────┘  │
│                             │
│  Not found?                 │
│  ┌─────────────────────┐    │
│  │  Free-text beer name│    │
│  └─────────────────────┘    │
│                             │
│  Keg volume (litres)        │
│  ┌─────────────────────┐    │
│  │  30                 │    │  ← numeric input
│  └─────────────────────┘    │
│                             │
│  Alcohol content (%)        │
│  ┌─────────────────────┐    │
│  │  4.4  (pre-filled)  │    │  ← pre-filled from Untappd if selected
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │   Next →            │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

**Step 2 — Pricing & Volumes:**
```
┌─────────────────────────────┐
│  ←  New Keg Session  2/2   │
│                             │
│  Price per litre (€)        │
│  ┌─────────────────────┐    │
│  │  3.50               │    │
│  └─────────────────────┘    │
│                             │
│  Predefined pour sizes      │
│  (drag to reorder, × to rm) │
│                             │
│  ┌──────┐ ┌──────┐          │
│  │ 0.5l │ │ 0.3l │  + Add  │  ← chip list + add chip button
│  └──────┘ └──────┘          │
│                             │
│  ─────────────────────────  │
│                             │
│  ┌─────────────────────┐    │
│  │   Create Session    │    │  ← primary button (amber)
│  └─────────────────────┘    │
└─────────────────────────────┘
```
- On success → **Keg Session Detail** (status: not yet tapped).

---

### 7.9 Keg Session Detail Screen

**Route:** `/keg/:sessionId`  
**Purpose:** The main live screen during a party. Changes appearance based on keg status.

#### 7.9.1 Status: Not Tapped (creator only, before sharing)

```
┌─────────────────────────────┐
│  ←  Pilsner Urquell   ⋮    │  ← overflow: Edit / Delete
│                             │
│  ┌─── Session Ready ─────┐  │
│  │  🍺 Pilsner Urquell   │  │
│  │  30 l  ·  4.4 %  ·  €3.50/l  │
│  │                       │  │
│  │  Tap the keg to start!│  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────────────────┐    │
│  │   🍺  Tap Keg!      │    │  ← large primary amber button
│  └─────────────────────┘    │
└─────────────────────────────┘
```

#### 7.9.2 Status: Active

```
┌─────────────────────────────┐
│  ←  Pilsner Urquell   ⋮    │  ← overflow: Pause / Share / Keg Done
│                             │
│  ┌─── KEG LEVEL ─────────┐  │
│  │  ████████████░░░ 62%  │  │  ← animated amber fill bar
│  │  18.6 l remaining     │  │
│  │  ~2 h 15 m until empty│  │
│  └───────────────────────┘  │
│                             │
│  My stats                   │  ← section header (collapsible)
│  ┌───────────────────────┐  │
│  │  🍺 Current beer  12:34│ │  ← timer counting up (Roboto Mono)
│  │  ⏱ Since last     00:45│ │
│  │  📊 Avg rate   0.4 l/h │  │
│  │  🧪 Est. BAC   0.03 ‰  │  ← only if weight/age set; "Drink responsibly"
│  │  💶 My total    €4.20  │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────────────────────┐│
│  │   🍺  I got beer!       ││  ← large FAB-style primary button
│  └─────────────────────────┘│
│                             │
│  Participants               │  ← collapsible section
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │ Jan  │ │ Eva  │ │+Pour ││  ← avatar chips; tap for user card; +Pour opens pour-for sheet
│  └──────┘ └──────┘ └──────┘│
└─────────────────────────────┘
```

**Overflow menu (⋮) for creator:**
- Pause keg ("Untap unfinished keg")
- Share join link
- Edit session details
- Mark keg as done

**Overflow menu (⋮) for participant:**
- Share join link
- Mark keg as done

#### 7.9.3 Status: Paused

```
┌─────────────────────────────┐
│  ←  Pilsner Urquell  ⋮     │
│                             │
│  ┌─── KEG PAUSED ────────┐  │
│  │   ⏸  Keg is untapped  │  │  ← amber/orange warning banner
│  │   Pouring is disabled  │  │
│  └───────────────────────┘  │
│                             │
│  [stats still visible]      │
│                             │
│  ┌─────────────────────┐    │
│  │   🍺  Tap Keg Again │    │  ← creator only; re-enables pouring
│  └─────────────────────┘    │
└─────────────────────────────┘
```

#### 7.9.4 Status: Done

```
┌─────────────────────────────┐
│  ←  Pilsner Urquell         │
│                             │
│  ┌─── KEG EMPTY 🎉 ───────┐ │
│  │  Session complete!      │ │  ← confetti animation on first view
│  │  Mar 9, 2026  4h 20m   │ │
│  └─────────────────────────┘│
│                             │
│  Final stats                │
│  ┌───────────────────────┐  │
│  │  Total poured  28.4 l │  │
│  │  Participants    12   │  │
│  │  My total    €5.60    │  │
│  └───────────────────────┘  │
│                             │
│  Accounts / bills           │  ← section
│  ┌───────────────────────┐  │
│  │  🏠 Novák family  €14 │  │
│  │  👤 Tomáš (solo)  €4  │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────────────────┐    │
│  │  Export to Settle Up│    │  ← creator only; amber button
│  └─────────────────────┘    │
└─────────────────────────────┘
```

---

### 7.10 "I Got Beer" Bottom Sheet

Slides up from the bottom when user taps **I got beer!**

```
┌─────────────────────────────┐
│  ▬▬▬  (drag handle)         │
│  Log a pour for you         │
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │ 0.5l │ │ 0.3l │ │ 0.2l ││  ← predefined volume chips (last used highlighted)
│  └──────┘ └──────┘ └──────┘│
│                             │
│  Or enter manually:         │
│  ┌──────────────────┐       │
│  │  0.50  l         │       │  ← numeric input with stepper +-
│  └──────────────────┘       │
│                             │
│  ┌─────────────────────┐    │
│  │   ✓  Log Pour       │    │  ← primary button
│  └─────────────────────┘    │
│                             │
│  Pour for someone else ›    │  ← text link → User Picker sheet
└─────────────────────────────┘
```
- After logging: snackbar "Pour logged! Undo" (5 s timeout for undo action).

---

### 7.11 Pour for Someone Else — User Picker Sheet

Slides up over the pour sheet (or opens separately from participant chips).

```
┌─────────────────────────────┐
│  ▬▬▬                        │
│  Pour for…                  │
│                             │
│  🔍  Search participant     │  ← search field
│                             │
│  ┌───────────────────────┐  │
│  │  [av] Jan Novák       │  │  ← participant row, tap to select
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  [av] Eva Nováková    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  [av] Tomáš Procházka │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```
After selecting a user → volume picker sheet (same as 7.10) pre-fills last volume for that user.  
On confirm → pour logged + push notification sent to target user.

---

### 7.12 User Detail Card (bottom sheet)

Tapping a participant avatar/chip from the session screen opens a modal card:

```
┌─────────────────────────────┐
│  ▬▬▬                        │
│                             │
│  ┌─────────────────────────┐│
│  │  [large avatar]         ││
│  │  Jan Novák              ││  ← nickname
│  │  "Drinking for 3 h 10 m"││  ← sub-headline
│  └─────────────────────────┘│
│                             │
│  ┌─── Stats (if public) ─┐  │
│  │  🍺 Current beer  14:02│  │
│  │  ⏱ Since last     02:10│  │
│  │  📊 Avg rate   0.5 l/h │  │
│  │  💶 Session cost  €6.00│  │
│  └────────────────────────┘  │
│                             │
│  [Stats hidden by user]     │  ← shown instead if user hid stats
│                             │
│  Joint account: Novák family│  ← if member of a joint account
│                             │
│  ┌─────────────────────┐    │
│  │  🍺  Pour for Jan   │    │  ← shortcut pour button
│  └─────────────────────┘    │
└─────────────────────────────┘
```

---

### 7.13 Participants / Accounts Tab (inside session)

Accessible via tab or segment inside Keg Session Detail:

```
┌─────────────────────────────┐
│  Participants   Accounts    │  ← tab bar
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │  [av] Jan Novák  0.5l ⬤│  │  ← ⬤ = active now (green dot)
│  │       €2.50  ·  3h 10m│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  [av] Eva  1.0l        │  │
│  │       €5.00  ·  2h 00m│  │
│  └───────────────────────┘  │
│                             │  ← Accounts tab:
│  ┌───────────────────────┐  │
│  │  🏠 Novák family      │  │
│  │  Jan + Eva  ·  1.5 l  │  │
│  │  €7.50                │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  👤 Tomáš (solo)      │  │
│  │  0.3 l  ·  €1.50      │  │
│  └───────────────────────┘  │
│                             │
│  + Join / Create Account ›  │  ← text action
└─────────────────────────────┘
```

---

### 7.14 Joint Account Management Sheet

```
┌─────────────────────────────┐
│  ▬▬▬                        │
│  My Joint Account           │
│                             │
│  Account name               │
│  ┌─────────────────────┐    │
│  │  Novák family       │    │
│  └─────────────────────┘    │
│                             │
│  Members                    │
│  ┌───────────────────────┐  │
│  │  [av] Jan Novák  (you)│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  [av] Eva Nováková    │  │
│  └───────────────────────┘  │
│  + Add member               │  ← opens participant picker
│                             │
│  ┌─────────────────────┐    │
│  │   Save              │    │
│  └─────────────────────┘    │
│                             │
│  Leave account              │  ← destructive text link
└─────────────────────────────┘
```

---

### 7.15 Share Session Screen / Sheet

Accessible from the overflow menu on the Keg Session Detail.

```
┌─────────────────────────────┐
│  ←  Share Keg Session       │
│                             │
│  Invite friends to join     │
│                             │
│  ┌─── QR Code ────────────┐ │
│  │                        │ │
│  │   ██████░░░░██████     │ │  ← QR code (large, centred)
│  │   ██░░░░██░░░░░░██     │ │
│  │   ██████░░░░██████     │ │
│  │                        │ │
│  └────────────────────────┘ │
│                             │
│  beerer.app/join/abc123     │  ← copyable deep link
│  ┌─────────────────────┐    │
│  │  📋  Copy link      │    │
│  └─────────────────────┘    │
│                             │
│  Share via…                 │
│  ┌──────────┐ ┌──────────┐  │
│  │ WhatsApp │ │ Messages │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │   Mail   │ │  Other…  │  │  ← system share sheet
│  └──────────┘ └──────────┘  │
└─────────────────────────────┘
```

---

### 7.16 Join Session Screen

**Route:** `/join/:sessionId`  
Reached via deep link or QR code scan.

```
┌─────────────────────────────┐
│  ←                          │
│                             │
│  You're invited to a party! │
│                             │
│  ┌─── Keg Info ───────────┐ │
│  │  🍺  Pilsner Urquell   │ │
│  │  30 l  ·  4.4 %        │ │
│  │  Active  ·  12 people  │ │
│  │  Host: Jan Novák       │ │
│  └────────────────────────┘ │
│                             │
│  Your nickname              │
│  ┌─────────────────────┐    │
│  │  Ondřej             │    │  ← pre-filled from profile
│  └─────────────────────┘    │
│                             │
│  Visibility settings        │
│  ┌─────────────────────────┐│
│  │ 🔓 Show my stats   [ON] ││  ← toggle
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ 🔓 Show BAC est.   [OFF]││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────┐    │
│  │   Join Session 🍺   │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

---

### 7.17 Profile Screen

**Route:** `/profile`

```
┌─────────────────────────────┐
│  ←  My Profile     ✏ Edit  │
│                             │
│  ┌────────────────────────┐ │
│  │  [large avatar circle] │ │
│  │  Jan Novák             │ │
│  │  jan@example.com       │ │
│  └────────────────────────┘ │
│                             │
│  ─── Statistics ──────────  │
│  Weight  80 kg              │
│  Age     30                 │
│  Gender  Male               │
│                             │
│  ─── Privacy settings ────  │
│  ┌─────────────────────────┐│
│  │ Show stats to others [ON]││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ Show BAC estimate  [OFF] ││
│  └─────────────────────────┘│
│                             │
│  ─── Session History ─────  │
│  3 sessions joined          │
│  > View history             │
│                             │
│  Delete account             │  ← destructive, small text
└─────────────────────────────┘
```

**Edit Profile Sheet** (slides up on ✏ tap):  
Fields for nickname, weight, age, gender with Save / Cancel actions.

---

### 7.18 Settings Screen

**Route:** `/settings`

```
┌─────────────────────────────┐
│  ←  Settings                │
│                             │
│  ─── Notifications ───────  │
│  Someone pours for me  [ON] │
│  Keg nearly empty      [ON] │
│  Keg done              [ON] │
│                             │
│  ─── Display ─────────────  │
│  Volume units   [Litres ▾]  │  ← dropdown (L / mL / pints)
│                             │
│  ─── Account ─────────────  │
│  Change password            │
│  Sign out                   │
│  Delete account             │
└─────────────────────────────┘
```

---

### 7.19 Session History Screen

**Route:** `/sessions/history`

```
┌─────────────────────────────┐
│  ←  Past Sessions           │
│                             │
│  ┌───────────────────────┐  │
│  │  🍺 Pilsner Urquell   │  │
│  │  Mar 9, 2026  Done    │  │
│  │  28.4 l  12 people    │  │
│  │  My total: €5.60      │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  🍺 Kozel Dark        │  │
│  │  Mar 1, 2026  Done    │  │
│  │  20.0 l  8 people     │  │
│  └───────────────────────┘  │
│             …               │
└─────────────────────────────┘
```
Tapping a card → Keg Session Detail in read-only/done state.

---

### 7.20 Export to Settle Up Screen

**Route:** `/keg/:sessionId/settle`  
Accessible to session creator only after keg is done.

```
┌─────────────────────────────┐
│  ←  Export to Settle Up     │
│                             │
│  Review the bill split      │
│                             │
│  ┌───────────────────────┐  │
│  │  🏠 Novák family      │  │
│  │  Jan + Eva            │  │
│  │  Total: €14.00        │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  👤 Tomáš (solo)      │  │
│  │  Total: €4.00         │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────────────────┐    │
│  │  Export to Settle Up│    │  ← amber button; calls Cloud Function
│  └─────────────────────┘    │
│                             │
│  ℹ Settle Up will create a  │
│    group with these amounts.│  ← info note
└─────────────────────────────┘
```
- Loading overlay during Cloud Function call.
- On success: confirmation card with link to the Settle Up group.

---

### 7.21 About Screen

**Route:** `/about`

Logo, version, open-source licences, privacy policy link, "Drink Responsibly" disclaimer.

---

## 8. Navigation Map

```
Splash
  ├── Welcome (unauthenticated)
  │     ├── Sign In
  │     │     └── Forgot Password
  │     └── Register
  └── Home (authenticated)
        ├── [Drawer] Profile
        ├── [Drawer] Settings
        ├── [Drawer] About
        ├── [Drawer] Sign Out
        ├── Session History
        ├── [FAB] Create Keg Session (step 1 → step 2)
        └── Keg Session Detail
              ├── [Tab] Participants
              ├── [Tab] Accounts
              ├── [Sheet] I Got Beer (volume picker)
              │     └── [Sheet] Pour for Someone
              ├── [Sheet] User Detail Card
              ├── [Sheet] Joint Account Management
              ├── Share Session
              ├── [Creator] Export to Settle Up
              └── [Creator] Edit Session
```

Deep link `/join/:sessionId` → Auth check → Join Session → Keg Session Detail

---

## 9. Key Component Library

| Component | Description |
|-----------|-------------|
| `KegFillBar` | Animated vertical bar shaped like a keg silhouette, amber-to-foam gradient |
| `StatTile` | Label + Roboto Mono value, optional trend arrow, used in stats cards |
| `ParticipantChip` | Avatar + nickname chip with optional live-activity green dot |
| `PourButton` | Full-width amber CTA with haptic + particle animation on tap |
| `VolumePickerSheet` | Bottom sheet with predefined chips + manual stepper input |
| `SessionCard` | Summary card used in Home and History lists |
| `UserDetailCard` | Bottom-sheet card showing per-user stats and a quick-pour shortcut |
| `JoinLinkSheet` | QR code + deep link + share-intent buttons |
| `SnackbarPour` | Amber snackbar with "Undo" action (5 s timeout) |
| `BacBanner` | BAC estimate strip with "Drink Responsibly" note; hidden if opted out |



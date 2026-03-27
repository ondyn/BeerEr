# Beerer Screenshot & Mock Data Scripts

## 1. Populate Mock Data

Fills Firestore with realistic test data for Google Play Store screenshots.

### Prerequisites

```bash
# Option A: Application Default Credentials
gcloud auth application-default login

# Option B: Service account key
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
```

### Run

```bash
node scripts/populate_mock_data.js
```

### What it creates

| Data | Count | Details |
|------|-------|---------|
| Firebase Auth users | 8 | Czech names, verified email, varied demographics |
| Firestore profiles | 8 | With weight, age, gender, avatar icons |
| Active keg sessions | 5 | `created`, `active` (×3), `paused` states |
| Finished keg sessions | 5 | `done` state, various beers, fully consumed |
| Pours | ~200+ | Distributed across users, realistic timestamps |
| Joint accounts | 6 | Couples and groups across sessions |
| Guest users | 2 | Manual (non-app) participants |

### Login for screenshots

```
Email:    tomas.novak@beerer.app
Password: Test1234!
```

---

## 2. Take Screenshots

Automated screenshot capture across three emulators.

### Emulators

| AVD Name | Category | Form Factor |
|----------|----------|-------------|
| pixel_8A | phone | Phone (1080×2400) |
| Tablet7 | tablet7 | 7" Tablet |
| Tablet10 | tablet10 | 10" Tablet |

### Usage

```bash
# Full automated (flutter drive through all screens)
./scripts/take_screenshots.sh --drive

# Quick capture of current screen on each emulator
./scripts/take_screenshots.sh --adb

# Help
./scripts/take_screenshots.sh --help
```

### Output

Screenshots are saved to:
```
screenshots/
├── phone/          # pixel_8A screenshots
├── tablet7/        # Tablet7 screenshots
└── tablet10/       # Tablet10 screenshots
```

### Google Play Store Requirements

- **Format:** PNG or JPEG
- **Max size:** 8 MB each
- **Aspect ratio:** 16:9 or 9:16
- **Dimensions:** 320–3,840 px per side

### Screenshots Captured

| # | Screen | Description |
|---|--------|-------------|
| 01 | Welcome | Onboarding / sign-in screen |
| 02 | Sign In | Email + password form |
| 03 | Home | Active keg sessions list |
| 04 | Drawer | Navigation drawer |
| 05 | Keg Detail | Active keg with fill bar |
| 06 | Keg Stats | Statistics section (time, volume, cost) |
| 07 | Participants | Participant list with avatars |
| 08 | Nearly Empty | Keg almost depleted |
| 09 | Paused Keg | Keg in paused state |
| 10 | History | Past keg sessions |
| 11 | Done Detail | Finished keg overview |
| 12 | Cost Breakdown | Per-user costs |
| 13 | Profile | User profile with avatar |
| 14 | Create Keg | New keg form |
| 15 | Keg Info | Beer details from BeerWeb |
| 16 | Share Session | QR code + share links |
| 17 | Settings | App settings |


### tips
- Permission dialog detected — tapping Allow
- Do automated sign in
```
/Users/ondrejhnyk/Library/Android/sdk/emulator/emulator -avd pixel_8A -no-window -no-audio -no-snapshot-load

# Kill the emulator, wipe its userdata, restart
/Users/ondrejhnyk/Library/Android/sdk/platform-tools/adb -s emulator-5554 emu kill
sleep 3
# Wipe userdata and start fresh
/Users/ondrejhnyk/Library/Android/sdk/emulator/emulator -avd pixel_8A -wipe-data -no-snapshot -no-window -no-audio &
echo "Emulator restarting with wiped data..."

/Users/ondrejhnyk/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell df /data

firebase firestore:delete --all-collections --project ondyn-beerer

```
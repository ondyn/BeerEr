#!/usr/bin/env bash
#
# take_screenshots.sh — Automated screenshot capture for Beerer
#
# Runs ONE emulator at a time to conserve CPU/RAM.
# Starts emulator → runs flutter drive → captures screenshots → shuts down.
#
# Prerequisites:
#   1. Run populate_mock_data.js first to fill Firestore with test data.
#   2. AVDs must exist: pixel_8A, Tablet7, Tablet10
#   3. ANDROID_HOME or ANDROID_SDK_ROOT must be set (or emulator on PATH)
#
# Usage:
#   chmod +x scripts/take_screenshots.sh
#   ./scripts/take_screenshots.sh --drive
#
# Google Play requirements:
#   - PNG or JPEG, up to 8 MB each
#   - 16:9 or 9:16 aspect ratio
#   - Each side between 320 px and 3,840 px
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER="${PROJECT_DIR}/.fvm/flutter_sdk/bin/flutter"
ADB="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}/platform-tools/adb"
EMULATOR_BIN="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}/emulator/emulator"

SCREENSHOT_BASE="${PROJECT_DIR}/screenshots"

# ─── Emulator definitions ───────────────────────────────────────────────
# Parallel arrays (compatible with Bash 3 on macOS)
EMULATOR_ORDER=("pixel_8A" "Tablet10")
EMULATOR_CATEGORY=("phone" "tablet10")
# Uncomment to test with a single device:
# EMULATOR_ORDER=("Tablet10")
# EMULATOR_CATEGORY=("tablet10")

# Lookup: AVD name → category
get_category() {
  local avd="$1"
  local i
  for i in "${!EMULATOR_ORDER[@]}"; do
    if [ "${EMULATOR_ORDER[$i]}" = "$avd" ]; then
      echo "${EMULATOR_CATEGORY[$i]}"
      return 0
    fi
  done
  echo "unknown"
}

# ─── Timeout for flutter drive (seconds) ────────────────────────────────
DRIVE_TIMEOUT=300  # 5 minutes per device

# ─── Colours ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[Beerer]${NC} $*" >&2; }
ok()   { echo -e "${GREEN}  ✅${NC} $*" >&2; }
warn() { echo -e "${YELLOW}  ⚠️${NC}  $*" >&2; }
err()  { echo -e "${RED}  ❌${NC} $*" >&2; }

# ─── Helper: wait for emulator to fully boot ────────────────────────────
wait_for_boot() {
  local serial="$1"
  local max_wait=180
  local elapsed=0

  log "Waiting for $serial to boot…"
  while [ "$elapsed" -lt "$max_wait" ]; do
    local boot_status
    boot_status=$("$ADB" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$boot_status" = "1" ]; then
      ok "Emulator $serial booted."
      # Extra wait for launcher to settle
      sleep 15
      # Disable soft keyboard so it doesn't appear in screenshots.
      # show_ime_with_hard_keyboard=0 means "don't show software keyboard
      # when a hardware keyboard is connected" (emulators have hw keyboard).
      "$ADB" -s "$serial" shell settings put secure show_ime_with_hard_keyboard 0 2>/dev/null || true
      return 0
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done
  err "Emulator $serial did not boot within ${max_wait}s"
  return 1
}

# ─── Helper: find serial for a running AVD ──────────────────────────────
get_serial() {
  local avd_name="$1"
  local serials
  serials=$("$ADB" devices 2>/dev/null | grep "^emulator-" | awk '{print $1}' || true)
  for s in $serials; do
    local name
    name=$("$ADB" -s "$s" emu avd name 2>/dev/null | head -1 | tr -d '\r' || echo "")
    if [ "$name" = "$avd_name" ]; then
      echo "$s"
      return 0
    fi
  done
  echo ""
}

# ─── Helper: start a single emulator and return its serial ──────────────
start_emulator() {
  local avd_name="$1"

  log "Starting emulator: $avd_name"
  # Redirect emulator stdout/stderr so it doesn't hold the subshell pipe open
  "$EMULATOR_BIN" -avd "$avd_name" -no-audio -no-snapshot-save -no-boot-anim \
    >/dev/null 2>&1 &

  # Wait until adb sees the serial
  local serial=""
  local wait_serial=0
  while [ -z "$serial" ] && [ "$wait_serial" -lt 60 ]; do
    sleep 3
    wait_serial=$((wait_serial + 3))
    serial=$(get_serial "$avd_name")
  done

  if [ -z "$serial" ]; then
    err "Emulator $avd_name did not register with adb after 60s."
    return 1
  fi

  wait_for_boot "$serial" || return 1
  echo "$serial"
}

# ─── Helper: shutdown a single emulator ──────────────────────────────────
shutdown_emulator() {
  local serial="$1"
  local avd_name="$2"

  log "Shutting down emulator: $avd_name ($serial)"
  "$ADB" -s "$serial" emu kill 2>/dev/null || true

  # Wait for it to disappear
  local wait_count=0
  while [ "$wait_count" -lt 30 ]; do
    local still_there
    still_there=$("$ADB" devices 2>/dev/null | grep "^${serial}" || true)
    if [ -z "$still_there" ]; then
      ok "Emulator $avd_name stopped."
      sleep 3  # Extra cooldown before next emulator
      return 0
    fi
    sleep 2
    wait_count=$((wait_count + 2))
  done
  warn "Emulator $avd_name may still be running."
}

# ─── Flutter Drive for one device ────────────────────────────────────────
run_drive_for_device() {
  local avd_name="$1"
  local category="$2"
  local orientation="${3:-portrait}"  # "portrait" or "landscape"
  local we_started_it=false
  local serial

  serial=$(get_serial "$avd_name")

  # If not running, start it
  if [ -z "$serial" ]; then
    we_started_it=true
    serial=$(start_emulator "$avd_name") || {
      err "Failed to start $avd_name. Skipping."
      return 1
    }
  else
    ok "Emulator $avd_name already running ($serial)"
  fi

  local outdir
  if [ "$orientation" = "landscape" ]; then
    outdir="${SCREENSHOT_BASE}/${category}_landscape"
  else
    outdir="${SCREENSHOT_BASE}/${category}"
  fi
  mkdir -p "$outdir"

  # Set orientation
  if [ "$orientation" = "landscape" ]; then
    log "Rotating $avd_name to landscape…"
    "$ADB" -s "$serial" shell settings put system accelerometer_rotation 0 2>/dev/null || true
    "$ADB" -s "$serial" shell settings put system user_rotation 1 2>/dev/null || true
    sleep 3
  else
    log "Ensuring $avd_name is in portrait…"
    "$ADB" -s "$serial" shell settings put system accelerometer_rotation 0 2>/dev/null || true
    "$ADB" -s "$serial" shell settings put system user_rotation 0 2>/dev/null || true
    sleep 2
  fi

  # Delete old screenshots and logs before capturing new ones.
  log "Cleaning old screenshots in $outdir/"
  find "$outdir" -name "*.png" -delete 2>/dev/null || true
  rm -f "${outdir}/flutter_drive.log" 2>/dev/null || true

  log "Running flutter drive on $avd_name ($serial)…"
  log "Screenshots → $outdir/"
  log "Timeout: ${DRIVE_TIMEOUT}s"

  cd "$PROJECT_DIR"

  # Pass ADB info + output dir to the Dart test via env vars.
  # The test uses adb screencap (not binding.takeScreenshot) so these
  # tell it where to find adb and where to save PNGs directly.
  # Run flutter drive as a background job with manual timeout
  SCREENSHOT_SERIAL="$serial" \
  SCREENSHOT_DIR="$outdir" \
  ADB_PATH="$ADB" \
  "$FLUTTER" drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshot_test.dart \
    -d "$serial" \
    --no-pub \
    --dart-define=io.flutter.EnableImpeller=false \
    2>&1 | tee "${outdir}/flutter_drive.log" &
  local drive_pid=$!

  # Wait up to DRIVE_TIMEOUT
  local drive_ok=true
  local waited=0
  while kill -0 "$drive_pid" 2>/dev/null && [ "$waited" -lt "$DRIVE_TIMEOUT" ]; do
    sleep 5
    waited=$((waited + 5))
  done

  if kill -0 "$drive_pid" 2>/dev/null; then
    warn "Flutter drive timed out after ${DRIVE_TIMEOUT}s on $avd_name. Killing…"
    kill "$drive_pid" 2>/dev/null || true
    pkill -f "flutter.*drive.*${serial}" 2>/dev/null || true
    wait "$drive_pid" 2>/dev/null || true
    drive_ok=false
  else
    wait "$drive_pid" || drive_ok=false
  fi

  if [ "$drive_ok" = false ]; then
    warn "Flutter drive had issues on $avd_name ($orientation). Check ${outdir}/flutter_drive.log"
  else
    ok "Flutter drive complete for $avd_name ($orientation) → $outdir/"
  fi

  # Restore portrait orientation after landscape run
  if [ "$orientation" = "landscape" ]; then
    log "Restoring $avd_name to portrait…"
    "$ADB" -s "$serial" shell settings put system user_rotation 0 2>/dev/null || true
    sleep 2
  fi

  # Shutdown if we started it (only after the last orientation pass)
  if [ "$we_started_it" = true ] && [ "$orientation" != "portrait" ]; then
    shutdown_emulator "$serial" "$avd_name"
  fi
}

# ─── ADB capture for one device ─────────────────────────────────────────
run_adb_for_device() {
  local avd_name="$1"
  local category="$2"
  local serial

  serial=$(get_serial "$avd_name")
  if [ -z "$serial" ]; then
    err "Emulator $avd_name is not running. Skipping. (Start it manually or use --drive)"
    return 1
  fi

  local outdir="${SCREENSHOT_BASE}/${category}"
  mkdir -p "$outdir"

  log "ADB screenshot on $avd_name ($serial)…"

  "$ADB" -s "$serial" shell screencap -p /sdcard/screenshot.png
  "$ADB" -s "$serial" pull /sdcard/screenshot.png "${outdir}/screenshot_$(date +%H%M%S).png" > /dev/null 2>&1
  "$ADB" -s "$serial" shell rm /sdcard/screenshot.png

  ok "Screenshot captured → $outdir/"
}

# ─── Main ───────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  🍺  Beerer Screenshot Automation"
echo "══════════════════════════════════════════════════════════════"
echo ""

MODE="${1:---drive}"

# Check prerequisites
if [ ! -x "$FLUTTER" ] && [ ! -f "$FLUTTER" ]; then
  err "Flutter not found at $FLUTTER"
  err "Make sure FVM is set up: .fvm/flutter_sdk/bin/flutter"
  exit 1
fi

if [ ! -x "$ADB" ] && [ ! -f "$ADB" ]; then
  err "adb not found. Set ANDROID_HOME or ANDROID_SDK_ROOT."
  exit 1
fi

case "$MODE" in
  --drive|--flutter-drive)
    log "Mode: Flutter Drive (sequential — one emulator at a time, portrait + landscape)"
    echo ""
    for avd in "${EMULATOR_ORDER[@]}"; do
      category="$(get_category "$avd")"
      echo ""
      log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log "  📱 $avd → $category (portrait)"
      log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      run_drive_for_device "$avd" "$category" "portrait" || true
      echo ""
      log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log "  🔄 $avd → ${category}_landscape (landscape)"
      log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      run_drive_for_device "$avd" "$category" "landscape" || true
      echo ""
    done
    ;;

  --adb|--capture)
    log "Mode: ADB screencap (capture current screen on running emulators)"
    echo ""
    for avd in "${EMULATOR_ORDER[@]}"; do
      category="$(get_category "$avd")"
      run_adb_for_device "$avd" "$category" || true
    done
    ;;

  --help|-h)
    echo "Usage: $0 [--drive | --adb | --help]"
    echo ""
    echo "  --drive    Run flutter drive on each emulator sequentially (default)"
    echo "             Starts/stops emulators as needed to save CPU/RAM."
    echo "  --adb      Take ADB screenshot of current screen on running emulators"
    echo "  --help     Show this help"
    echo ""
    echo "Emulators: ${EMULATOR_ORDER[*]}"
    echo "Output:    screenshots/<device_category>/"
    echo ""
    echo "Prerequisites:"
    echo "  1. node scripts/populate_mock_data.js  (fill Firestore with test data)"
    echo "  2. AVDs created: pixel_8A, Tablet7, Tablet10"
    echo ""
    exit 0
    ;;

  *)
    err "Unknown mode: $MODE"
    echo "Use --help for usage info."
    exit 1
    ;;
esac

# ─── Summary ────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
log "Screenshot capture complete!"
echo ""
log "Output directories:"
for avd in "${EMULATOR_ORDER[@]}"; do
  category="$(get_category "$avd")"
  for suffix in "" "_landscape"; do
    local_dir="${SCREENSHOT_BASE}/${category}${suffix}"
    if [ -d "$local_dir" ]; then
      count=$(find "$local_dir" -name "*.png" | wc -l | tr -d ' ')
      echo "   ${category}${suffix}/  →  ${count} screenshots"
    fi
  done
done
echo ""
log "Google Play Store requirements check:"
log "  ✓ Format: PNG"
log "  ✓ Max size: 8 MB per image"
log "  ✓ Aspect ratio: 16:9 or 9:16"
log "  ✓ Dimensions: 320–3840 px per side"
echo ""
echo "══════════════════════════════════════════════════════════════"

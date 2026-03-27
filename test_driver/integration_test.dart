/// Host-side test driver for screenshot integration test.
///
/// Runs on the Mac (not on the device). Responsibilities:
///  1. Auto-dismiss the Android notification-permission dialog that appears
///     when the app calls NotificationService.init() → requestPermission().
///     We poll for it via `adb shell dumpsys window windows` and tap "Allow"
///     with `adb shell input keyevent` so the Dart code unblocks.
///  2. Poll /sdcard/ss_request_* sentinel files written by the test.
///     When a request file appears, run `adb screencap`, pull the PNG to the
///     host output dir, then write /sdcard/ss_done_NAME so the test unblocks.
///
/// This avoids binding.convertFlutterSurfaceToImage() which freezes the
/// Flutter surface so that all subsequent adb screencaps show the same
/// frozen frame.
///
/// Usage:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d `<serial>`
library;

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Taps the "Allow" button on any Android runtime-permission dialog.
Future<bool> _dismissPermissionDialog(
    String adbBin, List<String> serialArgs) async {
  final dump = await Process.run(
      adbBin, [...serialArgs, 'shell', 'dumpsys', 'window', 'windows']);
  final out = dump.stdout as String;
  if (!out.contains('permissioncontroller')) return false;

  print('🔔  Permission dialog detected — tapping Allow');

  // Tap the Allow button (right side of dialog on 1080×1920).
  await Process.run(adbBin,
      [...serialArgs, 'shell', 'input', 'tap', '756', '1468']);
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // Keyboard fallback.
  await Process.run(
      adbBin, [...serialArgs, 'shell', 'input', 'keyevent', 'KEYCODE_TAB']);
  await Process.run(
      adbBin, [...serialArgs, 'shell', 'input', 'keyevent', 'KEYCODE_TAB']);
  await Process.run(
      adbBin, [...serialArgs, 'shell', 'input', 'keyevent', 'KEYCODE_ENTER']);
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return true;
}

/// Captures a screenshot via adb screencap and pulls it to [localPath].
/// Dismisses the soft keyboard first to avoid capturing it in screenshots.
Future<bool> _captureScreenshot(
    String adbBin, List<String> serialArgs, String name, String outDir) async {
  final devicePath = '/data/local/tmp/ss_cap_$name.png';
  final localPath = '$outDir/$name.png';

  final cap = await Process.run(
      adbBin, [...serialArgs, 'shell', 'screencap', '-p', devicePath]);
  if (cap.exitCode != 0) {
    print('⚠️  screencap failed [$name]: ${cap.stderr}');
    return false;
  }

  final pull = await Process.run(
      adbBin, [...serialArgs, 'pull', devicePath, localPath]);
  if (pull.exitCode != 0) {
    print('⚠️  adb pull failed [$name]: ${pull.stderr}');
    return false;
  }

  await Process.run(adbBin, [...serialArgs, 'shell', 'rm', devicePath]);

  final size = File(localPath).lengthSync();
  print('📸  Saved: $localPath  (${(size / 1024).round()} KB)');
  return true;
}

Future<void> main() async {
  final String serial = Platform.environment['SCREENSHOT_SERIAL'] ?? '';
  final String outDir = Platform.environment['SCREENSHOT_DIR'] ?? 'screenshots';
  final String adbBin = Platform.environment['ADB_PATH'] ??
      '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb';
  final List<String> serialArgs =
      serial.isNotEmpty ? ['-s', serial] : <String>[];

  print('🖥️  Driver started  adb=$adbBin  serial=$serial  outDir=$outDir');

  await Directory(outDir).create(recursive: true);

  // Clean up any leftover sentinel files from a previous run.
  await Process.run(adbBin, [
    ...serialArgs, 'shell', 'run-as', 'com.beerer.beerer',
    'sh', '-c',
    'rm -f cache/ss_request_* cache/ss_done_* /data/local/tmp/ss_cap_*',
  ]);

  // ── Background permission-dialog dismisser (first 20 s) ──────────────
  var dialogDismissed = false;
  Timer.periodic(const Duration(seconds: 1), (t) async {
    if (dialogDismissed || t.tick > 20) { t.cancel(); return; }
    final dismissed = await _dismissPermissionDialog(adbBin, serialArgs);
    if (dismissed) { dialogDismissed = true; t.cancel(); }
  });

  // ── Sentinel-file screenshot poller ──────────────────────────────────
  // The test writes ss_request_NAME into its app cache dir (only writable
  // by the app process). We poll via `adb shell run-as com.beerer.beerer
  // ls cache/` every second, screencap when we see a request, then write
  // ss_done_NAME back into the cache dir via run-as so the test unblocks.
  var screenshotBusy = false;
  Timer.periodic(const Duration(seconds: 1), (t) async {
    if (t.tick > 600 || screenshotBusy) return;

    final ls = await Process.run(adbBin, [
      ...serialArgs, 'shell', 'run-as', 'com.beerer.beerer',
      'ls', 'cache/',
    ]);
    if (ls.exitCode != 0) return;

    final files = (ls.stdout as String).split('\n');
    for (final file in files) {
      final f = file.trim();
      if (!f.startsWith('ss_request_')) continue;

      final name = f.replaceFirst('ss_request_', '');
      print('📷  Capturing screenshot: $name');
      screenshotBusy = true;

      await _captureScreenshot(adbBin, serialArgs, name, outDir);

      // Signal the test that we're done, then remove the request file.
      await Process.run(adbBin, [
        ...serialArgs, 'shell', 'run-as', 'com.beerer.beerer',
        'touch', 'cache/ss_done_$name',
      ]);
      await Process.run(adbBin, [
        ...serialArgs, 'shell', 'run-as', 'com.beerer.beerer',
        'rm', '-f', 'cache/ss_request_$name',
      ]);

      screenshotBusy = false;
      break; // Handle one request per tick; next tick picks up the next.
    }
  });

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args]) async {
      // Not used — screenshot signaling is via sentinel files.
      return true;
    },
  );
}

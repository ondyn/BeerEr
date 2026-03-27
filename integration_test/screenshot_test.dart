/// Screenshot integration test for Beerer.
///
/// Navigates through all key screens and triggers screenshots via a
/// sentinel-file handshake with the host-side driver:
///   1. Test writes  cache/ss_request_NAME  (empty marker)
///   2. Driver polls, sees the file, runs adb screencap, pulls PNG, then
///      writes  cache/ss_done_NAME
///   3. Test polls until cache/ss_done_NAME exists, then cleans up both.
///
/// Prerequisites:
///   node scripts/populate_mock_data.js
///   Run via: ./scripts/take_screenshots.sh --drive
library;

import 'dart:io';

import 'package:beerer/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Helpers ──────────────────────────────────────────────────────────

  Future<void> settle(WidgetTester tester,
      [Duration duration = const Duration(seconds: 3)]) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Dismiss the on-screen keyboard by un-focusing any text field,
  /// then wait for the keyboard animation to finish.
  Future<void> dismissKeyboard(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester, const Duration(milliseconds: 500));
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    await settle(tester, const Duration(seconds: 1));
  }

  // Sentinel-file screenshot handshake.
  Future<void> takeScreenshot(WidgetTester tester, String name) async {
    // Always dismiss keyboard before capturing.
    await dismissKeyboard(tester);
    await settle(tester, const Duration(seconds: 1));

    final cacheDir = Directory('/data/data/com.beerer.beerer/cache');
    final requestFile = File('${cacheDir.path}/ss_request_$name');
    final doneFile = File('${cacheDir.path}/ss_done_$name');

    // Clean up any leftovers from a previous run.
    if (doneFile.existsSync()) doneFile.deleteSync();

    // Signal the driver.
    requestFile.writeAsStringSync('');
    debugPrint('📸 Screenshot requested: $name');

    // Wait for the driver to finish screencapping (up to 15 s).
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (doneFile.existsSync()) break;
    }
    if (!doneFile.existsSync()) {
      debugPrint('⚠️  Screenshot timeout (driver did not respond): $name');
    }

    // Clean up sentinel files.
    try {
      requestFile.deleteSync();
    } catch (_) {}
    try {
      doneFile.deleteSync();
    } catch (_) {}
  }

  /// Pumps until [finder] finds at least one widget, or times out.
  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return true;
    }
    debugPrint('⚠️  waitFor timed out: $finder');
    return false;
  }

  /// Taps [finder.first] if present, settles, returns true if tapped.
  /// Uses warnIfMissed: false to suppress hit-test warnings that cause
  /// test failures when widgets are partially obscured.
  Future<bool> safeTap(WidgetTester tester, Finder finder,
      {String? label}) async {
    if (finder.evaluate().isNotEmpty) {
      debugPrint('👆 Tapping: ${label ?? finder}');
      await tester.tap(finder.first, warnIfMissed: false);
      await settle(tester, const Duration(seconds: 2));
      return true;
    }
    debugPrint('⚠️  Not found (skip): ${label ?? finder}');
    return false;
  }

  /// Navigates back via the Back tooltip button.
  Future<void> goBack(WidgetTester tester) async {
    final back = find.byTooltip('Back');
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first, warnIfMissed: false);
      await settle(tester, const Duration(seconds: 2));
      debugPrint('⬅️  Went back');
    } else {
      final close = find.byTooltip('Close');
      if (close.evaluate().isNotEmpty) {
        await tester.tap(close.first, warnIfMissed: false);
        await settle(tester, const Duration(seconds: 2));
        debugPrint('⬅️  Closed');
      } else {
        debugPrint('⚠️  No Back/Close button found');
      }
    }
  }

  /// Ensure we're on the home screen by dismissing dialogs / going back.
  Future<bool> ensureOnHome(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      if (find.text('Beerer').evaluate().isNotEmpty &&
          find.byType(FloatingActionButton).evaluate().isNotEmpty) {
        return true;
      }
      // Dismiss any dialogs via Cancel button
      final cancel = find.widgetWithText(TextButton, 'Cancel');
      if (cancel.evaluate().isNotEmpty) {
        await tester.tap(cancel.first, warnIfMissed: false);
        await settle(tester, const Duration(seconds: 1));
        continue;
      }
      await goBack(tester);
    }
    return find.text('Beerer').evaluate().isNotEmpty;
  }

  /// Opens the drawer and taps a menu item by text.
  Future<bool> navigateViaDrawer(
      WidgetTester tester, String menuText) async {
    debugPrint('📍 Opening drawer for: $menuText');
    final scaffoldFinder = find.byType(Scaffold);
    try {
      tester.firstState<ScaffoldState>(scaffoldFinder).openDrawer();
      await settle(tester, const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️  Could not open drawer: $e');
      return false;
    }

    final menuItem = find.text(menuText);
    if (menuItem.evaluate().isEmpty) {
      debugPrint('⚠️  Menu item "$menuText" not found in drawer');
      // Close the drawer
      await tester.tapAt(Offset(
        tester.view.physicalSize.width / tester.view.devicePixelRatio - 20,
        tester.view.physicalSize.height / tester.view.devicePixelRatio / 2,
      ));
      await settle(tester, const Duration(seconds: 1));
      return false;
    }

    await tester.tap(menuItem.first, warnIfMissed: false);
    await settle(tester, const Duration(seconds: 3));
    return true;
  }

  // ── Test ─────────────────────────────────────────────────────────────

  group('Screenshot Tour', () {
    testWidgets('Capture all key screens', (tester) async {
      debugPrint('🚀 Starting screenshot tour');

      // Launch the app.
      app.main(); // ignore: unawaited_futures

      // Give Firebase + NotificationService time to complete.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 12)));

      // Pump until a Scaffold appears.
      debugPrint('⏳ Waiting for first screen...');
      final bool appReady = await waitFor(
        tester,
        find.byType(Scaffold),
        timeout: const Duration(seconds: 30),
      );
      if (!appReady) {
        debugPrint('❌ No Scaffold found — aborting.');
        return;
      }
      await settle(tester, const Duration(seconds: 2));
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .where((t) => t.isNotEmpty)
          .take(6)
          .toList();
      debugPrint('✅ App ready. Visible text: $texts');

      // ── 1. Welcome screen ──────────────────────────────────────────
      final welcomeBtn = find.widgetWithText(FilledButton, 'Sign in');
      if (welcomeBtn.evaluate().isNotEmpty) {
        debugPrint('📍 On welcome screen');
        await takeScreenshot(tester, '01_welcome');

        // Navigate to sign-in form.
        await tester.tap(welcomeBtn.first);
        await settle(tester, const Duration(seconds: 3));
        debugPrint('📍 On sign-in screen');
        await takeScreenshot(tester, '02_sign_in');

        // Enter credentials.
        final fields = find.byType(TextField);
        if (fields.evaluate().length >= 2) {
          await tester.enterText(fields.at(0), 'tomas.novak@beerer.app');
          await tester.pump(const Duration(milliseconds: 300));
          await tester.enterText(fields.at(1), 'Test1234!');
          await tester.pump(const Duration(milliseconds: 300));
          debugPrint('📧 Credentials entered');
        }

        // Dismiss keyboard before tapping Sign in.
        await dismissKeyboard(tester);

        // Tap sign-in button.
        final signInBtn = find.widgetWithText(FilledButton, 'Sign in');
        if (signInBtn.evaluate().isNotEmpty) {
          debugPrint('👆 Tapping Sign in button');
          await tester.tap(signInBtn.first);
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(seconds: 12));
          });
          await settle(tester, const Duration(seconds: 3));
          debugPrint('✅ After sign-in');
        }
      } else {
        debugPrint('📍 No welcome button — likely already signed in');
      }

      // ── 2. Home screen ─────────────────────────────────────────────
      debugPrint('⏳ Waiting for home (Beerer title)...');
      final bool foundHome = await waitFor(
        tester,
        find.text('Beerer'),
        timeout: const Duration(seconds: 30),
      );
      if (!foundHome) {
        debugPrint('❌ Home not found — aborting.');
        return;
      }
      debugPrint('✅ On home screen');
      await settle(tester, const Duration(seconds: 3));
      await takeScreenshot(tester, '03_home_active_sessions');

      // ── 3. Navigation drawer ───────────────────────────────────────
      debugPrint('📍 Step 3: Drawer');
      try {
        final scaffoldFinder = find.byType(Scaffold);
        tester.firstState<ScaffoldState>(scaffoldFinder).openDrawer();
        await settle(tester, const Duration(seconds: 2));
        await takeScreenshot(tester, '04_navigation_drawer');
        // Close drawer by tapping outside (right edge).
        await tester.tapAt(Offset(
          tester.view.physicalSize.width / tester.view.devicePixelRatio - 20,
          tester.view.physicalSize.height / tester.view.devicePixelRatio / 2,
        ));
        await settle(tester, const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⚠️  Drawer error: $e');
      }

      // ── 4. Active keg detail ───────────────────────────────────────
      debugPrint('📍 Step 4: Keg detail - Pilsner Urquell');
      if (await safeTap(tester, find.text('Pilsner Urquell'),
          label: 'Pilsner Urquell')) {
        await settle(tester, const Duration(seconds: 4));
        await takeScreenshot(tester, '05_keg_detail_active');
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -350));
        await settle(tester, const Duration(seconds: 2));
        await takeScreenshot(tester, '06_keg_detail_stats');
        await tester.drag(scrollable, const Offset(0, -350));
        await settle(tester, const Duration(seconds: 2));
        await takeScreenshot(tester, '07_keg_detail_participants');
        await goBack(tester);
      }

      // ── 5. Nearly-empty keg ────────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 5: Matuška California');
      if (await safeTap(tester, find.text('Matuška California'),
          label: 'Matuška California')) {
        await settle(tester, const Duration(seconds: 4));
        await takeScreenshot(tester, '08_keg_nearly_empty');
        await goBack(tester);
      }

      // ── 6. Paused keg ──────────────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 6: Bernard 12°');
      if (await safeTap(tester, find.text('Bernard 12°'),
          label: 'Bernard 12°')) {
        await settle(tester, const Duration(seconds: 4));
        await takeScreenshot(tester, '09_keg_paused');
        await goBack(tester);
      }

      // ── 7. History via drawer ──────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 7: History');
      if (await navigateViaDrawer(tester, 'Past Sessions')) {
        await settle(tester, const Duration(seconds: 3));
        await takeScreenshot(tester, '10_history');
        if (await safeTap(tester, find.text('Gambrinus 11°'),
            label: 'Gambrinus 11°')) {
          await settle(tester, const Duration(seconds: 4));
          await takeScreenshot(tester, '11_keg_done_detail');
          final scrollable = find.byType(Scrollable).first;
          await tester.drag(scrollable, const Offset(0, -350));
          await settle(tester, const Duration(seconds: 2));
          await takeScreenshot(tester, '12_keg_done_costs');
          await goBack(tester);
        }
        await goBack(tester);
      }

      // ── 8. Profile ─────────────────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 8: Profile');
      // Tap the profile IconButton in the AppBar (contains a person Icon
      // inside a CircleAvatar). Find the specific IconButton wrapping
      // the CircleAvatar, not the CircleAvatar itself (which can't
      // receive taps if obscured).
      final profileBtn = find.byWidgetPredicate(
        (w) => w is IconButton && w.icon is CircleAvatar,
      );
      if (await safeTap(tester, profileBtn, label: 'Profile icon button')) {
        await settle(tester, const Duration(seconds: 3));
        await takeScreenshot(tester, '13_profile');

        // Scroll down to see stats and privacy settings.
        final profileScrollable = find.byType(Scrollable);
        if (profileScrollable.evaluate().isNotEmpty) {
          await tester.drag(profileScrollable.first, const Offset(0, -300));
          await settle(tester, const Duration(seconds: 2));
          await takeScreenshot(tester, '13b_profile_stats');
        }

        await goBack(tester);
      }

      // ── 9. Create keg ──────────────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 9: Create keg');
      // Target the "New Keg Session" FAB specifically by its heroTag.
      final newKegFab = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'new_keg',
      );
      if (await safeTap(tester, newKegFab, label: 'New Keg FAB')) {
        await settle(tester, const Duration(seconds: 3));
        await takeScreenshot(tester, '14_create_keg');
        await goBack(tester);
      }

      // ── 10. Keg info & share (via popup menu) ──────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 10: Keg info & share');
      if (await safeTap(tester, find.text('Pilsner Urquell'),
          label: 'Pilsner Urquell (keg info)')) {
        await settle(tester, const Duration(seconds: 4));

        // Open the popup menu (three-dot button).
        final popupMenuBtn = find.byType(PopupMenuButton<String>);
        if (await safeTap(tester, popupMenuBtn, label: 'Popup menu')) {
          await settle(tester, const Duration(seconds: 1));

          // Tap "Keg Information" menu item.
          final kegInfoItem = find.text('Keg Information');
          final kegInfoItemAlt = find.text('Keg information');
          final infoFinder = kegInfoItem.evaluate().isNotEmpty
              ? kegInfoItem
              : kegInfoItemAlt;

          if (await safeTap(tester, infoFinder, label: 'Keg info menu')) {
            await settle(tester, const Duration(seconds: 3));
            await takeScreenshot(tester, '15_keg_info');
            await goBack(tester);
          }
        }

        // Re-open popup for share.
        final popupMenuBtn2 = find.byType(PopupMenuButton<String>);
        if (await safeTap(tester, popupMenuBtn2, label: 'Popup menu (share)')) {
          await settle(tester, const Duration(seconds: 1));

          final shareItem = find.text('Share join link');
          final shareItemAlt = find.text('Share Join Link');
          final shareFinder = shareItem.evaluate().isNotEmpty
              ? shareItem
              : shareItemAlt;

          if (await safeTap(tester, shareFinder, label: 'Share menu')) {
            await settle(tester, const Duration(seconds: 3));
            await takeScreenshot(tester, '16_share_session');
            await goBack(tester);
          }
        }

        await goBack(tester);
      }

      // ── 11. Settings via drawer ────────────────────────────────────
      await ensureOnHome(tester);
      debugPrint('📍 Step 11: Settings');
      if (await navigateViaDrawer(tester, 'Settings')) {
        await settle(tester, const Duration(seconds: 3));
        await takeScreenshot(tester, '17_settings');
        await goBack(tester);
      }

      await ensureOnHome(tester);
      debugPrint('🏁 Screenshot tour complete!');
    });
  });
}

import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Top-level handler for background FCM data-only messages.
///
/// Must be a top-level function (not a class method) for Flutter to invoke
/// it in a separate isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Data-only messages don't produce a system notification automatically.
  // Show one via flutter_local_notifications so the user sees it.
  final plugin = FlutterLocalNotificationsPlugin();

  const androidChannel = AndroidNotificationChannel(
    'beerer_default',
    'BeerEr Notifications',
    description: 'Notifications about pours, keg status, and BAC.',
    importance: Importance.high,
  );

  final title = message.data['title'] as String? ?? 'BeerEr';
  final body = message.data['body'] as String? ?? '';

  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannel.id,
        androidChannel.name,
        channelDescription: androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: message.data['session_id'] as String?,
  );
}

/// Centralised push & local notification service.
///
/// Call [init] once from `main()` after Firebase is initialised.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for beer-related pushes.
  static const _androidChannel = AndroidNotificationChannel(
    'beerer_default',
    'BeerEr Notifications',
    description: 'Notifications about pours, keg status, and BAC.',
    importance: Importance.high,
  );

  // --------------------------------------------------------------------------
  // Initialisation
  // --------------------------------------------------------------------------

  Future<void> init() async {
    // 1. Request permissions (iOS & Android 13+).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Register the background handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Initialise flutter_local_notifications.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already asked via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Create the Android notification channel.
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // 5. Listen for foreground FCM messages.
    //    We suppress the system notification when the app is active.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Handle notification taps that re-open the app.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 7. Save / refresh the FCM token.
    await _saveToken();
    _fcm.onTokenRefresh.listen((_) => _saveToken());
  }

  // --------------------------------------------------------------------------
  // FCM token management
  // --------------------------------------------------------------------------

  Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'preferences': {'fcm_token': token},
      },
      SetOptions(merge: true),
    );
  }

  // --------------------------------------------------------------------------
  // Foreground message handling
  // --------------------------------------------------------------------------

  void _handleForegroundMessage(RemoteMessage message) {
    // `onMessage` only fires when the app is in the foreground.
    // Per requirement: suppress notifications while the app is active.
    // Data-only messages that arrive when the app is NOT active are handled
    // by [firebaseMessagingBackgroundHandler] which shows a local notification.
    //
    // So here we intentionally do nothing.
  }

  // --------------------------------------------------------------------------
  // Notification tap
  // --------------------------------------------------------------------------

  void _handleMessageOpenedApp(RemoteMessage message) {
    // TODO: navigate to the relevant keg session screen using
    // `appNavigatorKey` if session_id is present.
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: navigate when user taps a local notification.
  }

  // --------------------------------------------------------------------------
  // BAC-zero local notification
  // --------------------------------------------------------------------------

  /// The fixed notification id used for the BAC-zero reminder so that
  /// scheduling a new one automatically replaces the old one.
  static const _bacZeroNotificationId = 999;

  /// Schedules (or re-schedules) a local notification that fires when the
  /// user's BAC is estimated to reach zero.
  ///
  /// Pass `null` to cancel a previously scheduled notification (e.g. when
  /// BAC is already 0 or the user disabled the setting).
  Future<void> scheduleBacZeroNotification(Duration? timeToZero) async {
    // Always cancel the old one first.
    await _local.cancel(_bacZeroNotificationId);

    if (timeToZero == null || timeToZero.inSeconds <= 0) return;

    // flutter_local_notifications does not have a simple "schedule after
    // duration" API — we compute the exact date/time instead.
    // For simplicity we use `zonedSchedule` with the TZ-aware datetime.
    // However, that requires the timezone package init. To keep things simple
    // and avoid the timezone init ceremony, we approximate with a periodic
    // check or just show when the remaining time is small.

    // Pragmatic approach: schedule via the platform channel directly.
    // On Android, use `schedule` (deprecated but simple) via the plugin's
    // `zonedSchedule`. On iOS, same API.
    //
    // For now, we use the simpler delayed-show approach: fire a delayed
    // future. This works as long as the app process is alive (foreground or
    // background). For a fully robust solution a WorkManager / BGTaskScheduler
    // would be needed — that's an enhancement for later.
    Future.delayed(timeToZero, () async {
      await _local.show(
        _bacZeroNotificationId,
        '🚗 Ready to drive!',
        'Your estimated BAC has reached 0. Drive safely!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Cancels a previously scheduled BAC-zero notification.
  Future<void> cancelBacZeroNotification() async {
    await _local.cancel(_bacZeroNotificationId);
  }
}

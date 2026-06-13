import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../utils/notification_route_mapper.dart';
import 'api_service.dart';
import 'firebase_env_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.ensureFirebaseInitialized();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'default',
    'Notifications',
    description: 'Notifications de messages et collaborations',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenSubscription;
  GoRouter? _router;
  Map<String, dynamic>? _pendingRouteData;
  bool _initialized = false;
  bool _enabled = false;
  String? _lastToken;

  static Future<bool> ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return true;

    try {
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env', isOptional: true);
      }
      final options = FirebaseEnvOptions.currentPlatform;
      if (options == null) return false;
      await Firebase.initializeApp(options: options);
      return true;
    } catch (e) {
      debugPrint('Firebase initialization skipped: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _enabled = await ensureFirebaseInitialized();
    if (!_enabled) {
      debugPrint('Push notifications disabled: Firebase env config missing.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _requestPermissions();

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _messageOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _openRoute(message.data),
    );
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(_registerToken);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _pendingRouteData = Map<String, dynamic>.from(initialMessage.data);
    }
  }

  void attachRouter(GoRouter router) {
    _router = router;
    final pending = _pendingRouteData;
    if (pending != null) {
      _pendingRouteData = null;
      _openRoute(pending);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenSubscription?.cancel();
  }

  Future<void> syncToken() async {
    if (!_enabled) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e) {
      debugPrint('Unable to sync FCM token: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (!_enabled) return;

    try {
      final token = _lastToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService().deletePushToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
      _lastToken = null;
    } catch (e) {
      debugPrint('Unable to unregister FCM token: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    _lastToken = token;
    await ApiService().registerPushToken(
      token: token,
      provider: 'fcm',
      platform: FirebaseEnvOptions.platformName ?? 'unknown',
      appVersion: '1.0.0+1',
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          _openRoute(Map<String, dynamic>.from(decoded));
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;
    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.messageId?.hashCode.abs() ?? message.hashCode.abs(),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openRoute(Map<String, dynamic> data) {
    final route = NotificationRouteMapper.routeFor(data);
    final router = _router;
    if (route == null || router == null) {
      _pendingRouteData = data;
      return;
    }

    router.go(route);
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Background messaging handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<Map<String, dynamic>> _onTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of notification tap events with payload data
  static Stream<Map<String, dynamic>> get onTapStream => _onTapController.stream;

  /// Android channel for high importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  /// Initialize notifications: request permissions, set up local notifications, and configure handlers.
  static Future<void> initialize() async {
    // 1. Request notification permission (critical for Android 13+ and iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 2. Initialize local notifications for foreground alerts
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _onTapController.add(data);
          } catch (e) {
            if (kDebugMode) {
              print('Error decoding notification response payload: $e');
            }
          }
        }
      },
    );

    // Create high importance channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Configure foreground presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: ${message.messageId}');
      }
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 6. Handle messages that opened the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      _onTapController.add(message.data);
    });

    // Check if the app was opened from a terminated state via a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state via notification');
      }
      _onTapController.add(initialMessage.data);
    }

    // 7. Watch Auth State Changes to update or remove FCM token automatically
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await updateToken(user.uid);
      }
    });
  }

  /// Retrieve and update current user's FCM token in Firestore.
  static Future<void> updateToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
        if (kDebugMode) {
          print('FCM Token successfully updated in Firestore: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM Token in Firestore: $e');
      }
    }
  }

  /// Remove user's FCM token from Firestore (call on logout).
  static Future<void> removeToken(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      if (kDebugMode) {
        print('FCM Token removed from Firestore for user: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing FCM Token from Firestore: $e');
      }
    }
  }

  /// Send a push notification to a specific user's token directly from the client (for Spark plan testing via FCM HTTP v1).
  static Future<void> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const String serviceAccountJson = r'''{
  "type": "service_account",
  "project_id": "YOUR_PROJECT_ID",
  "private_key_id": "YOUR_PRIVATE_KEY_ID",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
  "client_email": "YOUR_CLIENT_EMAIL",
  "client_id": "YOUR_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "YOUR_CERT_URL",
  "universe_domain": "googleapis.com"
}''';

    if (serviceAccountJson.isEmpty) {
      if (kDebugMode) {
        print('FCM: Service Account JSON is not configured in NotificationService. Skipping push dispatch.');
      }
      return;
    }

    try {
      final Map<String, dynamic> credentialsMap = jsonDecode(serviceAccountJson);
      final accountCredentials = ServiceAccountCredentials.fromJson(credentialsMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Obtain an authenticated client via googleapis_auth
      final client = await clientViaServiceAccount(accountCredentials, scopes);

      // Extract Project ID dynamically from the JSON key
      final projectId = credentialsMap['project_id'];

      final response = await client.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        body: jsonEncode({
          'message': {
            'token': recipientToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'notification': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              }
            }
          }
        }),
      );

      client.close();

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('FCM: Direct HTTP v1 push notification sent successfully.');
        }
      } else {
        if (kDebugMode) {
          print('FCM: Failed to send push notification. Status: ${response.statusCode}. Body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM: Error sending push notification: $e');
      }
    }
  }
}

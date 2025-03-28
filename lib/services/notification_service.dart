import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize native timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Make sure you have this icon

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // Callback for when a notification is received while the app is in the foreground (iOS legacy)
  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, navigating to a specific page...
    print('Notification received while foregrounded (iOS legacy): $id, $title, $body, $payload');
  }

  // Callback for when a notification response is received (user taps on notification)
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      print('Notification Response Payload: $payload');
    }
    // Here you could navigate to a specific screen based on the payload
  }

  // Request permissions for iOS and Android 13+
  Future<bool?> requestPermissions() async {
     bool? result;
     // For iOS
     if (defaultTargetPlatform == TargetPlatform.iOS) {
        result = await flutterLocalNotificationsPlugin
           .resolvePlatformSpecificImplementation<
               IOSFlutterLocalNotificationsPlugin>()
           ?.requestPermissions(
             alert: true,
             badge: true,
             sound: true,
           );
     } 
     // For Android 13+ (API 33+)
     else if (defaultTargetPlatform == TargetPlatform.android) {
         final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
             flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                 AndroidFlutterLocalNotificationsPlugin>();
         result = await androidImplementation?.requestNotificationsPermission(); // Changed from requestPermission
     }
     return result;
  }

  // --- Core Notification Methods ---

  Future<void> scheduleNotification({
    required int id, // Unique ID for the notification
    required String title,
    required String body,
    required DateTime scheduledDateTime, // The exact time to show the notification
    String? payload, // Optional data to pass with notification
  }) async {
    if (scheduledDateTime.isBefore(DateTime.now())) {
        print("Scheduled time ${scheduledDateTime.toIso8601String()} is in the past. Notification not scheduled.");
        return; // Don't schedule notifications for past times
    }
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local), // Use local timezone
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_channel_id', // Channel ID
          'Shift Notifications', // Channel Name
          channelDescription: 'Notifications for upcoming shifts',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time, // Adjust if needed for repeating
    );
     print("Notification scheduled for ID: $id at ${scheduledDateTime.toIso8601String()}");
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
     print("Cancelled notification with ID: $id");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
     print("Cancelled all notifications");
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'test_channel_id', // Channel ID
            'Test Notifications', // Channel Name
            channelDescription: 'Channel for testing notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      999, // Unique ID for test notification
      'Test Notification',
      'If you see this, notifications are working!',
      platformChannelSpecifics,
      payload: 'test_payload',
    );
     print("Showing test notification");
  }
} 
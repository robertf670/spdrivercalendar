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

    try {
      // Initialize native timezone database
      tz.initializeTimeZones();


      // --- Create Android Notification Channels ---
      const AndroidNotificationChannel shiftChannel = AndroidNotificationChannel(
        'shift_channel_id', // id
        'Shift Notifications', // name
        description: 'Notifications for upcoming shifts', // description
        importance: Importance.max,
      );

      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_channel_id', // id
        'Test Notifications', // name
        description: 'Channel for testing notifications', // description
        importance: Importance.max,
      );

      // Register the channels with the system
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPluginInstance =
          flutterLocalNotificationsPlugin;
      await flutterLocalNotificationsPluginInstance
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(shiftChannel);

      await flutterLocalNotificationsPluginInstance
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(testChannel);

      // --- End Create Android Notification Channels ---

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher'); 

      // iOS initialization settings
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
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


    } catch (e) {
      // Failed to initialize notifications, continue without notifications
    }

  }

  // Callback for when a notification is received while the app is in the foreground (iOS legacy)
  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {

  }

  // Callback for when a notification response is received (user taps on notification)
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null) {
      // Handle notification tap
    }
  }

  // Request permissions for iOS and Android 13+
  Future<bool?> requestPermissions() async {
     bool? result;
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
     else if (defaultTargetPlatform == TargetPlatform.android) {
         final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
             flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                 AndroidFlutterLocalNotificationsPlugin>();
         result = await androidImplementation?.requestNotificationsPermission(); 
     }
     return result;
  }

  // --- Use FLN zonedSchedule (Simplified version from previous attempt) ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now)) {

      return;
    }

    final delay = scheduledDateTime.difference(now);
    if (delay.isNegative) {

       return;
    }

    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.now(tz.local).add(delay);



    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime, 
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'shift_channel_id',
            'Shift Notifications',
            channelDescription: 'Notifications for upcoming shifts',
            importance: Importance.max, 
            priority: Priority.high, 
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, 
        payload: payload,
      );

    } catch (e) {
      // Failed to schedule notification
    }
  }

  // Use FLN cancel
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);

  }

  // Use FLN cancelAll
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();

  }

  // --- Keep Test Notification Method --- 
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'test_channel_id', 
            'Test Notifications', 
            channelDescription: 'Channel for testing notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'If you see this, notifications are working!',
      platformChannelSpecifics,
      payload: 'test_payload',
    );

  }

  // --- Keep Pending Notifications Method (for FLN) --- 
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingRequests = 
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      return pendingRequests;
    } catch (e) {
      // Failed to get pending notifications, return empty list
       return []; 
    }
  }
} 

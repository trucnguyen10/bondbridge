import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    print("Initializing time zones");
    tz.initializeTimeZones(); // Initialize the time zone database
    print("Time zones initialized");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo');
    print("Android Initialization Settings created");

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    print("Initialization Settings created");

    print("Initializing flutter local notifications plugin");
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print("Notification tapped with payload: ${response.payload}");
      },
    );
    print("Flutter local notifications plugin initialized");
  }

  Future<void> scheduleRandomDailyNotification() async {
    // Fetch all notifications from Firestore
    var notifications =
        await FirebaseFirestore.instance.collection('notifications').get();
    var notificationList = notifications.docs;
    if (notificationList.isEmpty) {
      print('No notifications to schedule');
      return;
    }

    // Randomly select a notification
    var randomNotification =
        notificationList[Random().nextInt(notificationList.length)].data();
    var content = randomNotification['content'];

    // Store the selected prompt in Firestore
    await FirebaseFirestore.instance
        .collection('daily_prompt')
        .doc('latest')
        .set({'content': content, 'timestamp': DateTime.now()});
    print('Scheduling notification with content: $content');
    print('time' + _nextInstanceOfTwelveFortyPM().toString());

    var androidDetails = const AndroidNotificationDetails(
      'daily_notification_channel_id',
      'Daily Notifications',
      channelDescription: 'Daily notification channel',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    // Schedule notification for a specific time (e.g., 12:40 PM local time)
    await flutterLocalNotificationsPlugin.zonedSchedule(0, 'Daily Reminder',
        content, _nextInstanceOfTwelveFortyPM(), platformDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  tz.TZDateTime _nextInstanceOfTwelveFortyPM() {
    // Set the time zone to EST
    final tz.Location estLocation = tz.getLocation('America/New_York');

    // Get the current time in EST
    final tz.TZDateTime nowEst = tz.TZDateTime.now(estLocation);
    print(nowEst.toString() + " now est");
    // Schedule for 12:40 PM EST
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        estLocation, nowEst.year, nowEst.month, nowEst.day, 8, 38);
    // If the scheduled time is in the past, add one day
    if (scheduledDate.isBefore(nowEst)) {
      scheduledDate = nowEst.add(const Duration(seconds: 10));
    }
    print(scheduledDate.toString());
    return scheduledDate;
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TestNotificationWidget {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> testNotification() async {
    var notifications =
        await FirebaseFirestore.instance.collection('notifications').get();
    var notificationList = notifications.docs;

    var randomNotification =
        notificationList[Random().nextInt(notificationList.length)].data();
    var content = randomNotification['content'];

    // Store the selected prompt in Firestore
    await FirebaseFirestore.instance
        .collection('dailyPrompts')
        .doc('current')
        .set({'prompt': content});

    print('Prompt' + content);

    var androidDetails = const AndroidNotificationDetails(
      'test_channel_id',
      'Test Channel',
      channelDescription: 'This is a test notification channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Topic Of The Day!',
      content,
      platformDetails,
    );
  }
}

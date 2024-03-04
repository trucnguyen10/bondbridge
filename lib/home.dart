// HomePage.dart

import 'package:flutter/material.dart';
import 'test_noti.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the App!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                TestNotificationWidget.testNotification();
              },
              child: Text('Test Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

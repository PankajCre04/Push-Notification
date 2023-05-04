import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_notification/const.dart';

class LocalNotificationServices {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
    );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static void display(RemoteMessage message) async {
    try {
      print("--> In Notification Method");
      Random random = Random();
      int id = random.nextInt(1000);
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "mychannel",
          "my channel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      );
      print("--> Random Is ${id}");
      await _flutterLocalNotificationsPlugin.show(
        id,
        message.notification?.title ?? "Random Title",
        message.notification?.title ?? "Random Body",
        notificationDetails,
      );
    } on Exception catch (error) {
      print("--> Notification Error ${error}");
    }
  }

  sendNotification(String title, String token) async {
    final data = {
      'Click_action': '',
      'id': '1',
      'status': 'done',
      'message': title,
    };

    try {
      http.Response response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{'title': title, 'body': 'You are followed by someone'},
          'priority': 'high',
          'data': data,
          'to': token,
        }),
      );
      if (response.statusCode == 200) {
        print("--> Success");
      } else {
        print("--> Error");
      }
    } catch (error) {
      print("-- Send Notification Error ${error}");
    }
  }

  Future createAndSubscribeToTopic(String topic, String token) async {
    final response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(<String, dynamic>{
        'to': '/topics/$topic',
        'registration_tokens': token,
      }),
    );
    if (response.statusCode == 200) {
      print('Successfully subscribed to topic $topic');
    } else if (response.statusCode == 207) {
      // If some tokens are invalid, they will still return a 200 OK response with a partial failure message
      final responseBody = jsonDecode(response.body);
      final results = responseBody['results'] as List<dynamic>;
      final errorIndexes = <int>[];

      for (var i = 0; i < results.length; i++) {
        final result = results[i] as Map<String, dynamic>;
        if (result.containsKey('error')) {
          errorIndexes.add(i);
        }
      }
      if (errorIndexes.isEmpty) {
        print('Successfully subscribed to topic $topic');
      } else {
        print('Failed to subscribe to topic $topic at indexes $errorIndexes');
      }
    } else {
      print('Failed to subscribe to topic $topic with error code ${response.statusCode}');
    }
  }
}

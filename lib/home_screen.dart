import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:push_notification/const.dart';
import 'package:push_notification/services/notification_services.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String token = "";
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessage.listen((event) {
      LocalNotificationServices.display(event);
    });
    requestPermission();
    getToken();
    // initInfo();
  }

  sendNotificationToTopic(String topic) async {
    final data = {
      'Click_action': '',
      'id': '1',
      'status': 'done',
      'message': "$topic",
    };

    try {
      http.Response response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'title': "$topic",
            'body': 'You are followed by someone'
          },
          'priority': 'high',
          'data': data,
          'to': '/topics/$topic',
        }),
      );

      if (response.statusCode == 200) {
        print("--> Success");
      } else {
        print("--> Error");
        print("--> ${response.statusCode}");
      }
    } catch (error) {
      print("-- Send Notification Error ${error}");
    }
  }

  sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Key=$serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_LOCAL_NOTIFICATION',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              'title': title,
              'body': body,
              'android_channe_id': "push_notification",
            },
            "to": token,
          },
        ),
      );
    } catch (error) {
      print("--> error");
    }
  }

  void addServiceFunctionality() async {
    await http.get(Uri.parse("url"));
  }

  initInfo() async {
    var androidInitializer =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSetting =
        InitializationSettings(android: androidInitializer);
    flutterLocalNotificationsPlugin.initialize(initializationSetting);
    await FirebaseMessaging.instance.subscribeToTopic('news');
    //  await FirebaseMessaging.instance.subscribeToTopic('sports');
    await FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("........... onMessage.............");
      print(
          "onMessage: ${message.notification?.title}/${message.notification?.body}");

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        "Push",
        "Push",
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        styleInformation: bigTextStyleInformation,
      );
      NotificationDetails platformChannelSpecific =
          NotificationDetails(android: androidNotificationDetails);
      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        platformChannelSpecific,
        payload: message.data['title'],
      );
    });
  }

  getToken() async {
    await FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        token = value.toString();
      });
      saveToken(); // saving fetched token.
    });
  }

  saveToken() async {
    await FirebaseFirestore.instance.collection("UserTokens").doc("users").set({
      'token': token,
    }, SetOptions(merge: true));
  }

  requestPermission() async {
    FirebaseMessaging messaging = await FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("--> user granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("--> user granted provisional permission");
    } else {
      print("--> user declined or not accepted permission");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Push Notification"),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print("--> Sending to Everyone");
                await LocalNotificationServices()
                    .sendNotification("Everyone", token);
              },
              child: const Text("Send Notification to Everyone"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                print("Sending to Sports");
                await sendNotificationToTopic("Sports");
              },
              child: const Text("Send Notification to Sports"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                print("Sending to News");
                await sendNotificationToTopic("News");
              },
              child: const Text("Send Notification to News"),
            ),
            const SizedBox(height: 30),
            const Divider(height: 2, thickness: 4),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                print('-->subscribe sports topic ');
                // await LocalNotificationServices().createAndSubscribeToTopic("Sports", token);
                await FirebaseMessaging.instance.subscribeToTopic("Sports");
              },
              child: const Text("Subscribe to Sports"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                print('-->subscribe news topic ');
                // await LocalNotificationServices().createAndSubscribeToTopic("News", token);
                await FirebaseMessaging.instance.subscribeToTopic("News");
              },
              child: const Text("Subscribe to News"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                print('-->Unsubscribe sports topic ');
                // await LocalNotificationServices().createAndSubscribeToTopic("Sports", token);
                await FirebaseMessaging.instance.unsubscribeFromTopic("Sports");
              },
              child: const Text("Unsubscribe to Sports"),
            ),
            ElevatedButton(
              onPressed: () async {
                print('-->Unsubscribe news topic');
                // await LocalNotificationServices().createAndSubscribeToTopic("News", token);
                await FirebaseMessaging.instance.unsubscribeFromTopic("News");
              },
              child: const Text("Unsubscribe to News"),
            ),
          ],
        ),
      )),
    );
  }
}

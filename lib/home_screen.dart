import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

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
    reuestPermission();
    getToken();
    initInfo();
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': '',
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
              'android_channe_id': "push",
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

  initInfo() {
    var androidInitializer =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSetting =
        InitializationSettings(android: androidInitializer);
    flutterLocalNotificationsPlugin.initialize(initializationSetting);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
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
      // token fetched now save token
      saveToken();
    });
  }

  saveToken() async {
    await FirebaseFirestore.instance.collection("UserTokens").doc("User1").set({
      'token': token,
    });
  }

  void reuestPermission() async {
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
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(hintText: "username"),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "title"),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(hintText: "body"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
                onPressed: () async {
                  String name = _usernameController.text.trim();
                  String title = _titleController.text.trim();
                  String body = _bodyController.text.trim();
                },
                child: const Text("Submit")),
          ],
        ),
      )),
    );
  }
}

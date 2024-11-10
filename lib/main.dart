import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chatScreen.dart';
import 'databaseHelper.dart';
import 'signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'showChats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.data}");

  await Firebase.initializeApp();
  //Initialize the user-specific database
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  await DatabaseHelper().initDatabase(currentUserId);
  // Check if there's data to save
  if (message.data.isNotEmpty) {
    await saveMessageToSQLite(message.data);  // Save the message data to SQLite
    //Show notification
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    showNotification();
    print('Message saved to SQLite');
  }
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> showNotification() async {
  // Remove the 'const' keyword as this is dynamically created
  var inboxStyle = InboxStyleInformation(
    ['Line 1', 'Line 2', 'Line 3', 'Line 4'], // Add as many lines as you want
    contentTitle: 'Multi-line Notification Title',
    summaryText: 'Summary of the notification',
  );

  // Remove 'const' keyword from AndroidNotificationDetails
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel_id', // Channel ID
    'channel_name', // Channel name
    //styleInformation: inboxStyle, // Pass the inbox style
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker', // Optional ticker for older Android versions
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // Display the notification
  await flutterLocalNotificationsPlugin.show(
    0, // Unique notification ID
    'Test Title', // Notification title
    'Test Body', // Notification body
    platformChannelSpecifics, // Notification details
    payload: 'Notification Payload', // Optional payload
  );
}
// Create a ValueNotifier to hold FCM data
ValueNotifier<Map<String, dynamic>?> fcmDataNotifier = ValueNotifier(null);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();




  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Register Firebase foreground message listener globally
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async{

    String fcmType = message.data['fcmtype'];
    if(fcmType=='chat'){
      print("Received foreground message: ${message.data}");

      // Check if there's data to save
      if (message.data.isNotEmpty) {
        // Pass the data to the ValueNotifier
        fcmDataNotifier.value = message.data;

        await saveMessageToSQLite(message.data);  // Save the message data to SQLite

        print('Message saved to SQLite');
      }

      if (message.notification != null) {
        print('Notification Title: ${message.notification!.title}');
        print('Notification Body: ${message.notification!.body}');
      }
    }else if(fcmType=='statusUpdate'){
      User? currentUser = FirebaseAuth.instance.currentUser;
      String currentUserId = currentUser?.uid ?? '';
      DatabaseHelper databaseHelper=DatabaseHelper();
      await databaseHelper.updateMessageReceivedStatus(messageId: message.data['messageId'], userId1: currentUserId, userId2: message.data['receiverId']);
    }
  });

  bool isLoggedIn = await checkLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// // Background message handler
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   User? currentUser = FirebaseAuth.instance.currentUser;
//   String currentUserId = currentUser?.uid ?? '';
//   DatabaseHelper databaseHelper=DatabaseHelper();
//   // Initialize SQLite and save the message
//   await saveMessageToSQLite(message.data);
// }
//
Future<void> saveMessageToSQLite(Map<String, dynamic> data) async {
  print("hgfds");
  // Timestamp timestamp = data['timestamp'] as Timestamp;
  // DateTime messageTime = timestamp.toDate();
  final timestampString = data['timestamp'];
  final timestamp = DateTime.parse(timestampString);

  final message = {
    'senderId':data['senderId'],
    'messageId':data['messageId'],
    'content':data['content'],
    'timestamp':timestamp.toString(),
    'messageType':data['messageType'],
  };
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  DatabaseHelper databaseHelper=DatabaseHelper();
  print("r");
  await databaseHelper.insertChat(currentUserId,data['senderId'],message);
  await updateReceivedStatus(data);
  print(message);
}


Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn= prefs.getBool('isLoggedIn') ?? false;
  if(isLoggedIn){
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    //Initialize the user-specific database
    await DatabaseHelper().initDatabase(currentUserId);
  }
  return isLoggedIn;
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({super.key,required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home:isLoggedIn?Home():Signin(),
    );
  }
}

//Update received status
Future<void> updateReceivedStatus(Map<String, dynamic> data)async{
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  CollectionReference messages = FirebaseFirestore.instance.collection('updateReceivedStatus');
  // Add a new document with the specified fields
  await messages.add({
    'userId': data['senderId'],
    'receiverId': currentUserId,
    'messageId': data['messageId'],
  });
}













































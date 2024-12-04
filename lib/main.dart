import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:translator/translator.dart';
import 'chatScreen.dart';
import 'databaseHelper.dart';
import 'signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'showChats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:http/http.dart' as http;





/// Store received file details in the database
Future<void> storeReceivedFile({
  required String senderId,
  required String receiverId,
  required String messageId,
  required String fileUrl,
  required String fileName,
  required String fileType,
  required size,
}) async {
  // Create a map of file details
  final fileDetails = {
    'name': fileName,
    'url': fileUrl,
    'size':size, // Placeholder if size is unknown initially
    'extension': fileType,
    'isDownloaded': 0, // Not downloaded yet
    'path': null, // To be updated upon download
  };
  await Firebase.initializeApp();
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  await DatabaseHelper().initDatabase(currentUserId);
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // Convert to JSON for storage
  String jsonString = jsonEncode(fileDetails);

  // Insert chat data in SQLite
  Map<String, dynamic> chatData = {
    'senderId': senderId,
    'messageId': messageId,
    'content': jsonString,
    'timestamp': DateTime.now().toIso8601String(),
    'messageType': 'file', // file type
    // 'isRead': 0,
    // 'isReceived': 1,
    'isDelivered': 0, // Flag to track download status
  };

  await _dbHelper.insertChat(receiverId, senderId, chatData);
}



Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  String fcmType = message.data['fcmtype'];
  await Firebase.initializeApp();
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  await DatabaseHelper().initDatabase(currentUserId);
  if (fcmType == 'chat') {

    if(message.data['messageType']=="file"){
      print("file received");
      String senderId=message.data['senderId'];
      String receiverId=message.data['receiverId'];
      String messageId = message.data['messageId'];
      String fileUrl=message.data['fileUrl'];
      String fileName=message.data['content'];
      String fileType=message.data['extension'];
      int size = int.parse(message.data['size'].toString());
      storeReceivedFile(size: size,senderId: senderId, receiverId: receiverId, messageId: messageId, fileUrl: fileUrl, fileName: fileName, fileType: fileType);

      User? currentUser = FirebaseAuth.instance.currentUser;
      String currentUserId = currentUser?.uid ?? '';
      DatabaseHelper db=DatabaseHelper();
      Map<String, String?> settings = await db.getUserNotificationSettings(currentUserId);
      if(settings['isSmartPingEnabled']!="yes"){
        await showNotification(message);
      }


    }else{
      print("Handling a background message: ${message.data}");


      User? currentUser = FirebaseAuth.instance.currentUser;
      String currentUserId = currentUser?.uid ?? '';


      if (message.data.isNotEmpty) {

        fcmDataNotifier.value = message.data;

        await saveMessageToSQLite(message.data);
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
        var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
        flutterLocalNotificationsPlugin.initialize(initializationSettings);

       // showNotification(message);
        User? currentUser = FirebaseAuth.instance.currentUser;
        String currentUserId = currentUser?.uid ?? '';
        DatabaseHelper db=DatabaseHelper();
        Map<String, String?> settings = await db.getUserNotificationSettings(currentUserId);
        if(settings['isSmartPingEnabled']=="yes"){
          final String apiKey = 'AIzaSyAh_L-SnXqAHCk8POf02nxQN_37Y4Gqxwo'; // Replace with your actual API key
          final String url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': "The user wants to receive notification only for: ${settings['onlyNotifiedFor']}. The message is ${message.data['content']}. If user should receive notification then give 5 starts ***** in response, if user should not receive notification then give 5 @@@@@ in response."},
                  ],
                },
              ],
            }),
          );

          if (response.statusCode == 200) {
            print(response.body);
            // Parse the JSON
            Map<String, dynamic> data = jsonDecode(response.body);

            // Extract the text content
            String text = data['candidates'][0]['content']['parts'][0]['text'];
            if (text.contains('*****')) {
              print("The text contains five continuous stars!");
              final mylansettings = await db.getLanguageTranslationSettings(message.data['senderId']);
              if(mylansettings?['isLanguageTranslationEnabled']==1){
                print("yes");
                User? user = FirebaseAuth.instance.currentUser;
                final translator = GoogleTranslator();
                var translation = await translator.translate("${message.data['content']}", to: mylansettings?["translateToKey"], from: mylansettings?["translateFromKey"]);
                await showNotification(message,translation.text);
                db.updateMessageContent(user!.uid, message.data['senderId'],message.data['messageId'], translation.text,mylansettings?["translateToKey"]);
                print("Message translated");
              }else{
                await showNotification(message);
              }
            }


          } else {

            print("Error");
          }
        }else{
          final mylansettings = await db.getLanguageTranslationSettings(message.data['senderId']);
          if(mylansettings?['isLanguageTranslationEnabled']==1){
            print("yes");
            User? user = FirebaseAuth.instance.currentUser;
            final translator = GoogleTranslator();
            var translation = await translator.translate("${message.data['content']}", to: mylansettings?["translateToKey"], from: mylansettings?["translateFromKey"]);
            await showNotification(message,translation.text);
            db.updateMessageContent(user!.uid, message.data['senderId'],message.data['messageId'], translation.text,mylansettings?["translateToKey"]);
            print("Message translated");
          }else{
            await showNotification(message);
          }
        }
       // DatabaseHelper db=DatabaseHelper();

        print('Message saved to SQLite');
      }
    }
  }else if(fcmType=="update_received_status"){
    print("background");
    updateReceivedStatusInDb(message);
  }
  else if(fcmType=="deleteMessage"){
    deleteMessageInDb(message);
  }
}

ValueNotifier<Map<String, dynamic>?> fcmDeleteNotifier = ValueNotifier(null);
Future<void> deleteMessageInDb(RemoteMessage message) async {
  DatabaseHelper databaseHelper = DatabaseHelper();
  String messageId = message.data['messageId'];
  String receiverId= message.data['receiverId'];
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  await databaseHelper.deleteMessageById(messageId, currentUserId, receiverId);
  fcmDeleteNotifier.value = Map<String, dynamic>.from(message.data);
}

ValueNotifier<Map<String, dynamic>?> fcmUpdateReceivedStatusNotifier = ValueNotifier(null);

Future<void> updateReceivedStatusInDb(RemoteMessage message) async {
  String messageId = message.data['messageId'];
  String receiverId= message.data['receiverId'];
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  DatabaseHelper databaseHelper = DatabaseHelper();
  await databaseHelper.updateReceivedStatus(messageId: messageId,userId1: currentUserId,userId2: receiverId);
  fcmUpdateReceivedStatusNotifier.value = Map<String, dynamic>.from(message.data);
  print("Message ID $messageId");
  print("yesssssssssssssssssssssssssssssssssss");
}


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> showNotification(RemoteMessage message,[String translated=""]) async {
  String senderName = message.data['username'] ?? 'Unknown Sender';
  String messageContent = message.data['content'] ?? 'No Content';

  int generate8DigitId() {
    final random = Random();
    // Generate a random 8-digit number between 10,000,000 and 99,999,999
    return 10000000 + random.nextInt(90000000);
  }

  int notificationId = generate8DigitId();

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    // actions: <AndroidNotificationAction>[
    //   AndroidNotificationAction(
    //     'ACTION_REPLY', // Unique action identifier
    //     'Reply', // Label for the action
    //     //icon: '@drawable/ic_reply', // Optional, provide a drawable icon
    //   ),
    // ],

  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    notificationId, // Unique notification ID
    senderName,
    translated==""?messageContent:translated,
    platformChannelSpecifics,
    payload: 'Notification Payload',
  );
}

ValueNotifier<Map<String, dynamic>?> fcmDataNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    String fcmType = message.data['fcmtype'];
    if (fcmType == 'chat') {
      print("Received foreground message: ${message.data}");

      if(message.data['messageType']=="file"){
        print("file received");
        String senderId=message.data['senderId'];
        String receiverId=message.data['receiverId'];
        String messageId = message.data['messageId'];
        String fileUrl=message.data['fileUrl'];
        String fileName=message.data['content'];
        String fileType=message.data['extension'];
        int size = int.parse(message.data['size'].toString());
        storeReceivedFile(size: size,senderId: senderId, receiverId: receiverId, messageId: messageId, fileUrl: fileUrl, fileName: fileName, fileType: fileType);

      }
      else  {
        if((message.data.isNotEmpty)){
          // fcmDataNotifier.value = message.data;
          await saveMessageToSQLite(message.data);
          print('Message saved to SQLite');
          DatabaseHelper db=DatabaseHelper();
          final settings = await db.getLanguageTranslationSettings(message.data['senderId']);
          if(settings?['isLanguageTranslationEnabled']==1){
            print("yes");
            User? user = FirebaseAuth.instance.currentUser;
            final translator = GoogleTranslator();
            var translation = await translator.translate("${message.data['content']}", to: settings?["translateToKey"], from: settings?["translateFromKey"]);
            db.updateMessageContent(user!.uid, message.data['senderId'],message.data['messageId'], translation.text,settings?["translateToKey"]);
            print("Message translated");
          }
        }

      }

      if (message.notification != null) {
        print('Notification Title: ${message.notification!.title}');
        print('Notification Body: ${message.notification!.body}');
      }

      User? currentUser = FirebaseAuth.instance.currentUser;
      String currentUserId = currentUser?.uid ?? '';
      DatabaseHelper db=DatabaseHelper();
      Map<String, String?> settings = await db.getUserNotificationSettings(currentUserId);
      if(settings['isSmartPingEnabled']=="yes"){
        final String apiKey = 'AIzaSyAh_L-SnXqAHCk8POf02nxQN_37Y4Gqxwo'; // Replace with your actual API key
        final String url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': "The user wants to receive notification only for: ${settings['onlyNotifiedFor']}. The message is ${message.data['content']}. If user should receive notification then give 5 starts ***** in response, if user should not receive notification then give 5 @@@@@ in response."},
                ],
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          print(response.body);
          // Parse the JSON
          Map<String, dynamic> data = jsonDecode(response.body);

          // Extract the text content
          String text = data['candidates'][0]['content']['parts'][0]['text'];
          if (text.contains('*****')) {
            print("The text contains five continuous stars!");
            final mylansettings = await db.getLanguageTranslationSettings(message.data['senderId']);
            if(mylansettings?['isLanguageTranslationEnabled']==1){
              print("yes");
              User? user = FirebaseAuth.instance.currentUser;
              final translator = GoogleTranslator();
              var translation = await translator.translate("${message.data['content']}", to: mylansettings?["translateToKey"], from: mylansettings?["translateFromKey"]);
              await showNotification(message,translation.text);
              db.updateMessageContent(user!.uid, message.data['senderId'],message.data['messageId'], translation.text,mylansettings?["translateToKey"]);
              print("Message translated");
            }else{
              await showNotification(message);
            }
          }


        } else {

          print("Error");
        }
      }else{
        final mylansettings = await db.getLanguageTranslationSettings(message.data['senderId']);
        if(mylansettings?['isLanguageTranslationEnabled']==1){
          print("yes");
          User? user = FirebaseAuth.instance.currentUser;
          final translator = GoogleTranslator();
          var translation = await translator.translate("${message.data['content']}", to: mylansettings?["translateToKey"], from: mylansettings?["translateFromKey"]);
          await showNotification(message,translation.text);
          db.updateMessageContent(user!.uid, message.data['senderId'],message.data['messageId'], translation.text,mylansettings?["translateToKey"]);
          print("Message translated");
        }else{
          await showNotification(message);
        }
      }
    } else if(fcmType=="update_received_status"){
      updateReceivedStatusInDb(message);
    }
    else if(fcmType=="deleteMessage"){
      print("unsend");
      deleteMessageInDb(message);
      print("\n\n\nMessageDeleted\n\n\n");
    }
  });

  bool isLoggedIn = await checkLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> saveMessageToSQLite(Map<String, dynamic> data) async {
  print("Saving message to SQLite");

  final timestampString = data['timestamp'];
  final timestamp = DateTime.parse(timestampString);

  final message = {
    'senderId': data['senderId'],
    'messageId': data['messageId'],
    'content': data['content'],
    'timestamp': timestamp.toString(),
    'messageType': data['messageType'],
  };

  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  DatabaseHelper databaseHelper = DatabaseHelper();
  await databaseHelper.insertChat(currentUserId, data['senderId'], message);
  await updateReceivedStatus(data);
  print('Message saved to database');
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    await DatabaseHelper().initDatabase(currentUserId);
  }

  return isLoggedIn;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? Home() : Signin(),
      //home:Signin(),
    );
  }
}

Future<void> updateReceivedStatus(Map<String, dynamic> data) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String currentUserId = currentUser?.uid ?? '';
  CollectionReference messages = FirebaseFirestore.instance.collection('updateReceivedStatus');

  await messages.add({
    'userId': data['senderId'],
    'receiverId': currentUserId,
    'messageId': data['messageId'],
  });
}

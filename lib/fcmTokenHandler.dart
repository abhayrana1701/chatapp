import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FCMTokenHandler {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> storeFCMToken(String userId) async {
    try {
      // Request permission to show notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? fcmToken = await _firebaseMessaging.getToken();

        if (fcmToken != null) {
          // Store FCM token in Firestore under the specified document ID
          await FirebaseFirestore.instance
              .collection('userDetails') // Collection name
              .doc(userId)               // Document ID (user ID)
              .set({'fcmtoken': fcmToken}, SetOptions(merge: true));

          print("FCM token stored successfully.");
        } else {
          print("Failed to retrieve FCM token.");
        }
      } else {
        print("Notification permission not granted.");
      }
    } catch (e) {
      print("Error storing FCM token: $e");
    }
  }
}

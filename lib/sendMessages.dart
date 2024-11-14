import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'databaseHelper.dart';

class SendMessages{


  //Function to send message
  static Future<String> sendTextMessage({
    required String receiverId,
    required String message,
    required messageId,
    required username,
  }) async {

    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    // Prepare the message data for sqflite
    final timestamp = DateTime.now().toIso8601String();
    Map<String, dynamic> messageDataForLocalDb = {
      'senderId': currentUserId,
      'messageId':messageId,
      'content': message,
      'timestamp': timestamp,
      'messageType': "text",
      'isRead':0,
      'isReceived':0,
      'isDelivered':0,

    };

    // Store the message in SQLite
    await DatabaseHelper().insertChat(
      currentUserId,receiverId,messageDataForLocalDb
    ).then((value) {
      print("Save to db");
    },);
    

    try {
      // Reference to the 'messages' subcollection inside 'chats'
      CollectionReference messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(getRoomId(receiverId,currentUserId))
          .collection('messages');

      // Prepare the message data for firestore
      Map<String, dynamic> messageData = {
        'senderId': currentUserId,
        'receiverId':receiverId,
        'content': message,
        'messageId':messageId,
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': "text",
        'isRead':0,
        'isReceived':0,
        'username':username
      };

      // Add the message to Firestore
      await messagesRef.add(messageData);

      //Success(Message Sent)
      await DatabaseHelper().updateMessageDeliveryStatus(
        userId1: currentUserId,
        userId2: receiverId,
        messageId: messageId,
        isDelivered: 1,
      );
      return messageId;
    } catch (e) {
      //Failed to send message
    }
    return "";
  }


  //Function to get room-id
  static String getRoomId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2];
    userIds.sort();
    return '${userIds[0]}_${userIds[1]}';
  }

}
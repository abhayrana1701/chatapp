import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mychatapplication/databaseHelper.dart';
import 'package:mychatapplication/sendMessages.dart';
import 'package:uuid/uuid.dart';

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick multiple files using FilePicker
  Future<List<PlatformFile>?> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      return result.files;
    } else {
      return null; // User canceled the picker
    }
  }

  /// Upload files to Firebase Storage and store in sqflite
  Future<void> uploadFiles(List<PlatformFile> files,
      {required String currentUserId,
        required String receiverId,
        required String type,
        required Function(Map<String, dynamic> chatData) onSavedInLocalDb,
        required Function(String messageId,int isDelivered) onDeliveryStatusUpdated,
      }) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Insert in database before uploading

    List messageIds=[];
    DatabaseHelper databaseHelper=DatabaseHelper();
    for(var file in files){
      //Generating unique id for each message
      var uuid=Uuid();
      final messageId=uuid.v4();
      messageIds.add(messageId);
      // Create a map of the file details
      final fileDetails = {
        'name': file.name,
        'path': file.path,
        'size': file.size,
        'extension':type=='file'?file.extension:file.name.split('.').last,
      };

      // Convert the map to a JSON string
      String jsonString = jsonEncode(fileDetails);

      Map<String, dynamic> chatData={
        'senderId':currentUserId,
        'messageId':messageId,
        'content':jsonString,
        'timestamp':DateTime.now().toIso8601String(),
        'messageType':type,
        'isRead':0,
        'isReceived':0,
        'isDelivered':-1,
      };

      await databaseHelper.insertChat(
          currentUserId,
          receiverId,
          chatData
      );

      onSavedInLocalDb(chatData);

    }

    int i=0;
    var messageId;
    for (var file in files) {
      try {
        // Upload each file to Firebase Storage
        final String filePath = 'uploads/${file.name}';
        // Read the file bytes
        final fileBytes = await File(file.path!).readAsBytes();
        UploadTask uploadTask = _storage.ref(filePath).putData(fileBytes);

        // Continue uploading even when switching screens
        uploadTask.whenComplete(() async {
          // Get the download URL once the upload is complete
          String downloadURL = await _storage.ref(filePath).getDownloadURL();
          print('File uploaded: $downloadURL');


          messageId=messageIds[i];
          i++;
          // Store the reference in Firestore
          await _firestore.collection('chats').doc(SendMessages.getRoomId(currentUserId, receiverId))
              .collection('messages').add({
            'fileUrl': downloadURL,
            'senderId':currentUserId,
            'content': file.name,
            'messageId':messageId,
            'timestamp': FieldValue.serverTimestamp(),
            'messageType': type,
            'isRead':0,
            'isReceived':0,
            'isDelivered':0
          });

          databaseHelper.updateMessageDeliveryStatus(messageId: messageId, isDelivered: 1, userId1: currentUserId, userId2: receiverId);
          try{
            print("yes ho gya");
            onDeliveryStatusUpdated(messageId,1);
          }catch(e){}

        }).catchError((e) {
          //If fail to deliver a message
          onDeliveryStatusUpdated(messageId,0);
          databaseHelper.updateMessageDeliveryStatus(messageId: messageId, isDelivered: 0, userId1: currentUserId, userId2: receiverId);
          print('Error uploading file: $e');
        });
      } catch (e) {
        //If fail to deliver a message
        onDeliveryStatusUpdated(messageId,0);
        databaseHelper.updateMessageDeliveryStatus(messageId: messageId, isDelivered: 0, userId1: currentUserId, userId2: receiverId);
        print('Error uploading file: ${file.name}, Error: $e');
      }
    }
  }
}

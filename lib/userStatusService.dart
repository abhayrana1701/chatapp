import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call this method when the user comes online
  void updateOnlineStatus() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    _firestore.collection('userDetails').doc(currentUserId).set({
      'lastScene': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  // Call this method when the user goes offline
  void updateOfflineStatus() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    _firestore.collection('userDetails').doc(currentUserId).update({
      'isOnline': false,
      'lastScene': FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastScene extends StatefulWidget {
  String receiverId;
  LastScene({super.key,required this.receiverId});

  @override
  State<LastScene> createState() => _LastSceneState();
}

class _LastSceneState extends State<LastScene> {


  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) {
      return 'Last seen time unavailable';
    }

    final now = DateTime.now();

    // Check if lastSeen is today
    if (now.day == lastSeen.day &&
        now.month == lastSeen.month &&
        now.year == lastSeen.year) {
      return 'Last seen today at ${DateFormat('hh:mm a').format(lastSeen)}';
    }

    // Check if lastSeen is yesterday
    final yesterday = now.subtract(Duration(days: 1));
    if (yesterday.day == lastSeen.day &&
        yesterday.month == lastSeen.month &&
        yesterday.year == lastSeen.year) {
      return 'Last seen yesterday at ${DateFormat('hh:mm a').format(lastSeen)}';
    }

    // Otherwise, show the date and time
    return 'Last seen on ${DateFormat('dd/MM/yyyy').format(lastSeen)} at ${DateFormat('hh:mm a').format(lastSeen)}';
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userDetails')
          .doc(widget.receiverId.toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return Center(child: CircularProgressIndicator()); // Show loading indicator
        }

        if (snapshot.hasError) {
          // return Text('Error: ${snapshot.error}'); // Handle errors
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // return Text('User not found'); // Handle document not found
        }

        // Retrieve data safely
        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        // Check for null userData
        if (userData == null) {
          return Text('No user data available'); // Handle null data
        }

        // Check the online status
        var isOnline = userData['isOnline'] ?? false; // Safely check for null values
        if (isOnline == true) {
          return Row(
            children: [
              Icon(Icons.circle, size: 10, color: Color.fromRGBO(124, 252, 0, 1)),
              SizedBox(width: 5),
              Text("Active Now", style: TextStyle(fontSize: 12)),
            ],
          );
        }

        // Handle last seen timestamp
        var lastSeenTimestamp = userData['lastScene'];
        String lastSeenText='';

        if(lastSeenTimestamp is Timestamp) {
          DateTime lastSeen = lastSeenTimestamp.toDate();
          lastSeenText = formatLastSeen(lastSeen); // Assuming formatLastSeen is defined elsewhere
        }

        return lastSeenText==""?Container():Text(lastSeenText, style: TextStyle(fontSize: 12));
      },
    );

  }
}

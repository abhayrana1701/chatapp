import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Add Contacts Module Components/showContact.dart';
import 'Add Contacts Module Components/showRequestsReceived.dart';

class AddContacts extends StatefulWidget {
  const AddContacts({super.key});

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {

  //TextEditingController
  TextEditingController searchController=TextEditingController();

  //Store Search results
  List<Map<String, dynamic>> searchResults = [];

  // To store user type (contact, requestSent, requestReceived)
  Map<String, String> userTypes = {};

  //Show loading status
  bool isLoading=false;

  //Function for searching/adding users
  Future<void> _searchUsers(String query) async {
    setState(() {
      isLoading = true;
      searchResults = [];
      userTypes = {}; // Clear previous user types
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    try {
      // Get current user's existing contacts, requests sent, and received
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(currentUserId)
          .get();

      if (currentUserDoc.exists) {
        // Get requestsSent, requestsReceived, and contacts
        QuerySnapshot requestsSentSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('requestsSent')
            .get();

        QuerySnapshot requestsReceivedSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('requestsReceived')
            .get();

        QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('contacts')
            .get();

        // Add all userIds from these subcollections to exclude from the search
        for (var doc in requestsSentSnapshot.docs) {
          userTypes[doc.id] = 'requestSent'; // Store type for icon display
        }

        for (var doc in requestsReceivedSnapshot.docs) {
          userTypes[doc.id] = 'requestReceived'; // Store type for icon display
        }

        for (var doc in contactsSnapshot.docs) {
          userTypes[doc.id] = 'contact'; // Store type for icon display
        }
      }

      // Perform search by username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff') // Ensures a range search
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in userSnapshot.docs) {
          if(currentUserId!=doc.id){ // Avoid showing current user in search result
            results.add(doc.data() as Map<String, dynamic>);
            userTypes[doc.id] ??= 'newUser'; // New user who isn't in contacts/requests
          }
      }

      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor:Colors.white,
        title: Text("Add contacts"),
      ),

      body:Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [

            TextField(

              controller: searchController,
              cursorColor: Color.fromRGBO(1,102,255,1),
              keyboardType: TextInputType.emailAddress,

              decoration: InputDecoration(
                fillColor: Color.fromRGBO(243,244,246,1,),
                filled:true,
                hintText: "Search...",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded border
                  borderSide: BorderSide(color: Colors.transparent), // No border by default
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded border
                  borderSide: BorderSide(color: Colors.white, width: 2), // Blue border when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded border
                  borderSide: BorderSide(color:Color.fromRGBO(1,102,255,1), width: 2),
                ),
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(left:15,right:10),
              ),

              onChanged: (value){
                if (value.isNotEmpty) {
                  _searchUsers(value);
                } else {
                  setState(() {
                    searchResults = [];
                  });
                }
              },

            ),

            searchResults.length==0?
            ShowRequestsReceived():
            ShowContact(contacts: searchResults,userTypes: userTypes,),

          ],
        ),
      )

    );
  }
}

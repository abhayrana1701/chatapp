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
  List<Map<String, dynamic>> requestsSent = [];
  List<Map<String, dynamic>> requestsReceived = [];
  List<Map<String, dynamic>> contacts = [];

  //Show loading status
  bool isLoading=false;

  //Function for searching/adding users
  Future<void> _searchUsers(String query) async {
    setState(() {
      isLoading = true;
      searchResults = [];
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

        List<Map<String, dynamic>> requestsSentResults = [];
        // Iterate through each document and add to results list
        for (var doc in requestsSentSnapshot.docs) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id; // Include the document ID if needed
          requestsSentResults.add(userData);
        }

        setState(() {
          requestsSent = requestsSentResults;
        });

        QuerySnapshot requestsReceivedSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('requestsReceived')
            .get();

        List<Map<String, dynamic>> requestsReceivedResults = [];
        // Iterate through each document and add to results list
        for (var doc in requestsReceivedSnapshot.docs) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id; // Include the document ID if needed
          requestsReceivedResults.add(userData);
        }

        setState(() {
          requestsReceived = requestsReceivedResults;
        });

        QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('contacts')
            .get();

        List<Map<String, dynamic>> contactsResults = [];
        // Iterate through each document and add to results list
        for (var doc in contactsSnapshot.docs) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id; // Include the document ID if needed
          contactsResults.add(userData);
        }

        setState(() {
          contacts = contactsResults;
        });

      }

      // Perform search by username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff') // Ensures a range search
          .get();

      List<Map<String, dynamic>> results = [];

      // Iterate through each document and add to results list
      for (var doc in userSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id; // Include the document ID if needed
        results.add(userData);
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
            ShowContact(refresh: (){setState(() {
              _searchUsers(searchController.text.toString());
            });},isClicked: false,searchResults: searchResults,requestsSent: requestsSent,requestsReceived: requestsReceived,contacts: contacts,),

          ],
        ),
      )

    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'contactsModuleChatItem.dart';
import 'contactsModuleAddNewContactOption.dart';
import 'databaseHelper.dart';

class Contacts extends StatefulWidget {
  const Contacts({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {

  @override
  void initState() {
    super.initState();
    _fetchStoredContacts();
    _loadAndStoreContacts();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> storedContacts = [];

  Future<void> _fetchStoredContacts() async {
    var data = await _dbHelper.getContacts();
    setState(() {
      storedContacts = data;
    });
  }

  Future<void> _loadAndStoreContacts() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    CollectionReference contactsList = FirebaseFirestore.instance
        .collection('userDetails')
        .doc(currentUserId.toString())
        .collection('contacts');

    QuerySnapshot querySnapshot = await contactsList.get();

    for (var doc in querySnapshot.docs) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(doc.id)
          .get();

      bool isContactExists = await _dbHelper.isContactExists(doc['userId']);

      if (!isContactExists) {
        Map<String, dynamic> contact = {
          'userId': userDoc['userId'],
          'username': userDoc['username'],
          'name': userDoc['name'],
          'profilePic': userDoc['profilePic'],
        };
        await _dbHelper.insertContact(contact);
        _fetchStoredContacts();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Contacts"),
      ),

      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          ContactsModuleAddNewContactOption(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text("Contacts on Flash"),
          ),

          Expanded(child: ContactsModuleChatItem(storedContacts: storedContacts)),

        ],
      )

    );
  }
}

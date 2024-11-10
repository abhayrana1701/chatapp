import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShowContact extends StatefulWidget {
  List<Map<String, dynamic>> contacts;
  Map<String, String> userTypes = {};
  ShowContact({super.key,required this.contacts,required this.userTypes});

  @override
  State<ShowContact> createState() => _ShowContactState();
}

class _ShowContactState extends State<ShowContact> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          itemCount: widget.contacts.length,
          itemBuilder: (context, index) {

            Map<String, dynamic> user = widget.contacts[index];
            String userId = user['userId'];

            // Determine the icon based on user type (contact, requestSent, requestReceived, newUser)
            IconData userIcon;
            if (widget.userTypes[userId] == 'contact') {
              userIcon = Icons.contacts;
            } else if (widget.userTypes[userId] == 'requestSent') {
              userIcon = Icons.send;
            } else if (widget.userTypes[userId] == 'requestReceived') {
              userIcon = Icons.inbox;
            } else {
              userIcon = Icons.person_add; // For new users not in any list
            }

            return Column(
              children: [
                Container(
                  height:50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Row(
                        children: [

                          Padding(
                            padding: EdgeInsets.only(right: MediaQuery.of(context).size.width*0.02,left:MediaQuery.of(context).size.width*0.02),
                            child: CircleAvatar(),
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user["name"],style: TextStyle(fontWeight: FontWeight.bold),),
                              Text(user["username"]),
                            ],
                          ),

                        ],
                      ),

                      IconButton(
                          onPressed: ()async{
                            User? currentUser = FirebaseAuth.instance.currentUser;
                            String currentUserId = currentUser?.uid ?? '';
                            await Future.wait([
                              FirebaseFirestore.instance
                                  .collection('userDetails')
                                  .doc(currentUserId.toString())
                                  .collection('contacts')
                                  .doc(userId)
                                  .set({
                                'userId': userId,
                                'isTranslationEnabled':0,
                                'translateTo':'none',
                                'translateFrom':'none',
                                'blocked': "false",
                              }),
                              FirebaseFirestore.instance
                                  .collection('userDetails')
                                  .doc(userId)
                                  .collection('contacts')
                                  .doc(currentUserId.toString())
                                  .set({
                                'userId': currentUserId.toString(),
                                'isTranslationEnabled':0,
                                'translateTo':'none',
                                'translateFrom':'none',
                                'blocked': "false"
                              }),
                            ]);
                          },
                          icon: Icon(userIcon,color: Color.fromRGBO(1,102,255,1),),
                      )

                    ],
                  ),
                ),

                Container(
                  height:0.5,
                  color:Colors.grey,
                )

              ],
            );
          },
      ),
    );
  }
}

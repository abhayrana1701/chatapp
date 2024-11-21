import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShowContact extends StatefulWidget {
  List<Map<String, dynamic>> searchResults;
  List<Map<String, dynamic>> requestsSent;
  List<Map<String, dynamic>> requestsReceived;
  List<Map<String, dynamic>> contacts;
  bool isClicked;
  Function refresh;
  ShowContact({super.key,required this.refresh,required this.isClicked,required this.searchResults,required this.requestsSent,required this.requestsReceived,required this.contacts});

  @override
  State<ShowContact> createState() => _ShowContactState();
}

class _ShowContactState extends State<ShowContact> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          itemCount: widget.searchResults.length,
          itemBuilder: (context, index) {

            Map<String, dynamic> user = widget.searchResults[index];
            String userId = user['userId'];

            User? currentUser = FirebaseAuth.instance.currentUser;

            return Column(
              children: [
                Padding(
                  padding:EdgeInsets.only(top:10),
                  child: Container(

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Color.fromRGBO(243,244,246,1,),
                    ),
                    child: Padding(
                    padding:EdgeInsets.only(top:10,bottom:10,right:10),
                      child:Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Row(
                            children: [

                              Padding(
                                padding: EdgeInsets.only(right: MediaQuery.of(context).size.width*0.02,left:MediaQuery.of(context).size.width*0.02),
                                child: CircleAvatar(
                                  backgroundColor:Colors.white,
                                  child: user["profilePic"] != ""
                                      ? ClipOval(  // Clip the image into a circular shape
                                    child: Image.network(
                                      user["profilePic"],
                                      fit: BoxFit.cover, // Ensure the image covers the circle
                                      width: 60.0, // Adjust width to the size of the CircleAvatar
                                      height: 60.0, // Adjust height to the size of the CircleAvatar
                                    ),
                                  ):Icon(
                                    CupertinoIcons.person,
                                    size: 30.0, // Icon size
                                    color: Color.fromRGBO(1,102,255,1),
                                  ),
                                ),
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

                          // IconButton(
                          //   onPressed: ()async{
                          //     User? currentUser = FirebaseAuth.instance.currentUser;
                          //     String currentUserId = currentUser?.uid ?? '';
                          //     await Future.wait([
                          //       FirebaseFirestore.instance
                          //           .collection('userDetails')
                          //           .doc(currentUserId.toString())
                          //           .collection('contacts')
                          //           .doc(userId)
                          //           .set({
                          //         'userId': userId,
                          //         'isTranslationEnabled':0,
                          //         'translateTo':'none',
                          //         'translateFrom':'none',
                          //         'blocked': "false",
                          //       }),
                          //       FirebaseFirestore.instance
                          //           .collection('userDetails')
                          //           .doc(userId)
                          //           .collection('contacts')
                          //           .doc(currentUserId.toString())
                          //           .set({
                          //         'userId': currentUserId.toString(),
                          //         'isTranslationEnabled':0,
                          //         'translateTo':'none',
                          //         'translateFrom':'none',
                          //         'blocked': "false"
                          //       }),
                          //     ]);
                          //   },
                          //   icon: Icon(Icons.add,color: Color.fromRGBO(1,102,255,1),),
                          // )

                          if(currentUser!.uid==user['userId'])
                            InkWell(
                                onTap: (){
                                  if (widget.isClicked == false) {
                                    // Disable the button
                                    print("hurray");
                                    setState(() {
                                      widget.isClicked = true;
                                    });

                                    // Call your refresh function (assumed to be a method in the widget)
                                    widget.refresh();

                                  }
                                },
                                child: Text("You",style:TextStyle(color: Color.fromRGBO(1,102,255,1),))
                            ),

                          if(widget.requestsReceived.any((map) => map['userId'] == user['userId']))
                            InkWell(
                            onTap: ()async{

                              if (widget.isClicked == false) {
                                // Disable the button
                                print("hurray");
                                setState(() {
                                  widget.isClicked = true;
                                });

                                User? currentUser = FirebaseAuth.instance.currentUser;
                                String currentUserId = currentUser?.uid ?? '';
                                await Future.wait([
                                  FirebaseFirestore.instance
                                      .collection('userDetails')
                                      .doc(currentUserId.toString())
                                      .collection('contacts')
                                      .doc(user['userId'])
                                      .set({
                                    'userId': user['userId'],
                                  }),
                                  FirebaseFirestore.instance
                                      .collection('userDetails')
                                      .doc(user['userId'])
                                      .collection('contacts')
                                      .doc(currentUserId.toString())
                                      .set({
                                    'userId': currentUserId.toString(),
                                  }),
                              FirebaseFirestore.instance
                                  .collection('userDetails')
                                  .doc(user['userId'])
                                  .collection('requestsSent')
                                  .doc(currentUserId.toString())
                                  .delete()
                                  .then((_) {
                              print('Document successfully deleted!');
                              }).catchError((error) {
                              print('Error deleting document: $error');
                              }),
                                  FirebaseFirestore.instance
                                      .collection('userDetails')
                                      .doc(currentUserId)
                                      .collection('requestsReceived')
                                      .doc(user['userId'])
                                      .delete()
                                      .then((_) {
                                    print('Document successfully deleted!');
                                  }).catchError((error) {
                                    print('Error deleting document: $error');
                                  })
                              ]);


                                // Call your refresh function (assumed to be a method in the widget)
                                widget.refresh();

                              }


                            },
                              child: Text("Accept",style:TextStyle(color: Color.fromRGBO(1,102,255,1),))
                            ),

                          if(widget.requestsSent.any((map) => map['userId'] == user['userId']))
                            InkWell(
                                onTap: (){
                                  //Do nothing
                                },
                                child: Text("Request Sent",style:TextStyle(color: Color.fromRGBO(1,102,255,1),))
                            ),

                          if(widget.contacts.any((map) => map['userId'] == user['userId']))
                            InkWell(
                                onTap: (){
                                  // Do nothing
                                },
                                child: Text("Contact",style:TextStyle(color: Color.fromRGBO(1,102,255,1),))
                            ),

                          if(!widget.requestsReceived.any((map) => map['userId'] == user['userId']) && !widget.requestsSent.any((map) => map['userId'] == user['userId']) && !widget.contacts.any((map) => map['userId'] == user['userId']) && currentUser!.uid!=user['userId'])
                            InkWell(
                                onTap: ()async{

                                  if (widget.isClicked == false) {
                                    // Disable the button
                                    print("hurray");
                                    setState(() {
                                      widget.isClicked = true;
                                    });

                                    User? currentUser = FirebaseAuth.instance.currentUser;
                                    String currentUserId = currentUser?.uid ?? '';
                                    await Future.wait([
                                      FirebaseFirestore.instance
                                          .collection('userDetails')
                                          .doc(currentUserId.toString())
                                          .collection('requestsSent')
                                          .doc(user['userId'])
                                          .set({
                                        'userId': user['userId'],
                                      }),
                                      FirebaseFirestore.instance
                                          .collection('userDetails')
                                          .doc(user['userId'])
                                          .collection('requestsReceived')
                                          .doc(currentUserId.toString())
                                          .set({
                                        'userId': currentUserId.toString(),
                                      }),
                                    ]);

                                    // Call your refresh function (assumed to be a method in the widget)
                                    widget.refresh();

                                  }

                                },
                                child: Text("Add",style:TextStyle(color: Color.fromRGBO(1,102,255,1),))
                            )

                        ],
                      ),
                    )
                  ),
                ),
              ],
            );
          },
      ),
    );
  }
}

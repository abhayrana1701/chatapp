import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glowy_borders/glowy_borders.dart';
import 'package:mychatapplication/databaseHelper.dart';
import 'package:mychatapplication/selectLanguage.dart';
import 'package:mychatapplication/sendMessages.dart';

class ChatScreenOptionsMenu extends StatefulWidget {
  Function translateLanguage;
  String receiverId;
  Function deleteChat;
  Function update;
  Function(String liveChat) updateLiveChat;
  ChatScreenOptionsMenu({super.key,required this.update,required this.deleteChat,required this.translateLanguage,required this.receiverId,required this.updateLiveChat});

  @override
  State<ChatScreenOptionsMenu> createState() => _ChatScreenOptionsMenuState();
}

class _ChatScreenOptionsMenuState extends State<ChatScreenOptionsMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      constraints: BoxConstraints(
        maxWidth: 150,
      ),
      onSelected: (value) {
        // Handle the selected value here
        print(value);
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'Option 1',
            child: Option(icon: FontAwesomeIcons.language,text: "Translate",iconColor: Color.fromRGBO(29,169,96,1)),
            onTap: ()async{
              DatabaseHelper databaseHelper=DatabaseHelper();
              int? isLanguageTranslationEnabled=await databaseHelper.getLanguageTranslationStatus(widget.receiverId);
              String? from=await databaseHelper.getTranslateFromStatus(widget.receiverId);
              String? fromKey=await databaseHelper.getTranslateFromKeyStatus(widget.receiverId);
              String? to=await databaseHelper.getTranslateToStatus(widget.receiverId);
              String? toKey=await databaseHelper.getTranslateFromKeyStatus(widget.receiverId);
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedGradientBorder(
                            borderSize: 2,
                            glowSize: 0,
                            gradientColors: [
                              Color(0xFFF953C6), // Dark Pink
                              Color(0xFF833AB4), // Purple
                              Color(0xFFE94057), // Pink-Red
                              Color(0xFFFF6F61)  // Coral
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(243, 244, 246, 1),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "Translate",
                                                    style: TextStyle(fontSize: 25),
                                                  ),
                                                  CupertinoSwitch(
                                                    value: isLanguageTranslationEnabled==0?false:true,
                                                    onChanged: (bool value) {
                                                      setState(() {
                                                        isLanguageTranslationEnabled = value?1:0;
                                                      });
                                                      databaseHelper.updateLanguageTranslationStatus(widget.receiverId, isLanguageTranslationEnabled!);
                                                      // if(isLanguageTranslationEnabled){
                                                      //   translateLanguage();
                                                      // }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap:(){
                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectLanguage(fromOrTo: "from",),)).then((value) {
                                                databaseHelper.updateTranslateFromStatus(widget.receiverId, value[1]);
                                                databaseHelper.updateTranslateFromKeyStatus(widget.receiverId, value[0]);
                                                setState((){
                                                  fromKey=value[0];
                                                  from=value[1];
                                                  widget.update();
                                                });
                                              },);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        from!,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Icon(Icons.keyboard_arrow_down)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width:5),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap:(){
                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectLanguage(fromOrTo: "to",),)).then((value) {
                                                databaseHelper.updateTranslateToStatus(widget.receiverId, value[1]);
                                                databaseHelper.updateTranslateToKeyStatus(widget.receiverId, value[0]);
                                                setState((){
                                                  toKey=value[0];
                                                  to=value[1];
                                                  widget.update();
                                                });
                                              },);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        to!,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Icon(Icons.keyboard_arrow_down)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Break down language barriers instantly—translate messages with ease!",
                                        ),
                                      ),
                                    ),


                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
              widget.translateLanguage();
            }
          ),

          PopupMenuItem<String>(
            value: 'Option 1',
            child: Option(icon: FontAwesomeIcons.commentDots,text: "Live Chat",iconColor: Color.fromRGBO(1, 102, 255, 1)),
            onTap: ()async{
              DatabaseHelper databaseHelper=DatabaseHelper();
              int? isLiveChatEnabled=await databaseHelper.getLiveChatStatus(widget.receiverId);
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedGradientBorder(
                            borderSize: 2,
                            glowSize: 0,
                            gradientColors: [
                              Color(0xFFF953C6), // Dark Pink
                              Color(0xFF833AB4), // Purple
                              Color(0xFFE94057), // Pink-Red
                              Color(0xFFFF6F61)  // Coral
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(243, 244, 246, 1),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "Live Chat",
                                                    style: TextStyle(fontSize: 25),
                                                  ),
                                                  CupertinoSwitch(
                                                    value: isLiveChatEnabled==0?false:true,
                                                    onChanged: (bool value) async{

                                                        if(isLiveChatEnabled==0){
                                                          isLiveChatEnabled=1;
                                                          setState(() {
                                                          });
                                                        }else{
                                                          isLiveChatEnabled=0;
                                                          setState(() {
                                                          });
                                                          User? currentUser = FirebaseAuth.instance.currentUser;
                                                          String currentUserId = currentUser?.uid ?? '';
                                                          final firestore = FirebaseFirestore.instance;
                                                          await firestore.collection('chats').doc(SendMessages.getRoomId(currentUserId, widget.receiverId)).collection('liveChats').doc(currentUserId).set({
                                                            'liveChat': '',
                                                          });
                                                          widget.updateLiveChat('');
                                                        }
                                                        databaseHelper.updateLiveChatStatus(widget.receiverId, isLiveChatEnabled!);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Experience chat like never before with live message previews and real-time typing visibility.",
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Watch messages come to life as they’re typed and feel the excitement with instant updates.",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          PopupMenuItem<String>(
            value: 'Option 1',
            child: Option(icon: FontAwesomeIcons.trash,text: "Delete",iconColor:Color.fromRGBO(250,101,51, 1)),
            onTap: ()async{

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Align(alignment:Alignment.center,child: Text('Delete Chat')),
                    backgroundColor: Color.fromRGBO(243,244,246,1,),
                    contentPadding: EdgeInsets.only(top:15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Set the border radius here
                    ),
                    content: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Are you sure you want to delete all Chat?'),
                        SizedBox(height: 15,),
                        Container(
                            height:0.5,
                            color:Colors.grey
                        ),
                        InkWell(
                            onTap:()async{
                              DatabaseHelper db=DatabaseHelper();
                              User? user = FirebaseAuth.instance.currentUser;
                              db.deleteTable(user!.uid.toString(), widget.receiverId);
                              widget.deleteChat();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                                alignment: Alignment.center,
                                height:50,
                                child: Text("Delete Chat",style: TextStyle(color: Color.fromRGBO(223,77,93,1),),)
                            )

                        ),
                        Container(
                            height:0.5,
                            color:Colors.grey
                        ),
                        InkWell(
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
                            onTap:(){
                              Navigator.pop(context);
                            },
                            child: Container(
                                alignment: Alignment.center,
                                height:50,
                                child: Text("Cancel",style: TextStyle(color: Color.fromRGBO(1,102,255,1),),)
                            )
                        ),
                      ],
                    ),

                  );
                },
              );

            },
          ),

        ];
      },
    );
  }
}

Widget Option({
  required icon,
  required text,
  required iconColor
}){
  return Row(
    children: [
      CircleAvatar(
        backgroundColor: iconColor,
        child:FaIcon(
          icon, // Document icon
          //size: 50.0,
          color: Colors.white,
        ),
      ),
      SizedBox(width:10),
      Text(text),
    ],
  );
}
import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mychatapplication/sendMessages.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'databaseHelper.dart';
import 'imageViewerScreen.dart';

class ShowChats extends StatefulWidget {
  List<Map<String, dynamic>> chatsList;
  ScrollController scrollController;
  String receiverId;
  // Attach the key here
  ShowChats({Key? key, required this.chatsList, required this.scrollController, required this.receiverId})
      : super(key: key); // Pass the key to the superclass constructor


  @override
  State<ShowChats> createState() => ShowChatsState();
}

class ShowChatsState extends State<ShowChats> {

  void update(){
    print("Updated");
  }

  // when encounter image show it with other next image and skip next image from showing again
  int toSkip=0;

  void _showPopupMenu(BuildContext context, Offset position, String item,String messageId,Map<String, dynamic> chat) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      color:Colors.white,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position.translate(1, 1),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'forward',
          child: Row(
            children: [
              Icon(CupertinoIcons.arrowshape_turn_up_right),
              SizedBox(width: 10),
              Text('Forward  '),
            ],
          ),
        ),
        if(chat['messageType']=="text")
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(CupertinoIcons.doc_on_doc),
              SizedBox(width: 10),
              Text('Copy'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(CupertinoIcons.delete),
              SizedBox(width: 10),
              Text('Delete'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'unsend',
          child: Row(
            children: [
              Icon(CupertinoIcons.arrow_uturn_left, color: Colors.red),
              SizedBox(width: 10),
              Text('Unsend', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value)async {
      if (value == 'forward') {
        // Handle forward action
        print('Forward selected');
      } else if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: chat['content'])).then((_) {
        });
        // Handle copy action
        print('Copy selected');
      } else if (value == 'delete') {
        // Handle delete action
        User? currentUser = FirebaseAuth.instance.currentUser;
        String currentUserId = currentUser?.uid ?? '';
        await DatabaseHelper().deleteMessageById(messageId,currentUserId,widget.receiverId);
        widget.chatsList.removeWhere((message) => message['messageId'] == messageId);
        setState(() {

        });
        print('Delete selected');
      } else if (value == 'unsend') {
        // Handle unsend action
        print('Unsend selected');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        //Have two additional length for showing live chats
        itemCount: widget.chatsList.length+2,
        controller: widget.scrollController,
        cacheExtent: double.infinity,
        itemBuilder: (context, index) {

          if (index==0){return Container();}

          if (index==(widget.chatsList.length)) {
            if(widget.chatsList[0]['content']==null || widget.chatsList[0]['content']==''){return Container();}
            return Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(1, 102, 255, 1),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.chatsList[0]['content'],style: TextStyle(color:Colors.white),), // You may want to provide a message here
                    ),
                  ),
                  Text("Live",style: TextStyle(color: Colors.grey,fontSize: 12),)
                ],
              ),
            );
          }

          User? currentUser = FirebaseAuth.instance.currentUser;
          String currentUserId = currentUser?.uid ?? '';

          if (index==(widget.chatsList.length)+1) {
            print("yesnn");
            return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(SendMessages.getRoomId(currentUserId,widget.receiverId))
                    .collection('liveChats')
                    .doc(widget.receiverId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(); // Loading indicator
                }

                if (snapshot.hasError) {
                  return Container();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container();
                }

                // Access the 'livechat' field
                String liveChat = snapshot.data!['liveChat'] ?? '';
                if(liveChat!=''){
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (widget.scrollController.hasClients) {
                      widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
                    }
                  });
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(243,244,246,1),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(liveChat,style: TextStyle(color:Colors.black),), // You may want to provide a message here
                          ),
                        ),
                        Text("Live",style: TextStyle(color: Colors.grey,fontSize: 12),)
                      ],
                    ),
                  );
                }

                return Container();
              },
            );
          }


          final chat = widget.chatsList[index];
          final timestamp = chat['timestamp'] ;
          DateTime dateTime = DateTime.parse(timestamp);
          final formattedTime = DateFormat('h:mm a').format(dateTime);

          if(toSkip>0){
            toSkip--;
            return Container();
          }

          switch(chat['messageType']){

            case 'text':
              return Align(
                alignment: chat['senderId'].toString()==currentUserId?Alignment.centerRight:Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: chat['senderId'].toString()==currentUserId?CrossAxisAlignment.end:CrossAxisAlignment.start,
                  children: [
                    Draggable(
                      feedback: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        child: Material(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width*0.7,
                            ),
                            decoration: BoxDecoration(
                              color: chat['senderId'].toString()==currentUserId?Color.fromRGBO(1,102,255,1):Color.fromRGBO(243,244,246,1),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child:Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(chat['content'],style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,),
                              ),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(),
                      child: GestureDetector(
                        onLongPressStart: (LongPressStartDetails details) {
                          _showPopupMenu(context, details.globalPosition, 'item[index]',chat['messageId'],chat);
                        },
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width*0.7,
                          ),
                          decoration: BoxDecoration(
                            color: chat['senderId'].toString()==currentUserId?Color.fromRGBO(1,102,255,1):Color.fromRGBO(243,244,246,1),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child:Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(chat['content'],style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,),
                            ),
                          ),
                        ),
                      ),
                    ),


                    //Make this reusable after + Add Functionality
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formattedTime,style: TextStyle(color: Colors.grey,fontSize: 12),),
                        SizedBox(width:2),
                        chat['senderId']==currentUserId?Stack(
                          children: [


                            if (chat['isRead']==1)...[
                              Container(height:14,width:21),
                              Positioned(
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Color.fromRGBO(1,102,255,1),
                                  child: IconTheme(
                                    data: IconThemeData(size: 10,color: Colors.white),
                                    child: Icon(Icons.check, size: 10),
                                  ),
                                ),
                              ),
                              Positioned(
                                left:7,
                                child: CircleAvatar(
                                  radius:7,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color.fromRGBO(1,102,255,1),
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            if (chat['isReceived']==1 && chat['isRead']==0)...[
                              Container(height:14,width:19),
                              Positioned(
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius:6,
                                  backgroundColor:Color.fromRGBO(1,102,255,1),
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor:Colors.white,
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left:7,
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius:6,
                                  backgroundColor: Color.fromRGBO(1,102,255,1),
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Colors.white,
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                    ),
                                  ),
                                ),
                              ),
                            ],


                            if(chat['isReceived'] ==0 && chat['isRead']==0)...[
                              chat['isDelivered']==0?Icon(Icons.watch_later_outlined,color: Color.fromRGBO(1,102,255,1),size: 15,):CircleAvatar(
                                radius:6,
                                backgroundColor: Color.fromRGBO(1,102,255,1),
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Colors.white,
                                  child: IconTheme(
                                    data: IconThemeData(size: 10,color: Colors.white),
                                    child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                  ),
                                ),
                              ),
                            ]


                          ],
                        ):Container(),
                      ],
                    )
                  ],
                ),
              );

            case 'file':
              Map<String, dynamic> fileDetails = jsonDecode(chat['content']);
              return Align(
                  alignment: chat['senderId'].toString()==currentUserId?Alignment.centerRight:Alignment.centerLeft,
                  child:Padding(
                    padding: const EdgeInsets.only(top:8,bottom:8),
                    child: Column(
                      crossAxisAlignment: chat['senderId'].toString()==currentUserId?CrossAxisAlignment.end:CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: ()async{
                            await OpenFile.open(fileDetails['path']);
                          },
                          onLongPressStart: (LongPressStartDetails details) {
                            _showPopupMenu(context, details.globalPosition, 'item[index]',chat['messageId'],chat);
                          },
                          child: Container(
                            width:MediaQuery.of(context).size.width*0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              color: chat['senderId'].toString()==currentUserId?Color.fromRGBO(1,102,255,1):Color.fromRGBO(243,244,246,1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [

                                  FaIcon(FontAwesomeIcons.file,color:Colors.white),
                                  SizedBox(width:10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fileDetails['name'],style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,),maxLines: 2,overflow: TextOverflow.ellipsis,),
                                        Row(
                                          children: [
                                            Text((fileDetails['size'] / (1024 * 1024)).toStringAsFixed(2),style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,)),
                                            Text("MB",style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,)),
                                            SizedBox(width:10),
                                            CircleAvatar(
                                              backgroundColor:currentUserId==chat['senderId']?Colors.white:Colors.black,
                                              radius: 3,
                                            ),
                                            SizedBox(width:10),
                                            Text(fileDetails['extension'],style: TextStyle(color:currentUserId==chat['senderId']?Colors.white:Colors.black,))
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(width:1),
                                  chat['isDelivered']==-1?SizedBox(height:20,width:20,child: CircularProgressIndicator(strokeWidth: 2,color:Colors.white)):Container(),

                                ],
                              ),
                            ),
                          ),
                        ),

                        //Make this reusable after + Add Functionality
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formattedTime,style: TextStyle(color: Colors.grey,fontSize: 12),),
                            SizedBox(width:2),
                            chat['senderId']==currentUserId?Stack(
                              children: [

                                if(chat['isReceived'] ==0 && chat['isRead']==0)...[
                                  chat['isDelivered']==0||chat['isDelivered']==-1?Icon(Icons.watch_later_outlined,color: Color.fromRGBO(1,102,255,1),size: 15,):CircleAvatar(
                                    radius:6,
                                    backgroundColor: Color.fromRGBO(1,102,255,1),
                                    child: CircleAvatar(
                                      radius: 5,
                                      backgroundColor: Colors.white,
                                      child: IconTheme(
                                        data: IconThemeData(size: 10,color: Colors.white),
                                        child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                      ),
                                    ),
                                  ),
                                ],

                                if (chat['isRead']==1)...[
                                  Container(height:14,width:21),
                                  Positioned(
                                    top:0,bottom:0,
                                    child: CircleAvatar(
                                      radius: 6,
                                      backgroundColor: Color.fromRGBO(1,102,255,1),
                                      child: IconTheme(
                                        data: IconThemeData(size: 10,color: Colors.white),
                                        child: Icon(Icons.check, size: 10),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left:7,
                                    child: CircleAvatar(
                                      radius:7,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Color.fromRGBO(1,102,255,1),
                                        child: IconTheme(
                                          data: IconThemeData(size: 10,color: Colors.white),
                                          child: Icon(Icons.check, size: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                if (chat['isReceived']==1 && chat['isRead']==0)...[
                                  Container(height:14,width:19),
                                  Positioned(
                                    top:0,bottom:0,
                                    child: CircleAvatar(
                                      radius:6,
                                      backgroundColor:Color.fromRGBO(1,102,255,1),
                                      child: CircleAvatar(
                                        radius: 5,
                                        backgroundColor:Colors.white,
                                        child: IconTheme(
                                          data: IconThemeData(size: 10,color: Colors.white),
                                          child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left:7,
                                    top:0,bottom:0,
                                    child: CircleAvatar(
                                      radius:6,
                                      backgroundColor: Color.fromRGBO(1,102,255,1),
                                      child: CircleAvatar(
                                        radius: 5,
                                        backgroundColor: Colors.white,
                                        child: IconTheme(
                                          data: IconThemeData(size: 10,color: Colors.white),
                                          child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],


                              ],
                            ):Container(),
                          ],
                        ),

                      ],
                    ),
                  )
              );
            case 'image':
              dynamic chat1,chat2,chat3;
              bool showCarousel=false;
              if(widget.chatsList.length>=index+3){
                chat1 = widget.chatsList[index];
                chat2 = widget.chatsList[index+1];
                chat3 = widget.chatsList[index+2];
                showCarousel=true;
              }
              if(showCarousel && chat1['messageType']=='image' && chat2['messageType']=='image' && chat3['messageType']=='image'){
                int itemCount=0;
                int i=0;
                for(int i=index;i<widget.chatsList.length;i++){
                  var currentChat=widget.chatsList[i];
                  if(currentChat['messageType']=='image'){
                    itemCount++;
                  }else{
                    break;
                  }
                }
                toSkip=itemCount-1;
                print("item$itemCount");
                return Align(
                  alignment: chat1['senderId'].toString()==currentUserId?Alignment.centerRight:Alignment.centerLeft,
                  child: Container(
                    width:MediaQuery.of(context).size.width*0.4,
                    height:170,
                    child: CarouselSlider.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, indexCarasoul, realIndex) {
                          var currentChat=widget.chatsList[index+indexCarasoul];
                          Map<String, dynamic> fileDetails = jsonDecode(currentChat['content']);
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: (){
                                  List<Map<String, dynamic>> imageItems = widget.chatsList
                                      .where((item) => item['messageType'] == 'image')
                                      .toList();

                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ImageViewerScreen(imageDetailsList: imageItems,initialIndex: 0,),));
                                },
                                onLongPressStart: (LongPressStartDetails details) {
                                  _showPopupMenu(context, details.globalPosition, 'item[index]',chat['messageId'],chat);
                                },
                                child: Container(
                                  width:MediaQuery.of(context).size.width*0.35,
                                  height:150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    color:Color.fromRGBO(243,244,246,1,),
                                  ),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image(image: FileImage(File(fileDetails['path'])))
                                  ),
                                ),
                              ),
                              //Make this reusable after + Add Functionality
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(formattedTime,style: TextStyle(color: Colors.grey,fontSize: 12),),
                                  SizedBox(width:2),
                                  chat['senderId']==currentUserId?Stack(
                                    children: [

                                      if(chat['isReceived'] ==0 && chat['isRead']==0)...[
                                        chat['isDelivered']==0||chat['isDelivered']==-1?Icon(Icons.watch_later_outlined,color: Color.fromRGBO(1,102,255,1),size: 15,):CircleAvatar(
                                          radius:6,
                                          backgroundColor: Color.fromRGBO(1,102,255,1),
                                          child: CircleAvatar(
                                            radius: 5,
                                            backgroundColor: Colors.white,
                                            child: IconTheme(
                                              data: IconThemeData(size: 10,color: Colors.white),
                                              child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                            ),
                                          ),
                                        ),
                                      ],

                                      if (chat['isRead']==1)...[
                                        Container(height:14,width:21),
                                        Positioned(
                                          top:0,bottom:0,
                                          child: CircleAvatar(
                                            radius: 6,
                                            backgroundColor: Color.fromRGBO(1,102,255,1),
                                            child: IconTheme(
                                              data: IconThemeData(size: 10,color: Colors.white),
                                              child: Icon(Icons.check, size: 10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left:7,
                                          child: CircleAvatar(
                                            radius:7,
                                            backgroundColor: Colors.white,
                                            child: CircleAvatar(
                                              radius: 6,
                                              backgroundColor: Color.fromRGBO(1,102,255,1),
                                              child: IconTheme(
                                                data: IconThemeData(size: 10,color: Colors.white),
                                                child: Icon(Icons.check, size: 10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      if (chat['isReceived']==1 && chat['isRead']==0)...[
                                        Container(height:14,width:19),
                                        Positioned(
                                          top:0,bottom:0,
                                          child: CircleAvatar(
                                            radius:6,
                                            backgroundColor:Color.fromRGBO(1,102,255,1),
                                            child: CircleAvatar(
                                              radius: 5,
                                              backgroundColor:Colors.white,
                                              child: IconTheme(
                                                data: IconThemeData(size: 10,color: Colors.white),
                                                child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left:7,
                                          top:0,bottom:0,
                                          child: CircleAvatar(
                                            radius:6,
                                            backgroundColor: Color.fromRGBO(1,102,255,1),
                                            child: CircleAvatar(
                                              radius: 5,
                                              backgroundColor: Colors.white,
                                              child: IconTheme(
                                                data: IconThemeData(size: 10,color: Colors.white),
                                                child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],


                                    ],
                                  ):Container(),
                                ],
                              ),
                            ],
                          );
                        },

                        options: CarouselOptions(
                          enlargeCenterPage: true,
                          scrollPhysics: BouncingScrollPhysics(),
                          autoPlay: true,
                          enableInfiniteScroll: true,
                        )
                    ),
                  ),
                );
              }
              Map<String, dynamic> fileDetails = jsonDecode(chat['content']);
              return Align(
                alignment: chat['senderId'].toString()==currentUserId?Alignment.centerRight:Alignment.centerLeft,
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onLongPressStart: (LongPressStartDetails details) {
                        _showPopupMenu(context, details.globalPosition, 'item[index]',chat['messageId'],chat);
                      },
                      child: Container(
                        width:MediaQuery.of(context).size.width*0.35,
                        height:170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color:Color.fromRGBO(243,244,246,1,),
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image(image: FileImage(File(fileDetails['path'])))
                        ),
                      ),
                    ),

                    //Make this reusable after + Add Functionality
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formattedTime,style: TextStyle(color: Colors.grey,fontSize: 12),),
                        SizedBox(width:2),
                        chat['senderId']==currentUserId?Stack(
                          children: [

                            if(chat['isReceived'] ==0 && chat['isRead']==0)...[
                              chat['isDelivered']==0||chat['isDelivered']==-1?Icon(Icons.watch_later_outlined,color: Color.fromRGBO(1,102,255,1),size: 15,):CircleAvatar(
                                radius:6,
                                backgroundColor: Color.fromRGBO(1,102,255,1),
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Colors.white,
                                  child: IconTheme(
                                    data: IconThemeData(size: 10,color: Colors.white),
                                    child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                  ),
                                ),
                              ),
                            ],

                            if (chat['isRead']==1)...[
                              Container(height:14,width:21),
                              Positioned(
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Color.fromRGBO(1,102,255,1),
                                  child: IconTheme(
                                    data: IconThemeData(size: 10,color: Colors.white),
                                    child: Icon(Icons.check, size: 10),
                                  ),
                                ),
                              ),
                              Positioned(
                                left:7,
                                child: CircleAvatar(
                                  radius:7,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color.fromRGBO(1,102,255,1),
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            if (chat['isReceived']==1 && chat['isRead']==0)...[
                              Container(height:14,width:19),
                              Positioned(
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius:6,
                                  backgroundColor:Color.fromRGBO(1,102,255,1),
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor:Colors.white,
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left:7,
                                top:0,bottom:0,
                                child: CircleAvatar(
                                  radius:6,
                                  backgroundColor: Color.fromRGBO(1,102,255,1),
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Colors.white,
                                    child: IconTheme(
                                      data: IconThemeData(size: 10,color: Colors.white),
                                      child: Icon(Icons.check, size: 10,color:Color.fromRGBO(1,102,255,1)),
                                    ),
                                  ),
                                ),
                              ),
                            ],


                          ],
                        ):Container(),
                      ],
                    ),
                  ],
                ),
              );

          }

        },
    );
  }
}



import 'dart:async';
import 'dart:convert';
import 'package:animated_icon/animated_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychatapplication/chatScreenInputField.dart';
import 'package:mychatapplication/lastScene.dart';
import 'package:mychatapplication/sendMessages.dart';
import 'package:mychatapplication/showChatRecommendations.dart';
import 'package:uuid/uuid.dart';
import 'chatScreenOptionsMenu.dart';
import 'databaseHelper.dart';
import 'showChats.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'main.dart';
import 'chatScreenInputField.dart';
import 'viewContactDetails.dart';

class ChatScreen extends StatefulWidget {
  String receiverId,name;
  ChatScreen({super.key,required this.receiverId,required this.name});

  @override
  State<ChatScreen> createState() => ChatScreenState();

}

class ChatScreenState extends State<ChatScreen> {

  //TextEditingController
  TextEditingController chatController=TextEditingController();

  //To store chats for displaying
  //Keep first index reserved for current user live chat
  List<Map<String, dynamic>> chatsList = [{}];

  //Scroll Controller for auto scrolling on receiving or sending message
  final ScrollController _scrollController = ScrollController();

  //Chat recommendations
  List chatRecommendations=[];
  Map<String, dynamic>? fcmData;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadChats();
    _scrollController.addListener(_onScroll);
    //receiveMessages();

    // Listen for changes in the ValueNotifier (FCM data)
    fcmDataNotifier.addListener(() {
      print("yeahhhh");
      fcmData = fcmDataNotifier.value;
      final timestampString = fcmData?['timestamp'];
      final timestamp = DateTime.parse(timestampString);
      final message = {
        'senderId':fcmData?['senderId'],
        'messageId':fcmData?['messageId'],
        'content':fcmData?['content'],
        'timestamp':timestamp.toString(),
        'messageType':fcmData?['messageType'],
      };
      setState(() {
        print("finally");
        chatsList.add(message);
      });
    });

    deliveryStatusNotifier.addListener(() {
      // for (var map in chatsList) {
      //   List? messageId=deliveryStatusNotifier.value;
      //   if (map['messageId'] ==messageId?[0]) {
      //     //map['isDelivered'] = 1;
      //     break; // Exit loop once the element is found and updated
      //   }
      // }
      // setState(() {
      //
      // });
    });

  }

  bool showScrollToBottom=false;
  void _onScroll() {
    // Check if the scroll position is not at the bottom
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent) {
        if(!showScrollToBottom){
          setState((){
            showScrollToBottom=true;
          });
        }
    }
    else{
      setState((){
        showScrollToBottom=false;
      });
    }
  }

  //Load chats stored in database
  loadChats()async{
    DatabaseHelper databaseHelper=DatabaseHelper();
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';
    var tempChatsList= await databaseHelper.loadChats(
      currentUserId,
      widget.receiverId
    );
    setState(() {
      chatsList.addAll(tempChatsList);
      print(chatsList);
    });
    // Scroll to the bottom after the layout has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scroll after chats have been added and rendered
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 900), curve: Curves.easeOut);
      }
    });
  }


  //Variables for receiveMessages to work
  StreamSubscription? _subscription;
  List processedMessages=[];
  void receiveMessages() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    var chatId=SendMessages.getRoomId(currentUserId, widget.receiverId);

    _subscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) async {
      try {
        _subscription?.pause();

        final List<Map<String, dynamic>> newMessages = [];

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var doc = change.doc;
            if (doc['senderId'] != currentUserId && !processedMessages.contains(doc.id)) {
              // Convert Firestore Timestamp to DateTime
              Timestamp timestamp = doc['timestamp'] as Timestamp;
              DateTime messageTime = timestamp.toDate();

              final messageData = {
                ...doc.data() as Map<String, dynamic>,
                'timestamp': messageTime.toString(),
              };

              newMessages.add(messageData);
              processedMessages.add(doc.id);
            }
          }
        }

        if (newMessages.isNotEmpty) {
          setState(() {
            chatsList.addAll(newMessages);
          });

          for (var message in newMessages) {
            DatabaseHelper databaseHelper=DatabaseHelper();
            await databaseHelper.insertChat(currentUserId.toString(),widget.receiverId.toString(), message);
          }
        }

        // Delete documents
        for (var docId in processedMessages) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(docId)
              .delete();
        }

        processedMessages.clear();
      } catch (e) {
      } finally {
        _subscription?.resume();
      }
    });
  }


  // Function to auto-scroll to the bottom
  void _scrollToBottom(int duration) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent+50, //Added 50 here because message type field has height 50
        duration: Duration(milliseconds: duration),
        curve: Curves.easeOut,
      );
    }
  }


  //Generate hint message

  void generateChatRecommendations() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    for (int i = chatsList.length - 1; i >= 0; i--) {
      var message = chatsList[i];
      if (message['messageType'] == "text") {
        var senderOrReceiver = message['senderId'] == currentUserId ? "sender" : "receiver";
        var prompt="";
        if(senderOrReceiver=="sender"){
          prompt="Guidelines for generating response is that messages which i will actually send should be enclosed by triple *** from starting and beginning and no new line characters should be there. Generate 10 messages that i can send after sending following message to a person: ${message['content']}";
        }
        else{
          prompt="Guidelines for generating response is that messages which i will actually send should be enclosed by triple *** from starting and beginning and no new line characters should be there.Generate 10 messages that i can send in response after receiving following message from a person: ${message['content']}";
        }
        List recommendations=await getChatRecommendationsFromAi(prompt);
        setState(() {
          print("hello");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Scroll after chats have been added and rendered
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent,);
            }
          });
          chatRecommendations=recommendations;
        });
        break;
      }
    }
  }

  Future<List> getChatRecommendationsFromAi(String prompt) async {
    final String apiKey = 'AIzaSyAh_L-SnXqAHCk8POf02nxQN_37Y4Gqxwo'; // Replace with your actual API key
    final String url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      return extractMessages(response.body);
    } else {
      // Handle the error
      return [];
    }
  }

  List extractMessages(String input) {
    // Use a regular expression to find all occurrences between **
    final RegExp regExp = RegExp(r'\*\*\*(.*?)\*\*\*');
    final matches = regExp.allMatches(input);

    // Create a list to store the extracted messages
    final List<String> extractedMessages = [];

    // Iterate over the matches and extract the text
    for (var match in matches) {
      // Clean up the message by removing unwanted characters
      String message = match.group(1)?.trim().replaceAll(r'\"', '') ?? '';
      extractedMessages.add(message);
    }
    return extractedMessages;
  }


  void updateChats(){
    loadChats();
    print("loaded");
  }


 bool  expandRecommendations=false;

 double height=50;



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        //Color remains white while scrolling
        surfaceTintColor: Colors.white,
        title: Row(
          children: [

            GestureDetector(
              onTap:(){
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewContactDetails(),
                  ),
                );

              },
              child:CircleAvatar(),
            ),
            SizedBox(width:5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,style: TextStyle(fontWeight: FontWeight.w400,fontSize: 18),),
                //LastScene(receiverId: widget.receiverId)
              ],
            )

          ],

        ),

        actions: [
          ChatScreenOptionsMenu(receiverId: widget.receiverId,translateLanguage: (){print("translation");},
            updateLiveChat: (liveChat){
              setState(() {
                // Update the 'content' key of the first map
                chatsList[0]['content'] = liveChat;
              });

              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //   // Scroll after chats have been added and rendered
              //   if (_scrollController.hasClients) {
              //     _scrollController.jumpTo(_scrollController.position.maxScrollExtent+50,);
              //   }
              // });

            },
          )
        ],

      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [



            Column(
              children: [

                Expanded(child:ShowChats(chatsList: chatsList,scrollController: _scrollController,receiverId: widget.receiverId,)),


                !expandRecommendations?chatRecommendations.isEmpty?Container():SizedBox(height:50,child: ShowChatRecommendations(recommendations: chatRecommendations,receiverId: widget.receiverId,
                  updateDeliveryStatus: (messageId, isDelivered) {
                  for (var map in chatsList) {
                    if (map['messageId'] == messageId) {
                      map['isDelivered'] = 1;
                      break; // Exit loop once the element is found and updated
                    }
                  }
                  setState(() {

                  });
                },expand: (){
                  setState(() {
                    expandRecommendations=!expandRecommendations;
                  });
                },onReturnValue: (value){
                  setState(() {
                    chatsList.add(value);
                    chatRecommendations=[];
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Scroll after chats have been added and rendered
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent,);
                    }
                  });
                }
                  ,)):Container(),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15))
                  ),
                  height:height,

                  child: ChatScreenInputField(receiverId: widget.receiverId, onReturnValue: (Map<String, dynamic> value) {
                      setState(() {
                        chatsList.add(value);
                      });
                      _scrollToBottom(300);
                    },
                    onSent: (){generateChatRecommendations();},
                    showAiDialog: (){
                      setState(() {
                        height=250;
                      });

                    },
                    expand: (){
                    setState(() {
                      expandRecommendations=false;
                    });
                    },
                    updateDeliveryStatus:(value,isDelivered){
                    print("me ttooo");
                      for (var map in chatsList) {
                        if (map['messageId'] == value) {
                          print("aaaaaaaaaaaaaaaaaaaa");
                          map['isDelivered'] = 1;
                          break; // Exit loop once the element is found and updated
                        }
                      }
                      setState(() {

                      });

                    } ,
                    updateLiveChat: (liveChat) {
                      setState(() {
                        // Update the 'content' key of the first map
                        chatsList[0]['content'] = liveChat;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Scroll after chats have been added and rendered
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent,);
                        }
                      });
                    },
                  ),
                ),

                expandRecommendations?Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child:SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children:chatRecommendations.map((item) {
                        //Intrinsic width makes container take only required width
                        return IntrinsicWidth(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom:4,right:8),
                            child: GestureDetector(
                              onTap:(){

                                String message=item;
                                //Generating unique id for each message
                                var uuid=Uuid();
                                final messageId=uuid.v4();
                                User? currentUser = FirebaseAuth.instance.currentUser;
                                String currentUserId = currentUser?.uid ?? '';
                                Map<String, dynamic> messageData = {
                                  'senderId': currentUserId,
                                  'messageId':messageId,
                                  'content': message,
                                  'timestamp': DateTime.now().toIso8601String(),
                                  'messageType': "text",
                                  'isRead':0,
                                  'isReceived':0,
                                  'isDelivered':0,
                                };
                                ////

                                setState(() {
                                  chatsList.add(messageData);
                                  chatRecommendations=[];
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  // Scroll after chats have been added and rendered
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent,);
                                  }
                                });

                                ////

                                SendMessages.sendTextMessage(receiverId: widget.receiverId, message:message, messageId: messageId).then(
                                      (value) {
                                    if(value!=""){
                                      for (var map in chatsList) {
                                        if (map['messageId'] == value) {
                                          map['isDelivered'] = 1;
                                          break; // Exit loop once the element is found and updated
                                        }
                                      }
                                      setState(() {

                                      });
                                    }
                                  },
                                );

                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color:Color.fromRGBO(243,244,246,1,),
                                ),
                                child:Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(item,style: TextStyle(color: Colors.black),),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ):Container(),

              ],
            ),
            showScrollToBottom?Positioned(
              bottom:55,right:0,
              child: InkWell(
                onTap:(){
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15), // Shadow color and opacity
                        blurRadius: 5, // Softness of the shadow
                        offset: Offset(0, 3), // Position of the shadow
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22.5,
                    backgroundColor: Color.fromRGBO(255, 255, 255, 0.9),
                    child: Icon(Icons.arrow_drop_down),
                  ),
                )
                ,
              ),
            ):Container(),
          ],
        ),
      ),

    );
  }
}


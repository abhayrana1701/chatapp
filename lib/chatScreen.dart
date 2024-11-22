import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:animated_icon/animated_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mychatapplication/chatScreenInputField.dart';
import 'package:mychatapplication/lastScene.dart';
import 'package:mychatapplication/sendMessages.dart';
import 'package:mychatapplication/showChatRecommendations.dart';
import 'package:mychatapplication/viewProfile.dart';
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
  String receiverId,name,username,about,translateToKey;
  dynamic profilePic;
  ChatScreen({super.key,required this.translateToKey,required this.profilePic,required this.receiverId,required this.name,required this.username,required this.about});

  @override
  State<ChatScreen> createState() => ChatScreenState();

}

class ChatScreenState extends State<ChatScreen>with WidgetsBindingObserver  {

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
  final Random random = Random();
  late final int hi;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadChats();
    hi= Random().nextInt(4) + 2; // Generates a random value from 2 to 5

    Timer.periodic(Duration(milliseconds: 500), (timer) {
      //loadChats();
    });
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    //receiveMessages();

    callFunctionAfterDelay();


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

    fcmUpdateReceivedStatusNotifier.addListener(() {

      fcmDataR = fcmDataNotifier.value;
      final messageId = fcmDataR?["messageId"];
      setState(() {
        print("eneterd");
        //tempp
        loadChats();
        for (int i = 1; i < chatsList.length; i++) {
          var chat = chatsList[i];
          //print(chat['messageId']);
          if (chat['messageId'] == messageId) {
            print("Message Content: ${chat['content']}");
            chat['isReceived'] = 1;
          }
        }
        print(messageId);
      });
    });


    fcmDeleteNotifier.addListener(() {
      setState(() {
        loadChats();
      });
    });

  }

  Future<void> callFunctionAfterDelay() async {
    // Delay of 3 seconds
    await Future.delayed(Duration(seconds: 2));

    // Call the getRecentChats function after the delay
    generateChatRecommendations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<String, dynamic>? fcmDataR;
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

  loadChats() async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    // Load chats from the database
    var tempChatsList = await databaseHelper.loadChats(
      currentUserId,
      widget.receiverId,
    );

    // Update the state with the loaded chats, but don't clear the chatsList right away
    List<dynamic> previousChatsList = List.from(chatsList);  // Store previous state

    // Now update the chats list with new data
    setState(() {
      chatsList.clear();
      chatsList.addAll([{}]);  // Add empty object if needed for consistency
      chatsList.addAll(tempChatsList);
      print(chatsList);
    });

    // Scroll to the bottom after the layout has been rendered, but only if new chats were loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Only scroll if the size of the loaded chats is greater than the previous list
        if (tempChatsList.length > previousChatsList.length) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 900),
            curve: Curves.easeOut,
          );
        }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Detect when the app regains focus
    if (state == AppLifecycleState.resumed) {
      // Call the function you want when the app regains focus
      onAppResumed();
    }
  }

  void onAppResumed() {
    // Your custom logic when the app regains focus
    print("App has regained focus!");
    // You can call any specific function here
    loadChats();
  }



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
                    builder: (context) => ViewProfile(profilePic: widget.profilePic,userid: widget.receiverId,username: widget.username,about: widget.about,name: widget.name,),
                  ),
                ).then((value) {
                  widget.about=value;
                },);

              },
              child:CircleAvatar(
                backgroundColor:  Color.fromRGBO(243,244,246,1,),
                child:widget.profilePic==null?Icon(CupertinoIcons.person,color: Color.fromRGBO(1,102,255,1),):null,
                backgroundImage:widget.profilePic!=null ?MemoryImage(widget.profilePic):null,
              ),
            ),
            SizedBox(width:5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                    onTap:(){
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ViewProfile(profilePic: widget.profilePic,userid: widget.receiverId,username: widget.username,about: widget.about,name: widget.name,),
                        ),
                      ).then((value) {
                        widget.about=value;
                      },);

                    },
                    child: Text(widget.name,style: TextStyle(fontWeight: FontWeight.w400,fontSize: 18),)
                ),
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

            },deleteChat: (){
              loadChats();
            },update: (){
            setState(() {

            });
            },
          )
        ],

      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [

            if(chatsList.length==1 )...[
              Column(
                children: [
                  Container(
                    width:MediaQuery.of(context).size.width*0.7,
                    height:MediaQuery.of(context).size.width*0.7,
                    decoration:BoxDecoration(
                      borderRadius:BorderRadius.all(Radius.circular(15)),
                      color:Color.fromRGBO(243,244,246,1,),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Lottie.asset(
                        'assets/hi$hi.json',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Text(
                      "Feeling chatty? Say Hi and start the conversation!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      "Say the magic words – a friendly 'Hi' to get started! 💬",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                ],
              )

            ],

            Column(
              children: [



                Expanded(child:ShowChats(translateToKey: widget.translateToKey,chatsList: chatsList,scrollController: _scrollController,receiverId: widget.receiverId,)),


                !expandRecommendations?chatRecommendations.isEmpty?Container():SizedBox(height:50,child: ShowChatRecommendations(username: widget.name,recommendations: chatRecommendations,receiverId: widget.receiverId,
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

                  child: ChatScreenInputField(about: widget.about,username: widget.name,receiverId: widget.receiverId, onReturnValue: (Map<String, dynamic> value) {
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
                          loadChats();
                          print("good");
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

                                SendMessages.sendTextMessage(receiverId: widget.receiverId, message:message, messageId: messageId,username: widget.name).then(
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


import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mychatapplication/databaseHelper.dart';
import 'package:uuid/uuid.dart';
import 'cameraScreen.dart';
import 'fileUploadService.dart';
import 'sendMessages.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import 'package:wheel_slider/wheel_slider.dart';
ValueNotifier<List<dynamic>?> deliveryStatusNotifier = ValueNotifier<List<dynamic>?>(null);
class ChatScreenInputField extends StatefulWidget {

  String receiverId;
  Function(Map<String, dynamic>) onReturnValue;
  Function(String messageId,int isDelivered)updateDeliveryStatus;
  Function(String liveChat) updateLiveChat;
  Function onSent;
  Function() expand;
  Function() showAiDialog;
  String username;
  String about;
  ChatScreenInputField({super.key,required this.about,required this.username,required this.showAiDialog,required this.expand,required this.onSent,required this.receiverId,required this.onReturnValue,required this.updateDeliveryStatus,required this.updateLiveChat});

  @override
  State<ChatScreenInputField> createState() => _ChatScreenInputFieldState();
}

class _ChatScreenInputFieldState extends State<ChatScreenInputField> {

  //TextEditingController
  TextEditingController chatController=TextEditingController();
  TextEditingController aiController=TextEditingController();

  //For uploading/sending different files
  final FileUploadService _fileUploadService = FileUploadService();

  //For animating file selection menu
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();
  final ScrollController _scrollController3 = ScrollController();

String isgeneratingc="no";

  double _textSize = 18.0;
  int aiscreen=1;
  int selectedMinute = 0;
  int prevaiscreen=-1;
  List<dynamic> questions = [

  ];
String chat="";

  // Create a FocusNode to attach to the TextField
  FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;


  @override
  void initState() {
    super.initState();
    // Add a listener to detect focus changes
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
        if(_isKeyboardVisible){
          widget.expand();
        }
      });
    });
  }

  @override
  void dispose() {
    // Dispose the FocusNode when it's no longer needed
    _focusNode.dispose();
    super.dispose();
  }

  bool isAiVisisble=false;

  bool showLoadingQuestions=true;
  void loadQuestions(){
    // Delay for 2 seconds and then show the widget
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        print("doneeeeeeeeeeeeeeeeeeeee");
        showLoadingQuestions = false; // Update the state to show the widget
      });
    });
  }


  Future<List> getChatSuggestionsFromAi(String prompt,int i) async {
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
              {'text':prompt},
            ],
          },
        ],
      }),
    );


    if (response.statusCode == 200) {
      return extractMessages(response.body);
    } else {
      // Handle the error
      return [];
    }
  }

  Future<String> getChatFromAi(String prompt,int i) async {
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
              {'text':prompt},
            ],
          },
        ],
      }),
    );


    if (response.statusCode == 200) {
      // Decode the JSON data into a Dart map
      Map<String, dynamic> jsonData = jsonDecode(response.body);

      // Extract specific text fields
      String chat = jsonData['candidates'][0]['content']['parts'][0]['text'];
      print(response.body);
      return chat;
    } else {
      // Handle the error
      return "";
    }
  }
  TextEditingController command=TextEditingController();


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


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        isAiVisisble?Container(
          width:MediaQuery.of(context).size.width,
          height:250,

          decoration: BoxDecoration(
            color:Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5), // Shadow color
                spreadRadius: 2, // Spread of the shadow
                blurRadius: 5, // Blur effect
                //offset: Offset(2, 5), // Shadow position (x, y)
              ),
            ],
          ),
          child:Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: 3,
              cursorColor:  Color.fromRGBO(1,102,255,1),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'What’s on your mind? Let’s create!',
                hintStyle: TextStyle(color: Colors.grey), // Hint text style
              ),
            ),
          )
        ):Container(),
        
        !isAiVisisble?Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _focusNode, // Attach the FocusNode
        
                controller: chatController,
                cursorColor: Color.fromRGBO(1,102,255,1),
                onChanged: (value)async{
                  setState(() {
        
                  });
                  DatabaseHelper databaseHelper=DatabaseHelper();
                  int? isLiveChatEnabled=await databaseHelper.getLiveChatStatus(widget.receiverId);
        
                  //Add Live chat to firebase
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  String currentUserId = currentUser?.uid ?? '';
                  final firestore = FirebaseFirestore.instance;
                  if(isLiveChatEnabled==1){
                    widget.updateLiveChat(value);
                    await firestore.collection('chats').doc(SendMessages.getRoomId(currentUserId, widget.receiverId)).collection('liveChats').doc(currentUserId).set({
                      'liveChat': value.trim(),
                      'timestamp$currentUserId':FieldValue.serverTimestamp()
                    });
                  }
                  else{
                    await firestore.collection('chats').doc(SendMessages.getRoomId(currentUserId, widget.receiverId)).collection('liveChats').doc(currentUserId).set({
                      'liveChat': '',
                    });
                  }
        
                },
                decoration: InputDecoration(
                  fillColor: Color.fromRGBO(243,244,246,1,),
                  filled:true,
                  hintText: "Chat...",
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
                  prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  suffixIcon:Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {



// Define a list of gradients for more vibrant backgrounds
                              final List<List<Color>> gradientPalette = [
                                [Color(0xFFFF5E5B), Color(0xFFFFC371)],  // Neon Pink to Orange
                                [Color(0xFF9CFF2E), Color(0xFF00E676)],  // Neon Green to Light Green
                                [Color(0xFFFF4081), Color(0xFFFF8A80)],  // Bright Pink Gradient
                                [Color(0xFFFFEB3B), Color(0xFFFFF176)],  // Bright Yellow Gradient
                                [Color(0xFF7C4DFF), Color(0xFF651FFF)],  // Bright Purple to Deep Violet
                                [Color(0xFF18FFFF), Color(0xFF00E5FF)],  // Electric Cyan to Aqua
                                [Color(0xFFFF1744), Color(0xFFFF8A80)],  // Vivid Red to Light Coral
                                [Color(0xFF00E676), Color(0xFF69F0AE)],  // Vivid Green to Light Mint
                                [Color(0xFFFF9100), Color(0xFFFFD740)],  // Neon Orange to Yellow
                                [Color(0xFF2979FF), Color(0xFF82B1FF)],  // Bright Blue to Light Blue
                                [Color(0xFFAA00FF), Color(0xFFD500F9)],  // Vivid Purple to Bright Magenta
                              ];



                              List<List<Color>> usedGradients = [];

// Function to get a random gradient from the list
                              List<Color> getRandomGradient(List<List<Color>> usedGradients) {
                                if(usedGradients.length==2){
                                  usedGradients=[];
                                }
                                final random = Random();
                                List<Color> gradient;
                                do {
                                  gradient = gradientPalette[random.nextInt(gradientPalette.length)];
                                } while (usedGradients.contains(gradient));
                                usedGradients.add(gradient);
                                return gradient;
                              }


                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: StatefulBuilder(
                                  builder: (BuildContext context, setState) {
                                    double _textSize = 18.0; // Default text size
                                    return Container(
                                      width: MediaQuery.of(context).size.width * 0.9, // Set a specific width
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(Radius.circular(18)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Visibility(
                                              visible: aiscreen==1?true:false,
                                              child: Expanded(child: Container())
                                          ),
                                          Visibility(
                                            visible: aiscreen==1?true:false,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ClipOval(
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: getRandomGradient(usedGradients),
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            ),
                                                          ),
                                                          child: Transform.scale(
                                                            scale: 3,
                                                            child: Lottie.asset(
                                                              'assets/aiemojiupdated.json',
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      ClipOval(
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: getRandomGradient(usedGradients),
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            ),
                                                          ),
                                                          child: Transform.scale(
                                                            scale: 3,
                                                            child: Lottie.asset(
                                                              'assets/aiemojiupdated.json',
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    "Fluxion AI",
                                                    style: TextStyle(fontSize: 30, color: Color.fromRGBO(192, 192, 192, 1)),
                                                  ),
                                                  Text(
                                                    "Unlock the art of messaging with Fluxion AI — effortless, personalized texts that hit just the right note, every time.",
                                                    style: TextStyle(color: Color.fromRGBO(192, 192, 192, 1)),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                              visible: aiscreen==1?true:false,
                                              child: Expanded(child: Container())
                                          ),
                                          Visibility(
                                            visible: aiscreen==1?true:false,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap:(){
                                                      setState((){
                                                        aiscreen=2;
                                                      });
                                                      getChatSuggestionsFromAi("Guidelines for generating response is that messages which i will actually send should be enclosed by triple *** from starting and beginning and no new line characters should be there. Generate 20 messages that i can ask ai model to generate content about. My reltionship with person to whom i will send ai generated messages is: ${widget.about}",0).then((value) {
                                                        setState(() {
                                                          questions=value;
                                                          print("doneeeeeeeeeeeeeeeeeeeee");
                                                          showLoadingQuestions = false; // Update the state to show the widget
                                                          print(questions);
                                                        });
                                                      },);
                                                      // Future.delayed(Duration(seconds: 2), () {
                                                      //   setState(() {
                                                      //     print("doneeeeeeeeeeeeeeeeeeeee");
                                                      //     showLoadingQuestions = false; // Update the state to show the widget
                                                      //   });
                                                      // });
                                                    },
                                                    child: Container(
                                                      alignment: Alignment.center,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15)),
                                                        color: Color.fromRGBO(240, 240, 240, 1),
                                                      ),
                                                      child: GradientText('Suggest', 12),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 40,
                                                  width: 1,
                                                  color: Colors.transparent,
                                                ),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: (){
                                                      setState((){
                                                        aiscreen=3;
                                                        prevaiscreen=1;
                                                      });
                                                    },
                                                    child: Container(
                                                      alignment: Alignment.center,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(15)),
                                                        color: Color.fromRGBO(240, 240, 240, 1),
                                                      ),
                                                      child: GradientText('Imagine', 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                              visible: aiscreen==3?true:false,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [

                                                Visibility(
                                                visible: isgeneratingc=="done"?true:false,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Response",
                                                            style: TextStyle(fontSize: 30, color: Color.fromRGBO(192, 192, 192, 1)),
                                                          ),
                                                          GestureDetector(
                                                              onTap: (){
                                                                chatController.text=chat;
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Icon(CupertinoIcons.pencil,color: Color.fromRGBO(192, 192, 192, 1),)
                                                          )
                                                        ],
                                                      ),
                                                      Container(
                                                        height:MediaQuery.of(context).size.width*0.4,
                                                        //color:Colors.red,
                                                        child: SingleChildScrollView(
                                                          scrollDirection: Axis.vertical,
                                                          child: Column(
                                                            children: [
                                                              Text(chat,style: TextStyle(color:Colors.black),softWrap: true,overflow: TextOverflow.visible,),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          GestureDetector(
                                                            onTap:(){
                                                              setState((){
                                                                isgeneratingc="no";
                                                              });
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                               color:Color.fromRGBO(243,244,246,1),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(4.0),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(CupertinoIcons.pencil,size: 18,),
                                                                    SizedBox(width:5),
                                                                    Text("Ask",style: TextStyle(color: Colors.black),),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          GestureDetector(
                                                            onTap: () {
                                                              User? currentUser = FirebaseAuth.instance.currentUser;
                                                              String currentUserId = currentUser?.uid ?? '';
                                                              final firestore = FirebaseFirestore.instance;

                                                              //Generating unique id for each message
                                                              var uuid=Uuid();
                                                              final messageId=uuid.v4();
                                                              final timestamp = DateTime.now().toIso8601String();
                                                              //For displaying
                                                              Map<String, dynamic> messageData = {
                                                                'senderId': currentUserId,
                                                                'messageId':messageId,
                                                                'content': chatController.text.toString(),
                                                                'timestamp': timestamp,
                                                                'messageType': "text",
                                                                'isRead':0,
                                                                'isReceived':0,
                                                                'isDelivered':0,
                                                              };
                                                              widget.onReturnValue(messageData);
                                                              SendMessages.sendTextMessage(
                                                                  message: chat,
                                                                  receiverId:widget.receiverId,
                                                                  messageId: messageId,username:widget.username
                                                              ).then(
                                                                    (value) {
                                                                  if(value!=""){
                                                                    // Pass the data to the ValueNotifier
                                                                    List data=[value,1];
                                                                    deliveryStatusNotifier.value = data;
                                                                    widget.updateDeliveryStatus(value,1);
                                                                  }
                                                                },
                                                              );
                                                              widget.onSent();
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    Color(0xFFFF4081), // Bright neon pink
                                                                    Color(0xFFFF80AB), // Light neon pink
                                                                  ],
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                ),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(4.0),
                                                                child: Row(
                                                                  children: [
                                                                    Text("Send",style: TextStyle(color: Colors.white),),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          )


                                                        ],
                                                      )

                                                    ],
                                                  ),
                                                ),

                                                    Visibility(
                                                      visible: isgeneratingc == "yes" ? true : false,
                                                      child:Transform.scale(
                                                        scale: 0.8,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                          child: Lottie.asset(
                                                            "assets/loading3.json",
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      )

                                                    ),

                                                    Visibility(
                                                      visible: isgeneratingc=="no"?true:false,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Ask Fluxion AI",
                                                            style: TextStyle(fontSize: 30, color: Color.fromRGBO(192, 192, 192, 1)),
                                                          ),
                                                          TextField(
                                                            maxLines: 5,
                                                            controller: command,
                                                            cursorColor: Color.fromRGBO(1, 102, 255, 1),
                                                            style: TextStyle(
                                                              // Add your text styling here if needed
                                                            ),
                                                            decoration: InputDecoration(
                                                              border: InputBorder.none, // Removes the border
                                                            ),
                                                            onChanged: (value) {
                                                              print(value.split('\n').length);
                                                              // Optionally, you can calculate the number of lines here if needed
                                                            },
                                                          ),


                                                          SizedBox(height:15),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                          GestureDetector(
                                                            onTap:(){
                                                              setState((){
                                                                aiscreen=1;
                                                              });
                                                            },
                                                            child: CircleAvatar(
                                                            backgroundColor:Color.fromRGBO(243,244,246,1),
                                                                                                              radius: 12,
                                                                                                              child:Icon(
                                                            CupertinoIcons.back,
                                                            color:Colors.black,
                                                            size: 20,
                                                                                                              )
                                                                                                          ),
                                                          ),

                                                              GenerateButton(onPressed: (){
                                                                setState((){
                                                                  isgeneratingc="yes";
                                                                });
                                                                 getChatFromAi("Guidelines for generating response is that generate a message based on my prompt. My prompt is: ${command.text.toString()}. Also keep in mind that you have to create only response that i can directly send regardless of saying you have not appropriate info or provide more context. My relationship with person to whom i will send ai generated messages is: ${widget.about}",1).then((value) {
                                                                   setState(() {
                                                                     isgeneratingc="done";
                                                                     chat=value;
                                                                   });
                                                                 });
                                                              }),
                                                            ],
                                                          )

                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                          ),

                                          //For showing suggestions
                                          Visibility(
                                            visible: aiscreen==2?true:false,
                                            child: Column(
                                              children:[
                                                Column(
                                                  //crossAxisAlignment: CrossAxisAlignment.start,

                                                  children: [
                                                    showLoadingQuestions==true?Column(


                                                      children: [
                                                        Container(
                                                          height:165,
                                                          width:200,
                                                          // color:Colors.red,
                                                          child: Lottie.asset(
                                                            'assets/loading1.json',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        Container(
                                                          height:40,width:200,
                                                          child: Lottie.asset(
                                                            'assets/loading2.json',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ],
                                                    ):Container(),


                                                    showLoadingQuestions==false?
                                                    Column(
                                                      children: [


                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Container(
                                                            height: 200, // Adjust height as needed
                                                            child: ListWheelScrollView.useDelegate(
                                                              itemExtent: 50, // Height of each item
                                                              onSelectedItemChanged: (index) {
                                                                setState(() {
                                                                  selectedMinute = index; // Update selected minute
                                                                });
                                                              },
                                                              childDelegate: ListWheelChildBuilderDelegate(
                                                                builder: (context, index) {
                                                                  // Customize the appearance of each minute
                                                                  return Container(
                                                                    alignment: Alignment.center,
                                                                    decoration: BoxDecoration(
                                                                      gradient: index == selectedMinute
                                                                          ? LinearGradient(
                                                                        colors: [
                                                                          Color(0xFFFF5E5B), // Neon Pink
                                                                          Color(0xFFFFC371), // Orange
                                                                          Color(0xFFFFEB3B)
                                                                        ], // Bright Yellow], // Define your gradient colors here
                                                                        begin: Alignment.topLeft,
                                                                        end: Alignment.bottomRight,
                                                                      )
                                                                          : null, // No gradient for unselected items
                                                                      color: index != selectedMinute ? Color.fromRGBO(243,244,246,1) : null, // Color fallback for unselected items
                                                                      borderRadius: BorderRadius.circular(10),
                                                                    ),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.all(2),
                                                                      child: Text(
                                                                        questions[index],
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: index == selectedMinute ? Colors.white : Colors.black,
                                                                        ),
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                childCount: questions.length, // 0 to 59 minutes
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(left:15,bottom:8,right:15),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              GestureDetector(
                                                                onTap:(){
                                                                  setState((){
                                                                    aiscreen=1;
                                                                    showLoadingQuestions=true;
                                                                  });
                                                                },
                                                                child: CircleAvatar(
                                                                    backgroundColor:Color.fromRGBO(243,244,246,1),
                                                                    radius: 12,
                                                                    child:Icon(
                                                                      CupertinoIcons.back,
                                                                      color:Colors.black,
                                                                      size: 20,
                                                                    )
                                                                ),
                                                              ),
                                                              GenerateButton(
                                                                onPressed: () {
                                                                  setState((){
                                                                    isgeneratingc="yes";
                                                                    aiscreen=3;
                                                                  });
                                                                  getChatFromAi("Guidelines for generating response is that generate a message based on my prompt. My prompt is: ${questions[selectedMinute]}  My relationship with person to whom i will send ai generated messages is: ${widget.about}",1).then((value) {
                                                                    setState(() {
                                                                      isgeneratingc="done";
                                                                      aiscreen=3;
                                                                      chat=value;
                                                                    });
                                                                  });
                                                                  print('Generating AI content...');
                                                                },
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ):Container(),







                                                    // WheelSlider.customWidget(
                                                    //   totalCount: 3,
                                                    //   initValue: 5,
                                                    //   isInfinite: false,
                                                    //   horizontal: false,
                                                    //   scrollPhysics: const BouncingScrollPhysics(),
                                                    //   children: [
                                                    //     Container(
                                                    //       height:20,width:100,
                                                    //       color:Colors.red,
                                                    //     ),
                                                    //     Container(
                                                    //       height:20,width:100,
                                                    //       color:Colors.red,
                                                    //     ),
                                                    //     Container(
                                                    //       height:20,width:100,
                                                    //       color:Colors.red,
                                                    //     ),
                                                    //   ],
                                                    //   onValueChanged: (val) {
                                                    //     setState(() {
                                                    //
                                                    //     });
                                                    //   },
                                                    //   hapticFeedbackType: HapticFeedbackType.vibrate,
                                                    //   showPointer: false,
                                                    //   itemSize: 20,
                                                    // ),

                                                  ],
                                                )

                                              ]
                                            ),
                                          )

                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                          setState(() {
                            aiscreen=1;
                            showLoadingQuestions=true;
                            isgeneratingc="no";
                            command.text="";
                          });
                        },
                        icon: Icon(Icons.bolt),
                      ),


                      IconButton(
                          onPressed: (){
        
                            showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
        
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          height:80,
                                          width:MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(Radius.circular(5)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.5), // Shadow color
                                                spreadRadius: 2, // Spread of the shadow
                                                blurRadius: 5, // Blur effect
                                                offset: Offset(2, 5), // Shadow position (x, y)
                                              ),
                                            ],
                                          ),
        
                                          child: Material(
                                            borderRadius: BorderRadius.all(Radius.circular(5)),
                                            color:Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
        
                                                  SingleChildScrollView(
                                                    controller: _scrollController1,
                                                    physics: NeverScrollableScrollPhysics(),
                                                    child: Column(
                                                      children: [
                                                        InkWell(
                                                          onTap:()async{
                                                            User? currentUser = FirebaseAuth.instance.currentUser;
                                                            String currentUserId = currentUser?.uid ?? '';
                                                            // Pick multiple files
                                                            List<PlatformFile>? files = await _fileUploadService.pickFiles();
                                                            if (files != null) {
                                                              // Upload the files (uploads continue even if screen is switched)
                                                              await _fileUploadService.uploadFiles(files,receiverId: widget.receiverId,currentUserId: currentUserId,type: 'file',
                                                                  onSavedInLocalDb: (chatData){
                                                                    widget.onReturnValue(chatData);
                                                                    print("yesssss");
                                                                  },username: widget.username,
                                                                  onDeliveryStatusUpdated: (messageId,isDelivered){
                                                                print("updateddddd");
                                                                    widget.updateDeliveryStatus(messageId,isDelivered);
                                                                  }
                                                              );
                                                            }
                                                          },
                                                          child: Column(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor: Color.fromRGBO(127,102,255,1),
                                                                child:FaIcon(
                                                                  FontAwesomeIcons.fileLines, // Document icon
                                                                  color: Colors.white,
                                                                ),
                                                              ),
        
                                                              Text("Document"),
                                                            ],
                                                          ),
                                                        ),
        
        
                                                        InkWell(
                                                          onTap: (){
                                                            _scrollController1.animateTo(
                                                              0,
                                                              duration: const Duration(milliseconds: 300),
                                                              curve: Curves.easeOut,
                                                            );
                                                            _scrollController2.animateTo(
                                                              0,
                                                              duration: const Duration(milliseconds: 300),
                                                              curve: Curves.easeOut,
                                                            );
                                                            _scrollController3.animateTo(
                                                              0,
                                                              duration: const Duration(milliseconds: 300),
                                                              curve: Curves.easeOut,
                                                            );
                                                          },
                                                          child: Column(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor: Color.fromRGBO(127,102,255,1),
                                                                child:FaIcon(
                                                                  FontAwesomeIcons.times, // Document icon
                                                                  color: Colors.white,
                                                                ),
                                                              ),
        
                                                              Text("Cancel"),
                                                            ],
                                                          ),
                                                        )
        
                                                      ],
                                                    ),
                                                  ),
        
                                                  InkWell(
                                                    onTap:(){
                                                      _scrollController1.animateTo(
                                                        _scrollController1.position.maxScrollExtent,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeOut,
                                                      );
                                                      _scrollController2.animateTo(
                                                        _scrollController2.position.maxScrollExtent,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeOut,
                                                      );
                                                      _scrollController3.animateTo(
                                                        _scrollController3.position.maxScrollExtent,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeOut,
                                                      );
                                                      //_pickImageFromCamera();
                                                    },
                                                    child: Column(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor: Color.fromRGBO(253,46,116,1),
                                                          child:FaIcon(
                                                            FontAwesomeIcons.camera, // Document icon
                                                            color: Colors.white,
                                                          ),
                                                        ),
        
                                                        Text("Camera"),
                                                      ],
                                                    ),
                                                  ),
        
                                                  SingleChildScrollView(
                                                    controller: _scrollController2,
                                                    physics: NeverScrollableScrollPhysics(),
                                                    child: Column(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor: Color.fromRGBO(200,97,250,1),
                                                          child:FaIcon(
                                                            FontAwesomeIcons.image, // Document icon
                                                            color: Colors.white,
                                                          ),
                                                        ),
        
                                                        Text("Gallery"),
        
                                                        InkWell(
                                                          onTap: ()async{
                                                            ImagePicker _picker=ImagePicker();
                                                            final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
                                                            if (pickedFile != null) {
                                                              // Convert XFile to a PlatformFile-like structure
                                                              PlatformFile platformFile = PlatformFile(
                                                                name: pickedFile.name,
                                                                path: pickedFile.path,
                                                                size: await File(pickedFile.path).length(),
                                                              );
                                                              User? currentUser = FirebaseAuth.instance.currentUser;
                                                              String currentUserId = currentUser?.uid ?? '';
                                                              // Upload the files (uploads continue even if screen is switched)
                                                              await _fileUploadService.uploadFiles([platformFile],receiverId: widget.receiverId,currentUserId: currentUserId,type: 'image',
                                                                  onSavedInLocalDb: (chatData){
                                                                    widget.onReturnValue(chatData);
                                                                  },username: widget.username,
                                                                  onDeliveryStatusUpdated: (messageId,isDelivered){
                                                                    widget.updateDeliveryStatus(messageId,isDelivered);
                                                                  }
                                                              );
                                                            }
                                                            },
                                                          child: Column(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor: Color.fromRGBO(127,102,255,1),
                                                                child:FaIcon(
                                                                  FontAwesomeIcons.images, // Document icon
                                                                  color: Colors.white,
                                                                ),
                                                              ),
        
                                                              Text("Image"),
                                                            ],
                                                          ),
                                                        )
        
                                                      ],
                                                    ),
                                                  ),
        
                                                  SingleChildScrollView(
                                                    controller: _scrollController3,
                                                    physics: NeverScrollableScrollPhysics(),
                                                    child: Column(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor: Color.fromRGBO(249,102,51,1),
                                                          child:FaIcon(
                                                            FontAwesomeIcons.volumeUp, // Document icon
                                                            color: Colors.white,
                                                          ),
                                                        ),
        
                                                        Text("Audio"),
        
                                                        InkWell(
                                                          onTap: (){},
                                                          child: Column(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor: Color.fromRGBO(127,102,255,1),
                                                                child:FaIcon(
                                                                  FontAwesomeIcons.video, // Document icon
                                                                  color: Colors.white,
                                                                ),
                                                              ),
        
                                                              Text("Video"),
                                                            ],
                                                          ),
                                                        )
        
                                                      ],
                                                    ),
                                                  ),
        
                                                ],
                                              ),
                                            ),
                                          ),
        
                                        ),
                                      ),
        
                                      SizedBox(height:55),
        
                                    ],
                                  );
                                },
                            );
        
                          },
                          icon: Icon(Icons.attach_file_rounded),
                      ),
        
        
                    ],
                  )
        
                ),
              ),
            ),
            SizedBox(width:5),
            GestureDetector(
              onTap: ()async{
                //Not send message if it is empty
                if(chatController.text.toString().trim().isEmpty){return;}
                User? currentUser = FirebaseAuth.instance.currentUser;
                String currentUserId = currentUser?.uid ?? '';
                final firestore = FirebaseFirestore.instance;
        
                widget.updateLiveChat('');
                //Generating unique id for each message
                var uuid=Uuid();
                final messageId=uuid.v4();
                final timestamp = DateTime.now().toIso8601String();
                //For displaying
                Map<String, dynamic> messageData = {
                  'senderId': currentUserId,
                  'messageId':messageId,
                  'content': chatController.text.toString(),
                  'timestamp': timestamp,
                  'messageType': "text",
                  'isRead':0,
                  'isReceived':0,
                  'isDelivered':0,
                };
                widget.onReturnValue(messageData);
                SendMessages.sendTextMessage(
                  message: chatController.text.toString(),
                  receiverId:widget.receiverId,
                  messageId: messageId,username:widget.username
                ).then(
                      (value) {
                    if(value!=""){
                      // Pass the data to the ValueNotifier
                      List data=[value,1];
                      deliveryStatusNotifier.value = data;
                      widget.updateDeliveryStatus(value,1);
                    }
                  },
                );
                widget.onSent();
                //SendMessage
                await firestore.collection('chats').doc(SendMessages.getRoomId(currentUserId, widget.receiverId)).collection('liveChats').doc(currentUserId).set({
                  'liveChat': '',
                });
        
                // Clear the text field
                chatController.clear();
              },
              child: Container(
                width:45,
                height:45,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:Color.fromRGBO(1,102,255,1)
                ),
                child:chatController.text.trim().isEmpty?Icon(Icons.mic,color:Colors.white):Icon(Icons.send_rounded,color:Colors.white),
              ),
            )
        
          ],
        ):Container(),
      ],
    );
  }
}


class GradientText extends StatelessWidget {
  final String text;
  final double textSize;
  const GradientText(this.text,this.textSize);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [

            Color(0xFFFF6F61), // Coral
            Color(0xFFFF4081), // Bright Pink

        ],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white, // Fallback color
          fontSize: textSize
        ),
      ),
    );
  }
}

class GenerateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GenerateButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:80,
        height:22,
        padding: EdgeInsets.symmetric(vertical:2, horizontal: 2), // Reduced padding
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0), // Smaller border radius
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2), // Reduced offset for shadow
              blurRadius: 5.0, // Reduced blur radius
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.flash_on, color: Colors.white,size: 14, ), // Smaller icon size
            SizedBox(width: 2), // Reduced space between icon and text
            Text(
              'Generate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

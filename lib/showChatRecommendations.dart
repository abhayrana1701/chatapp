import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mychatapplication/sendMessages.dart';
import 'package:uuid/uuid.dart';

class ShowChatRecommendations extends StatefulWidget {
  List recommendations;
  String receiverId;
  Function(String messageId,int isDelivered)updateDeliveryStatus;
  Function(Map<String, dynamic>) onReturnValue;
  Function() expand;
  ShowChatRecommendations({super.key,required this.onReturnValue,required this.expand,required this.recommendations,required this.receiverId,required this.updateDeliveryStatus});

  @override
  State<ShowChatRecommendations> createState() => _ShowChatRecommendationsState();
}

class _ShowChatRecommendationsState extends State<ShowChatRecommendations> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap:(){
              FocusScope.of(context).unfocus();
              widget.expand();
            },
            child: Icon(Icons.expand_more)
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.recommendations.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left:4,right:8,top:8,bottom:8),
                child: GestureDetector(
                  onTap: (){
                    String message=widget.recommendations[index];
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
                    widget.onReturnValue(messageData);
                    SendMessages.sendTextMessage(receiverId: widget.receiverId, message:message, messageId: messageId).then(
                          (value) {
                        if(value!=""){
                          widget.updateDeliveryStatus(value,1);
                        }
                      },
                    );
                  },
                  onDoubleTap: (){
          
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color:Color.fromRGBO(243,244,246,1,),
                    ),
                    child:Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.recommendations[index],style: TextStyle(color: Colors.black),),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

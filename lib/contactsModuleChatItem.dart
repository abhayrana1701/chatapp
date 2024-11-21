import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chatScreen.dart';

class ContactsModuleChatItem extends StatefulWidget {
  List<Map<String, dynamic>> storedContacts;
  ContactsModuleChatItem({super.key,required this.storedContacts});

  @override
  State<ContactsModuleChatItem> createState() => _ContactsModuleChatItemState();
}

class _ContactsModuleChatItemState extends State<ContactsModuleChatItem> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.storedContacts.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final contact = widget.storedContacts[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(translateToKey: contact['translateToKey'],profilePic: contact['profilePic'],username: contact['username'],about: contact['about'],name:contact['name'],receiverId: (contact['userId']))));
          },
          child: Padding(
            padding: const EdgeInsets.only(left:10,right:10,bottom: 10,top:10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:  Color.fromRGBO(243,244,246,1,),
                  child:contact["profilePic"!]==null?Icon(CupertinoIcons.person,color: Color.fromRGBO(1,102,255,1),):null,
                  backgroundImage:contact["profilePic"!]!=null ?MemoryImage(contact["profilePic"]):null,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(contact['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(contact['username']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

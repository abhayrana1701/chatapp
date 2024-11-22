import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'addContacts.dart';

class ContactsModuleAddNewContactOption extends StatefulWidget {
  const ContactsModuleAddNewContactOption({super.key});

  @override
  State<ContactsModuleAddNewContactOption> createState() => _ContactsModuleAddNewContactOptionState();
}

class _ContactsModuleAddNewContactOptionState extends State<ContactsModuleAddNewContactOption> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddContacts(),));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [

              Padding(
                padding: const EdgeInsets.only(left:10,right:15),
                child: CircleAvatar(
                  child: Icon(CupertinoIcons.person_add,color:Colors.white),
                  backgroundColor: Color.fromRGBO(1,102,255,1),
                ),
              ),

              Text("Add New Contact"),

            ],
          ),



        ],
      ),
    );
  }
}

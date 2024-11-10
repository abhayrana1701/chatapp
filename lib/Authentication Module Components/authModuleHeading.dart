import 'package:flutter/material.dart';

class AuthModuleHeading extends StatelessWidget {
  String heading;
  AuthModuleHeading({super.key,required this.heading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.125,bottom:MediaQuery.of(context).size.height*0.05),
      child: Text(heading,style: TextStyle(color: Color.fromRGBO(1,102,255,1),fontWeight: FontWeight.bold,fontSize: 30),),
    );
  }
}

import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  String text;
  bool isAuthProcessing;
  final VoidCallback onPressed;

  Button({super.key,required this.text,required this.isAuthProcessing,required this.onPressed,});

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isAuthProcessing?null:widget.onPressed,
      child: Container(
        alignment:Alignment.center,
        height:50,
        decoration:BoxDecoration(
          color: Color.fromRGBO(1,102,255,1),
          borderRadius: BorderRadius.all(Radius.circular(10),),
        ),
        child:widget.isAuthProcessing?CircularProgressIndicator(color: Colors.white,):Text(widget.text,style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
      ),
    );
  }
}
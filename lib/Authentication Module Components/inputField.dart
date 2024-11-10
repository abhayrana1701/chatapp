import 'package:flutter/material.dart';

class InputField extends StatefulWidget {

  TextEditingController controller;
  String hintText;
  bool showSuffixIcon;
  InputField({super.key,required this.controller,required this.hintText,required this.showSuffixIcon});

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {

  bool isObscure=false;

  @override
  Widget build(BuildContext context) {
    return TextField(

      controller: widget.controller,
      cursorColor: Color.fromRGBO(1,102,255,1),
      keyboardType: TextInputType.emailAddress,
      obscureText: isObscure,

      decoration: InputDecoration(
        fillColor: Color.fromRGBO(243,244,246,1,),
        filled:true,
        hintText: widget.hintText,

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
        suffixIcon: widget.showSuffixIcon?IconButton(
          onPressed: (){
            setState(() {
              isObscure=!isObscure;
            });
          },
          icon: isObscure?Icon(Icons.visibility ): Icon(Icons.visibility_off),
        ):null,

      ),
    );
  }
}
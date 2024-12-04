import 'package:flutter/material.dart';
import 'Authentication Module Components/authModuleHeading.dart';
import 'Authentication Module Components/button.dart';
import 'Authentication Module Components/inputField.dart';

class RecoverPassword extends StatefulWidget {
  const RecoverPassword({super.key});

  @override
  State<RecoverPassword> createState() => _RecoverPasswordState();
}

class _RecoverPasswordState extends State<RecoverPassword> {

  //TextEditingControllers
  TextEditingController emailController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body:Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [

              AuthModuleHeading(heading: "Recover Password"),

              //Input Fields
              InputField(controller: emailController, hintText: "Email",showSuffixIcon: false,isObscure: false,),

              SizedBox(height:MediaQuery.of(context).size.height*0.02),
              Button(isAuthProcessing: false,text: "Continue",onPressed: (){}),

            ],
          ),
        ),
      )

    );
  }
}

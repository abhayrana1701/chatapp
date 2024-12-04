import 'package:flutter/material.dart';
import 'package:mychatapplication/Authentication%20Module%20Components/authModuleHeading.dart';
import 'Authentication Module Components/authOptionToggle.dart';
import 'Authentication Module Components/button.dart';
import 'Authentication Module Components/inputField.dart';
import 'Resuable Components/showSnackbar.dart';
import 'emailVerfication.dart';
import 'signin.dart';
import 'signup2.dart';
import 'validate.dart';

class Signup1 extends StatefulWidget {
  const Signup1({super.key});

  @override
  State<Signup1> createState() => _Signup1State();
}

class _Signup1State extends State<Signup1> {

  //TextEditingControllers
  TextEditingController emailController=TextEditingController();
  TextEditingController passwordController=TextEditingController();
  TextEditingController confirmPasswordController=TextEditingController();

  //Error messages
  String emailErrorMessage="";
  String passwordErrorMessage="";
  String confirmPasswordErrorMessage="";

  //Show status
  bool isAuthProcessing=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body:Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children:[

              AuthModuleHeading(heading: "Register"),

              //Input Fields
              InputField(controller: emailController, hintText: "Email",showSuffixIcon: false,isObscure: false,),
              Align(alignment:Alignment.centerLeft,child: Text(" $emailErrorMessage",style: TextStyle(color:Colors.red),)),
              SizedBox(height:MediaQuery.of(context).size.height*0.03),
              InputField(controller: passwordController, hintText: "Password",showSuffixIcon: true,isObscure: true,),
              Align(alignment:Alignment.centerLeft,child: Text(" $passwordErrorMessage",style: TextStyle(color:Colors.red),)),
              SizedBox(height:MediaQuery.of(context).size.height*0.03),
              InputField(controller: confirmPasswordController, hintText: "Confirm Password",showSuffixIcon: true,isObscure: true,),
              Align(alignment:Alignment.centerLeft,child: Text(" $confirmPasswordErrorMessage",style: TextStyle(color:Colors.red),)),

              SizedBox(height:MediaQuery.of(context).size.height*0.02),
              Button(
                isAuthProcessing: isAuthProcessing,
                text: "Continue",
                onPressed: ()async{
                    setState(() {
                      isAuthProcessing=true;
                    });
                    FocusScope.of(context).unfocus();
                    emailErrorMessage=Validate.validateEmail(emailController.text.toString())!;
                    passwordErrorMessage=Validate.validatePassword(passwordController.text.toString())!;
                    confirmPasswordErrorMessage=Validate.validateConfirmPassword(passwordController.text.toString(), confirmPasswordController.text.toString())!;
                    if(emailErrorMessage=='' && passwordErrorMessage=='' && confirmPasswordErrorMessage==''){
                      if(await Validate.doesEmailExist(emailController.text.toString())){
                        setState(() {
                          isAuthProcessing=false;
                        });
                        ShowSnackbar.showSnackbar(context: context,color: Colors.red,message: "Email already exists, please sign in or use a different one to sign up.");
                      }
                      else{
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => Signup2(email: emailController.text.toString(),password: passwordController.text.toString(),),));
                      }
                    }
                    setState(() {
                      isAuthProcessing=false;
                    });
                  },
              ),

              SizedBox(height:MediaQuery.of(context).size.height*0.03),
              AuthoptionToggle(text1: "Already have an account? ",text2: "Sign In",navigateToScreen: Signin(),)

            ],
          ),
        ),
      ),

    );
  }
}



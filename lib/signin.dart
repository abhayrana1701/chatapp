import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Resuable Components/showSnackbar.dart';
import 'Authentication Module Components/authModuleHeading.dart';
import 'Authentication Module Components/authOptionToggle.dart';
import 'Authentication Module Components/button.dart';
import 'Authentication Module Components/inputField.dart';
import 'databaseHelper.dart';
import 'home.dart';
import 'recoverPassword.dart';
import 'signup1.dart';
import 'fcmTokenHandler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {

  //TextEditingControllers
  TextEditingController emailController=TextEditingController();
  TextEditingController passwordController=TextEditingController();

  bool isLogging=false;

  void signin()async{
    FocusScope.of(context).unfocus();

    setState(() {
      isLogging=true;
    });

    FirebaseAuth firebaseAuth=FirebaseAuth.instance;
    try{
      UserCredential userCredential=await firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text.toString(),
        password: passwordController.text.toString(),
      );

      //Initialize the user-specific database
      await DatabaseHelper().initDatabase(userCredential.user!.uid);

      //On Successful sign-in
      //Store FCM token
      FCMTokenHandler().storeFCMToken(userCredential.user!.uid);

      //Store that user is signed in
      final prefs=await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn',true);

      //Navigate to home screen on successful sign in
      //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home(),));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Home()),
              (Route<dynamic> route) => false // This removes all previous routes
      );


    }on FirebaseAuthException catch (e){
      String message;
      switch (e.code) {
        case 'invalid-credential':
          message = 'The credentials are not valid.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Something went wrong. Please try again.';
      }
      setState(() {
        isLogging=false;
      });
      ShowSnackbar.showSnackbar(context: context,color: Colors.red,message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body:Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children:[
          
              AuthModuleHeading(heading: "Sign In"),
          
              //Input Fields
              InputField(controller: emailController, hintText: "Email",showSuffixIcon: false,),
              SizedBox(height:MediaQuery.of(context).size.height*0.04),
              InputField(controller: passwordController, hintText: "Password",showSuffixIcon: true,),
          
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                    onTap: (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => RecoverPassword(),));
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.02, bottom: MediaQuery.of(context).size.height*0.02),
                      child: Text("Forgot Password?",style: TextStyle(color: Color.fromRGBO(1,102,255,1),),),
                    )
                ),
              ),
          
              Button(isAuthProcessing: isLogging,text: "Log In",onPressed: (){signin();},),
          
              SizedBox(height:MediaQuery.of(context).size.height*0.03),
              AuthoptionToggle(text1: "Don't have an account? ",text2: "Sign Up",navigateToScreen: Signup1(),)
          
            ]
          ),
        ),
      ),

    );
  }
}



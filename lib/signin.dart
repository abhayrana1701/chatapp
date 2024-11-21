import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {


  Future<void> fetchAndSaveUserDetails(String userId) async {
    try {
      // Step 1: Fetch the user data from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('userDetails') // Replace with your collection name
          .doc(userId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data()!;

        // Step 2: Handle profile picture URL (check for null or empty string)
        String? profilePicUrl = userData['profilePic']; // Assuming 'profilePicUrl' field is available
        Uint8List? profilePic;

        if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
          // Only download if the URL is not empty
          profilePic = await downloadProfilePicture(profilePicUrl);
        } else {
          // Handle case where there's no profile picture URL (either null or empty)
          profilePic = null;
        }

        // Step 3: Store the data in SQLite database
        DatabaseHelper db = DatabaseHelper();
        await db.insertUser(
          username: userData['username'],
          userId: userData['userId'],
          name: userData['name'],
          email: userData['email'],
          profilePic: profilePic,
        );

        // Step 4: Update the UI
        setState(() {

        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }


  Future<Uint8List?> downloadProfilePicture(String url) async {
    try {
      // Download the image from Firebase Storage using the URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes; // Return the image data as bytes (Uint8List)
      } else {
        print("Failed to download profile picture");
        return null;
      }
    } catch (e) {
      print("Error downloading profile picture: $e");
      return null;
    }
  }


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
      DatabaseHelper db=DatabaseHelper();
      await fetchAndSaveUserDetails(userCredential.user!.uid);
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



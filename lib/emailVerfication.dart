import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Authentication Module Components/authModuleHeading.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'Resuable Components/showSnackbar.dart';
import 'home.dart';
import 'signup2.dart';

class EmailVerification extends StatefulWidget {
  String username,name,email,password;
  EmailVerification({super.key,required this.username,required this.name,required this.email,required this.password});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {


  //Create new user
  Future<void> signup() async {
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Get the user ID
      String userId = userCredential.user!.uid;

      // Call function to create user details in Firestore
      await createUserDetails(userId);
    } catch (e) {
      ShowSnackbar.showSnackbar(context: context, message: "Something went wrong. Please try again.", color: Colors.red);
    }
  }

  Future<void> createUserDetails(String userId) async {
    try {
      // Reference to Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Add user details to 'userDetails' collection
      await firestore.collection('userDetails').doc(userId).set({
        'username': widget.username,
        'name': widget.name,
        'email': widget.email,
        'userId':userId,
        'isOnline': '',
        'lastScene': '',
        'profilePic': '', // Store profile pic URL when available
      });

      // Initialize subcollections
      await firestore.collection('userDetails').doc(userId).collection('contacts').add({});
      await firestore.collection('userDetails').doc(userId).collection('requestsSent').add({});
      await firestore.collection('userDetails').doc(userId).collection('requestsReceived').add({});

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home(),));

    } catch (e) {
      ShowSnackbar.showSnackbar(context: context, message: "Something went wrong. Please try again.", color: Colors.red);
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
            children: [

              AuthModuleHeading(heading: "Verify Email"),

              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  text: "Please enter the 4-digit OTP sent to your email for verification.",
                  children: [
                    TextSpan(
                      text:"Change email?",
                      style: TextStyle(color:Color.fromRGBO(1,102,255,1),),
                    )
                  ]
                )
              ),

              Padding(
                padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.04,bottom:MediaQuery.of(context).size.height*0.04),
                child: OtpTextField(
                  numberOfFields: 4,
                  borderColor: Color.fromRGBO(1,102,255,1),
                  fillColor: Color.fromRGBO(243,244,246,1,),
                  filled: true,

                  enabledBorderColor: Colors.transparent,
                  focusedBorderColor: Color.fromRGBO(1,102,255,1),
                  cursorColor: Color.fromRGBO(1,102,255,1),

                  //set to true to show as box or false to show as dash
                  showFieldAsBox: true,
                  //runs when a code is typed in
                  onCodeChanged: (String code) {
                    //handle validation or checks here
                  },
                  //runs when every textfield is filled
                  onSubmit: (String verificationCode)async{
                    // Reference to the Firestore collection
                    CollectionReference collectionRef = FirebaseFirestore.instance.collection("emailVerifications");
                    DocumentSnapshot docSnapshot = await collectionRef.doc(widget.email).get();

                    // Document exists, check the timestamp of the existing document
                    Timestamp existingOtpTimestamp = docSnapshot.get('timestampOfLastReceivedOtp');
                    Timestamp currentTime = Timestamp.now();

                    // Calculate the time difference in hours
                    Duration difference = currentTime.toDate().difference(existingOtpTimestamp.toDate());

                    if(difference.inHours>24){
                      await collectionRef.doc(widget.email).update({
                        "attempts":0,
                      });
                    }

                    var otp=docSnapshot.get('otp');
                    var attempts=docSnapshot.get('attempts');
                    if(attempts>2){
                      ShowSnackbar.showSnackbar(context: context, message: "Too much attempts.", color: Colors.red);
                      return;
                    }

                    if(difference.inMinutes<10 && otp.toString()==verificationCode.toString()){
                      signup().then((value) {
                        //Navigator.of(context).push(MaterialPageRoute(builder: (context) => Home(),));
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => Home()),
                                (Route<dynamic> route) => false // This removes all previous routes
                        );

                      },);
                    }
                    else{
                      await collectionRef.doc(widget.email).update({
                        "attempts":FieldValue.increment(1),
                      });
                      ShowSnackbar.showSnackbar(context: context, message: "Otp is not valid.", color: Colors.red);
                    }
                  }, // end onSubmit
                ),
              ),

              Text("Enter 4-digit code."),
              SizedBox(height:MediaQuery.of(context).size.height*0.015),
              Text("Didn't receive code?",style: TextStyle(color:Color.fromRGBO(1,102,255,1)),),

            ],
          ),
        ),
      )

    );
  }
}

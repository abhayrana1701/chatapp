import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychatapplication/emailVerfication.dart';
import 'Resuable Components/showSnackbar.dart';
import 'Authentication Module Components/authModuleHeading.dart';
import 'Authentication Module Components/button.dart';
import 'Authentication Module Components/inputField.dart';
import 'home.dart';
import 'validate.dart';

class Signup2 extends StatefulWidget {
  final String email,password;
  const Signup2({super.key,required this.email,required this.password});

  @override
  State<Signup2> createState() => _Signup2State();
}

class _Signup2State extends State<Signup2> {

  //TextEditingControllers
  TextEditingController firstNameController=TextEditingController();
  TextEditingController lastNameController=TextEditingController();
  TextEditingController userNameController=TextEditingController();

  //Error messages
  String firstNameErrorMessage="";
  String lastNameErrorMessage="";
  String userNameErrorMessage="";

  //show status
  bool isAuthProcessing=false;

  Future<void> createVerificationDocument() async {
    // Reference to the Firestore collection
    CollectionReference collectionRef = FirebaseFirestore.instance.collection("emailVerifications");

    try {
      // Check if the document exists
      DocumentSnapshot docSnapshot = await collectionRef.doc(widget.email).get();

      // If the document does not exist, create it with the data
      if (!docSnapshot.exists) {
        await collectionRef.doc(widget.email).set({
          "email": widget.email,
          "attempts":0,
          "otp":"",
          "timestampOfLastReceivedOtp":FieldValue.serverTimestamp(),
          "status":"requireotp",
        });
        print("Document successfully created!");
      } else {

        // Document exists, check the timestamp of the existing document
        Timestamp existingOtpTimestamp = docSnapshot.get('timestampOfLastReceivedOtp');
        Timestamp currentTime = Timestamp.now();

        // Calculate the time difference in hours
        Duration difference = currentTime.toDate().difference(existingOtpTimestamp.toDate());

        // Check if the time difference is more than 24 hours
        if (difference.inHours >= 24) {
          // If more than 24 hours, update the specified fields and additional fields
          await collectionRef.doc(widget.email).update({
            "status":"requireotp",
            "attempts":0,
          });
          print("Document updated with specific fields and additional fields due to time condition!");
        } else {
          // Just update the usual fields
          await collectionRef.doc(widget.email).update({
            "status":"requireotp",
          });
          print("Document updated with specific fields!");
        }
      }
    } catch (e) {
      print("Error creating document: $e");
    }
  }

  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void dispose() {
    // Cancel the listener when the widget is disposed to avoid memory leaks
    _subscription?.cancel();
    super.dispose();
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

              AuthModuleHeading(heading: "Profile Info"),

              Text("Please provide your name, username, and an optional profile picture.",textAlign: TextAlign.center,),
              Padding(
                padding: const EdgeInsets.only(top:8,bottom:15),
                child: CircleAvatar(
                  backgroundColor: Color.fromRGBO(243,244,246,1,),
                  radius: 50,
                  child: Icon(Icons.add_a_photo_outlined,color:Colors.grey),
                ),
              ),

              //Input Fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        InputField(controller: firstNameController, hintText: "First Name",showSuffixIcon: false,),
                        Align(alignment:Alignment.centerLeft,child: Text("$firstNameErrorMessage",style: TextStyle(color:Colors.red),)),
                      ],
                    ),
                  ),
                  SizedBox(width:5),
                  Expanded(
                    child: Column(
                      children: [
                        InputField(controller: lastNameController, hintText: "Last Name",showSuffixIcon: false,),
                        Align(alignment:Alignment.centerLeft,child: Text("$lastNameErrorMessage",style: TextStyle(color:Colors.red),)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height:MediaQuery.of(context).size.height*0.025),
              InputField(controller: userNameController, hintText: "User Name",showSuffixIcon: false,),
              Align(alignment:Alignment.centerLeft,child: Text("$userNameErrorMessage",style: TextStyle(color:Colors.red),)),

              SizedBox(height:MediaQuery.of(context).size.height*0.025),
              Button(
                isAuthProcessing: isAuthProcessing,
                text: "Finish Registration",
                onPressed: (){
                  setState(() {
                    firstNameErrorMessage=Validate.validateName(firstNameController.text.toString())!;
                    lastNameErrorMessage=Validate.validateName(lastNameController.text.toString())!;
                    userNameErrorMessage=Validate.validateUsername(userNameController.text.toString())!;

                    isAuthProcessing=true;

                    if(firstNameErrorMessage=='' && lastNameErrorMessage=='' && userNameErrorMessage==''){
                      createVerificationDocument().then(
                        (value) async{
                          // Reference to the Firestore collection
                          CollectionReference collectionRef = FirebaseFirestore.instance.collection('emailVerifications');

                          // Set up a real-time listener on the document
                          _subscription= collectionRef.doc(widget.email).snapshots().listen((docSnapshot) {
                            if (docSnapshot.exists) {
                              // Get the value of the 'status' field
                              String status = docSnapshot.get('status');

                              // Check if the status is 'haveotp'
                              if (status == 'haveotp') {
                                // Stop listening immediately before performing the action
                                _subscription?.cancel();
                                // Perform the desired action
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmailVerification(
                                  email: widget.email,
                                  name: firstNameController.text.toString()+" "+lastNameController.text.toString(),
                                  password: widget.password,
                                  username: userNameController.text.toString(),
                                ),));
                                print("Action performed");
                              } else {
                                print("Status is not 'haveotp'. Listening for changes...");
                              }
                            } else {
                              isAuthProcessing=false;
                              print("Document does not exist.");
                            }
                          });
                        },
                      );
                    }else{
                      setState(() {
                        isAuthProcessing=false;
                      });
                    }
                  });
                },
              ),

            ],
          ),
        ),
      )

    );
  }
}

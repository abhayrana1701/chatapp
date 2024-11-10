import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Validate{

  static String? validateEmail(String email) {
    // Regular expression for validating email format
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    if (email.isEmpty) {
      return 'Email cannot be empty';
    } else if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return ''; // Valid email
  }

  static String? validatePassword(String password) {
    // Password criteria: At least 8 characters, contains a letter and a number
    if (password.isEmpty) {
      return 'Password cannot be empty';
    } else if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return ''; // Valid password
  }

  static String? validateConfirmPassword(String password,String confirmPassword){
    if(password!=confirmPassword){
      return "Password and confirm password do not match";
    }
    return '';
  }

  static Future<bool> doesEmailExist(String email) async {
    // Reference to the userDetails collection
    final CollectionReference userDetails = FirebaseFirestore.instance.collection('userDetails');

    // Query Firestore to check if any document has the given email
    final QuerySnapshot result = await userDetails.where('email', isEqualTo: email).get();

    // Check if the query returned any documents
    if (result.docs.isNotEmpty) {
      return true; // Email exists
    } else {
      return false; // Email does not exist
    }
  }

  static String? validateName(String name) {
    // Regular expression for alphabet-only name
    final RegExp nameRegex = RegExp(r"^[a-zA-Z]+$");

    if (name.isEmpty) {
      return 'Name cannot be empty';
    } else if (!nameRegex.hasMatch(name)) {
      return 'Name should only contain alphabets';
    }
    return ''; // Valid name
  }

  static String? validateUsername(String username) {
    // Regular expression for valid username (alphabets, numbers, underscores)
    final RegExp usernameRegex = RegExp(r"^[a-zA-Z0-9_]+$");

    if (username.isEmpty) {
      return 'Username cannot be empty';
    } else if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return ''; // Valid username
  }


}
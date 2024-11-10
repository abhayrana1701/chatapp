import 'package:flutter/material.dart';

class ShowSnackbar{
  static void showSnackbar({ required BuildContext context, required String message,required Color color}){
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white), // Text color
      ),
      backgroundColor: color, // Red background color
      behavior: SnackBarBehavior.floating, // Allows padding from edges
      margin: EdgeInsets.only(
        bottom: 20.0, // Bottom padding
        left: 20.0,   // Left padding
        right: 20.0,  // Right padding
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

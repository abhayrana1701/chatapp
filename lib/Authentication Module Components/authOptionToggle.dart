import 'package:flutter/material.dart';

class AuthoptionToggle extends StatelessWidget {
  String text1,text2;
  final navigateToScreen;
  AuthoptionToggle({super.key,required this.text1,required this.text2,required this.navigateToScreen});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text1),
        InkWell(
            onTap: (){
              //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => navigateToScreen,));
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => navigateToScreen),
                      (route) => route.isFirst // This ensures only the first route in the stack remains
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top:10,bottom:10),
              child: Text(text2,style: TextStyle(color: Color.fromRGBO(1,102,255,1),),),
            )
        )
      ],
    );
  }
}

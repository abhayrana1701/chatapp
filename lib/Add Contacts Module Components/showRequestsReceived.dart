import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'showContact.dart';

class ShowRequestsReceived extends StatefulWidget {
  const ShowRequestsReceived({super.key});

  @override
  State<ShowRequestsReceived> createState() => _ShowRequestsReceivedState();
}

class _ShowRequestsReceivedState extends State<ShowRequestsReceived> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadRequestsReceived();
  }

  //
  double animatedContainerHeight=50.5;

  //
  String viewToggleText="View More";

  //Show requests loading status
  bool isLoading=false;

  //Store received requests
  List<Map<String,dynamic>> receivedRequests=[];

  //Function to load received requests
  Future<void> loadRequestsReceived() async {

    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser?.uid ?? '';

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      List<Map<String, dynamic>> loadedRequests = [];

      // Fetch requests from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(currentUserId)
            .collection('requestsReceived')
            .get();

        for (var requestDoc in requestsSnapshot.docs) {
          Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;
          if (requestData.isNotEmpty) {
            loadedRequests.add(requestData);
          }
        }
      } else {
        print('User document does not exist.');
      }

      setState(() {
        receivedRequests = loadedRequests;
        if(receivedRequests.length>1){
          animatedContainerHeight=111;
        }
      });
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(" Added Me",style: TextStyle(fontSize: 15),),
            IconButton(
                onPressed: (){loadRequestsReceived();},
                icon: Icon(Icons.refresh_rounded,color: Color.fromRGBO(1,102,255,1),)
            )
          ],
        ),

        AnimatedContainer(
            height:animatedContainerHeight,
            width:MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            duration: Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color:Colors.white,
              border: Border(top: BorderSide(color: Colors.grey,width:0.5),left: BorderSide(color: Colors.grey,width:0.5),right: BorderSide(color: Colors.grey,width:0.5)),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
            ),
            //child: receivedRequests.length==0?Text("No requests Received"):ShowContact(),
        ),

        InkWell(
          onTap: (){
            if(viewToggleText=="View More"){
              if(receivedRequests.length>2){
                setState(() {
                  animatedContainerHeight=55.5*receivedRequests.length;
                  viewToggleText="View Less";
                });
              }
            }
            else{
              setState(() {
                animatedContainerHeight=111;
                viewToggleText="View More";
              });
            }
          },
          child: Container(
            alignment: Alignment.center,
            width:MediaQuery.of(context).size.width,
            height:40,
            decoration: BoxDecoration(
              color:Colors.white,
              border: Border.all(color: Colors.grey,width:0.5),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
            ),
            child:Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(viewToggleText,style: TextStyle(color:Color.fromRGBO(1,102,255,1)),),
            ),
          ),
        )

      ],
    );
  }
}


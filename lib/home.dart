import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glowy_borders/glowy_borders.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'Resuable Components/showSnackbar.dart';
import 'addContacts.dart';
import 'chatScreen.dart';
import 'contacts.dart';
import 'databaseHelper.dart';
import 'userStatusService.dart';
import 'signin.dart';
import 'package:share/share.dart';
import 'package:lottie/lottie.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{

  final UserStatusService _statusService = UserStatusService();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Map<String, dynamic>? userDetails;

  // Fetch user details from SQLite
  Future<void> fetchUserDetails() async {
    DatabaseHelper db = DatabaseHelper();
    var userData = await db.getUser();

    setState(() {
      userDetails = userData;
    });
  }

  int selectedOption=0;
  List<double> widths =[0.0,0.0,0.0,0.0,0.0,0.0];
  int oldIndex=0;
  List<Map<String, dynamic>> contactsWithRecentChat = [];
  List<Map<String, dynamic>> contactsImageWithRecentChat = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusService.updateOnlineStatus();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    fetchUserDetails();
    Timer.periodic(Duration(milliseconds: 500), (timer) {

      _fetchContactsWithRecentChat();
    });

  }

  List options=["My Profile Pic","Add Contacts","Share App","Reset Password","Log Out","Smart Notification"];
  List<IconData> icons = [
    CupertinoIcons.person_crop_circle,    // "My Profile"
    CupertinoIcons.phone,                 // "Contacts"
    CupertinoIcons.share,                 // "Share App"
    CupertinoIcons.lock,                  // "Reset Password"
    CupertinoIcons.square_arrow_right,    // "Log Out"
    CupertinoIcons.bell
  ];

  Future<void> uploadProfilePicture(ImageSource source) async {
    try {
      // Step 1: Select Image from Gallery or Camera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source,imageQuality: 50);

      if (image == null) {
        print("No image selected");
        return;
      }

      // Convert XFile to File
      File imageFile = File(image.path);

      // Step 2: Get Current User ID
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User is not logged in");
        return;
      }
      String userId = currentUser.uid;

      // Step 3: Upload Image to Firebase Storage
      String fileName = 'profile_pic_$userId.jpg';
      Reference storageRef =
      FirebaseStorage.instance.ref().child('profilePics').child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete and get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Step 4: Update Firestore with the Profile Picture URL
      await FirebaseFirestore.instance.collection('userDetails').doc(userId).update({
        'profilePic': downloadUrl,
      }).then(
        (value) async{
          Uint8List imageBytes = await image.readAsBytes();
          DatabaseHelper db=DatabaseHelper();
          await db.updateProfilePic(userId, imageBytes);
          ShowSnackbar.showSnackbar(context: context, message: "Profile picture updated successfully.", color:  Color.fromRGBO(1,102,255,1),);
          setState(() {
            fetchUserDetails();
          });
        },
      );

      print("Profile picture updated successfully.");
    } catch (e) {
      ShowSnackbar.showSnackbar(context: context, message: "Error updating prfile picture.", color:  Colors.red,);
      print("Error uploading profile picture: $e");
    }
  }


  Future<void> showNotification() async {
    // Remove the 'const' keyword as this is dynamically created
    var inboxStyle = InboxStyleInformation(
      ['Line 1', 'Line 2', 'Line 3', 'Line 4'], // Add as many lines as you want
      contentTitle: 'Multi-line Notification Title',
      summaryText: 'Summary of the notification',
    );

    // Remove 'const' keyword from AndroidNotificationDetails
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id', // Channel ID
      'channel_name', // Channel name
      styleInformation: inboxStyle, // Pass the inbox style
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker', // Optional ticker for older Android versions
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Display the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Unique notification ID
      'Test Title', // Notification title
      'Test Body', // Notification body
      platformChannelSpecifics, // Notification details
      payload: 'Notification Payload', // Optional payload
    );
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _statusService.updateOfflineStatus();
    } else if (state == AppLifecycleState.resumed) {
      _statusService.updateOnlineStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusService.updateOfflineStatus();
    super.dispose();
  }

  Future<void>resetPassword()async{
    Navigator.of(context).pop();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: userDetails?['email'],
      );
      ShowSnackbar.showSnackbar(context: context,color:  Color.fromRGBO(1,102,255,1),message: "Password reset email sent! Check your inbox.");
    } catch (e) {

      ShowSnackbar.showSnackbar(context: context,color: Colors.red,message:"Failed to send password reset email: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getContactsWithRecentChat() async {
    final db = await DatabaseHelper();

    // Step 1: Fetch contacts
    final contacts = await db.getContacts();

    // Step 2: Create a list to hold contacts with their most recent chat
    List<Map<String, dynamic>> contactsWithRecentChat = [];

    // Step 3: For each contact, get the most recent chat
    for (var contact in contacts) {
      final contactId = contact['userId']; // Assuming 'userId' is the unique identifier for each contact

      User? currentUser = FirebaseAuth.instance.currentUser;
      String currentUserId = currentUser?.uid ?? '';

      var recentChat;
      // Fetch the most recent chat for this contact
      try{
        final tempRecentChat = await db.getRecentChats(currentUserId, contactId);
        if (tempRecentChat != null && tempRecentChat.isNotEmpty) {
          recentChat = tempRecentChat;
        }else{
          continue;
        }

        // print("Aaaaaa$tempRecentChat");
        // print("rrrrrrrrrrrrrr $recentChat");
      }catch(e){

      }

      // Make a copy of the contact to allow modification
      Map<String, dynamic> modifiableContact = Map.from(contact);

      try{
        modifiableContact['recentChat'] = recentChat.isNotEmpty ? recentChat.first : null;
      }catch(e){}
      // Only take the first element if recentChat is not empty


      // Add the contact with recent chat to the list
      contactsWithRecentChat.add(modifiableContact);
    }

    // Step 4: Sort the contacts based on the timestamp of the most recent chat

    contactsWithRecentChat.sort((a, b) {
      final aTimestamp = a['recentChat']?['timestamp'];
      final bTimestamp = b['recentChat']?['timestamp'];

      // If either timestamp is null, consider it less recent
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;

      // Parse timestamps to DateTime for comparison
      final aDate = DateTime.parse(aTimestamp);
      final bDate = DateTime.parse(bTimestamp);
print(aDate);
print(bDate);
      return bDate.compareTo(aDate); // Sort in descending order (most recent first)
    });

    return contactsWithRecentChat;
  }


  Future<void> _fetchContactsWithRecentChat() async {
    int oldLen= contactsWithRecentChat.length;
    contactsWithRecentChat = await getContactsWithRecentChat();
    if(contactsWithRecentChat.length!=oldLen){
      contactsImageWithRecentChat=contactsWithRecentChat;
    }
    setState(() {}); // Update the UI after fetching data
  }



  bool showSearchBox=false;
  TextEditingController searchController=TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: showSearchBox?
        TextField(

          controller: searchController,
          cursorColor: Color.fromRGBO(1,102,255,1),
          keyboardType: TextInputType.emailAddress,
          focusNode: _focusNode,

          decoration: InputDecoration(
            fillColor: Color.fromRGBO(243,244,246,1,),
            filled:true,
            hintText: "Search...",

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Rounded border
              borderSide: BorderSide(color: Colors.transparent), // No border by default
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Rounded border
              borderSide: BorderSide(color: Colors.white, width: 2), // Blue border when enabled
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Rounded border
              borderSide: BorderSide(color:Color.fromRGBO(1,102,255,1), width: 2),
            ),
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.only(left:15,right:10),
            suffixIcon: InkWell(
              onTap:(){
                setState(() {
                  showSearchBox=false;
                  FocusScope.of(context).unfocus();
                });
              },
                child: Icon(CupertinoIcons.clear)
            ),
          ),

          onChanged: (value){

          },

        )
        :Text("Flash"),
        automaticallyImplyLeading: false,
        actions: [

          !showSearchBox?IconButton(
              onPressed: (){
                setState((){
                  showSearchBox=true;
                  _focusNode.requestFocus();
                });
              },
              icon: Icon(Icons.search_rounded),
          ):Container(),

        ],
      ),

      body:Column(
        children: [

          if(contactsWithRecentChat.length==0)...[
            Lottie.asset(
              'assets/addContacts.json',
              width: 300,
              height: 300,
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Text(
                "Step into Flash – Where Conversations Ignite Instantly!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Connect, Chat, and Spark New Conversations – All in a Flash!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
            ),

          ],

          Expanded(
            child:ListView.builder(
              itemCount: contactsWithRecentChat.length,
              itemBuilder: (context, index) {
                final contact = contactsWithRecentChat[index];
                final image=contactsImageWithRecentChat[index];

                // Assuming recentChat is a Map with keys 'message' and 'timestamp'
                final recentChat = contact['recentChat'];
                final recentMessage = recentChat != null ? recentChat['content'] : 'No messages';
                final isoDateString= recentChat != null ? recentChat['timestamp'] : '';
                String date='';
                void formatIsoDate() {
                  DateTime dateTime = DateTime.parse(isoDateString);
                  DateTime now = DateTime.now();
                  DateTime yesterday = now.subtract(Duration(days: 1));

                  // Check if the date is today
                  if (dateTime.year == now.year &&
                      dateTime.month == now.month &&
                      dateTime.day == now.day) {
                    // Return the time in hour:minute AM/PM format
                    date= DateFormat.jm().format(dateTime); // e.g., "2:30 PM"
                  }

                  // Check if the date is yesterday
                  else if (dateTime.year == yesterday.year &&
                      dateTime.month == yesterday.month &&
                      dateTime.day == yesterday.day) {
                    date= "Yesterday";
                  }

                  // Return the date in dd/mm/yyyy format
                  else {
                    date= DateFormat('dd/MM/yyyy').format(dateTime);
                  }
                }
                formatIsoDate();


                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(translateToKey: contact["translateToKey"],profilePic: contact['profilePic'],username: contact['username'],about: contact['about'],name:contact['name'],receiverId: (contact['userId'])))).then(
                      (value) {
                        _fetchContactsWithRecentChat();
                      },
                    );
                    // Handle tap action
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor:  Color.fromRGBO(243,244,246,1,),
                          child:image["profilePic"!]==null?Icon(CupertinoIcons.person,color: Color.fromRGBO(1,102,255,1),):null,
                          backgroundImage:image["profilePic"!]!=null ?MemoryImage(image["profilePic"]):null,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    contact['name'] ?? 'Unknown', // Replace with the contact's name
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(date),
                                ],
                              ),
                              Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if(recentChat['messageType']=="file")...[
                                    FaIcon(CupertinoIcons.doc,size: 15,),
                                    Container(width:5),
                                    Flexible(
                                      child: Text(jsonDecode(recentMessage)['name'],maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    ),
                                    Container(width:10),
                                  ],

                                  if(recentChat['messageType']=="image")...[
                                    FaIcon(CupertinoIcons.photo,size: 15,),
                                    Container(width:5),
                                    Flexible(
                                      child: Text(jsonDecode(recentMessage)['name'],maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    ),
                                    Container(width:10),
                                  ],

                                  if(recentChat['messageType']=="text")...[
                                    Expanded(
                                      child: Text(recentMessage,maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    ),
                                    Container(width:10),
                                  ],
                                  if (recentChat != null && recentChat['unreadCount']!=0) // Only show if there's a recent chat
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(1, 102, 255, 1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        recentChat['unreadCount'].toString(), // Replace with the actual unread message count if available
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),

                                ],
                              ),

                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
            )

          )

        ],
      ),

      floatingActionButton: ElevatedButton(
        onPressed: (){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => Contacts(),)).then(
            (value) {
              _fetchContactsWithRecentChat();
            },
          );
        },
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          minimumSize: Size(50,50),
          backgroundColor:  Color.fromRGBO(1,102,255,1),
        ),
        child:Icon(Icons.chat_bubble,color:Colors.white),
      ),

      drawer: Drawer(
        backgroundColor:Colors.white,
        child: Container(
            width:MediaQuery.of(context).size.width*0.6,
            height:MediaQuery.of(context).size.height,
            color: Colors.white,
            child:Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height:50),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:Color.fromRGBO(243,244,246,1,),
                    child:CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: userDetails?['profilePic']!=null?MemoryImage(userDetails?['profilePic']):null,
                      //child: ClipOval(child: Image(image: AssetImage("assets/profile.jpg"),)),
                    ),
                  ),
                  SizedBox(height:5),
                  Text(userDetails!['name'],style: TextStyle(color:Colors.black),),
                  Text("@${userDetails!['username']}",style: TextStyle(color:Colors.black),),
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            switch(index){
                              case 0:
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  backgroundColor: Colors.white,
                                  isScrollControlled: true, // Set to true if you want the bottom sheet to expand fully
                                  builder: (context) {
                                    return Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min, // Adjusts the height based on content
                                        children: [
                                          Text(
                                            'Profile Photo',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 10),
                                          Text('Your profile, your style — upload a picture'),
                                          SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              InkWell(
                                                onTap:(){
                                                  uploadProfilePicture(ImageSource.gallery);
                                                  Navigator.of(context).pop();
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor:Color.fromRGBO(248,101,50,1),
                                                  child:FaIcon(FontAwesomeIcons.image,color:Colors.white),
                                                ),
                                              ),
                                              InkWell(
                                                onTap:(){
                                                  uploadProfilePicture(ImageSource.camera);
                                                  Navigator.of(context).pop();
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor:Color.fromRGBO(200,97,249,1),
                                                  child:FaIcon(FontAwesomeIcons.camera,color:Colors.white),
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );



                              case 1:
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddContacts(),)).then(
                                      (value) {
                                    _fetchContactsWithRecentChat();
                                  },
                                );



                              case 2:
                              // Sharing the app link
                                Share.share('Check out this awesome chat app, Flash!\nhttps://www.flash.com');



                              case 3:
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Align(alignment:Alignment.center,child: Text('Reset Password')),
                                      backgroundColor: Color.fromRGBO(243,244,246,1,),
                                      contentPadding: EdgeInsets.only(top:15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10), // Set the border radius here
                                      ),
                                      content: Column(
                                        // crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('Do you want to reset password?'),
                                          SizedBox(height: 15,),
                                          Container(
                                              height:0.5,
                                              color:Colors.grey
                                          ),
                                          InkWell(
                                              onTap:(){
                                                resetPassword();
                                              },
                                              child: Container(
                                                  alignment: Alignment.center,
                                                  height:50,
                                                  child: Text("Reset Password",style: TextStyle(color: Color.fromRGBO(223,77,93,1),),)
                                              )

                                          ),
                                          Container(
                                              height:0.5,
                                              color:Colors.grey
                                          ),
                                          InkWell(
                                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
                                              onTap:(){
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                  alignment: Alignment.center,
                                                  height:50,
                                                  child: Text("Cancel",style: TextStyle(color: Color.fromRGBO(1,102,255,1),),)
                                              )
                                          ),
                                        ],
                                      ),

                                    );
                                  },
                                );





                              case 4:
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Align(alignment:Alignment.center,child: Text('Log Out')),
                                      backgroundColor: Color.fromRGBO(243,244,246,1,),
                                      contentPadding: EdgeInsets.only(top:15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10), // Set the border radius here
                                      ),
                                      content: Column(
                                        // crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('Are you sure you want to log out?'),
                                          SizedBox(height: 15,),
                                          Container(
                                              height:0.5,
                                              color:Colors.grey
                                          ),
                                          InkWell(
                                              onTap:()async{
                                                try {
                                                  await FirebaseAuth.instance.signOut();
                                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Signin(),)); // Navigate to the login screen or home screen
                                                } catch (e) {
                                                  // Handle errors here
                                                  print('Error logging out: $e');
                                                  // ScaffoldMessenger.of(context).showSnackBar(
                                                  //   SnackBar(content: Text('Error logging out. Please try again.')),
                                                  // );
                                                }
                                              },
                                              child: Container(
                                                  alignment: Alignment.center,
                                                  height:50,
                                                  child: Text("Log Out",style: TextStyle(color: Color.fromRGBO(223,77,93,1),),)
                                              )

                                          ),
                                          Container(
                                              height:0.5,
                                              color:Colors.grey
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
                                              onTap:(){
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                  alignment: Alignment.center,
                                                  height:50,
                                                  child: Text("Cancel",style: TextStyle(color: Color.fromRGBO(1,102,255,1),),)
                                              )
                                          ),
                                        ],
                                      ),

                                    );
                                  },
                                );
                              case 5:
                                Navigator.of(context).pop();
                                TextEditingController controller=TextEditingController();
                                DatabaseHelper db=DatabaseHelper();
                                User? currentUser = FirebaseAuth.instance.currentUser;
                                String currentUserId = currentUser?.uid ?? '';
                                Map<String, String?> settings = await db.getUserNotificationSettings(currentUserId);
                                bool isSmartPingEnabled=settings['isSmartPingEnabled']=="yes"?true:false;
                                print("settings['isSmartPingEnabled'] ${settings['isSmartPingEnabled']}");
                                controller.text=settings['onlyNotifiedFor']!;
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder: (BuildContext context, StateSetter setState) {
                                        return Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(),
                                              AnimatedGradientBorder(
                                                borderSize: 2,
                                                glowSize: 0,
                                                gradientColors: [
                                                  Color(0xFFF953C6), // Dark Pink
                                                  Color(0xFF833AB4), // Purple
                                                  Color(0xFFE94057), // Pink-Red
                                                  Color(0xFFFF6F61)  // Coral
                                                ],
                                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                                child: Container(
                                                  width: MediaQuery.of(context).size.width * 0.7,
                                                  height: 250,
                                                  decoration: BoxDecoration(
                                                    color: Color.fromRGBO(243, 244, 246, 1),
                                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                                                ),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.max,
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        "Smart Ping",
                                                                        style: TextStyle(fontSize: 25),
                                                                      ),
                                                                      CupertinoSwitch(
                                                                        value: isSmartPingEnabled,
                                                                        onChanged: (bool value) {
                                                                          setState((){
                                                                            setState((){
                                                                              isSmartPingEnabled=!isSmartPingEnabled;
                                                                            });
                                                                            db.updateSmartPingEnabled(currentUserId,isSmartPingEnabled?"yes":"no");
                                                                          });
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        GestureDetector(
                                                          onTap:(){
                                          
                                                          },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                                            ),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          "Only Get Notified For: ",
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      Icon(CupertinoIcons.pencil),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    child: Material(
                                                                      child: TextField(
                                                                        controller: controller,
                                                                        cursorColor: Colors.black,
                                                                        decoration: InputDecoration(
                                                                          border: InputBorder.none,
                                                                          fillColor: Colors.white,
                                                                          filled: true,
                                                                          contentPadding: EdgeInsets.only(right:4,left:4)
                                                                        ),
                                                                        onChanged: (value){
                                                                          db.updateNotifiedFor(currentUserId, value);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                          
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text(
                                                              "Only the essentials, when you need them—smart notifications that prioritize what matters.",
                                                            ),
                                                          ),
                                                        ),
                                          
                                          
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );



                              default:
                                break;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top:0,bottom: 8),
                            child: Container(
                              width:MediaQuery.of(context).size.width,
                              height:45,
                              decoration: BoxDecoration(
                                  color:Color.fromRGBO(243,244,246,1,),
                                  borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 500),
                                      width:0,
                                      height:45,
                                      decoration: BoxDecoration(
                                          color:Color.fromRGBO(1,102,255,1),
                                          borderRadius: BorderRadius.all(Radius.circular(10))
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width:10),
                                        Icon(icons[index],color:Colors.black,),
                                        SizedBox(width:10),
                                        Text(options[index],style: TextStyle(color:Colors.black),),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
        ),
      ),

    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'addContacts.dart';
import 'chatScreen.dart';
import 'contacts.dart';
import 'databaseHelper.dart';
import 'userStatusService.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{

  final UserStatusService _statusService = UserStatusService();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  int selectedOption=0;
  List<double> widths =[0.0,0.0,0.0,0.0,0.0,0.0];
  int oldIndex=0;
  List<Map<String, dynamic>> contactsWithRecentChat = [];
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
    _fetchContactsWithRecentChat();
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

      // Fetch the most recent chat for this contact
      final recentChat = await db.getRecentChats(currentUserId, contactId);

      // Make a copy of the contact to allow modification
      Map<String, dynamic> modifiableContact = Map.from(contact);

      // Only take the first element if recentChat is not empty
      modifiableContact['recentChat'] = recentChat.isNotEmpty ? recentChat.first : null;

      // Add the contact with recent chat to the list
      contactsWithRecentChat.add(modifiableContact);
    }

    print("Recent Chat: $contactsWithRecentChat");
    return contactsWithRecentChat;
  }
  Future<void> _fetchContactsWithRecentChat() async {
    contactsWithRecentChat = await getContactsWithRecentChat();
    setState(() {}); // Update the UI after fetching data
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Flash"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: (){showNotification();},
              icon: Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddContacts(),));
            },
            icon: Icon(Icons.person_add),
          )
        ],
      ),

      body:Column(
        children: [

          Expanded(
            child:ListView.builder(
              itemCount: contactsWithRecentChat.length,
              itemBuilder: (context, index) {
                final contact = contactsWithRecentChat[index];

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
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(name:contact['name'],receiverId: (contact['userId']))));
                    // Handle tap action
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          // Optionally, set the avatar image if available
                          // backgroundImage: NetworkImage(contact['avatarUrl']), // Example for loading image from URL
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(recentMessage),
                                  if (recentChat != null) // Only show if there's a recent chat
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(1, 102, 255, 1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '1', // Replace with the actual unread message count if available
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
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => Contacts(),));
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
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    //child: ClipOval(child: Image(image: AssetImage("assets/profile.jpg"),)),
                  ),
                  SizedBox(height:5),
                  Text("Abhay Rana",style: TextStyle(color:Colors.white),),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: (){
                            setState(() {
                              widths[oldIndex]=0;
                              widths[index]=MediaQuery.of(context).size.width ;
                            });
                            oldIndex=index;
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
                                      width:widths[index]==-1?MediaQuery.of(context).size.width:widths[index],
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
                                        //Icon(icons[index],color: Colors.white,),
                                        SizedBox(width:10),
                                        //Text(options[index],style: TextStyle(color:Colors.white),),
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

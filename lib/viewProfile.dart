import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mychatapplication/databaseHelper.dart';

class ViewProfile extends StatefulWidget {
  String name,username,about,userid;
  dynamic profilePic;
   ViewProfile({super.key,required this.profilePic,required this.name,required this.username,required this.about,required this.userid});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> with SingleTickerProviderStateMixin{

  TextEditingController about=TextEditingController();
  TabController? _tabController;
  double appBarHeight=200;
  double setProfilewidth=0;
  IconData setProfileIcon=CupertinoIcons.pencil;
  double height=180;
  IconData iconarrow=Icons.keyboard_arrow_down;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Initialize TabController with length equal to the number of tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Specify the value to return
        Navigator.pop(context, widget.about);
        return false; // Prevents default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body:CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
          SliverAppBar(
            toolbarHeight: 0,
          automaticallyImplyLeading: false,
          expandedHeight: appBarHeight, // Initial height of the AppBar
          floating: false,
          pinned: true, // Keeps the app bar visible when scrolling down
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(

            // background: profilePicBytes != null
            //     ? Image.memory(
            //   profilePicBytes!, // Using MemoryImage to load profile image if available
            //   fit: BoxFit.cover,
            // )
            //     :
            background:widget.profilePic!=null?Image.memory(widget.profilePic,fit: BoxFit.cover,):null,
          ),
          stretch: true, // Enables the stretching effect
          stretchTriggerOffset: 100.0, // Controls how much to pull down to stretch
          onStretchTrigger: () async {
            // Optional: Perform an action when fully stretched
            print("AppBar stretched");
          },),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) =>Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                                          children: [
                          SizedBox(height:15),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'User Profile',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Color.fromRGBO(1, 102, 255, 1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     setState(() {
                                    //       setProfilewidth = setProfilewidth == 0.0 ? 60.0 : 0.0; // Toggle the width between 0 and 40
                                    //       setProfileIcon = setProfileIcon == CupertinoIcons.pencil ? CupertinoIcons.clear : CupertinoIcons.pencil;
                                    //     });
                                    //   },
                                    //   child: Icon(
                                    //     setProfileIcon,
                                    //     color:  Color.fromRGBO(1, 102, 255, 1),
                                    //   ),
                                    // ),
                                    AnimatedContainer(
                                      width: setProfilewidth,
                                      height: 25,
                                      duration: Duration(milliseconds: 500),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    setProfilewidth = setProfilewidth == 0.0 ? 60.0 : 0.0; // Toggle the width between 0 and 40
                                                    setProfileIcon = setProfileIcon == CupertinoIcons.pencil ? CupertinoIcons.clear : CupertinoIcons.pencil;
                                                  });
                                                  // pickAndUploadProfilePic(context, ImageSource.camera);
                                                },
                                                child: Icon(FontAwesomeIcons.camera, size: 15, color: Color.fromRGBO(253, 46, 116, 1)),
                                              ),
                                              SizedBox(width: 20),
                                              GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      setProfilewidth = setProfilewidth == 0.0 ? 60.0 : 0.0; // Toggle the width between 0 and 40
                                                      setProfileIcon = setProfileIcon == CupertinoIcons.pencil ? CupertinoIcons.clear : CupertinoIcons.pencil;
                                                    });
                                                    // pickAndUploadProfilePic(context, ImageSource.gallery);
                                                  },
                                                  child: Icon(FontAwesomeIcons.image, size: 15, color: Color.fromRGBO(127, 102, 255, 1))
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                           SizedBox(height:15),
                           Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: AnimatedContainer(
                               duration: Duration(milliseconds: 800),
                              width: MediaQuery.of(context).size.width,
                              height:height,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5), // Shadow color with opacity
                                    spreadRadius: 5,                      // Spread radius of the shadow
                                    blurRadius: 7,                        // Blur radius of the shadow
                                    offset: Offset(0, 3),                 // Offset in X and Y
                                  ),
                                ],color:Colors.white,
                                // gradient: LinearGradient(
                                //   begin: Alignment.topLeft,
                                //   end: Alignment.bottomRight,
                                //   colors: [
                                //     Color.fromRGBO(1, 102, 255, 1),  // Bright Blue
                                //     Color.fromRGBO(0, 76, 191, 1),   // Deep Blue
                                //     Color.fromRGBO(51, 153, 255, 1), // Lighter Sky Blue
                                //   ],
                                //   stops: [0.0, 0.5, 1.0],
                                // ),


                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: TextStyle(
                                        color:  Color.fromRGBO(1, 102, 255, 1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 4), // Add space between the texts
                                    Text(
                                      "Name",
                                      style: TextStyle(
                                        color:  Color.fromRGBO(1, 102, 255, 1),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Divider(
                                      color: Color.fromRGBO(1, 102, 255, 1),
                                      thickness: 0.5,
                                    ),
                                    GestureDetector(
                                      onTap:(){
                                        setState(() {

                                        });
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                widget.username,
                                                style: TextStyle(
                                                  color:  Color.fromRGBO(1, 102, 255, 1),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              // Icon(
                                              //   !isCelestialCodeExpanded?Icons.keyboard_arrow_down:Icons.keyboard_arrow_up,
                                              //   color: Colors.white,
                                              // ),
                                            ],
                                          ),
                                          SizedBox(height: 4), // Add space between the rows
                                          Text(
                                            "User Name",
                                            style: TextStyle(
                                              color:  Color.fromRGBO(1, 102, 255, 1),
                                              fontSize: 14,
                                            ),
                                          ),

                                          Divider(
                                            color:  Color.fromRGBO(1, 102, 255, 1),
                                            thickness: 0.5,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "About",
                                                style: TextStyle(
                                                  color: Color.fromRGBO(1, 102, 255, 1),
                                                  fontSize: 14,
                                                ),

                                              ),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap:(){
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            backgroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8.0),
                                                            ),
                                                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Custom padding for content
                                                            content: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                TextField(
                                                                  maxLines: 4,
                                                                  controller: about,
                                                                  decoration: InputDecoration(
                                                                    labelText: "Profile Overview",
                                                                    labelStyle: TextStyle(color: Color.fromRGBO(1, 102, 255, 1)),
                                                                    enabledBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: Color.fromRGBO(1, 102, 255, 1), // Border color
                                                                        width: 2.0,
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(8.0),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                        color: Color.fromRGBO(1, 102, 255, 1), // Border color when focused
                                                                        width: 2.0,
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(8.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            actionsPadding: EdgeInsets.symmetric(vertical: 4.0), // Custom padding for actions
                                                            actions: [
                                                              Center(
                                                                child: TextButton(
                                                                  onPressed: () {
                                                                    DatabaseHelper db=DatabaseHelper();
                                                                    db.updateAbout(widget.userid, about.text.toString());
                                                                    setState(() {
                                                                      widget.about=about.text.toString();
                                                                    });
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  style: TextButton.styleFrom(
                                                                    foregroundColor: Colors.white,
                                                                    backgroundColor: Color.fromRGBO(1, 102, 255, 1),
                                                                  ),
                                                                  child: Text("Update"),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );


                                                    },
                                                    child: Icon(
                                                      setProfileIcon,
                                                      color:  Color.fromRGBO(1, 102, 255, 1),
                                                    ),
                                                  ),
                                                  SizedBox(width:10),
                                                  GestureDetector(
                                                    onTap: (){
                                                      setState(() {
                                                        height==180?height=250:height=180;
                                                        iconarrow==Icons.keyboard_arrow_down?iconarrow=Icons.keyboard_arrow_up:iconarrow=Icons.keyboard_arrow_down;
                                                      });
                                                    },
                                                    child: Icon(
                                                      iconarrow,
                                                      color:  Color.fromRGBO(1, 102, 255, 1),
                                                    ),
                                                  ),
                                                ],
                                              )

                                            ],
                                          ),AnimatedContainer(
                                            duration: Duration(milliseconds: 600),
                                            height:height==180?0:70,
                                            //color: Colors.red,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  Text(widget.about,style: TextStyle(color:  Color.fromRGBO(1, 102, 255, 1),),)
                                                ],
                                              ),
                                            ),
                                          )


                                        ],
                                      ),
                                    )

                                  ],
                                ),
                              ),
                                                       ),
                           ),
                          TabBar(
                            controller: _tabController, // Use the controller here
                            labelColor:  Color.fromRGBO(1, 102, 255, 1),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor:  Color.fromRGBO(1, 102, 255, 1),
                            indicatorWeight: 3,
                            dividerColor: Colors.black,
                            dividerHeight: 0,
                            tabs: [
                              Tab(text: 'Media'),
                              Tab(text: 'Files'),
                            ],
                          ),

                                          ],
                                        ),
                        ),
                        SizedBox(height:MediaQuery.of(context).size.height*0.62),
                      ],
                    ),

                childCount: 1, // Number of items in the list
              ),

            ),

          ],
        ),
      ),
    );
  }
}

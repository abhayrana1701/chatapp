import 'package:flutter/material.dart';

class ViewContactDetails extends StatefulWidget {
  const ViewContactDetails({super.key});

  @override
  State<ViewContactDetails> createState() => _ViewContactDetailsState();
}

class _ViewContactDetailsState extends State<ViewContactDetails> {
  double appBarHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: appBarHeight, // Initial height of the AppBar
            floating: false,
            pinned: true, // Keeps the app bar visible when scrolling down
            title: AnimatedOpacity(
              opacity: 1 - (appBarHeight / 200), // Disappear as you pull down
              duration: Duration(milliseconds: 300),
              child: CircleAvatar(
                radius: 30.0,
                child: ClipOval(
                  child: Image.asset(
                    "assets/profileaa.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Stretchable App Bar',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Image.asset(
                'assets/profileaa.jpg', // Background image for the AppBar
                fit: BoxFit.cover,
              ),
            ),
            stretch: true, // Enables the stretching effect
            stretchTriggerOffset: 100.0, // Controls how much to pull down to stretch
            onStretchTrigger: () async {
              // Optional: Perform an action when fully stretched
              print("AppBar stretched");
            },
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => ListTile(
                title: Text('Item #$index'),
              ),
              childCount: 50, // Number of items in the list
            ),
          ),
        ],
      ),
    );
  }
}

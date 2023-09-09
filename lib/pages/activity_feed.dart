import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search_message.dart';
import 'package:sm_app/widgets/activityFeedItems.dart';
import 'package:sm_app/widgets/progress.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeed createState() => _ActivityFeed();
}

class _ActivityFeed extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
      .doc(currentUser.id)
      .collection('feedItems')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .get();
    List<ActivityFeedItem> feedItems = [];
    snapshot.docs.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
     });
    return feedItems;
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Activity Feed",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.0
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: () => showSearchMessage(context),
          ),
        ],
      ),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data as List<Widget>,
            );
          },
        ),
      ),
    );
  }
}

showSearchMessage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
      SearchMessage(),
      )
    );
  }
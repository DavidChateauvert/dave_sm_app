import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({ required this.currentUser });

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts = [];
  List<String> followingList = [];
  Key _listKey = UniqueKey();
  

  @override
  void initState() {
    // initializeFirebase();
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
      .doc(widget.currentUser.id)
      .collection('timelinePosts')
      .orderBy('timestamp', descending: true)
      .get();

      List<Post> posts = snapshot.docs.map((doc) => Post.fromDocumentForTimeline
      (doc, MediaQuery.of(context).padding.top + kToolbarHeight)).toList();
      setState(() {
        this.posts = posts;
        _listKey = UniqueKey();
      });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
      .doc(currentUser.id)
      .collection('userFollowing')
      .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void initializeFirebase() async {
    await Firebase.initializeApp();
  }

  buildTimeline() {
    // ignore: unnecessary_null_comparison
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUserToFollow();
    }
    return NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification scrollInfo) {
      if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
        // Load more data or handle the end of the list
        return true;
      }
      return false;
    },
    child: RefreshIndicator(
      onRefresh: () => getTimeline(),
      child: ListView.builder(
        // reverse: true,
        key: _listKey,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (BuildContext context, int index) {
          final reversedIndex = posts.length - 1 - index;
          return posts[reversedIndex];
        },
        
      ),
    ),
  );
  }

  Widget buildContainer(userResults) {
              return Container(
                color: Color.fromARGB(255, 244, 186, 184).withOpacity(0.2),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(12.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.person_add,
                            color: Color.fromARGB(255, 89, 36, 99),
                            size: 30.0,
                          ),
                          SizedBox(width: 8.0,),
                          Text(
                            "Users to Follow",
                            style: TextStyle(
                              color: Color.fromARGB(255, 89, 36, 99),
                              fontSize: 30.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(children: userResults),
                  ],
                ),
              );
            }

  buildUserToFollow() {
    return StreamBuilder(
      stream: usersRef.orderBy('timestamp', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data?.docs.forEach((doc) { 
          User user = User.fromDocument(doc);
          if (currentUser.id == user.id) {
            return;
          } else if (followingList.contains(user.id)) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
          return buildContainer(userResults);
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
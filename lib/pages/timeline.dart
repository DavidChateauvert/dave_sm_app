import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
// import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({required this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts = [];
  List<String> followingList = [];
  Key _listKey = UniqueKey();
  bool timelineIsEmpty = false;

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp')
        .get();

    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromDocumentForTimeline(
            doc, MediaQuery.of(context).padding.top + kToolbarHeight))
        .toList();
    setState(() {
      this.posts = posts;
      if (posts.isEmpty) {
        this.timelineIsEmpty = true;
      }
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

  buildTimeline(context) {
    if (!timelineIsEmpty) {
      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            // Load more data or handle the end of the list
            return true;
          }
          return false;
        },
        child: RefreshIndicator.adaptive(
          onRefresh: () => getTimeline(),
          child: ListView.builder(
            key: _listKey,
            itemCount: posts.length,
            itemBuilder: (BuildContext context, int index) {
              return posts[index];
            },
          ),
        ),
      );
    } else {
      return buildEmptyTimeline(context);
    }
  }

  buildEmptyTimeline(context) {
    return followingList.isEmpty
        ? buildUserToFollowForNewUser(context)
        : buildUserToFollow(context);
  }

  buildUserToFollow(context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 48,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Your timeline is empty for the moment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Click here to start searching for people you know and have more post on your timeline",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: MediaQuery.of(context).size.width / 4 * 0.96),
              Icon(
                CupertinoIcons.arrow_down,
                color: Theme.of(context).colorScheme.primaryContainer,
                size: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  buildUserToFollowForNewUser(context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 48,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to Dave",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  "Your timeline is empty for the moment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Click here to start searching for people you know and you'll be able to see their post",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: MediaQuery.of(context).size.width / 4 * 0.96),
              Icon(
                CupertinoIcons.arrow_down,
                color: Theme.of(context).colorScheme.primaryContainer,
                size: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context),
      body: RefreshIndicator.adaptive(
        onRefresh: () => getTimeline(),
        child: buildTimeline(context),
      ),
    );
  }
}

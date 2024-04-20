import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/post_counter.dart';
import 'package:sm_app/widgets/cleanTimeline.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  final GlobalKey<TimelineState> key;

  Timeline({required this.key, required this.currentUser});

  @override
  TimelineState createState() => TimelineState();
}

class TimelineState extends State<Timeline> {
  List<Post> posts = [];
  List<String> followingList = [];
  Key _listKey = UniqueKey();
  bool timelineIsEmpty = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getToTop() {
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
      Provider.of<PostCounterProvider>(context, listen: false).postCounter =
          posts.length;
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

  int determineTimelineLength(List<Post> posts) {
    if (posts.isEmpty) {
      return 0;
    } else {
      return posts.length + 1;
    }
  }

  buildTimeline(context) {
    if (!timelineIsEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: () => getTimeline(),
        child: ListView.builder(
          key: _listKey,
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: determineTimelineLength(posts),
          itemBuilder: (BuildContext context, int index) {
            if (index == posts.length) {
              return CleantTimeline(
                handleCleanTimeline: () {
                  deleteAllPostInTimeline();
                  setState(() {
                    timelineIsEmpty = true;
                  });
                },
              );
            }
            return posts[index];
          },
        ),
      );
    } else {
      return buildEmptyTimeline(context);
    }
  }

  deleteAllPostInTimeline() async {
    QuerySnapshot timelineSnapshot =
        await timelineRef.doc(currentUser.id).collection('timelinePosts').get();

    timelineSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
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
      appBar: header(context), //, showPostCounter: true
      body: buildTimeline(context),
    );
  }
}

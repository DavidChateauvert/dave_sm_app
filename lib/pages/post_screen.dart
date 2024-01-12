import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post_profile.dart';
import 'package:sm_app/widgets/progress.dart';

class PostScreen extends StatefulWidget {
  final String userId;
  final String postId;

  PostScreen({
    required this.userId,
    required this.postId,
  });

  @override
  _ProfileScreen createState() => _ProfileScreen();
}

class _ProfileScreen extends State<PostScreen> {
  bool isLoading = false;
  PostProfile? post;

  @override
  void initState() {
    super.initState();
    getPost();
  }

  getPost() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot snapshot = await timelineRef
        .doc(currentUser.id)
        .collection('timelinePosts')
        .doc(widget.postId)
        .get();

    setState(() {
      isLoading = false;
      if (snapshot.exists) {
        post = PostProfile.fromDocument(snapshot);
      } else {
        post = buildPostAlreadySeen();
      }
    });
  }

  buildPostAlreadySeen() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.secondary,
      child: const Text(
        "Post already seen",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  buildProfilePost() {
    if (isLoading) {
      return circularProgress();
    }
    return Container(
      child: post,
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, titleText: "Posts"),
      body: ListView(
        children: <Widget>[
          Divider(
            height: 0.0,
          ),
          buildProfilePost()
        ],
      ),
    );
  }
}

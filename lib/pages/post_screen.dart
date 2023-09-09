import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
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

class _ProfileScreen extends State<PostScreen>{
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

  DocumentSnapshot snapshot = await postsRef
    .doc(currentUser.id)
    .collection('userPosts')
    .doc(widget.postId)
    .get();

  setState(() {
    isLoading = false;
    post = PostProfile.fromDocument(snapshot);
  });
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
     appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.0
          ),
        ),
      ),
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
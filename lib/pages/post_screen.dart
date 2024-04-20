import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post_profile.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PostScreen extends StatefulWidget {
  final String userId;
  final String postId;
  final String type;
  final String postOwnerId;

  PostScreen({
    required this.userId,
    required this.postId,
    required this.type,
    required this.postOwnerId,
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

    try {
      DocumentSnapshot doc;
      if (["like", "comment"].contains(widget.type) ||
          (widget.type == "commentLike" &&
              widget.postOwnerId == currentUser.id)) {
        doc = await postsRef
            .doc(currentUser.id)
            .collection('userPosts')
            .doc(widget.postId)
            .get();
      } else {
        doc = await timelineRef
            .doc(currentUser.id)
            .collection('timelinePosts')
            .doc(widget.postId)
            .get();
      }

      if (doc.exists) {
        setState(() {
          post = PostProfile.fromDocument(doc);
        });
      }
    } catch (error) {
      print("Error getting document: $error");
      return "";
    }

    setState(() {
      isLoading = false;
    });
  }

  buildPostAlreadySeen() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.secondary,
      child: Text(
        AppLocalizations.of(context)!.post_already_seen,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
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
          isLoading
              ? circularProgress()
              : post == null
                  ? buildPostAlreadySeen()
                  : post,
        ],
      ),
    );
  }
}

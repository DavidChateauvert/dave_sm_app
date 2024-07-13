// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/progress.dart';
import '../models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LikePost extends StatefulWidget {
  final String postId;
  final String postOwnerId;

  LikePost({required this.postId, required this.postOwnerId});

  @override
  _LikePost createState() => _LikePost();
}

class _LikePost extends State<LikePost> {
  List<UserResult> userResult = [];

  buildFollowing() {
    // ignore: unnecessary_null_comparison
    if (userResult == null) {
      return circularProgress();
    }
    return ListView(
      children: userResult,
    );
  }

  getFriends() async {
    DocumentSnapshot doc;
    if (currentUser.id == widget.postOwnerId) {
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

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    List<String> likedUserIds = [];

    if (data != null && data.containsKey('likes')) {
      Map<String, dynamic> likesMap = data['likes'];

      likesMap.forEach((userId, isLiked) {
        if (isLiked == true) {
          likedUserIds.add(userId);
        }
      });
    }

    QuerySnapshot userSnapshot = await usersRef.get();

    List<UserResult> userResults = [];

    userSnapshot.docs.forEach((doc) {
      if (likedUserIds.contains(doc['id'])) {
        User user = User.fromDocument(doc);
        userResults.add(UserResult(user, false));
      }
    });

    if (mounted) {
      setState(() {
        this.userResult = userResults;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          AppLocalizations.of(context)!.likesAppBar,
          style: const TextStyle(color: Colors.white, fontSize: 30.0),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 89, 36, 99),
      ),
      body: buildFollowing(),
    );
  }
}

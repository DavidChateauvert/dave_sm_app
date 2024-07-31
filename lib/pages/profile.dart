// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/settings.dart';
import 'package:sm_app/widgets/checkInternetConnection.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post.dart';
import 'package:sm_app/widgets/profileHeader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';
import '../widgets/post_profile.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});

  @override
  _Profile createState() => _Profile();
}

class _Profile extends State<Profile> {
  final String currentUserId = currentUser.id;
  bool isFollowing = false;
  bool isFollowers = false;
  bool isFriend = false;
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  int friendsCount = 0;
  List<PostProfile> posts = [];
  List<Post> post = [];
  late User user;
  bool hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    checkInternet();
    getProfilePosts();
  }

  toCallOnRetry() {
    checkInternet();
    getProfilePosts();
  }

  Future<void> checkInternet() async {
    bool connected = await checkInternetConnection();
    setState(() {
      hasInternetConnection = connected;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    if (currentUserId == widget.profileId) {
      QuerySnapshot snapshot = await postsRef
          .doc(widget.profileId)
          .collection('userPosts')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        isLoading = false;
        postCount = snapshot.docs.length;
        posts =
            snapshot.docs.map((doc) => PostProfile.fromDocument(doc)).toList();
      });
    } else {
      QuerySnapshot snapshot =
          await postsRef.doc(widget.profileId).collection('userPosts').get();
      setState(() {
        isLoading = false;
        postCount = snapshot.docs.length;
      });
    }
  }

  buildProfilePost() {
    if (isLoading) {
      return Text(""); //circularProgress(context);
    } else if (posts.isEmpty && currentUserId == widget.profileId) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 30.0),
              child:
                  SvgPicture.asset('assets/images/no_post.svg', height: 140.0),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (posts.isEmpty && currentUserId != widget.profileId) {
      return Column(
        children: post,
      );
    }
    return Column(
      children: posts,
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,
          titleText: AppLocalizations.of(context)!.profile,
          removeBackButton: currentUserId == widget.profileId,
          showMessageButton: currentUserId == widget.profileId),
      body: currentUserId == widget.profileId
          ? ListView(
              children: <Widget>[
                ProfileHeader(
                  profileId: widget.profileId,
                ),
                Divider(
                  height: 0.0,
                ),
                hasInternetConnection
                    ? buildProfilePost()
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 64.0,
                        ),
                        child: showNoConnection(
                          context,
                          toCallOnRetry,
                        ),
                      ),
              ],
            )
          : hasInternetConnection
              ? ListView(
                  children: <Widget>[
                    ProfileHeader(
                      profileId: widget.profileId,
                    ),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.only(bottom: 64.0),
                  child: showNoConnection(
                    context,
                    toCallOnRetry,
                  ),
                ),
      drawer: currentUserId == widget.profileId
          ? SettingsPage(
              currentUserId: currentUserId,
            )
          : null,
    );
  }
}

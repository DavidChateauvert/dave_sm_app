// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/edit_profile.dart';
import 'package:sm_app/pages/friends.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/settings.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/post.dart';
import 'package:sm_app/widgets/progress.dart';

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

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    // getFollowers();
    // getFollowing();
    getFriendsCount();
    checkIfFollowing();
    checkIfFollowers();
    checkIfFriend();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  checkIfFollowers() async {
    DocumentSnapshot doc = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowers = doc.exists;
    });
  }

  checkIfFriend() async {
    DocumentSnapshot doc = await friendsRef
        .doc(currentUserId)
        .collection('userFriends')
        .doc(widget.profileId)
        .get();
    setState(() {
      isFriend = doc.exists;
    });
  }

  // getFollowers() async {
  //   QuerySnapshot snapshot = await followersRef
  //     .doc(widget.profileId)
  //     .collection('userFollowers')
  //     .get();
  //   setState(() {
  //     followersCount = snapshot.docs.length;
  //   });
  // }

  // getFollowing() async {
  //   QuerySnapshot snapshot = await followingRef
  //     .doc(widget.profileId)
  //     .collection('userFollowing')
  //     .get();
  //   setState(() {
  //     followingCount = snapshot.docs.length;
  //   });
  // }

  getFriendsCount() async {
    QuerySnapshot snapshot =
        await friendsRef.doc(widget.profileId).collection('userFriends').get();
    setState(() {
      friendsCount = snapshot.docs.length;
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
      QuerySnapshot snapshot = await timelineRef
          .doc(currentUserId)
          .collection('timelinePosts')
          .orderBy('timestamp', descending: true)
          .where("ownerId", isEqualTo: widget.profileId)
          .get();
      setState(() {
        isLoading = false;
        postCount = snapshot.docs.length;
        post = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
      });
    }
  }

  showFriends(BuildContext context, {required String profileId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Friends(profileId: profileId),
      ),
    );
  }

  handleNextPage(String label, int count) {
    if (label == "Friends") showFriends(context, profileId: widget.profileId);
  }

  buildCountColumn(String label, int count) {
    return GestureDetector(
      onTap: () => handleNextPage(label, count),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            count.toString(),
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  editPorfileAsync() async {
    User newInfoUser = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
    setState(() {
      user = newInfoUser;
    });
  }

  editProfile() {
    editPorfileAsync();
  }

  Container buildButton({String? text, Function? function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: TextButton(
        onPressed: function as void Function()?,
        child: Container(
          width: 200.0,
          height: 26.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing
                ? Theme.of(context).colorScheme.background
                : Theme.of(context).colorScheme.onBackground,
            border: Border.all(
              color: isFollowing
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(
            text!,
            style: TextStyle(
              color: isFollowing
                  ? Theme.of(context).colorScheme.onBackground
                  : Theme.of(context).colorScheme.background,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // Viewing your own profile - shouls show edit profile button
    if (currentUserId == widget.profileId) {
      return buildButton(text: "Edit profile", function: editProfile);
    } else if (isFriend) {
      return buildButton(text: "Unfriend", function: handleUnfollowUser);
    } else if (!isFollowers && isFollowing) {
      return buildButton(text: "Request Sent", function: handleUnfollowUser);
    } else if (isFollowers && !isFollowing) {
      return buildButton(text: "Accept Request", function: handleFollowUser);
    } else if (!isFollowing) {
      return buildButton(
          text: "Ask to be a friend", function: handleFollowUser);
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      isFriend = false;
    });
    // Remove follower
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
    // Remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
    // Delete friends if they were friends
    friendsRef
        .doc(currentUserId)
        .collection('userFriends')
        .doc(widget.profileId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
    friendsRef
        .doc(widget.profileId)
        .collection('userFriends')
        .doc(currentUserId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
    // Delete ActivityFeed
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
    // Delete message Feed
  }

  handleFollowUser() async {
    setState(() {
      if (isFollowers) {
        isFriend = true;
      }
      isFollowing = true;
    });
    // Add to followers
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});
    // Add to following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    // Add to friends if user is also following
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    if (doc.exists) {
      friendsRef
          .doc(currentUserId)
          .collection('userFriends')
          .doc(widget.profileId)
          .set({});
      friendsRef
          .doc(widget.profileId)
          .collection('userFriends')
          .doc(currentUserId)
          .set({});
      messagesRef
          .doc(currentUserId)
          .collection("and")
          .doc(widget.profileId)
          .set({
        "message": "Vous pouvez maintenant vous envoyer des messages",
        "username": user.firstName,
        "userId": widget.profileId,
        "lastUserSent": widget.profileId,
        "userProfileImg": user.photoUrl,
        "seen": false,
        "timestamp": DateTime.now(),
      });
      messagesRef
          .doc(widget.profileId)
          .collection("and")
          .doc(currentUserId)
          .set({
        "message": "Vous pouvez maintenant vous envoyer des messages",
        "username": currentUser.firstName,
        "userId": currentUserId,
        "lastUserSent": currentUserId,
        "userProfileImg": currentUser.photoUrl,
        "seen": false,
        "timestamp": DateTime.now(),
      });
      FirebaseApi().sendAcceptRequestNotification(
          widget.profileId, currentUser.displayName);
      setState(() {
        isFriend = true;
      });
    } else {
      FirebaseApi().sendFriendRequestNotification(
          widget.profileId, currentUser.displayName);
    }
    // ActivityFeed
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "postId": widget.profileId,
      "username": currentUser.displayName,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "seen": false,
      "timestamp": timestamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return linearProgress();
        }
        user = User.fromDocument(snapshot.data as DocumentSnapshot<Object?>);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: user.photoUrl.isEmpty
                          ? null
                          : CachedNetworkImageProvider(user.photoUrl)),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("Posts", postCount),
                            buildCountColumn("Friends", friendsCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[buildProfileButton()],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(width: 4.0),
                    user.verified
                        ? Icon(
                            Icons.verified_sharp,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18.0,
                          )
                        : Text(""),
                  ],
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePost() {
    if (isLoading) {
      return Text(""); //circularProgress();
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
          titleText: "Profile",
          removeBackButton: currentUserId == widget.profileId),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildProfilePost()
        ],
      ),
      drawer: SettingsPage(
        currentUserId: currentUserId,
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/edit_profile.dart';
import 'package:sm_app/pages/friends.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/pages/photo.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';

class ProfileHeader extends StatefulWidget {
  final String profileId;

  ProfileHeader({required this.profileId});

  @override
  _ProfileHeader createState() => _ProfileHeader();
}

class _ProfileHeader extends State<ProfileHeader> {
  final String currentUserId = currentUser.id;
  bool isFollowing = false;
  bool isFollowers = false;
  bool isFriend = false;
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  int friendsCount = 0;
  late User user;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getFriendsCount();
    checkIfFriend();
    checkIfFollowing();
    checkIfFollowers();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  checkIfFollowers() async {
    DocumentSnapshot doc = await followersRef
        .doc(currentUserId)
        .collection('userFollowers')
        .doc(widget.profileId)
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

  getFriendsCount() async {
    QuerySnapshot snapshot =
        await friendsRef.doc(widget.profileId).collection('userFriends').get();
    setState(() {
      friendsCount = snapshot.docs.length;
    });
  }

  showFriends(BuildContext context, {required String profileId}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Friends(profileId: profileId),
      ),
    );
  }

  handleNextPage(String label, int count) {
    showFriends(context,
        profileId: widget
            .profileId); // Est-ce que tu devrais savoir avec qui la personne est ami ?
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
        child: IntrinsicWidth(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
              borderRadius: BorderRadius.circular(100.0),
            ),
            child: Text(
              text!,
              style: TextStyle(
                color: isFollowing
                    ? Theme.of(context).colorScheme.onBackground
                    : Theme.of(context).colorScheme.background,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container buildMessageButton() {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              otherUserId: widget.profileId,
              updateMessage: (newMessage) {},
            ),
          ),
        ),
        child: Container(
          width: 200.0,
          height: 26.0,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Send message",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              Icon(
                Icons.send_outlined,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // Viewing your own profile - should show edit profile button
    if (currentUserId == widget.profileId) {
      return buildButton(
          text: AppLocalizations.of(context)!.edit_profile,
          function: editProfile);
    } else if (isFriend) {
      return buildButton(
          text: AppLocalizations.of(context)!.unfriend,
          function: handleUnfollowUser);
    } else if (!isFollowers && isFollowing) {
      return buildButton(
          text: AppLocalizations.of(context)!.request_sent,
          function: handleUnfollowUser);
    } else if (isFollowers && !isFollowing) {
      return buildButton(
          text: AppLocalizations.of(context)!.accept_request,
          function: handleFollowUser);
    } else {
      return buildButton(
          text: AppLocalizations.of(context)!.ask_to_be_friend,
          function: handleFollowUser);
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
        .delete();
    // Remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .delete();
    // Delete friends if they were friends
    friendsRef
        .doc(currentUserId)
        .collection('userFriends')
        .doc(widget.profileId)
        .delete();
    friendsRef
        .doc(widget.profileId)
        .collection('userFriends')
        .doc(currentUserId)
        .delete();
    // Delete ActivityFeed
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .delete();
    // Delete message Feed
    messagesRef
        .doc(currentUserId)
        .collection("and")
        .doc(widget.profileId)
        .delete();
    // Delete message Feed
    messagesRef
        .doc(widget.profileId)
        .collection("and")
        .doc(currentUserId)
        .delete();
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
    DocumentSnapshot doc = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
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
          context, widget.profileId, currentUser.displayName);
    } else {
      FirebaseApi().sendFriendRequestNotification(
          context, widget.profileId, currentUser.displayName);
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat.yMMMMd(
      Provider.of<LocaleProvider>(context, listen: false)
          .getLocaleFormatString(),
    ).format(dateTime);
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
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: user.photoUrl.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              _createRoute(
                                user.photoUrl,
                                1,
                                "profile",
                              ),
                            ),

                    // Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => Photo(
                    //           photoUrl: user.photoUrl,
                    //           aspectRatio: 1,
                    //           type: "profile",
                    //         ),
                    //       ),
                    //     ),
                    child: Hero(
                      tag: user.photoUrl,
                      child: CircleAvatar(
                        radius: 55.0,
                        backgroundColor: Colors.grey,
                        backgroundImage: user.photoUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(user.photoUrl),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                    ),
                  ),
                  SizedBox(width: 4.0),
                  user.verified
                      ? Icon(
                          Icons.verified_sharp,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24.0,
                        )
                      : Text(""),
                ],
              ),
              user.bio != "" ? const SizedBox(height: 24.0) : Container(),
              user.bio != ""
                  ? Container(
                      alignment: Alignment.center,
                      child: Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        ),
                      ),
                    )
                  : Container(),
              const SizedBox(height: 24.0),
              Container(
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!
                      .joined_at(formatTimestamp(user.timestamp)),
                  // 'Joined Dave on ${formatTimestamp(user.joinedAt)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  buildCountColumn(
                      AppLocalizations.of(context)!.posts, postCount),
                  buildCountColumn(
                      AppLocalizations.of(context)!.friends, friendsCount),
                ],
              ),
              const SizedBox(height: 24.0),
              buildProfileButton(),
              const SizedBox(height: 24.0),
              isFriend ? buildMessageButton() : Container(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
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
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: user.photoUrl.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              _createRoute(
                                user.photoUrl,
                                1,
                                "profile",
                              ),
                            ),

                    // Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => Photo(
                    //           photoUrl: user.photoUrl,
                    //           aspectRatio: 1,
                    //           type: "profile",
                    //         ),
                    //       ),
                    //     ),
                    child: Hero(
                      tag: user.photoUrl,
                      child: CircleAvatar(
                        radius: 55.0,
                        backgroundColor: Colors.grey,
                        backgroundImage: user.photoUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(user.photoUrl),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                    ),
                  ),
                  SizedBox(width: 4.0),
                  user.verified
                      ? Icon(
                          Icons.verified_sharp,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24.0,
                        )
                      : Text(""),
                ],
              ),
              user.bio != "" ? const SizedBox(height: 24.0) : Container(),
              user.bio != ""
                  ? Container(
                      alignment: Alignment.center,
                      child: Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        ),
                      ),
                    )
                  : Container(),
              const SizedBox(height: 24.0),
              Container(
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!
                      .joined_at(formatTimestamp(user.timestamp)),
                  // 'Joined Dave on ${formatTimestamp(user.joinedAt)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  buildCountColumn(
                      AppLocalizations.of(context)!.posts, postCount),
                  buildCountColumn(
                      AppLocalizations.of(context)!.friends, friendsCount),
                ],
              ),
              const SizedBox(height: 24.0),
              buildProfileButton(),
              const SizedBox(height: 24.0),
              isFriend ? buildMessageButton() : Container(),
            ],
          ),
        );
      },
    );
  }
}

showPhoto(
    BuildContext context, String photoUrl, double aspectRatio, String type) {
  Navigator.push(
    context,
    PageRouteBuilder(
      // transitionDuration: Duration(
      //     milliseconds: 200), // Adjust the transition duration as desired
      pageBuilder: (_, __, ___) => Photo(
        photoUrl: photoUrl,
        aspectRatio: aspectRatio,
        type: type,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

Route _createRoute(String photoUrl, double aspectRatio, String type) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Photo(
      photoUrl: photoUrl,
      aspectRatio: aspectRatio,
      type: type,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = 0.0;
      const end = 1.0;

      var tween = Tween(begin: begin, end: end);

      var fadeAnimation = animation.drive(tween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );
    },
  );
}

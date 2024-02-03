import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/post_screen.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

late Widget mediaPreview;
late String activityItemText;

class ActivityFeedItem extends StatefulWidget {
  final String username;
  final String userId;
  final String type;
  // late final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final bool seen;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    // required mediaUrl;
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.seen,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    final String commentData =
        doc['type'] == "comment" ? doc['commentData'] : '';

    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: commentData,
      seen: doc['seen'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  // ignore: no_logic_in_create_state
  _ActivityFeedItem createState() => _ActivityFeedItem(
        username: username,
        userId: userId,
        type: type,
        postId: postId,
        userProfileImg: userProfileImg,
        commentData: commentData,
        seen: seen,
        timestamp: timestamp,
      );
}

class _ActivityFeedItem extends State<ActivityFeedItem> {
  final String username;
  final String userId;
  final String type;
  // late final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  bool seen = false;
  bool deleteInstant = false;
  final Timestamp timestamp;

  _ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.seen,
    required this.timestamp,
  });

  configureMediaPreview(context) {
    mediaPreview = Text('');
    if (type == "like") {
      activityItemText = "liked your post";
    } else if (type == "follow") {
      activityItemText = "is following you";
    } else if (type == "comment") {
      activityItemText = "replied: $commentData";
    } else if (type == "message") {
      activityItemText = "sent you a new message";
    } else if (type == "mention") {
      activityItemText = "has tagged you in a post";
    } else {
      activityItemText = "Error: Unkown type '$type'";
    }
  }

  // seenNotification() {
  //   activityFeedRef
  //     .doc(currentUser.id)
  //     .collection("feedItems")
  //     .doc()
  //     .update({"seen": true});
  // }

  showNotification(context, type) {
    if ((["like", "comment", "mention"].contains(type))) {
      showPost(context, type);
    } else if (type == "follow") {
      showProfile(context, profileId: userId);
    } else {
      showProfile(context, profileId: userId);
    }
    setState(() {
      seen = true;
    });
  }

  deleteActivityFeedItems(context) async {
    setState(() {
      deleteInstant = true;
    });
    if (type == "follow") {
      try {
        activityFeedRef
            .doc(currentUser.id)
            .collection("feedItems")
            .doc(userId)
            .get()
            .then((doc) => {
                  if (doc.exists) {doc.reference.delete()}
                });
      } catch (e) {
        print("Error : $e");
      }
    } else {
      try {
        activityFeedRef
            .doc(currentUser.id)
            .collection("feedItems")
            .where("type", isEqualTo: type)
            .where("postId", isEqualTo: postId)
            .where("timestamp", isEqualTo: timestamp)
            .get()
            .then((doc) => doc.docs.forEach((document) {
                  activityFeedRef
                      .doc(currentUser.id)
                      .collection("feedItems")
                      .doc(document.id)
                      .delete();
                  if (!seen) {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .seenNotificationActivityFeed(postId);
                  }
                }));
      } catch (e) {
        print("Error : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return deleteInstant
        ? Container()
        : Column(
            children: [
              Divider(
                color: Theme.of(context).colorScheme.secondary,
                height: 0.0,
              ),
              Slidable(
                endActionPane: ActionPane(
                  motion: StretchMotion(),
                  children: [
                    SlidableAction(
                      flex: 1,
                      onPressed: ((context) =>
                          deleteActivityFeedItems(context)),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: CupertinoIcons.delete_simple,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => showNotification(context, type),
                  child: ListTile(
                    title: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        children: [
                          TextSpan(
                            text: username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' $activityItemText',
                            style: TextStyle(
                              fontWeight:
                                  seen ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(userProfileImg),
                    ),
                    subtitle: Text(
                      timeago.format(timestamp.toDate()),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: mediaPreview,
                  ),
                ),
              ),
            ],
          );
  }

  showPost(context, type) {
    if (!seen) {
      activityFeedRef
          .doc(currentUser.id)
          .collection("feedItems")
          .where("type", isEqualTo: type)
          .where("postId", isEqualTo: postId)
          .get()
          .then((doc) => doc.docs.forEach((document) {
                activityFeedRef
                    .doc(currentUser.id)
                    .collection("feedItems")
                    .doc(document.id)
                    .update({"seen": true});
                Provider.of<NotificationProvider>(context, listen: false)
                    .seenNotificationActivityFeed(postId);
              }));
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostScreen(userId: userId, postId: postId, type: type),
      ),
    );
  }

  showProfile(BuildContext context, {required String profileId}) {
    if (!seen) {
      activityFeedRef
          .doc(currentUser.id)
          .collection("feedItems")
          .doc(userId)
          .update({"seen": true});
      Provider.of<NotificationProvider>(context, listen: false)
          .seenNotificationActivityFeed(userId);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(profileId: profileId),
      ),
    );
  }

  setSeenInFirebase() {
    activityFeedRef
        .doc(currentUser.id)
        .collection("feedItems")
        .where("type", isEqualTo: "message")
        .get()
        .then((doc) => doc.docs.forEach((document) {
              activityFeedRef
                  .doc(currentUser.id)
                  .collection("feedItems")
                  .doc(document.id)
                  .update({"seen": true});
            }));
  }
}

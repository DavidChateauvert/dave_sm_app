import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/pages/report_post.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageFeedItem extends StatefulWidget {
  final String username;
  final String userId;
  final String lastUserSent;
  final String userProfileImg;
  final String message;
  final bool seen;
  final Timestamp timestamp;

  MessageFeedItem({
    required this.username,
    required this.userId,
    required this.lastUserSent,
    required this.userProfileImg,
    required this.message,
    required this.seen,
    required this.timestamp,
  });

  factory MessageFeedItem.fromDocument(DocumentSnapshot doc) {
    return MessageFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      lastUserSent: doc['lastUserSent'],
      userProfileImg: doc['userProfileImg'],
      message: doc['message'],
      seen: doc['seen'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  // ignore: no_logic_in_create_state
  _MessageFeedItem createState() => _MessageFeedItem(
        username: username,
        userId: userId,
        lastUserSent: lastUserSent,
        userProfileImg: userProfileImg,
        message: message,
        seen: seen,
        timestamp: timestamp,
      );
}

class _MessageFeedItem extends State<MessageFeedItem> {
  final String username;
  final String userId;
  final String lastUserSent;
  final String userProfileImg;
  String message;
  bool seen = false;
  final Timestamp timestamp;

  _MessageFeedItem({
    required this.username,
    required this.userId,
    required this.lastUserSent,
    required this.userProfileImg,
    required this.message,
    required this.seen,
    required this.timestamp,
  });

  showMessage(context) {
    showMessageScreen(context, profileId: userId);
    setState(() {
      seen = true;
    });
  }

  showReport(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReportPost(
        postId: userId,
        reportSubject: "Message",
      );
    }));
  }

  showDialogReport(context) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Report this post ?"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                showReport(context);
              },
              child: Text(
                'Report this conversation with $username',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  showDialogDelete(context) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Delete this conversation ?"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                deleteMessageFeedItems(context);
                Navigator.pop(context);
              },
              child: Text(
                'Delete this conversation with $username',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  deleteMessageFeedItems(context) {
    print("Delete");
  }

  @override
  Widget build(BuildContext context) {
    String whoSent = "";
    if (lastUserSent == currentUser.id) {
      whoSent = "Me :";
    }
    return Slidable(
      endActionPane: ActionPane(
        motion: StretchMotion(),
        children: [
          SlidableAction(
            flex: 1,
            onPressed: ((context) => showDialogReport(context)),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.flag,
            label: 'Report',
          ),
          SlidableAction(
            flex: 1,
            onPressed: ((context) => showDialogDelete(context)),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete_simple,
            label: 'Delete',
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 2.0),
        child: Container(
          color: Colors.white54,
          child: ListTile(
            title: GestureDetector(
              onTap: () => showMessage(context),
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $whoSent $message',
                      style: TextStyle(
                        fontWeight: seen ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(userProfileImg),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  setSeenInFirebase() {
    messagesRef
        .doc(currentUser.id)
        .collection("and")
        .doc(userId)
        .update({"seen": true});
    Provider.of<NotificationProvider>(context, listen: false)
        .seenNotificationMessage(userId);
  }

  showMessageScreen(BuildContext context, {required String profileId}) async {
    if (!seen) {
      setSeenInFirebase();
    }
    Provider.of<RouteObserverProvider>(context, listen: false)
        .setCurrentRoute(userId);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(otherUserId: profileId),
      ),
    );
    Provider.of<RouteObserverProvider>(context, listen: false)
        .setCurrentRoute("message-feed");
  }
}

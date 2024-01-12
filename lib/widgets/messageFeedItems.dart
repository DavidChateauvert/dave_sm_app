import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    String whoSent = "";
    if (lastUserSent == currentUser.id) {
      whoSent = "Me :";
    }
    return Padding(
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
    );
  }

  setSeenInFirebase() {
    messagesRef
        .doc(currentUser.id)
        .collection("and")
        .doc(userId)
        .update({"seen": true});
  }

  showMessageScreen(BuildContext context, {required String profileId}) async {
    if (!seen) {
      setSeenInFirebase();
    }
    message = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(otherUserId: profileId),
      ),
    );
  }
}

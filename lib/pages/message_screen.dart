// import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import '../models/user.dart';
import '../widgets/progress.dart';
// ignore: depend_on_referenced_packages
import 'package:chat_bubbles/chat_bubbles.dart';

// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  late final String otherUserId;

  MessageScreen({
    required this.otherUserId,
  });

  @override
  _MessageScreen createState() => _MessageScreen();
}

class _MessageScreen extends State<MessageScreen> {
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();
  final String currentUserId = currentUser.id;
  late String otherUserToken;

  @override
  void initState() {
    super.initState();
    initializeToken();
  }

  Future<void> initializeToken() async {
    String userTokens = await FirebaseApi().getToken(widget.otherUserId) ?? "";
    setState(() {
      otherUserToken = userTokens;
    });
  }

  buildMessages() {
    return StreamBuilder(
      stream: messagesRef
          .doc(currentUserId)
          .collection('and')
          .doc(widget.otherUserId)
          .collection("message")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Message> messages = [];
        snapshot.data?.docs.forEach((doc) {
          messages.add(Message.fromDocument(doc));
        });

        return GestureDetector(
          onTap: () => messageFocusNode.unfocus(),
          child: ListView(
            reverse: true,
            children: messages,
          ),
        );
      },
    );
  }

  addMessageInFirestore() async {
    if (messageController.text.isNotEmpty) {
      DateTime timestamp = DateTime.now();

      messagesRef
          .doc(currentUserId)
          .collection("and")
          .doc(widget.otherUserId)
          .collection('message')
          .add({
        "username": currentUser.username,
        "message": messageController.text,
        "timestamp": timestamp,
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "otherUserId": widget.otherUserId,
      });

      messagesRef
          .doc(widget.otherUserId)
          .collection("and")
          .doc(currentUserId)
          .collection("message")
          .add({
        "username": currentUser.username,
        "message": messageController.text,
        "timestamp": timestamp,
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "otherUserId": widget.otherUserId,
      });

      await addNotificationActivityFeed();
      FirebaseApi().sendMessageNotification(
          widget.otherUserId, messageController.text, currentUser.displayName);
    }

    messageController.clear();
  }

  // initMessegin() async {
  //   await FirebaseApi().initMessaging(currentUserId);
  // }

  addNotificationActivityFeed() async {
    try {
      await messagesRef
          .doc(widget.otherUserId)
          .collection("and")
          .doc(currentUserId)
          .update({
        "lastUserSent": currentUserId,
        "message": messageController.text,
        "seen": false,
        "timestamp": DateTime.now(),
      });
      await messagesRef
          .doc(currentUserId)
          .collection("and")
          .doc(widget.otherUserId)
          .update({
        "lastUserSent": currentUserId,
        "message": messageController.text,
        "seen": true,
        "timestamp": DateTime.now(),
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: usersRef.doc(widget.otherUserId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User otherUser =
              User.fromDocument(snapshot.data as DocumentSnapshot<Object?>);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: GestureDetector(
                onTap: () => showProfile(context, profileId: otherUser.id),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(otherUser.photoUrl),
                    ),
                    SizedBox(width: 8.0),
                    Text(otherUser.displayName),
                    SizedBox(width: 8.0),
                    otherUser.verified
                        ? Icon(
                            Icons.verified_sharp,
                            color: Colors.white,
                            size: 17.0,
                          )
                        : Text(""),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: <Widget>[
                Expanded(child: buildMessages()),
                Divider(),
                ListTile(
                  title: TextFormField(
                    controller: messageController,
                    focusNode: messageFocusNode,
                    decoration:
                        InputDecoration(labelText: "Write your message..."),
                    maxLines: null,
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => addMessageInFirestore(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                    ),
                    child: Icon(
                      Icons.send_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class Message extends StatelessWidget {
  final String username;
  final String userId;
  final String otherUserId;
  final String avatarUrl;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.username,
    required this.userId,
    required this.otherUserId,
    required this.avatarUrl,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      username: doc['username'],
      userId: doc['userId'],
      otherUserId: doc['otherUserId'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  buildSenderBubble() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    BubbleSpecialThree(
                      text: message,
                      color: const Color.fromARGB(255, 89, 36, 99),
                      tail: true,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      DateFormat.Hm().format(timestamp.toDate()),
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  buildReceiverBubble() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BubbleSpecialThree(
                      text: message,
                      color: Color.fromARGB(255, 244, 186, 184),
                      tail: true,
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                      ),
                      isSender: false,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      DateFormat.Hm().format(timestamp.toDate()),
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return currentUser.id == userId
        ? buildSenderBubble()
        : buildReceiverBubble();
  }
}

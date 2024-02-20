import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';

import 'package:sm_app/widgets/custom_image.dart';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

class Message extends StatelessWidget {
  final String messageId = Uuid().v4();
  final String username;
  final String userId;
  final String otherUserId;
  final String avatarUrl;
  final String message;
  final Timestamp timestamp;
  final String mediaUrl;
  final GlobalKey messageKey = GlobalKey();
  final GlobalKey imageKey = GlobalKey();

  Message({
    required this.username,
    required this.userId,
    required this.otherUserId,
    required this.avatarUrl,
    required this.message,
    required this.timestamp,
    required this.mediaUrl,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    final String mediaUrl =
        doc.data().toString().contains('mediaUrl') ? doc["mediaUrl"] : '';
    ;

    return Message(
      username: doc['username'],
      userId: doc['userId'],
      otherUserId: doc['otherUserId'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      mediaUrl: mediaUrl,
    );
  }

  buildBubbleOnlyText(BuildContext context, bool isSender) {
    return Column(
      children: <Widget>[
        Padding(
          key: messageKey,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: isSender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    BubbleSpecialThree(
                      text: message,
                      color: isSender
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      tail: true,
                      textStyle: TextStyle(
                        color: isSender
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontSize: 20.0,
                      ),
                      isSender: isSender,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      timeago.format(timestamp.toDate(), locale: 'en_short'),
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

  buildBubbleOnlyImage(BuildContext context, bool isSender) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: isSender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    BubbleNormalImage(
                      color: Theme.of(context).colorScheme.background,
                      key: imageKey,
                      id: messageId,
                      image: cachedNetworkImage(mediaUrl),
                      isSender: isSender,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      timeago.format(timestamp.toDate(), locale: 'en_short'),
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

  buildBubbleWithTextAndImage(BuildContext context, bool isSender) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: isSender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    BubbleNormalImage(
                      color: Theme.of(context).colorScheme.background,
                      key: imageKey,
                      id: messageId,
                      image: cachedNetworkImage(mediaUrl),
                      isSender: isSender,
                    ),
                    BubbleSpecialThree(
                      key: messageKey,
                      text: message,
                      color: isSender
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      tail: true,
                      textStyle: TextStyle(
                        color: isSender
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontSize: 20.0,
                      ),
                      isSender: isSender,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      timeago.format(timestamp.toDate(), locale: 'en_short'),
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

  Offset getPositionOnScreen() {
    RenderBox renderBox =
        messageKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    bool isSender = currentUser.id == userId;
    bool hasText = message != "";
    bool hasImage = mediaUrl != "";

    return (hasText && hasImage)
        ? buildBubbleWithTextAndImage(context, isSender)
        : (!hasText && hasImage)
            ? buildBubbleOnlyImage(context, isSender)
            : buildBubbleOnlyText(context, isSender);
  }
}

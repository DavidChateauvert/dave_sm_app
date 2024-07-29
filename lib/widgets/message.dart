import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/playVideoFullPage.dart';

import 'package:sm_app/widgets/custom_image.dart';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:sm_app/widgets/playVideo.dart';
import 'package:sm_app/widgets/profileHeader.dart';
import 'package:sm_app/widgets/videoThumbnail.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

class Message extends StatefulWidget {
  final String messageId = Uuid().v4();
  final String username;
  final String userId;
  final String otherUserId;
  final String avatarUrl;
  final String message;
  final Timestamp timestamp;
  final String mediaUrl;
  final String type;
  final int mediaUrlWidth;
  final int mediaUrlHeight;

  Message({
    required this.username,
    required this.userId,
    required this.otherUserId,
    required this.avatarUrl,
    required this.message,
    required this.timestamp,
    required this.mediaUrl,
    required this.type,
    required this.mediaUrlWidth,
    required this.mediaUrlHeight,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    final String mediaUrl =
        doc.data().toString().contains('mediaUrl') ? doc["mediaUrl"] : '';
    final String type =
        doc.data().toString().contains('type') ? doc["type"] : '';
    final int mediaUrlWidth = doc.data().toString().contains('mediaUrlWidth')
        ? doc["mediaUrlWidth"]
        : 100;

    final int mediaUrlHeight = doc.data().toString().contains('mediaUrlHeight')
        ? doc["mediaUrlHeight"]
        : 100;

    return Message(
      username: doc['username'],
      userId: doc['userId'],
      otherUserId: doc['otherUserId'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      mediaUrl: mediaUrl,
      type: type,
      mediaUrlWidth: mediaUrlWidth,
      mediaUrlHeight: mediaUrlHeight,
    );
  }

  @override
  _MessageState createState() => _MessageState();
}

class _MessageState extends State<Message> {
  final GlobalKey messageKey = GlobalKey();
  final GlobalKey imageKey = GlobalKey();
  String typeVideo = "message";

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
                      text: widget.message,
                      color: isSender
                          ? Theme.of(context).colorScheme.primary
                          : Color.fromARGB(255, 166, 29, 193),
                      tail: true,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                      isSender: isSender,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      timeago.format(widget.timestamp.toDate(),
                          locale: 'en_short'),
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
                    widget.type == "video"
                        ? BubbleNormalImage(
                            color: Theme.of(context).colorScheme.background,
                            key: imageKey,
                            id: widget.messageId,
                            image: VideoThumbnailWidget(
                              videoPath: widget.mediaUrl,
                            ),
                            isSender: isSender,
                            onTap: () => Navigator.of(context).push(
                              createRouteVideo(
                                context,
                                widget.messageId,
                                widget.mediaUrl,
                                1,
                                "message",
                                widget.mediaUrlHeight,
                                widget.mediaUrlWidth,
                              ),
                            ),
                          )
                        : BubbleNormalImage(
                            color: Theme.of(context).colorScheme.background,
                            key: imageKey,
                            id: widget.messageId,
                            image: cachedNetworkImage(widget.mediaUrl),
                            isSender: isSender,
                            onTap: () => Navigator.of(context).push(
                              createRoute(
                                context,
                                widget.messageId,
                                widget.mediaUrl,
                                1,
                                "message",
                                (MediaQuery.of(context).size.height -
                                        widget.mediaUrlHeight) *
                                    0.5,
                              ),
                            ),
                          ),
                    SizedBox(height: 4.0),
                    Text(
                      timeago.format(widget.timestamp.toDate(),
                          locale: 'en_short'),
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
                      id: widget.messageId,
                      image: widget.type == "video"
                          ? PlayVideo(
                              videoUrl: widget.mediaUrl,
                              type: "message",
                              file: null,
                              height: 200,
                              width: 200,
                            )
                          : cachedNetworkImage(widget.mediaUrl),
                      isSender: isSender,
                    ),
                    BubbleSpecialThree(
                      key: messageKey,
                      text: widget.message,
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
                      timeago.format(widget.timestamp.toDate(),
                          locale: 'en_short'),
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
    bool isSender = currentUser.id == widget.userId;
    bool hasText = widget.message != "";
    bool hasImage = widget.mediaUrl != "";

    return (hasText && hasImage)
        ? buildBubbleWithTextAndImage(context, isSender)
        : (!hasText && hasImage)
            ? buildBubbleOnlyImage(context, isSender)
            : buildBubbleOnlyText(context, isSender);
  }
}

Route createRouteVideo(BuildContext context, String tag, String mediaUrl,
    double aspectRatio, String type, int mediaHeight, int mediaWith) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => PlayVideoFullPage(
      mediaUrl: mediaUrl,
      height: mediaHeight,
      width: mediaWith,
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

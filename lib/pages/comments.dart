import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'home.dart';

class Comments extends StatefulWidget {
  late final String postId;
  late final String postOwnerId;
  late final Function() updateCommentStatus;
  // late final String mediaUrl;

  Comments({
    required this.postId,
    required this.postOwnerId,
    required this.updateCommentStatus,
    // required this.mediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: postId,
        postOwnerId: postOwnerId,
        updateCommentStatus: updateCommentStatus,
        // mediaUrl: mediaUrl
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  FocusNode commentFocusNode = FocusNode();
  late final String postId;
  late final String postOwnerId;
  late final Function() updateCommentStatus;
  // late final String mediaUrl;

  CommentsState({
    required this.postId,
    required this.postOwnerId,
    required this.updateCommentStatus,
    // required this.mediaUrl,
  });

  buildComment() {
    return StreamBuilder(
      stream: commentsRef
          .doc(postId)
          .collection('comments')
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data?.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return GestureDetector(
          onTap: () => commentFocusNode.unfocus(),
          child: ListView(
            children: comments,
          ),
        );
      },
    );
  }

  addComment() {
    updateCommentStatus();
    // Add to comments
    commentsRef.doc(postId).collection("comments").add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });

    // Add to activity feed
    if (postOwnerId != currentUser.id) {
      activityFeedRef.doc(postOwnerId).collection("feedItems").add({
        "type": "comment",
        "commentData": commentController.text,
        "username": currentUser.displayName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "seen": false,
        // "mediaUrl": mediaUrl,
        "timestamp": DateTime.now(),
      });
    }

    // Update post
    postsRef.doc(postOwnerId).collection('userPosts').doc(postId).update({
      "commentCount": FieldValue.increment(1),
      'comments.${currentUser.id}': true,
    });

    commentController.clear();
    commentFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComment()),
          Divider(),
          ListTile(
            title: TextFormField(
              maxLines: null,
              controller: commentController,
              focusNode: commentFocusNode,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlinedButton(
              onPressed: () => addComment(),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
              ),
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            comment,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          trailing: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}

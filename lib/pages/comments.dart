import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/widgets/comment.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:uuid/uuid.dart';

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
  bool isCommentNotEmpty = false;
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
          comments.add(Comment.fromDocument(doc, widget.postId));
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
    String commentTrim = commentController.text.trim();
    if (commentTrim.isNotEmpty) {
      updateCommentStatus();
      commentFocusNode.unfocus();
      String uuid = Uuid().v4();
      // Add to comments
      commentsRef.doc(postId).collection("comments").doc(uuid).set({
        "commentId": uuid,
        "username": currentUser.username,
        "comment": commentTrim,
        "timestamp": DateTime.now(),
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "likes": {},
      });

      // Add to activity feed
      if (postOwnerId != currentUser.id) {
        activityFeedRef.doc(postOwnerId).collection("feedItems").add({
          "type": "comment",
          "commentData": commentTrim,
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

      if (postOwnerId != currentUser.id) {
        sendNotification(commentTrim);
      }

      commentController.clear();
    }
  }

  sendNotification(String comment) async {
    FirebaseApi().sendCommentNotification(
        postOwnerId, currentUser.displayName, postId, comment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments", showMessageButton: false),
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
              onChanged: (value) {
                setState(() {
                  isCommentNotEmpty = value.trim().isNotEmpty;
                });
              },
            ),
            trailing: OutlinedButton(
              onPressed: isCommentNotEmpty ? () => addComment() : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                foregroundColor: isCommentNotEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/widgets/checkInternetConnection.dart';
import 'package:sm_app/widgets/comment.dart';
import 'package:sm_app/widgets/errorMessage.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    commentFocusNode.addListener(() {
      setState(() {
        isFocused = commentFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    commentFocusNode.dispose();
    super.dispose();
  }

  buildComment() {
    return StreamBuilder(
      stream: commentsRef
          .doc(postId)
          .collection('comments')
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
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

  addComment() async {
    String commentTrim = commentController.text.trim();
    try {
      if (!await checkInternetConnection()) {
        throw Exception(AppLocalizations.of(context)!.error_no_connection);
      }
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
            "postOwnerId": postOwnerId
          });
        }
        // Update post
        postsRef.doc(postOwnerId).collection('userPosts').doc(postId).update({
          "commentCount": FieldValue.increment(1),
          'comments.${currentUser.id}': true,
        });
        // Update timeline to be quicker
        timelineRef
            .doc(currentUser.id)
            .collection('timelinePosts')
            .doc(postId)
            .update({
          "commentCount": FieldValue.increment(1),
          'comments.${currentUser.id}': true,
        });

        if (postOwnerId != currentUser.id) {
          sendNotification(commentTrim);
        }

        commentController.clear();
      }
    } catch (e) {
      showErrorMessage(context, e);
    }
  }

  sendNotification(String comment) async {
    FirebaseApi().sendCommentNotification(
        context, postOwnerId, currentUser.displayName, postId, comment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,
          titleText: AppLocalizations.of(context)!.comments,
          showMessageButton: false),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComment()),
          Divider(),
          ListTile(
            title: TextFormField(
              maxLines: null,
              controller: commentController,
              focusNode: commentFocusNode,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.write_a_comment,
                border: isFocused ? UnderlineInputBorder() : InputBorder.none,
              ),
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
              child: Text(AppLocalizations.of(context)!.send_comment),
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
        ],
      ),
    );
  }
}

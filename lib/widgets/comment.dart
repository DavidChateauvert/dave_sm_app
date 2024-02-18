import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comment extends StatefulWidget {
  final String postId;
  final String commentId;
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  final dynamic likes;

  Comment({
    required this.postId,
    required this.commentId,
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
    required this.likes,
  });

  factory Comment.fromDocument(DocumentSnapshot doc, String postId) {
    final String commentId =
        doc.data().toString().contains('commentId') ? doc["commentId"] : "";
    final Map likes =
        doc.data().toString().contains('likes') ? doc["likes"] : {};

    return Comment(
      postId: postId,
      commentId: commentId,
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      likes: likes,
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  // ignore: no_logic_in_create_state
  _CommentState createState() => _CommentState(
        likes: likes,
        likeCount: getLikeCount(likes),
      );
}

class _CommentState extends State<Comment> {
  Map likes;
  int likeCount;
  late bool isLiked;

  _CommentState({
    required this.likes,
    required this.likeCount,
  });

  handleLikeComment() {
    bool _isLiked = likes[currentUser.id] == true;
    if (_isLiked) {
      commentsRef
          .doc(widget.postId)
          .collection("comments")
          .doc(widget.commentId)
          .update(
        {'likes.${currentUser.id}': false},
      );
      removeCommentLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUser.id] = false;
      });
    } else {
      commentsRef
          .doc(widget.postId)
          .collection("comments")
          .doc(widget.commentId)
          .update(
        {'likes.${currentUser.id}': true},
      );
      addCommentLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUser.id] = true;
      });
    }
  }

  addCommentLikeToActivityFeed() async {
    if (currentUser.id != widget.userId) {
      await activityFeedRef
          .doc(widget.userId)
          .collection("feedItems")
          .doc(widget.commentId)
          .set({
        "type": "commentLike",
        "username": currentUser.displayName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": widget.postId,
        "seen": false,
        "commentData": widget.comment,
        // "mediaUrl": mediaUrl,
        "timestamp": DateTime.now(),
      });
      await FirebaseApi().sendCommentLikeNotification(widget.userId,
          currentUser.displayName, widget.commentId, widget.comment);
    }
  }

  removeCommentLikeFromActivityFeed() {
    if (currentUser.id != widget.userId) {
      activityFeedRef
          .doc(widget.userId)
          .collection("feedItems")
          .doc(widget.commentId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUser.id] == true);
    return Column(
      children: <Widget>[
        ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: widget.userId),
            child: Text(
              widget.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(
            widget.comment,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
          ),
          leading: GestureDetector(
            onTap: () => showProfile(context, profileId: widget.userId),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.avatarUrl),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => handleLikeComment(),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Text(
                    "$likeCount",
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 4,
              ),
              Text(timeago.format(widget.timestamp.toDate(),
                  locale: 'en_short')),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}

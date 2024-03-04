// import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/likePost.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/custom_image.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';
import 'package:sm_app/widgets/playVideo.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';
import '../pages/comments.dart';

class PostProfile extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String mediaUrl;
  final int mediaUrlWidth;
  final int mediaUrlHeight;
  final String caption;
  final dynamic likes;
  final dynamic comments;
  final dynamic mentions;
  final int commentCount;
  final Timestamp timestamp;
  final String type;

  PostProfile({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.mediaUrl,
    required this.mediaUrlWidth,
    required this.mediaUrlHeight,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.commentCount,
    required this.mentions,
    required this.timestamp,
    required this.type,
  });

  factory PostProfile.fromDocument(DocumentSnapshot doc) {
    final String type =
        doc.data().toString().contains('type') ? doc['type'] : "";
    return PostProfile(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      mediaUrl: doc['mediaUrl'],
      mediaUrlWidth: doc['mediaUrlWidth'],
      mediaUrlHeight: doc['mediaUrlHeight'],
      caption: doc['caption'],
      likes: doc['likes'],
      comments: doc['comments'],
      commentCount: doc['commentCount'],
      mentions: doc['mentions'],
      timestamp: doc['timestamp'],
      type: type,
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
  _PostProfileState createState() => _PostProfileState(
        postId: postId,
        ownerId: ownerId,
        username: username,
        mediaUrl: mediaUrl,
        mediaUrlWidth: mediaUrlWidth,
        mediaUrlHeight: mediaUrlHeight,
        caption: caption,
        likes: likes,
        comments: comments,
        commentCount: commentCount,
        likeCount: getLikeCount(likes),
        mentions: mentions,
        timestamp: timestamp,
        type: type,
      );
}

class _PostProfileState extends State<PostProfile> {
  ScrollController scrollController = ScrollController();
  final String currentUserId = currentUser.id;
  final String postId;
  final String ownerId;
  final String username;
  final String mediaUrl;
  final int mediaUrlWidth;
  final int mediaUrlHeight;
  final String caption;
  final Timestamp timestamp;
  int likeCount;
  int commentCount;
  Map likes;
  Map comments;
  Map mentions;
  late bool isLiked;
  bool isCommented = false;
  bool isCommentedInstant = false;
  bool seen = false;
  double postHeight = 100.0;
  bool postHeightIsSet = false;
  bool deleteInstant = false;
  String type;

  _PostProfileState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.mediaUrl,
    required this.mediaUrlWidth,
    required this.mediaUrlHeight,
    required this.caption,
    required this.likeCount,
    required this.likes,
    required this.comments,
    required this.commentCount,
    required this.mentions,
    required this.timestamp,
    required this.type,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user =
            User.fromDocument(snapshot.data as DocumentSnapshot<Object?>);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Row(
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.0),
                user.verified
                    ? Icon(
                        Icons.verified_sharp,
                        color: Theme.of(context).colorScheme.primary,
                        size: 17.0,
                      )
                    : Text(""),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isPostOwner
                  ? IconButton(
                      onPressed: () => handleDeletePost(context),
                      icon: Icon(Icons.more_horiz),
                    )
                  : Text(''),
              Text(timeago.format(timestamp.toDate(), locale: 'en_short')),
            ],
          ),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Remove this post"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                deletePostInstant();
              },
              child: const Text(
                'Delete',
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

  deletePostInstant() {
    setState(() {
      seen = true;
      deleteInstant = true;
    });
    deletePost();
  }

  deletePost() async {
    // Delete post
    postsRef
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });

    // Delete uploaded image
    storageRef.child("post_$postId.jpg").delete();

    // Delete activity feed
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection('feedItems')
        .where(postId, isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // Delete comments
    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(postId).collection('comments').get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();

      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
      });
    }
  }

  addLikeToActivityFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        "type": "like",
        "username": currentUser.displayName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "seen": true,
        // "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }

  double handleRatio() {
    if ((mediaUrlWidth / mediaUrlHeight) < (9 / 12)) {
      return 9 / 12;
    }
    return mediaUrlWidth / mediaUrlHeight;
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () => handleLikePost(),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: AspectRatio(
              aspectRatio: handleRatio(),
              child: ZoomOverlay(
                modalBarrierColor: Colors.black12,
                minScale: 0.8,
                maxScale: 3.0,
                animationCurve: Curves.fastOutSlowIn,
                animationDuration: Duration(milliseconds: 300),
                twoTouchOnly: true,
                child: cachedNetworkImage(mediaUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  transformIntoHashTag(String text) {
    List<TextSpan> textSpans = [];

    List<String> parts = text.split('#');

    textSpans.add(
      TextSpan(
        text: parts[0],
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
        ),
      ),
    );

    for (int i = 1; i < parts.length; i++) {
      List<String> words = parts[i].split(' ');

      textSpans.add(
        TextSpan(
          text: '#${words.first} ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      );

      if (words.length > 1) {
        textSpans.add(
          TextSpan(
            text: words.sublist(1).join(' '),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w600,
              fontSize: 20.0,
            ),
          ),
        );
      }
    }
    return RichText(text: TextSpan(children: textSpans));
  }

  getMentionsListInText(text) {
    List<String> mentionsList = [];

    List<String> words = caption.split(' ');

    for (int i = 0; i < words.length; i++) {
      if (words[i].startsWith('@')) {
        String mentionKey = words[i].substring(1) + " " + words[i + 1];

        mentions.values.forEach((value) {
          if (mentionKey == value) {
            mentionsList.add('@${value}');
          }
        });
      }
    }
    return mentionsList;
  }

  Widget buildHighlightedText(String text) {
    if (text.contains("#") && mentions.isEmpty) {
      return transformIntoHashTag(text);
    } else if (mentions.isNotEmpty) {
      List<String> mentionsList = getMentionsListInText(text);
      List<TextSpan> textSpans = [];

      RegExp mentionRegex =
          RegExp(mentionsList.join('|'), caseSensitive: false);
      List<String> segments = text.split(mentionRegex);

      for (int i = 0; i < segments.length; i++) {
        String segment = segments[i];
        if (segment.contains("#")) {
          List<String> parts = segment.split('#');

          textSpans.add(
            TextSpan(
              text: parts[0],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.w600,
                fontSize: 20.0,
              ),
            ),
          );

          for (int i = 1; i < parts.length; i++) {
            List<String> words = parts[i].split(' ');

            textSpans.add(
              TextSpan(
                text: '#${words.first} ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            );

            if (words.length > 1) {
              textSpans.add(
                TextSpan(
                  text: words.sublist(1).join(' '),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 20.0,
                  ),
                ),
              );
            }
          }
        } else {
          textSpans.add(
            TextSpan(
              text: segment,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.w600,
                fontSize: 20.0,
              ),
            ),
          );
        }

        if (i < segments.length - 1 && mentionsList.isNotEmpty) {
          String mention = mentionsList[i];
          textSpans.add(
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    showProfile(context, profileId: getKeyByValue(mention)),
              text: mention,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          );
        }
      }
      return RichText(text: TextSpan(children: textSpans));
    } else {
      return Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
        ),
      );
    }
  }

  String getKeyByValue(String? value) {
    value = value?.substring(1);
    for (var entry in mentions.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    throw Exception("Value not found in the map");
  }

  showUserLikes(BuildContext context, String postId) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return LikePost(
        postId: postId,
        postOwnerId: widget.ownerId,
      );
    }));
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        caption == ""
            ? Text("")
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: () => handleLikePost(),
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        child: buildHighlightedText(caption),
                      ),
                    ),
                  ),
                ],
              ),
        mediaUrl == ""
            ? Text("")
            : Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: type == "video"
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            child: PlayVideo(
                              videoUrl: mediaUrl,
                              type: "post",
                              file: null,
                              height: mediaUrlHeight,
                            ),
                          )
                        : buildPostImage(),
                  ),
                ],
              ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: GestureDetector(
                onTap: () => handleLikePost(),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0,
                  color: Color.fromARGB(255, 244, 186, 184),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 30.0),
              child: GestureDetector(
                onTap: () => showComments(context,
                    postId: postId, ownerId: ownerId, updateCommentStatus: () {
                  setState(() {
                    isCommentedInstant = true;
                    commentCount++;
                  });
                }),
                child: Icon(
                  Icons.chat,
                  size: 28.0,
                  color: (isCommented || isCommentedInstant)
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            GestureDetector(
              onTap: () => showUserLikes(context, postId),
              child: Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text(
                  AppLocalizations.of(context)!.likes(likeCount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 40.0),
              child: Text(
                "$commentCount",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    isLiked = (likes[currentUserId] == true);
    isCommented = (comments[currentUserId] == true);

    return (!deleteInstant)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Divider(
                color: Color.fromARGB(255, 244, 186, 184),
                height: 0.0,
              ),
              const SizedBox(height: 8.0),
              buildPostHeader(),
              buildPostFooter(),
              const Divider(
                color: Color.fromARGB(255, 244, 186, 184),
              ),
            ],
          )
        : !deleteInstant
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Divider(
                    color: Color.fromARGB(255, 244, 186, 184),
                    height: 0.0,
                  ),
                  const Divider(
                    color: Colors.white,
                  ),
                ],
              )
            : Container();
  }

  showComments(BuildContext context,
      {required String postId,
      required String ownerId,
      required Function() updateCommentStatus}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        updateCommentStatus: updateCommentStatus,
      );
    }));
  }
}

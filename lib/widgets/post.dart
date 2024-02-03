import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/photo.dart';
import 'package:sm_app/pages/report_post.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/custom_image.dart';
// import 'package:sm_app/widgets/custom_image.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/user.dart';
import '../pages/comments.dart';

class Post extends StatefulWidget {
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
  final double appBarSize;
  final Timestamp timestamp;

  Post({
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
    required this.appBarSize,
    required this.timestamp,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
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
      appBarSize: 112.0,
    );
  }

  factory Post.fromDocumentForTimeline(
      DocumentSnapshot doc, double appBarSize) {
    return Post(
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
      appBarSize: appBarSize,
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
  _PostState createState() => _PostState(
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
        mentions: mentions,
        likeCount: getLikeCount(likes),
        appBarSize: appBarSize,
        timestamp: timestamp,
      );
}

// with AutomaticKeepAliveClientMixin<Post>

class _PostState extends State<Post> {
  ScrollController scrollController = ScrollController();
  final String currentUserId = currentUser.id;
  final String postId;
  final String ownerId;
  final String username;
  final String mediaUrl;
  final int mediaUrlWidth;
  final int mediaUrlHeight;
  final String caption;
  final double appBarSize;
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

  _PostState({
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
    required this.appBarSize,
    required this.timestamp,
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
                      icon: Icon(Icons.more_horiz_outlined),
                    )
                  : IconButton(
                      onPressed: () => handleSignalPost(context),
                      icon: Icon(Icons.more_horiz_outlined),
                    ),
              Text(timeago.format(timestamp.toDate(), locale: 'en_short')),
            ],
          ),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showCupertinoDialog(
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

  handleSignalPost(BuildContext parentContext) {
    return showCupertinoDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Report this post ?"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                showReport(context);
              },
              child: const Text(
                'Report post',
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

  seenPost() {
    setState(() {
      seen = true;
    });
    timelineRef
        .doc(currentUserId)
        .collection('timelinePosts')
        .doc(postId)
        .get()
        .then((doc) => {
              if (doc.exists) {doc.reference.delete()}
            });
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
        "seen": false,
        "commentData": "",
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
      onTap: () => showPhoto(context, mediaUrl, handleRatio()),
      onDoubleTap: () => handleLikePost(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: AspectRatio(
                aspectRatio: handleRatio(),
                child: cachedNetworkImage(mediaUrl),
              ),
            ),
          )
        ],
      ),
    );
  }

  RichText buildHighlightedText(String text) {
    List<String> mentionsList =
        mentions.values.map((value) => '@$value').toList().cast<String>();

    List<TextSpan> textSpans = [];

    RegExp mentionRegex = RegExp(mentionsList.join('|'), caseSensitive: false);
    List<String> segments = text.split(mentionRegex);

    for (int i = 0; i < segments.length; i++) {
      textSpans.add(TextSpan(
        text: segments[i],
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
        ),
      ));

      if (i < segments.length - 1 && mentionsList.isNotEmpty) {
        String mention = mentionsList[i];
        textSpans.add(
          TextSpan(
            recognizer: TapGestureRecognizer()
              ..onTap =
                  () => showProfile(context, profileId: getKeyByValue(mention)),
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
                    child: buildPostImage(),
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
                  color: Theme.of(context).colorScheme.secondary,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 40.0),
              child: Text(
                "$commentCount",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // bool get wantKeepAlive => !seen;

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    isCommented = (comments[currentUserId] == true);

    return (!seen && !deleteInstant)
        ? GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity! < 0) {
                showComments(context, postId: postId, ownerId: ownerId,
                    updateCommentStatus: () {
                  setState(() {
                    isCommentedInstant == true;
                    commentCount++;
                  });
                });
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Divider(
                  color: Theme.of(context).colorScheme.secondary,
                  height: 0.0,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                buildPostHeader(),
                buildPostFooter(),
                Divider(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          )
        : !deleteInstant
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Divider(
                    color: Theme.of(context).colorScheme.secondary,
                    height: 0.0,
                  ),
                  buildPostAlreadySeen(postHeight),
                  Divider(
                    color: Theme.of(context).colorScheme.background,
                  ),
                ],
              )
            : Container();
  }

  buildPostAlreadySeen(height) {
    return Container(
      height: height - 16,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.secondary,
      child: Text(
        "Post already seen",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  ScrollableState? scrollableState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save a reference to the nearest scrollable ancestor
    scrollableState = Scrollable.maybeOf(context);
    scrollableState?.position.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollableState?.position.removeListener(_scrollListener);
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  _scrollListener() {
    if (!seen) {
      // Calculate the position and size of the post
      final RenderBox postBox = context.findRenderObject() as RenderBox;
      final postPosition = postBox.localToGlobal(Offset.zero);
      final postSize = postBox.size;
      final postTop = postPosition.dy;
      final postBottom = postTop + postSize.height;

      if (postSize.height > postHeight) {
        setState(() {
          postHeightIsSet == true;
          postHeight = postSize.height;
        });
      }
      // Check if the post has scrolled out of view by scrolling up Doit changer
      if (postBottom < (appBarSize + 8)) {
        // Mark the post as seen and call deletePostInstant()
        seenPost();
      }
    }
  }

  showReport(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReportPost(
        postId: postId,
        reportSubject: "Post",
      );
    }));
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
        // postMediaUrl: mediaUrl,
      );
    }));
  }
}

showPhoto(BuildContext context, String photoUrl, double aspectRatio) {
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: Duration(
          milliseconds: 200), // Adjust the transition duration as desired
      pageBuilder: (_, __, ___) => Photo(
        photoUrl: photoUrl,
        aspectRatio: aspectRatio,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

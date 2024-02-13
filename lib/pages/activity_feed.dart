import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/widgets/activityFeedItems.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/progress.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeed createState() => _ActivityFeed();
}

class _ActivityFeed extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .doc(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    List<ActivityFeedItem> feedItems = [];
    snapshot.docs.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    Provider.of<ReloadNotifier>(context, listen: false)
        .setShouldReloadActivityFeed(false);
    return feedItems;
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar:
          header(context, titleText: "Notifications", removeBackButton: true),
      body: Container(
        child: FutureBuilder(
          key: ValueKey(
              context.watch<ReloadNotifier>().shouldReloadActivityFeed),
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data as List<Widget>,
            );
          },
        ),
      ),
    );
  }
}

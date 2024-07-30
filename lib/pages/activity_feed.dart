import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/widgets/activityFeedItems.dart';
import 'package:sm_app/widgets/checkInternetConnection.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeed createState() => _ActivityFeed();
}

class _ActivityFeed extends State<ActivityFeed> {
  bool isFeedEmpty = false;
  bool hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    checkInternet();
  }

  toCallOnRetry() {
    checkInternet();
    if (hasInternetConnection) {
      Provider.of<ReloadNotifier>(context, listen: false)
          .setShouldReloadMessageFeed(true);
    }
  }

  Future<void> checkInternet() async {
    bool connected = await checkInternetConnection();
    setState(() {
      hasInternetConnection = connected;
    });
  }

  getActivityFeed() async {
    List<ActivityFeedItem> feedItems = [];
    QuerySnapshot snapshot = await activityFeedRef
        .doc(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    if (snapshot.docs.isNotEmpty) {
      snapshot.docs.forEach((doc) {
        feedItems.add(ActivityFeedItem.fromDocument(doc));
      });
      Provider.of<ReloadNotifier>(context, listen: false)
          .setShouldReloadActivityFeed(false);
    } else {
      setState(() {
        isFeedEmpty = true;
      });
    }

    return feedItems;
  }

  buildEmptyTimeline(context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          AppLocalizations.of(context)!.message_empty_activity_feed,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar:
          header(context, titleText: "Notifications", removeBackButton: true),
      body: hasInternetConnection
          ? !isFeedEmpty
              ? Container(
                  child: FutureBuilder(
                    key: ValueKey(
                      context.watch<ReloadNotifier>().shouldReloadActivityFeed,
                    ),
                    future: getActivityFeed(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return circularProgress(context);
                      }
                      return ListView(
                        children: snapshot.data as List<Widget>,
                      );
                    },
                  ),
                )
              : buildEmptyTimeline(context)
          : showNoConnection(
              context,
              toCallOnRetry,
            ),
    );
  }
}

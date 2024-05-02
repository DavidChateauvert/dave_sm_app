import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/messageFeedItems.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessageFeed extends StatefulWidget {
  @override
  _MessageFeed createState() => _MessageFeed();
}

class _MessageFeed extends State<MessageFeed> {
  bool isFeedEmpty = false;

  List<MessageFeedItem> feedItems = [];
  getMessageFeed() async {
    QuerySnapshot snapshot = await messagesRef
        .doc(currentUser.id)
        .collection('and')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    if (snapshot.docs.isNotEmpty) {
      snapshot.docs.forEach((doc) {
        feedItems.add(MessageFeedItem.fromDocument(doc));
      });
      Provider.of<ReloadNotifier>(context, listen: false)
          .setShouldReloadMessageFeed(false);
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
          AppLocalizations.of(context)!.message_empty_message_feed,
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
      appBar: header(context,
          titleText: "Messages",
          showMessageButton: false,
          showAddMessageButton: true),
      body: !isFeedEmpty
          ? Container(
              child: FutureBuilder(
                key: ValueKey(
                    context.watch<ReloadNotifier>().shouldReloadMessageFeed),
                future: getMessageFeed(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return circularProgress();
                  }
                  return ListView(
                    children: snapshot.data as List<Widget>,
                  );
                },
              ),
            )
          : buildEmptyTimeline(context),
    );
  }
}

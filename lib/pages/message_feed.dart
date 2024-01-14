import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:sm_app/widgets/messageFeedItems.dart';
import 'package:sm_app/widgets/progress.dart';

class MessageFeed extends StatefulWidget {
  @override
  _MessageFeed createState() => _MessageFeed();
}

class _MessageFeed extends State<MessageFeed> {
  getMessageFeed() async {
    QuerySnapshot snapshot = await messagesRef
        .doc(currentUser.id)
        .collection('and')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    List<MessageFeedItem> feedItems = [];
    snapshot.docs.forEach((doc) {
      feedItems.add(MessageFeedItem.fromDocument(doc));
    });
    Provider.of<ReloadNotifier>(context, listen: false)
        .setShouldReloadMessageFeed(false);
    return feedItems;
  }

  @override
  Widget build(context) {
    final reloadNotifier = Provider.of<ReloadNotifier>(context, listen: false);
    return Scaffold(
      appBar: header(context,
          titleText: "Messages",
          showMessageButton: false,
          showAddMessageButton: true),
      body: Container(
        child: FutureBuilder(
          key: ValueKey<bool>(reloadNotifier.shouldReloadMessageFeed),
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
      ),
    );
  }
}

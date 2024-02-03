import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/search_message.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';

AppBar header(context,
    {String? titleText,
    removeBackButton = false,
    showMessageButton = true,
    showAddMessageButton = false}) {
  return AppBar(
    leading: (titleText == "Profile" && removeBackButton == true)
        ? Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 28,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          )
        : null,
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      // ignore: prefer_if_null_operators
      titleText != null ? titleText : "Timeline",
      style: const TextStyle(color: Colors.white, fontSize: 30.0),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    actions: [
      showMessageButton
          ? IconButton(
              onPressed: () {
                Provider.of<RouteObserverProvider>(context, listen: false)
                    .setCurrentRoute("message-feed");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageFeed(),
                    ));
              },
              icon: Badge(
                isLabelVisible: Provider.of<NotificationProvider>(context)
                            .notificationMessageCount ==
                        0
                    ? false
                    : true,
                label: Text(Provider.of<NotificationProvider>(context)
                    .notificationMessageCount
                    .toString()),
                child: Icon(
                  Provider.of<NotificationProvider>(context)
                              .notificationMessageCount ==
                          0
                      ? CupertinoIcons.bubble_right
                      : CupertinoIcons.bubble_right_fill,
                  size: 25.0,
                ),
              ),
            )
          : showAddMessageButton
              ? IconButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchMessage(),
                      )),
                  icon: Icon(CupertinoIcons.search))
              : Container(),
    ],
    backgroundColor: Theme.of(context).colorScheme.primary,
  );
}

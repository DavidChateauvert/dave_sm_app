import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/settings.dart';
import 'package:sm_app/providers/notification_provider.dart';

AppBar header(context,
    {String? titleText, removeBackButton = false, showMessageButton = true}) {
  return AppBar(
    leading: (titleText == "Profile" && removeBackButton == true)
        ? IconButton(
            icon: Icon(
              Icons.settings_outlined,
              size: 28,
            ),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    currentUserId: currentUser.id,
                  ),
                )),
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
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageFeed(),
                  )),
              icon: Badge(
                isLabelVisible: Provider.of<NotificationProvider>(context)
                            .notificationCount ==
                        0
                    ? false
                    : true,
                label: Text(Provider.of<NotificationProvider>(context)
                    .notificationCount
                    .toString()),
                child: Icon(
                  Provider.of<NotificationProvider>(context)
                              .notificationCount ==
                          0
                      ? CupertinoIcons.bubble_right
                      : CupertinoIcons.bubble_right_fill,
                  size: 25.0,
                ),
              ),
            )
          : Container(),
    ],
    backgroundColor: Theme.of(context).colorScheme.primary,
  );
}

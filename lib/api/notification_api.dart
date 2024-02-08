import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';

class NotificationsApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future init(context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) =>
          print("Received"),
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    _notifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) =>
            handleClick(context, details));
  }

  static void handleClick(context, NotificationResponse details) async {
    int type = details.id ?? 1;
    String screenValue = details.payload ?? "";
    if (type == 1) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()),
        (route) => false,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageFeed(),
        ),
      );
      if (screenValue != "") {
        Provider.of<RouteObserverProvider>(context, listen: false)
            .setCurrentRoute(screenValue);
        Provider.of<NotificationProvider>(context, listen: false)
            .seenNotificationMessage(screenValue);
        messagesRef
            .doc(currentUser.id)
            .collection("and")
            .doc(screenValue)
            .update({"seen": true});
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(otherUserId: screenValue),
          ),
        );
        Provider.of<RouteObserverProvider>(context, listen: false)
            .setCurrentRoute("message-feed");
      }
    }
  }

  static Future _notificationDetails() async {
    return NotificationDetails(
      android: AndroidNotificationDetails('channel id', 'channel name',
          importance: Importance.max),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: "plainCategory",
      ),
    );
  }

  static Future showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      await _notificationDetails(),
      payload: payload,
    );
  }
}

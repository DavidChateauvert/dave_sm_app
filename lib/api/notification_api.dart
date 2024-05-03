import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';
import 'package:sm_app/providers/shared_preferences.dart';

class NotificationsApi {
  static late BuildContext _context;

  static void initialize(BuildContext context) {
    _context = context;
  }

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

  Future<void> checkBackgroundMessage(BuildContext context) async {
    SharedPreferencesProvider().getMessagesFromSharedPreferences(context);
  }

  handleBackGroundMessage(RemoteMessage message) {
    String type = message.data['type'] ?? "";
    int typeId = typeToId(type);
    String screen = message.data['screen'] ?? "";

    String title = message.data['title'] ?? "";
    String body = message.data['body'] ?? "";
    NotificationsApi.showNotification(
        id: typeId, title: title, body: body, payload: screen);

    if (_context.mounted) {
      // Ios
      Provider.of<NotificationProvider>(_context, listen: false)
          .receiveNotificationHandler(message);
    } else {
      // Android
      OutsideMessage outsideMessage =
          OutsideMessage(type: type, screen: screen);
      SharedPreferencesProvider().setNotif(outsideMessage);
    }
  }

  int typeToId(String type) {
    switch (type) {
      case "message":
        return 1;
      case "mention":
      case "friend request question":
      case "friend request accept":
      case "like":
      case "comment":
        return 2;
      default:
        return 2;
    }
  }

  bool checkIfUserIsAlreadyInPage(int typeId, String screenValue) {
    final String currentRoute =
        Provider.of<RouteObserverProvider>(_context, listen: false)
            .currentRoute;

    if (currentRoute == screenValue) {
      return true;
    } else {
      return false;
    }
  }

  void handleNotificationInside(RemoteMessage message) {
    Provider.of<NotificationProvider>(_context, listen: false)
        .receiveNotificationHandler(message);

    String type = message.data['type'] ?? "";
    int typeId = typeToId(type);
    String screen = message.data['screen'] ?? "";

    String title = message.data['title'] ?? "";
    String body = message.data['body'] ?? "";
    NotificationsApi.showNotification(
        id: typeId, title: title, body: body, payload: screen);

    if (!checkIfUserIsAlreadyInPage(typeId, screen)) {
      // Provider.of<ReloadNotifier>(context, listen: false)
      //     .setShouldReloadActivityFeed(true);
      if (Provider.of<RouteObserverProvider>(_context, listen: false)
              .currentRoute ==
          "message-feed") {
        Provider.of<ReloadNotifier>(_context, listen: false)
            .setShouldReloadMessageFeed(true);
      }
    } else {
      messagesRef
          .doc(currentUser.id)
          .collection("and")
          .doc(screen)
          .update({"seen": true});
      Provider.of<NotificationProvider>(_context, listen: false)
          .seenNotificationMessage(screen);
    }
  }

  void handleNotificationOnClick(RemoteMessage message) async {
    String type = message.data['type'] ?? "";
    if (type != "") {
      String screenValue = message.data['screen'] ?? "";
      Navigator.of(_context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()),
        (route) => false,
      );
      if (type == "message") {
        Navigator.push(
          _context,
          MaterialPageRoute(
            builder: (context) => MessageFeed(),
          ),
        );
        Provider.of<RouteObserverProvider>(_context, listen: false)
            .setCurrentRoute("message-feed");
        if (screenValue != "") {
          Provider.of<RouteObserverProvider>(_context, listen: false)
              .setCurrentRoute(screenValue);
          Provider.of<NotificationProvider>(_context, listen: false)
              .seenNotificationMessage(screenValue);
          await Navigator.push(
            _context,
            MaterialPageRoute(
              builder: (context) => MessageScreen(
                otherUserId: screenValue,
                updateMessage: (newMessage) => null,
              ),
            ),
          );
          Provider.of<RouteObserverProvider>(_context, listen: false)
              .setCurrentRoute("message-feed");
        }
      } else if (type == "mention") {
        //String senderId = message.data['senderId'] ?? "";
        // onTap(4);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) =>
        //         PostScreen(userId: senderId, postId: screenValue, type: type),
        //   ),
        // );
        // Provider.of<NotificationProvider>(context, listen: false)
        //     .seenNotificationActivityFeed(screenValue);
      } else if (type == "friend request question" ||
          type == "friend request accept") {
        // onTap(4);
        Navigator.push(
          _context,
          MaterialPageRoute(
            builder: (context) => Profile(profileId: screenValue),
          ),
        );
        Provider.of<NotificationProvider>(_context, listen: false)
            .seenNotificationActivityFeed(screenValue);
      }
    }
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
            builder: (context) => MessageScreen(
              otherUserId: screenValue,
              updateMessage: (newMessage) => null,
            ),
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

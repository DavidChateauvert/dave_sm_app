import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:sm_app/providers/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  int _notificationBadgerCount = 0;
  List<String> _notificationMessageList = [];
  List<String> _notificationActivityList = [];

  int get notificationCount => _notificationBadgerCount;
  int get notificationMessageCount => _notificationMessageList.length;
  int get notificationActivityCount => _notificationActivityList.length;

  set notificationCount(int notificationCountSeter) {
    _notificationBadgerCount = notificationCountSeter;
    notifyListeners();
  }

  set notificationMessageCount(int notificationMessageCountSeter) {
    notificationMessageCount = notificationMessageCountSeter;
    notifyListeners();
  }

  set notificationActivityCount(int notificationActivityCountSeter) {
    notificationActivityCount = notificationActivityCountSeter;
    notifyListeners();
  }

  void receiveNotificationHandler(RemoteMessage message) {
    String type = message.data['type'] ?? "";
    String screen = message.data['screen'] ?? "";

    if (type == "message") {
      receiveNotificationMessage(screen);
    } else if ([
      "like",
      "comment",
      "mention",
      "friend request question",
      "friend request accept"
    ].contains(type)) {
      receiveNotificationActivity(screen);
    }
  }

  // Android
  void receiveNotificationHandlerAndroid(OutsideMessage message) {
    String type = message.type;
    String screen = message.screen;

    if (type == "message") {
      receiveNotificationMessage(screen);
    } else if ([
      "like",
      "comment",
      "mention",
      "friend request question",
      "friend request accept"
    ].contains(type)) {
      receiveNotificationActivity(screen);
    }
  }

  void receiveNotificationMessage(String userId) {
    if (!_notificationMessageList.contains(userId)) {
      _notificationMessageList.add(userId);
      notifyListeners();
      _notificationBadgerCount++;
      FlutterAppBadger.updateBadgeCount(_notificationBadgerCount);
    }
  }

  void seenNotificationMessage(String userId) {
    if (_notificationMessageList.contains(userId)) {
      _notificationMessageList.remove(userId);
      notifyListeners();
      _notificationBadgerCount--;
      FlutterAppBadger.updateBadgeCount(_notificationBadgerCount);
    }
  }

  void receiveNotificationActivity(String Id) {
    if (!_notificationActivityList.contains(Id)) {
      _notificationActivityList.add(Id);
      notifyListeners();
      _notificationBadgerCount++;
      FlutterAppBadger.updateBadgeCount(_notificationBadgerCount);
    }
  }

  void seenNotificationActivityFeed(String Id) {
    if (_notificationActivityList.contains(Id)) {
      _notificationActivityList.remove(Id);
      notifyListeners();
      _notificationBadgerCount--;
      FlutterAppBadger.updateBadgeCount(_notificationBadgerCount);
    }
  }

  void resetNotificationCount() {
    _notificationActivityList.clear();
    _notificationMessageList.clear();
    _notificationBadgerCount = 0;
    notifyListeners();
    FlutterAppBadger.updateBadgeCount(0);
  }

  void printNotificationCount() {
    print(_notificationActivityList);
  }
}

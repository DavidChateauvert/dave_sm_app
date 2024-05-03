import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sm_app/providers/notification_provider.dart';

class SharedPreferencesProvider with ChangeNotifier {
  void setNotif(OutsideMessage outsideMessage) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    List<String> messages = preferences.getStringList('messages') ?? [];
    messages.add(json.encode(outsideMessage.toJson()));
    preferences.setStringList('messages', messages);
    int numberOfNotifications = countDistinct(messages);
    FlutterAppBadger.updateBadgeCount(numberOfNotifications);
    notifyListeners();
  }

  int countDistinct(List<String> messages) {
    Set<String> uniqueMessages = Set<String>.from(messages);
    return uniqueMessages.length;
  }

  Future<void> getMessagesFromSharedPreferences(context) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    List<String> messageStrings = preferences.getStringList('messages') ?? [];
    // if empty, don't reset notification
    if (messageStrings != []) {
      FlutterAppBadger.updateBadgeCount(0);
    }

    List<OutsideMessage> messages = messageStrings
        .map((messageString) =>
            OutsideMessage.fromJson(json.decode(messageString)))
        .toList();
    messages.forEach((outsideMessage) {
      Provider.of<NotificationProvider>(context, listen: false)
          .receiveNotificationHandlerAndroid(outsideMessage);
    });
    preferences.remove('messages');
    notifyListeners();
  }
}

class OutsideMessage {
  final String type;
  final String screen;

  OutsideMessage({
    required this.type,
    required this.screen,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'screen': screen,
    };
  }

  factory OutsideMessage.fromJson(Map<String, dynamic> json) {
    return OutsideMessage(
      type: json['type'],
      screen: json['screen'],
    );
  }
}

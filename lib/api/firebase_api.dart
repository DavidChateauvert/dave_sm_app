import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sm_app/providers/locale_provider.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  late String fCMToken;

  Future<void> initMessaging(currentUserId) async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);

    if (fCMToken != null) {
      tokensRef.doc(currentUserId).set({
        "token": fCMToken,
      });
    }
  }

  deleteUserToken(currentUserId) async {
    tokensRef.doc(currentUserId).set({
      "token": "",
    });
  }

  requestPermissionText() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("all good");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("all good-ish");
    } else {
      print("not good");
    }
  }

  Future<String?> getToken(String receiverId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('tokens')
          .doc(receiverId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String token = data['token'];
        return token;
      } else {
        print("Document not found.");
        return "";
      }
    } catch (error) {
      print("Error getting document: $error");
      return "";
    }
  }

  Future<Locale?> getLocale(BuildContext context, String receiverId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String receiverLocale = data['locale'];
        return Provider.of<LocaleProvider>(context, listen: false)
            .getLocaleFromString(receiverLocale);
      } else {
        print("Document not found.");
        return Locale('en');
      }
    } catch (error) {
      print("Error getting document: $error");
      return Locale('en');
    }
  }

  sendMessageNotification(BuildContext context, String otherUserId,
      String message, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = message != "" ? message : "Sent you a photo";
    } else {
      textNotification = message != "" ? message : "Vous a envoyé une photo";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': message,
              'title': "Vous avez recu un message",
              'screen': "${currentUser.id}",
              'type': "message",
            },
            "notification": <String, dynamic>{
              "title": "$senderName",
              "body": textNotification,
            },
            "category": "message",
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendMentionsNotification(BuildContext context, String otherUserId,
      String senderName, String postId) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has identified you in a post";
    } else {
      textNotification = "$senderName vous a identifié dans une publication";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${postId}",
              'senderId': "${currentUser.id}",
              'type': "mention",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendFriendRequestNotification(
      BuildContext context, String otherUserId, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has sent you a friend request";
    } else {
      textNotification = "$senderName vous a envoyé une demande d'ami";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${currentUser.id}",
              'type': "friend request question",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendAcceptRequestNotification(
      BuildContext context, String otherUserId, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has accepted your friend request";
    } else {
      textNotification = "$senderName a accepté votre demande d'ami";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${currentUser.id}",
              'type': "friend request accept",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendLikeNotification(BuildContext context, String otherUserId,
      String senderName, String postId) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has liked your post";
    } else {
      textNotification = "$senderName a aimé votre publication";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${postId}",
              'senderId': "${currentUser.id}",
              'type': "like",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendCommentLikeNotification(BuildContext context, String otherUserId,
      String senderName, String postId, String comment) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has liked your comment : $comment";
    } else {
      textNotification = "$senderName a aimé votre commentaire : $comment";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${postId}",
              'senderId': "${currentUser.id}",
              'type': "commentLike",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendCommentNotification(BuildContext context, String otherUserId,
      String senderName, String postId, String comment) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
    Locale userLocale =
        await FirebaseApi().getLocale(context, otherUserId) ?? Locale('en');
    String textNotification;
    if (userLocale == Locale('en')) {
      textNotification = "$senderName has commented your post : $comment";
    } else {
      textNotification = "$senderName a commenté votre publication : $comment";
    }

    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAA5hU-q8Q:APA91bEsFeg67RQ2qtOnphuadgkwsmZ4K3zgdwHEvtnoIfdTS1hUvPbe-kUhuyZe0NvJiYnGwaikAp339wIGD_DmvunTzNK5oMNwhwN-hbCsqm-PC1kiO3wJOiYfNSQHbw3LiRFV-Vkp',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': "Dave",
              'title': "Dave",
              'screen': "${postId}",
              'senderId': "${currentUser.id}",
              'type': "comment",
            },
            "notification": <String, dynamic>{
              "title": "Dave",
              "body": textNotification,
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }
}

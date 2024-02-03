import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sm_app/pages/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  late String fCMToken;

  Future<void> initMessaging(currentUserId) async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);

    if (fCMToken != null) {
      tokensRef.doc(currentUserId).update({
        "token": fCMToken,
      });
    }
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

  sendMessageNotification(
      String otherUserId, String message, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";
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
              "body": message,
            },
            "category": "message",
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendMentionsNotification(
      String otherUserId, String senderName, String postId) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";

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
              "body": "$senderName vous a identifié dans un post",
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendFriendRequestNotification(String otherUserId, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";

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
              "body": "$senderName has sent you a friend request",
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }

  sendAcceptRequestNotification(String otherUserId, String senderName) async {
    String userTokens = await FirebaseApi().getToken(otherUserId) ?? "";

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
              "body": "$senderName has accepted your friend request",
            },
            "content_available": true,
            "to": userTokens,
          }));
    } catch (e) {
      print("erreur de send Notifcation");
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';

import 'package:sm_app/providers/locale_provider.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  FirebaseFunctions functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  late String fCMToken;

  Future<void> initMessaging(currentUserId) async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "$senderName",
        'body': textNotification,
        'screen': "${currentUser.id}",
        'type': "message",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${postId}",
        'type': "mention",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${currentUser.id}",
        'type': "friend request question",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${currentUser.id}",
        'type': "friend request accept",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${postId}",
        'type': "like",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${postId}",
        'type': "commentLike",
      });
    } catch (e) {
      print('Error sending message: $e');
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
      final HttpsCallable callable =
          functions.httpsCallable('sendNotification');
      await callable.call({
        'tokens': userTokens,
        'title': "Dave",
        'body': textNotification,
        'screen': "${postId}",
        'type': "comment",
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}

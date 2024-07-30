import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/progress.dart';
import '../../models/user.dart' as DaveUser;

class AuthentificationService {
  signInWithGoogle() async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  signInWithApple() async {
    try {
      var appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      await FirebaseAuth.instance.signInWithProvider(appleProvider);
    } catch (e) {
      print("Error signing in with Apple: $e");
    }
  }

  Map<String, String> ogMap = {
    "100364945154609990727": "simon.s.cote@gmail.com",
    "101924802992822653698": "doukhaneyasmine@gmail.com",
    "103404205137770745499": "imendoukhane10@gmail.com",
    "103688688891980225149": "jublegault@gmail.com",
    "105321614597959203364": "niktoumektoub@gmail.com",
    "106593283187924168095": "raphael.domingo.rdb@gmail.com",
    "108259239408748094251": "potternoah2012@gmail.com",
    "112112281762872398169": "boubou.stpierre@gmail.com",
    "113652797248457375698": "fbernier56@gmail.com",
    "114680131472867035837": "jeremy.perreault@oritech.ca",
    "116269485754794950267": "jeanthomasdagenais@gmail.com",
    "116824415698447617395": "trist.cousineau@gmail.com",
  };

  bool doesEmailExist(String email) {
    return ogMap.containsValue(email);
  }

  bool doesIdExist(String userId) {
    return ogMap.containsKey(userId);
  }

  Future<bool> checkIfAlreadyTransferred(String newUserId) async {
    bool alreadyTranferred = false;
    QuerySnapshot transferSnapshot = await transferRef.get();

    transferSnapshot.docs.forEach((doc) {
      if (doc.id == newUserId) {
        alreadyTranferred = true;
      }
    });

    return alreadyTranferred;
  }

  Future<String> getOldUserIdFromEmail(String email) async {
    String oldUserId = "";
    QuerySnapshot userSnapshot = await usersRef.get();

    userSnapshot.docs.forEach((doc) {
      if ((doc['email'] == email)) {
        oldUserId = doc['id'];
      }
    });

    return oldUserId;
  }

  transferUser(BuildContext context, String oldUserId, String newUserId) async {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: circularProgress(context),
        );
      },
    );
    try {
      DocumentSnapshot userRefData = await usersRef.doc(oldUserId).get();

      DaveUser.User user = DaveUser.User.fromDocument(userRefData);

      // Transfer user info
      if (userRefData.exists) {
        await usersRef.doc(newUserId).set({
          "id": newUserId,
          "username": user.displayName,
          "usernameLower": user.displayName.toString().toLowerCase(),
          "photoUrl": user.photoUrl,
          "email": user.email,
          "firstName": user.firstName,
          "lastName": user.lastName,
          "displayName": user.displayName,
          "displayNameLower": user.displayName.toLowerCase(),
          "bio": user.bio,
          "timestamp": user.timestamp,
          "theme": user.theme,
          "verified": user.verified,
          "locale": user.locale,
          "postsCount": user.postsCount,
          "gender": user.gender,
          "dateOfBirth": user.dateOfBirth,
        });
      }

      QuerySnapshot userFriends =
          await friendsRef.doc(oldUserId).collection('userFriends').get();

      userFriends.docs.forEach((doc) async {
        await friendsRef
            .doc(newUserId)
            .collection('userFriends')
            .doc(doc.id)
            .set({});

        await friendsRef
            .doc(doc.id)
            .collection('userFriends')
            .doc(newUserId)
            .set({});
      });

      QuerySnapshot userFollowers =
          await followersRef.doc(oldUserId).collection('userFollowers').get();

      userFollowers.docs.forEach((doc) async {
        await followersRef
            .doc(newUserId)
            .collection('userFollowers')
            .doc(doc.id)
            .set({});

        await followingRef
            .doc(doc.id)
            .collection('userFollowing')
            .doc(newUserId)
            .set({});
      });

      QuerySnapshot userFollowing =
          await followingRef.doc(oldUserId).collection('userFollowing').get();

      userFollowing.docs.forEach((doc) async {
        await followingRef
            .doc(newUserId)
            .collection('userFollowing')
            .doc(doc.id)
            .set({});

        await followersRef
            .doc(doc.id)
            .collection('userFollowers')
            .doc(newUserId)
            .set({});
      });

      await transferRef.doc(newUserId).set({});

      await usersRef.doc(oldUserId).delete();
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      print("Error Transfering Data");
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
      // OAuthProvider('apple.com').addScope('email').addScope('fullName');

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print(appleCredential);

      if (appleCredential.identityToken == null) {
        print("No identity token received.");
        return;
      }

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
      );

      print(credential);

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Error signing in with Apple: $e");
    }
  }

  Map<String, String> ogMap = {
    "100159983454055196517": "david.chateauvert25@gmail.com",
    "100364945154609990727": "simon.s.cote@gmail.com",
    "101471389277805089488": "ralph.younan123@gmail.com",
    "101612825633433984521": "ferreirajulianne@gmail.com",
    "101924802992822653698": "doukhaneyasmine@gmail.com",
    "102615848329479172617": "rosalie.couillard@gmail.com",
    "102931377173029788443": "max21soccer@gmail.com",
    "103404205137770745499": "imendoukhane10@gmail.com",
    "103481799505752667563": "yohann.tahar@gmail.com",
    "103688688891980225149": "jublegault@gmail.com",
    "103728939285997065880": "david.chateauvert@hotmail.fr",
    "105321614597959203364": "niktoumektoub@gmail.com",
    "105356883590824780714": "david.chateauvert@bloomix.ca",
    "106593283187924168095": "raphael.domingo.rdb@gmail.com",
    "107562480416146775718": "marco1camacho1@gmail.com",
    "107767682528570438472": "charles.fontaine94@gmail.com",
    "108014655950623273908": "mathieu.chateauvert.mc@gmail.com",
    "108259239408748094251": "potternoah2012@gmail.com",
    "111523379061803458543": "guillaume.trifiro@gmail.com",
    "112112281762872398169": "boubou.stpierre@gmail.com",
    "113271532028957863807": "afi539772@gmail.com",
    "113456531491623573825": "bstambadel@gmail.com",
    "113652486134777819431": "nickburgoa@hotmail.com",
    "113652797248457375698": "fbernier56@gmail.com",
    "114680131472867035837": "jeremy.perreault@oritech.ca",
    "114934494147942058921": "legaultkatrine@gmail.com",
    "116269485754794950267": "jeanthomasdagenais@gmail.com",
    "116449118474804652573": "mamoueldaigneault@gmail.com",
    "116824415698447617395": "trist.cousineau@gmail.com",
    "117044319590353857208": "david@hellodarwin.com",
    "118372581054595480477": "davegreencastle@gmail.com",
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
          child: circularProgress(),
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

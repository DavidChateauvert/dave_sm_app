// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/pages/timeline.dart';
import 'package:sm_app/pages/upload.dart';
import '../models/user.dart';
import 'activity_feed.dart';
import 'create_account.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final storageRef = FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final messagesRef = FirebaseFirestore.instance.collection('messages');
final friendsRef = FirebaseFirestore.instance.collection('friends');
final tokensRef = FirebaseFirestore.instance.collection('tokens');
final DateTime timestamp = DateTime.now();
late User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController = PageController();
  int pageIndex = 0;

  @override
  void initState() {
    //initializeFirebase();
    super.initState();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn();
    }, onError: (err) {
      print('Error signing in: $err');
    });
    //Reauthenticated user when pp is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn();
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  // void initializeFirebase() async {
  //   await Firebase.initializeApp();
  // }

  // handleSignIn(GoogleSignInAccount? account) async {
  //   if (account != null) {
  //       await createUserInFirestore();
  //       setState(() {
  //         isAuth = true;
  //       });
  //     } else {
  //       setState(() {
  //         isAuth = false;
  //       });
  //     }
  // }

  handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) {
        await googleSignIn.signIn();
      }
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } catch (error) {
      print('Error signing in: $error');
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    // 1 : Check if user exsits in users collection according to there id
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await usersRef.doc(user.id).get();
      if (!doc.exists) {
        // 2 : If they don't exist, take them to the create account page
        final username = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => CreateAccount()));
        // 3 : Get username from create account, use it to make new user document in users collection
        usersRef.doc(user.id).set({
          "id": user.id,
          "username": username,
          "usernameLower": username.toString().toLowerCase(),
          "photoUrl": user.photoUrl,
          "email": user.email,
          "displayName": user.displayName,
          "displayNameLower": user.displayName?.toLowerCase(),
          "bio": "",
          "timestamp": timestamp,
          "verifed": false,
        });
        // Make new user their own follower
        await followersRef
            .doc(user.id)
            .collection('userFollowers')
            .doc(user.id)
            .set({});

        doc = await usersRef.doc(user.id).get();
      }
      currentUser = User.fromDocument(doc);
      // await FirebaseApi().initMessaging(currentUser.id);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          Timeline(currentUser: currentUser),
          Search(),
          Upload(currentUser: currentUser),
          Profile(profileId: currentUser.id),
          ActivityFeed(),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_timeline_outlined),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_outlined),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
          ),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 244, 186, 184),
              Theme.of(context).primaryColor
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Dave',
              style: TextStyle(fontSize: 90, color: Colors.white),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 200,
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 60, color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor,
                      Color.fromARGB(255, 244, 186, 184)
                    ],
                  ),
                ),
                alignment: Alignment.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}

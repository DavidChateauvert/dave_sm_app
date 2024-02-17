// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/api/notification_api.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/pages/timeline.dart';
import 'package:sm_app/pages/upload.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';
import 'package:sm_app/providers/theme_provider.dart';
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
final reportsRef = FirebaseFirestore.instance.collection('reports');
final DateTime timestamp = DateTime.now();
late User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController =
      PageController(initialPage: 0, keepPage: false);
  int pageIndex = 0;
  bool isCreatingUser = false;

  @override
  void initState() {
    //initializeFirebase();
    super.initState();
    initLocalNotifications();
    FirebaseMessaging.onMessage.listen((message) {
      handleNotificationInside(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationOnClick(message);
    });
    FirebaseMessaging.onBackgroundMessage(handleBackGroundMessage);
    // googleSignIn.signIn();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn();
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauthenticated user when pp is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn();
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  void initLocalNotifications() async {
    await NotificationsApi.init(context);
  }

  handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) {
        await googleSignIn.signIn();
      }
      if (!isCreatingUser) {
        // Set the flag to indicate user creation is in progress
        await createUserInFirestore();
        setState(() {
          isAuth = true;
        });
      }
    } catch (error) {
      print('Error signing in: $error');
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    setState(() {
      isCreatingUser = true;
    });
    // 1 : Check if user exsits in users collection according to there id
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await usersRef.doc(user.id).get();
      if (!doc.exists) {
        setState(() {
          isCreatingUser = true;
        });
        // 2 : If they don't exist, take them to the create account page
        final User newUser = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreateAccount(
                      userId: user.id,
                    )));
        // 3 : Get username from create account, use it to make new user document in users collection
        usersRef.doc(user.id).set({
          "id": user.id,
          "username": newUser.displayName,
          "usernameLower": newUser.displayName.toString().toLowerCase(),
          "photoUrl": newUser.photoUrl != "" ? newUser.photoUrl : user.photoUrl,
          "email": user.email,
          "firstName": newUser.firstName,
          "lastName": newUser.lastName,
          "displayName": newUser.displayName,
          "displayNameLower": newUser.displayName.toLowerCase(),
          "bio": newUser.bio,
          "timestamp": timestamp,
          "theme": newUser.theme,
          "verified": false,
        });
        // Make new user their own follower
        await followersRef
            .doc(user.id)
            .collection('userFollowers')
            .doc(user.id)
            .set({});

        doc = await usersRef.doc(user.id).get();
        setState(() {
          isCreatingUser = false;
        });
      }
      currentUser = User.fromDocument(doc);
      Provider.of<ThemeProvider>(context, listen: false)
          .toggleThemeToParam(currentUser.theme);
      await FirebaseApi().initMessaging(currentUser.id);
    }
    setState(() {
      isCreatingUser = false;
    });
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
        Provider.of<RouteObserverProvider>(context, listen: false).currentRoute;

    if (currentRoute == screenValue) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> handleBackGroundMessage(RemoteMessage message) async {
    Provider.of<NotificationProvider>(context, listen: false)
        .receiveNotificationHandler(message);
  }

  void handleNotificationInside(RemoteMessage message) {
    Provider.of<NotificationProvider>(context, listen: false)
        .receiveNotificationHandler(message);

    String type = message.data['type'] ?? "";
    int typeId = typeToId(type);
    String screen = message.data['screen'] ?? "";

    if (!checkIfUserIsAlreadyInPage(typeId, screen)) {
      String title = message.notification?.title ?? "";
      String body = message.notification?.body ?? "";
      NotificationsApi.showNotification(
          id: typeId, title: title, body: body, payload: screen);

      Provider.of<ReloadNotifier>(context, listen: false)
          .setShouldReloadActivityFeed(true);
      if (Provider.of<RouteObserverProvider>(context, listen: false)
              .currentRoute ==
          "message-feed") {
        Provider.of<ReloadNotifier>(context, listen: false)
            .setShouldReloadMessageFeed(true);
      }
    } else {
      messagesRef
          .doc(currentUser.id)
          .collection("and")
          .doc(screen)
          .update({"seen": true});
      Provider.of<NotificationProvider>(context, listen: false)
          .seenNotificationMessage(screen);
    }
  }

  void handleNotificationOnClick(RemoteMessage message) async {
    String type = message.data['type'] ?? "";
    if (type != "") {
      String screenValue = message.data['screen'] ?? "";
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()),
        (route) => false,
      );
      if (type == "message") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageFeed(),
          ),
        );
        Provider.of<RouteObserverProvider>(context, listen: false)
            .setCurrentRoute("message-feed");
        if (screenValue != "") {
          Provider.of<RouteObserverProvider>(context, listen: false)
              .setCurrentRoute(screenValue);
          Provider.of<NotificationProvider>(context, listen: false)
              .seenNotificationMessage(screenValue);
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
      } else if (type == "mention") {
        //String senderId = message.data['senderId'] ?? "";
        onTap(4);
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
        onTap(4);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(profileId: screenValue),
          ),
        );
        Provider.of<NotificationProvider>(context, listen: false)
            .seenNotificationActivityFeed(screenValue);
      }
    }
  }

  onTap(int pageIndex) {
    pageController.jumpToPage(pageIndex);
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
        activeColor: Theme.of(context).colorScheme.primary,
        items: [
          BottomNavigationBarItem(
            label: "Timeline",
            icon: Icon(CupertinoIcons.text_justify),
          ),
          BottomNavigationBarItem(
            label: "Search",
            icon: Icon(CupertinoIcons.search),
          ),
          BottomNavigationBarItem(
            label: "Post",
            icon: Icon(CupertinoIcons.add),
          ),
          BottomNavigationBarItem(
            label: "Profile",
            icon: Icon(CupertinoIcons.person),
          ),
          BottomNavigationBarItem(
            label: "Notifications",
            icon: Badge(
              child: Icon(CupertinoIcons.bell),
              isLabelVisible: Provider.of<NotificationProvider>(context)
                          .notificationActivityCount ==
                      0
                  ? false
                  : true,
            ),
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
              Color.fromARGB(255, 89, 36, 99),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Text(
            //   'Dave',
            //   style: TextStyle(fontSize: 90, color: Colors.white),
            // ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 220,
                child: Center(
                  child: Text(
                    'Dave',
                    style: TextStyle(fontSize: 80, color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.fromARGB(255, 89, 36, 99),
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

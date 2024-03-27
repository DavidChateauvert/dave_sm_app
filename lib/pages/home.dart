// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/api/notification_api.dart';
import 'package:sm_app/pages/intro.dart';
import 'package:sm_app/pages/message_feed.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/pages/timeline.dart';
import 'package:sm_app/pages/upload.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';
import 'package:sm_app/providers/theme_provider.dart';
import '../models/user.dart' as DaveUser;
import 'activity_feed.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
final groupsRef = FirebaseFirestore.instance.collection('groups');
final DateTime timestamp = DateTime.now();
late DaveUser.User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController =
      PageController(initialPage: 0, keepPage: false);
  int pageIndex = 0;
  // bool isCreatingUser = false;
  GlobalKey<TimelineState> timelineKey = GlobalKey<TimelineState>();

  @override
  void initState() {
    //initializeFirebase();
    super.initState();

    checkIfUserExist();
    // getActiveUser();
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
    // googleSignIn.onCurrentUserChanged.listen((account) {
    //   handleSignIn();
    // }, onError: (err) {
    //   print('Error signing in: $err');
    // });
    // // Reauthenticated user when pp is opened
    // googleSignIn.signInSilently(suppressErrors: false).then((account) {
    //   handleSignIn();
    // }).catchError((err) {
    //   print('Error signing in: $err');
    // });
  }

  getActiveUser() async {
    final String userId;
    if (await FirebaseAuth.instance.currentUser!.providerData[0].providerId ==
        "google.com") {
      userId = googleSignIn.currentUser!.id;
    } else {
      userId = FirebaseAuth.instance.currentUser!.uid;
    }
    DocumentSnapshot doc = await usersRef.doc(userId).get();
    // if (!doc.exists) {
    currentUser = DaveUser.User.fromDocument(doc);
    Provider.of<ThemeProvider>(context, listen: false)
        .toggleThemeToParam(currentUser.theme);
    Provider.of<LocaleProvider>(context, listen: false)
        .toggleLocaleToParam(currentUser.locale);
    await FirebaseApi().initMessaging(currentUser.id);
    // } else {
    //   FirebaseAuth.instance.signOut();
    // }
  }

  checkIfUserExist() async {
    final String userId;
    print(4444);
    String provider =
        FirebaseAuth.instance.currentUser!.providerData[0].providerId;
    if (provider == "google.com") {
      userId = googleSignIn.currentUser!.id;
    } else {
      userId = FirebaseAuth.instance.currentUser!.uid;
    }
    DocumentSnapshot doc = await usersRef.doc(userId).get();
    if (!doc.exists) {
      final DaveUser.User newUser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Intro(
            userId: userId,
          ),
        ),
      );
      await usersRef.doc(userId).set({
        "id": userId,
        "username": newUser.displayName,
        "usernameLower": newUser.displayName.toString().toLowerCase(),
        "photoUrl": newUser.photoUrl != ""
            ? newUser.photoUrl
            : "https://firebasestorage.googleapis.com/v0/b/sm-app-4347b.appspot.com/o/Photo%20de%20profil%2Fperson-circle.png?alt=media&token=11b8cad9-ebf5-4ff2-860a-357b07548a75",
        "email": FirebaseAuth.instance.currentUser!.email,
        "firstName": newUser.firstName,
        "lastName": newUser.lastName,
        "displayName": newUser.displayName,
        "displayNameLower": newUser.displayName.toLowerCase(),
        "bio": newUser.bio,
        "timestamp": timestamp,
        "theme": newUser.theme,
        "verified": false,
        "locale": Provider.of<LocaleProvider>(context, listen: false)
            .getLocaleFormatString(),
        "postsCount": 0,
        "gender": newUser.gender,
        "dateOfBirth": newUser.dateOfBirth,
      });
      // Make new user their own follower
      await followersRef
          .doc(userId)
          .collection('userFollowers')
          .doc(userId)
          .set({});
      doc = await usersRef.doc(userId).get();
    }
    currentUser = DaveUser.User.fromDocument(doc);
    Provider.of<ThemeProvider>(context, listen: false)
        .toggleThemeToParam(currentUser.theme);
    Provider.of<LocaleProvider>(context, listen: false)
        .toggleLocaleToParam(currentUser.locale);
    await FirebaseApi().initMessaging(currentUser.id);
    setState(() {
      isAuth = true;
    });
  }

  void initLocalNotifications() async {
    await NotificationsApi.init(context);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
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
    if (this.pageIndex == 0 && pageIndex == 0) {
      timelineKey.currentState!.getToTop();
    }
    pageController.jumpToPage(pageIndex);
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          Timeline(key: timelineKey, currentUser: currentUser),
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
            label: AppLocalizations.of(context)!.timeline,
            icon: Icon(CupertinoIcons.text_justify),
          ),
          BottomNavigationBarItem(
            label: AppLocalizations.of(context)!.search,
            icon: Icon(CupertinoIcons.search),
          ),
          BottomNavigationBarItem(
            label: AppLocalizations.of(context)!.post,
            icon: Icon(CupertinoIcons.add),
          ),
          BottomNavigationBarItem(
            label: AppLocalizations.of(context)!.profile,
            icon: Icon(CupertinoIcons.person),
          ),
          BottomNavigationBarItem(
            label: AppLocalizations.of(context)!.notifications,
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
        color: Color.fromARGB(255, 89, 36, 99),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () => {FirebaseAuth.instance.signOut()},
              child: Image.asset(
                'assets/images/logo/logo_launch.png',
                width: 256,
              ),
            ),
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

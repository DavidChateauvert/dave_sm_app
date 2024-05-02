// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/api/notification_api.dart';
import 'package:sm_app/pages/authentification/authentification_service.dart';
import 'package:sm_app/pages/intro.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/pages/timeline.dart';
import 'package:sm_app/pages/upload.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/providers/notification_provider.dart';
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
final transferRef = FirebaseFirestore.instance.collection('transferred');
final DateTime timestamp = DateTime.now();
late DaveUser.User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late NotificationsApi notificationsApi;
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
    notificationsApi = NotificationsApi();

    checkIfUserExist();
    initLocalNotifications();
  }

  checkIfTransferred(String newUserId) async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    // Check if email is in the map
    if (AuthentificationService().doesEmailExist(userEmail)) {
      // Check if already tranferred
      bool alreadyTransferred =
          await AuthentificationService().checkIfAlreadyTransferred(newUserId);
      if (!alreadyTransferred) {
        String oldUserId =
            await AuthentificationService().getOldUserIdFromEmail(userEmail);
        AuthentificationService().transferUser(context, oldUserId, newUserId);
      }
    }
  }

  checkIfUserExist() async {
    final String userId;
    String provider =
        FirebaseAuth.instance.currentUser!.providerData[0].providerId;
    if (provider == "google.com") {
      GoogleSignInAccount? googleUser = googleSignIn.currentUser;
      if (googleUser == null) {
        googleUser = await googleSignIn.signInSilently();
      }
      // userId = googleUser!.id;
    }
    // else {
    userId = FirebaseAuth.instance.currentUser!.uid;
    //}
    // await checkIfTransferred(userId);
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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/notification_api.dart';
import 'package:sm_app/pages/authentification/authenfication_page.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/post_counter.dart';
import 'package:sm_app/providers/reload_provider.dart';
import 'package:sm_app/providers/route_observer_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:sm_app/theme/theme.dart';
import 'package:sm_app/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onMessage.listen((message) {
    NotificationsApi().handleNotificationInside(message);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    NotificationsApi().handleNotificationOnClick(message);
  });
  FirebaseMessaging.onBackgroundMessage(_handleBackGroundMessage);

  // FirebaseMessaging.onBackgroundMessage(handleBackGroundMessage);
  await Firebase.initializeApp();
  //initializeFirebase();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => NotificationProvider()),
          ChangeNotifierProvider(create: (context) => RouteObserverProvider()),
          ChangeNotifierProvider(create: (context) => ReloadNotifier()),
          ChangeNotifierProvider(create: (context) => PostCounterProvider()),
          ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ],
        child: MyApp(),
      ),
    );
  });
}

Future<void> _handleBackGroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationsApi().handleBackGroundMessage(message);
}

void initializeFirebase() async {
  await Firebase.initializeApp();
  // await Firebase.initializeApp(
  //   options: FirebaseOptions(
  //     apiKey: "AIzaSyDSBBIJnN5cWAyVZGnTGfiq36wcsnynyz4",
  //     authDomain: "sm-app-4347b.firebaseapp.com",
  //     projectId: "sm-app-4347b",
  //     storageBucket: "sm-app-4347b.appspot.com",
  //     messagingSenderId: "988198906820",
  //     appId: "1:988198906820:web:f789a36eeccf962dbc5291",
  //     measurementId: "G-S2H4HQV6WG",
  // ));
  // await FirebaseApi().initMessaging(currentUser.id);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NotificationsApi.initialize(context);
    return MaterialApp(
      title: 'Dave',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Provider.of<LocaleProvider>(context).locale,
      home: AuthentificationPage(),
    );
  }
}
